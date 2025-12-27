# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
