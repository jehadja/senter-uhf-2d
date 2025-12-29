# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.5] - 2025-12-29

### Fixed
- Fixed duplicate event channel subscriptions causing potential crashes
- Added null safety checks in `UhfTag.fromMap()` for invalid EPC data
- Proper cleanup of event subscriptions on dispose
- Added `cancelOnError: false` to prevent stream termination on errors

### Improved
- Better error handling in event channel setup
- Added guards to prevent multiple event channel subscriptions

## [1.0.4] - 2025-12-27

### Added
- `getSerialNumber({int lastHexChars = 6})` - extract serial from last N hex chars of EPC
- `getSerialNumberString({int lastHexChars = 6})` - get serial as string
- `extractHexRange(int start, int end)` - extract specific portion of EPC

### Fixed
- Serial number extraction now correctly gets the embedded serial from EPC
  Example: EPC with serial 15551831 (hex ED4D57) now extracts correctly

## [1.0.3] - 2025-12-27

### Added
- `epcDecimal` getter - converts EPC hex to BigInt decimal
- `epcDecimalString` getter - returns decimal as string
- `epcDecimalLast(int digits)` - get last N digits of decimal EPC
- `UhfTag.hexToDecimal(String hex)` - static utility for hex to decimal
- `UhfTag.decimalToHex(BigInt decimal)` - static utility for decimal to hex

## [1.0.2] - 2025-12-27

### Fixed
- Fixed AndroidManifest.xml package attribute issue for AGP 8.0+ compatibility
- Removed deprecated package attribute from AndroidManifest.xml
- Namespace now properly defined in build.gradle

## [1.0.1] - 2025-12-27

### Fixed
- Cleaned up build artifacts from package
- Reduced package size

## [1.0.0] - 2025-12-27

### Added
- Initial release
- UHF RFID tag reading support for Senter devices
- Continuous inventory scanning with real-time tag updates
- Power control (0-30 dBm) for adjustable reading range
- Tag stream via EventChannel for reactive UI updates
- State management with state stream
- Support for EPC, RSSI, frequency, and antenna ID data
- Example application with full UI

### Features
- `init()` - Initialize the UHF reader
- `dispose()` - Release UHF resources
- `startInventory()` - Start continuous tag scanning
- `stopInventory()` - Stop scanning
- `setPower(int dBm)` - Set output power (0-30 dBm)
- `getPower()` - Get current power level
- `tagStream` - Stream of scanned tags
- `stateStream` - Stream of reader state changes

### Supported Devices
- Senter UHF D2 series readers
- Compatible with PAD devices with built-in UHF readers
