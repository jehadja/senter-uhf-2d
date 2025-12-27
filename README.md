# Flutter UHF Plugin

[![pub package](https://img.shields.io/pub/v/flutter_uhf_plugin.svg)](https://pub.dev/packages/flutter_uhf_plugin)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A Flutter plugin for Senter UHF RFID readers. Supports tag inventory, power control, and continuous reading for Android devices.

**Author:** Jehad Jaghoub  
**Company:** Transforat

## Features

- ✅ Real-time UHF RFID tag reading
- ✅ Continuous inventory scanning
- ✅ Power control (0-30 dBm) for adjustable reading range
- ✅ Tag stream with EPC, RSSI, frequency data
- ✅ State management with reactive streams
- ✅ Optimized for Senter UHF D2 devices

## Supported Devices

- Senter UHF D2 series
- PAD devices with built-in UHF readers
- Other devices using the Senter UHF SDK

## Installation

Add this to your pubspec.yaml:

\`\`\`yaml
dependencies:
  flutter_uhf_plugin: ^1.0.0
\`\`\`

## Usage

\`\`\`dart
import 'package:flutter_uhf_plugin/flutter_uhf_plugin.dart';

final reader = UhfReader.instance;

// Initialize
await reader.init();
await reader.setPower(26); // 26 dBm for 5-6m range

// Listen to tags
reader.tagStream.listen((tag) {
  print('EPC: \${tag.epc}, RSSI: \${tag.rssi}');
});

// Start/stop scanning
await reader.startInventory();
await reader.stopInventory();

// Cleanup
await reader.dispose();
\`\`\`

## Power Guide

| Power (dBm) | Range |
|-------------|-------|
| 0-10 | ~0.5-2m |
| 10-20 | ~2-4m |
| 20-26 | ~4-6m |
| 26-30 | ~5-8m |

## License

MIT License - Jehad Jaghoub, Transforat
