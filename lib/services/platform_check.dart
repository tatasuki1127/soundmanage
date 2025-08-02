import 'dart:io';

class PlatformCheck {
  static bool get isIOS => Platform.isIOS;
  static bool get isAndroid => Platform.isAndroid;
  
  static void printPlatformInfo() {
    print('🔍 Platform Detection:');
    print('   iOS: $isIOS');
    print('   Android: $isAndroid');
    print('   Platform: ${Platform.operatingSystem}');
    print('   Version: ${Platform.operatingSystemVersion}');
  }
}