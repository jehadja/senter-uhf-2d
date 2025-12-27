/// Represents a UHF RFID tag
class UhfTag {
  /// The Electronic Product Code (EPC) of the tag
  final String epc;

  /// The Received Signal Strength Indicator (RSSI) in dBm
  final int? rssi;

  /// The frequency point at which the tag was read
  final int? frequencyKHz;

  /// The antenna ID that read the tag
  final int? antennaId;

  /// The timestamp when the tag was read
  final DateTime readTime;

  /// Number of times this tag has been read
  int readCount;

  UhfTag({
    required this.epc,
    this.rssi,
    this.frequencyKHz,
    this.antennaId,
    DateTime? readTime,
    this.readCount = 1,
  }) : readTime = readTime ?? DateTime.now();

  /// Create a UhfTag from a map (used for platform channel communication)
  factory UhfTag.fromMap(Map<dynamic, dynamic> map) {
    return UhfTag(
      epc: map['epc'] as String,
      rssi: map['rssi'] as int?,
      frequencyKHz: map['frequencyKHz'] as int?,
      antennaId: map['antennaId'] as int?,
      readCount: map['readCount'] as int? ?? 1,
    );
  }

  /// Convert to map for platform channel communication
  Map<String, dynamic> toMap() {
    return {
      'epc': epc,
      'rssi': rssi,
      'frequencyKHz': frequencyKHz,
      'antennaId': antennaId,
      'readTime': readTime.millisecondsSinceEpoch,
      'readCount': readCount,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UhfTag && other.epc == epc;
  }

  @override
  int get hashCode => epc.hashCode;

  @override
  String toString() {
    return 'UhfTag(epc: $epc, rssi: $rssi, readCount: $readCount)';
  }
}
