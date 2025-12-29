import 'dart:async';
import 'package:flutter/services.dart';
import 'uhf_tag.dart';
import 'uhf_reader_state.dart';

/// Flutter plugin for Senter UHF RFID readers
class UhfReader {
  /// Method channel for invoking native methods
  static const MethodChannel _channel = MethodChannel('flutter_uhf_plugin/methods');

  /// Event channel for receiving tag reads
  static const EventChannel _tagEventChannel = EventChannel('flutter_uhf_plugin/tags');

  /// Event channel for receiving state changes
  static const EventChannel _stateEventChannel = EventChannel('flutter_uhf_plugin/state');

  /// Singleton instance
  static UhfReader? _instance;

  /// Stream controller for tag events
  StreamController<UhfTag>? _tagStreamController;

  /// Stream controller for state changes
  StreamController<UhfReaderState>? _stateStreamController;

  /// Subscription for tag events from native
  StreamSubscription? _tagEventSubscription;

  /// Subscription for state events from native
  StreamSubscription? _stateEventSubscription;

  /// Whether event channels are set up
  bool _eventChannelsSetup = false;

  /// Current reader state
  UhfReaderState _state = UhfReaderState.uninitialized;

  /// Current power level in dBm
  int _powerLevel = 26;

  /// Set of unique tags found in current session
  final Set<String> _uniqueTags = {};

  /// Map of tags with their read counts
  final Map<String, UhfTag> _tagMap = {};

  /// Private constructor
  UhfReader._();

  /// Get the singleton instance
  static UhfReader get instance {
    _instance ??= UhfReader._();
    return _instance!;
  }

  /// Current reader state
  UhfReaderState get state => _state;

  /// Current power level in dBm (0-30)
  int get powerLevel => _powerLevel;

  /// Number of unique tags found
  int get uniqueTagCount => _uniqueTags.length;

  /// List of all unique tags found
  List<UhfTag> get tags => _tagMap.values.toList();

  /// Stream of tag reads
  Stream<UhfTag> get tagStream {
    _tagStreamController ??= StreamController<UhfTag>.broadcast();
    return _tagStreamController!.stream;
  }

  /// Stream of state changes
  Stream<UhfReaderState> get stateStream {
    _stateStreamController ??= StreamController<UhfReaderState>.broadcast();
    return _stateStreamController!.stream;
  }

  /// Initialize the UHF reader
  /// Returns true if initialization was successful
  Future<bool> init() async {
    try {
      _updateState(UhfReaderState.initializing);
      
      final bool result = await _channel.invokeMethod('init');
      
      if (result) {
        _updateState(UhfReaderState.ready);
        _setupEventChannels();
      } else {
        _updateState(UhfReaderState.error);
      }
      
      return result;
    } on PlatformException catch (e) {
      print('Failed to initialize UHF reader: ${e.message}');
      _updateState(UhfReaderState.error);
      return false;
    }
  }

  /// Set the power level (0-30 dBm)
  /// Higher power = longer range
  /// Recommended: 23-26 for 5-6 meter range
  Future<bool> setPower(int powerDbm) async {
    if (powerDbm < 0 || powerDbm > 30) {
      throw ArgumentError('Power must be between 0 and 30 dBm');
    }

    try {
      final bool result = await _channel.invokeMethod('setPower', {'power': powerDbm});
      if (result) {
        _powerLevel = powerDbm;
      }
      return result;
    } on PlatformException catch (e) {
      print('Failed to set power: ${e.message}');
      return false;
    }
  }

  /// Get the current power level from the reader
  Future<int?> getPower() async {
    try {
      final int? power = await _channel.invokeMethod('getPower');
      if (power != null) {
        _powerLevel = power;
      }
      return power;
    } on PlatformException catch (e) {
      print('Failed to get power: ${e.message}');
      return null;
    }
  }

  /// Start continuous inventory scanning
  Future<bool> startInventory() async {
    if (_state != UhfReaderState.ready) {
      print('Reader is not ready. Current state: $_state');
      return false;
    }

    try {
      final bool result = await _channel.invokeMethod('startInventory');
      if (result) {
        _updateState(UhfReaderState.scanning);
      }
      return result;
    } on PlatformException catch (e) {
      print('Failed to start inventory: ${e.message}');
      return false;
    }
  }

  /// Stop inventory scanning
  Future<bool> stopInventory() async {
    try {
      final bool result = await _channel.invokeMethod('stopInventory');
      if (result) {
        _updateState(UhfReaderState.ready);
      }
      return result;
    } on PlatformException catch (e) {
      print('Failed to stop inventory: ${e.message}');
      return false;
    }
  }

  /// Clear all found tags
  void clearTags() {
    _uniqueTags.clear();
    _tagMap.clear();
  }

  /// Check if the reader is initialized
  Future<bool> isInitialized() async {
    try {
      return await _channel.invokeMethod('isInitialized');
    } on PlatformException {
      return false;
    }
  }

  /// Get estimated range for a given power level
  static String getEstimatedRange(int powerDbm) {
    if (powerDbm <= 5) return '~0.5m';
    if (powerDbm <= 10) return '~1-2m';
    if (powerDbm <= 15) return '~2-3m';
    if (powerDbm <= 20) return '~3-4m';
    if (powerDbm <= 25) return '~4-5m';
    if (powerDbm <= 28) return '~5-6m';
    return '~6-8m';
  }

  /// Dispose of the reader resources
  Future<void> dispose() async {
    try {
      await stopInventory();
      await _channel.invokeMethod('dispose');
      _updateState(UhfReaderState.disposed);
      
      // Cancel native event subscriptions
      await _tagEventSubscription?.cancel();
      await _stateEventSubscription?.cancel();
      _tagEventSubscription = null;
      _stateEventSubscription = null;
      _eventChannelsSetup = false;
      
      await _tagStreamController?.close();
      await _stateStreamController?.close();
      _tagStreamController = null;
      _stateStreamController = null;
    } on PlatformException catch (e) {
      print('Failed to dispose UHF reader: ${e.message}');
    }
  }

  /// Setup event channels for receiving data from native side
  void _setupEventChannels() {
    // Only setup once to avoid multiple subscriptions
    if (_eventChannelsSetup) return;
    _eventChannelsSetup = true;

    try {
      _tagEventSubscription = _tagEventChannel.receiveBroadcastStream().listen(
        (dynamic event) {
          if (event is Map) {
            try {
              final tag = UhfTag.fromMap(event);
              _handleTagRead(tag);
            } catch (e) {
              print('Error parsing tag: $e');
            }
          }
        },
        onError: (dynamic error) {
          print('Tag event error: $error');
        },
        cancelOnError: false,
      );
    } catch (e) {
      print('Failed to setup tag event channel: $e');
    }

    try {
      _stateEventSubscription = _stateEventChannel.receiveBroadcastStream().listen(
        (dynamic event) {
          if (event is String) {
            final state = _parseState(event);
            _updateState(state);
          }
        },
        onError: (dynamic error) {
          print('State event error: $error');
        },
        cancelOnError: false,
      );
    } catch (e) {
      print('Failed to setup state event channel: $e');
    }
  }

  /// Handle a tag read event
  void _handleTagRead(UhfTag tag) {
    if (_tagMap.containsKey(tag.epc)) {
      _tagMap[tag.epc]!.readCount++;
    } else {
      _tagMap[tag.epc] = tag;
      _uniqueTags.add(tag.epc);
    }
    _tagStreamController?.add(tag);
  }

  /// Update the reader state
  void _updateState(UhfReaderState newState) {
    _state = newState;
    _stateStreamController?.add(newState);
  }

  /// Parse state string from native side
  UhfReaderState _parseState(String state) {
    switch (state.toLowerCase()) {
      case 'uninitialized':
        return UhfReaderState.uninitialized;
      case 'initializing':
        return UhfReaderState.initializing;
      case 'ready':
        return UhfReaderState.ready;
      case 'scanning':
        return UhfReaderState.scanning;
      case 'error':
        return UhfReaderState.error;
      case 'disposed':
        return UhfReaderState.disposed;
      default:
        return UhfReaderState.uninitialized;
    }
  }
}
