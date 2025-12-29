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
    final epcValue = map['epc'];
    if (epcValue == null || epcValue is! String || epcValue.isEmpty) {
      throw ArgumentError('Invalid or missing EPC value in tag data');
    }
    
    return UhfTag(
      epc: epcValue,
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

  /// Convert EPC hex string to decimal (BigInt for large values)
  /// Returns the decimal representation of the EPC
  BigInt get epcDecimal {
    final cleanHex = epc.replaceAll(RegExp(r'[^0-9A-Fa-f]'), '');
    if (cleanHex.isEmpty) return BigInt.zero;
    return BigInt.parse(cleanHex, radix: 16);
  }

  /// Convert EPC hex string to decimal string
  String get epcDecimalString => epcDecimal.toString();

  /// Get the serial number from the last N hex characters of the EPC
  /// For most RFID tags, the serial is in the last 6-8 hex chars
  /// Example: EPC "E20011223344ED4D57" with lastHexChars=6 -> "ED4D57" -> 15551831
  BigInt getSerialNumber({int lastHexChars = 6}) {
    final cleanHex = epc.replaceAll(RegExp(r'[^0-9A-Fa-f]'), '');
    if (cleanHex.isEmpty) return BigInt.zero;
    final start = cleanHex.length > lastHexChars 
        ? cleanHex.length - lastHexChars 
        : 0;
    final serialHex = cleanHex.substring(start);
    return BigInt.parse(serialHex, radix: 16);
  }

  /// Get serial number as string
  String getSerialNumberString({int lastHexChars = 6}) {
    return getSerialNumber(lastHexChars: lastHexChars).toString();
  }

  /// Extract serial from specific byte range (start and end are hex character positions)
  /// Example: extractHexRange(14, 20) extracts chars 14-19 (6 chars)
  BigInt extractHexRange(int start, int end) {
    final cleanHex = epc.replaceAll(RegExp(r'[^0-9A-Fa-f]'), '');
    if (cleanHex.isEmpty || start >= cleanHex.length) return BigInt.zero;
    final actualEnd = end > cleanHex.length ? cleanHex.length : end;
    final extracted = cleanHex.substring(start, actualEnd);
    if (extracted.isEmpty) return BigInt.zero;
    return BigInt.parse(extracted, radix: 16);
  }

  /// Get the last N digits of the decimal EPC (useful for short IDs)
  String epcDecimalLast(int digits) {
    final decimal = epcDecimalString;
    if (decimal.length <= digits) return decimal;
    return decimal.substring(decimal.length - digits);
  }

  /// Static utility to convert any hex string to decimal
  static BigInt hexToDecimal(String hex) {
    final cleanHex = hex.replaceAll(RegExp(r'[^0-9A-Fa-f]'), '');
    if (cleanHex.isEmpty) return BigInt.zero;
    return BigInt.parse(cleanHex, radix: 16);
  }

  /// Static utility to convert decimal to hex string
  static String decimalToHex(BigInt decimal) {
    return decimal.toRadixString(16).toUpperCase();
  }

  @override
  String toString() {
    return 'UhfTag(epc: $epc, epcDecimal: $epcDecimalString, rssi: $rssi, readCount: $readCount)';
  }
}
