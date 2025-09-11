import 'dart:async';
import 'package:golden_toolkit/golden_toolkit.dart';

/// Flutter test configuration
/// This file is automatically loaded by the Flutter test framework
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  return GoldenToolkit.runWithConfiguration(
    () async {
      // Load fonts for consistent golden test rendering
      await loadAppFonts();

      // Run the tests
      await testMain();
    },
    config: GoldenToolkitConfiguration(
      // Skip golden tests on CI if not running on the same OS
      skipGoldenAssertion: () => false,
      
      // Default device configuration for golden tests
      defaultDevices: const [
        Device.phone,
        Device.iphone11,
        Device.tabletPortrait,
      ],
      enableRealShadows: true,
    ),
  );
}