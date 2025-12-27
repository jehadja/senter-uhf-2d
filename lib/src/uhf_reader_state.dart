/// Represents the current state of the UHF reader
enum UhfReaderState {
  /// Reader is not initialized
  uninitialized,

  /// Reader is initializing
  initializing,

  /// Reader is ready to scan
  ready,

  /// Reader is actively scanning for tags
  scanning,

  /// Reader encountered an error
  error,

  /// Reader is disposed
  disposed,
}

/// Extension methods for UhfReaderState
extension UhfReaderStateExtension on UhfReaderState {
  /// Whether the reader is in a state that allows starting a scan
  bool get canStartScan => this == UhfReaderState.ready;

  /// Whether the reader is currently scanning
  bool get isScanning => this == UhfReaderState.scanning;

  /// Whether the reader is initialized and operational
  bool get isOperational =>
      this == UhfReaderState.ready || this == UhfReaderState.scanning;

  /// Human-readable description of the state
  String get description {
    switch (this) {
      case UhfReaderState.uninitialized:
        return 'Not Initialized';
      case UhfReaderState.initializing:
        return 'Initializing...';
      case UhfReaderState.ready:
        return 'Ready';
      case UhfReaderState.scanning:
        return 'Scanning...';
      case UhfReaderState.error:
        return 'Error';
      case UhfReaderState.disposed:
        return 'Disposed';
    }
  }
}
