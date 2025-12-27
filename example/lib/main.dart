import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_uhf_plugin/flutter_uhf_plugin.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UHF Reader Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const UhfReaderPage(),
    );
  }
}

class UhfReaderPage extends StatefulWidget {
  const UhfReaderPage({super.key});

  @override
  State<UhfReaderPage> createState() => _UhfReaderPageState();
}

class _UhfReaderPageState extends State<UhfReaderPage> {
  final UhfReader _reader = UhfReader.instance;
  
  StreamSubscription<UhfTag>? _tagSubscription;
  StreamSubscription<UhfReaderState>? _stateSubscription;
  
  List<UhfTag> _tags = [];
  UhfReaderState _state = UhfReaderState.uninitialized;
  double _powerSlider = 26;
  String _statusMessage = 'Tap Initialize to start';

  @override
  void initState() {
    super.initState();
    _setupListeners();
  }

  void _setupListeners() {
    _tagSubscription = _reader.tagStream.listen((tag) {
      setState(() {
        // Update existing tag or add new one
        final existingIndex = _tags.indexWhere((t) => t.epc == tag.epc);
        if (existingIndex >= 0) {
          _tags[existingIndex].readCount++;
        } else {
          _tags.insert(0, tag);
        }
      });
    });

    _stateSubscription = _reader.stateStream.listen((state) {
      setState(() {
        _state = state;
        _statusMessage = state.description;
      });
    });
  }

  @override
  void dispose() {
    _tagSubscription?.cancel();
    _stateSubscription?.cancel();
    _reader.dispose();
    super.dispose();
  }

  Future<void> _initReader() async {
    setState(() => _statusMessage = 'Initializing...');
    
    final success = await _reader.init();
    
    setState(() {
      if (success) {
        _statusMessage = 'Ready - Set power and tap Start';
        _state = UhfReaderState.ready;
      } else {
        _statusMessage = 'Failed to initialize';
        _state = UhfReaderState.error;
      }
    });
  }

  Future<void> _setPower() async {
    final power = _powerSlider.round();
    final success = await _reader.setPower(power);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Power set to $power dBm (${UhfReader.getEstimatedRange(power)})'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _toggleScanning() async {
    if (_state == UhfReaderState.scanning) {
      await _reader.stopInventory();
    } else if (_state == UhfReaderState.ready) {
      await _reader.startInventory();
    }
  }

  void _clearTags() {
    setState(() {
      _tags.clear();
      _reader.clearTags();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UHF Reader'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearTags,
            tooltip: 'Clear tags',
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Card
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Status: $_statusMessage',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _getStateColor(),
                        ),
                      ),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _getStateColor(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tags found: ${_tags.length}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),

          // Power Control
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Power Control',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_powerSlider.round()} dBm (${UhfReader.getEstimatedRange(_powerSlider.round())})',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  Slider(
                    value: _powerSlider,
                    min: 0,
                    max: 30,
                    divisions: 30,
                    label: '${_powerSlider.round()} dBm',
                    onChanged: _state.isOperational
                        ? (value) {
                            setState(() => _powerSlider = value);
                          }
                        : null,
                    onChangeEnd: (_) => _setPower(),
                  ),
                  const Text(
                    'Higher power = longer range (5-6m recommended: 23-26 dBm)',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),

          // Control Buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _state == UhfReaderState.uninitialized ||
                            _state == UhfReaderState.error
                        ? _initReader
                        : null,
                    icon: const Icon(Icons.power_settings_new),
                    label: const Text('Initialize'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _state.isOperational ? _toggleScanning : null,
                    icon: Icon(_state.isScanning ? Icons.stop : Icons.play_arrow),
                    label: Text(_state.isScanning ? 'Stop' : 'Start'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _state.isScanning ? Colors.red : Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tag List
          Expanded(
            child: _tags.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.nfc,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No tags found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start scanning to find UHF tags',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _tags.length,
                    itemBuilder: (context, index) {
                      final tag = _tags[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                Theme.of(context).colorScheme.primaryContainer,
                            child: Text('${index + 1}'),
                          ),
                          title: Text(
                            tag.epc,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            'Reads: ${tag.readCount}${tag.rssi != null ? ' | RSSI: ${tag.rssi} dBm' : ''}',
                          ),
                          trailing: Icon(
                            Icons.nfc,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Color _getStateColor() {
    switch (_state) {
      case UhfReaderState.uninitialized:
        return Colors.grey;
      case UhfReaderState.initializing:
        return Colors.orange;
      case UhfReaderState.ready:
        return Colors.green;
      case UhfReaderState.scanning:
        return Colors.blue;
      case UhfReaderState.error:
        return Colors.red;
      case UhfReaderState.disposed:
        return Colors.grey;
    }
  }
}
