import 'package:audio_session/audio_session.dart';
import 'dart:async';
import 'dart:io';
import 'platform_check.dart';

class AudioMixerService {
  static AudioSession? _session;
  static Timer? _keepAliveTimer;
  static bool _isVoIPActive = false;
  
  static Future<bool> enableVoIPMixing() async {
    try {
      _session = await AudioSession.instance;
      
      // 🍎 プラットフォーム診断情報の出力
      PlatformCheck.printPlatformInfo();
      print('Starting VoIP session configuration...');
      
      // 🚨 iOS Simulator検出と警告
      if (Platform.isIOS) {
        print('🍎 iOS Platform detected');
        try {
          final version = Platform.operatingSystemVersion;
          print('   iOS Version: $version');
          
          // iOS Simulatorの検出試行
          if (version.contains('Simulator') || version.contains('x86_64')) {
            print('⚠️  WARNING: iOS Simulator detected - Audio session functionality may be limited');
            print('   For full VoIP functionality, test on a real iOS device');
          }
        } catch (e) {
          print('   Version detection failed: $e');
        }
      }
      
      // 🎯 iOS互換性を優先した段階的設定
      try {
        // Stage 1: 最も基本的な設定から開始
        await _session!.configure(AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.playback,
          avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.mixWithOthers,
          avAudioSessionMode: AVAudioSessionMode.defaultMode,
        ));
        print('✅ Basic playback configuration successful');
        
        // Stage 2: より高度な設定を試行
        await _session!.configure(AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.playback,
          avAudioSessionCategoryOptions: 
            AVAudioSessionCategoryOptions.mixWithOthers |
            AVAudioSessionCategoryOptions.duckOthers,
          avAudioSessionMode: AVAudioSessionMode.spokenAudio,
        ));
        print('✅ Advanced playback configuration successful');
        
      } catch (configError) {
        print('⚠️ Advanced config failed, falling back to basic: $configError');
        
        // Fallback: 最小限の設定
        await _session!.configure(AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.ambient,
          avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.mixWithOthers,
        ));
        print('✅ Fallback ambient configuration successful');
      }
      
      // iOS: setActive(false)でパッシブモード
      try {
        await _session!.setActive(false);
        print('✅ Session set to passive mode');
      } catch (activeError) {
        print('⚠️ setActive failed (non-critical): $activeError');
      }
      
      // 軽量キープアライブ開始
      _startLightweightKeepAlive();
      
      _isVoIPActive = true;
      print('🎉 iOS VoIP session enabled successfully');
      return true;
      
    } catch (e) {
      print('❌ iOS VoIP session failed: $e');
      print('Error type: ${e.runtimeType}');
      
      // 🔄 最後の救済策: ambient only
      try {
        print('🔄 Attempting rescue with ambient-only configuration...');
        await _session!.configure(AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.ambient,
        ));
        _isVoIPActive = true;
        print('✅ Rescue configuration successful');
        return true;
      } catch (rescueError) {
        print('❌ Rescue attempt failed: $rescueError');
        return false;
      }
    }
  }
  
  static Future<bool> disableVoIPMixing() async {
    try {
      _stopKeepAliveSession();
      
      // 通常の再生セッションに戻す
      await _session?.configure(AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.mixWithOthers,
      ));
      
      await _session?.setActive(false);
      
      _isVoIPActive = false;
      print('VoIP mixing session disabled');
      return true;
    } catch (e) {
      print('VoIP session disable error: $e');
      return false;
    }
  }
  
  static void _startLightweightKeepAlive() {
    _stopKeepAliveSession();
    
    // 🔄 軽量キープアライブ（10秒間隔、WebView音声を阻害しない）
    _keepAliveTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      _maintainLightweightSession();
    });
  }
  
  static void _stopKeepAliveSession() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = null;
  }
  
  static Future<void> _maintainLightweightSession() async {
    try {
      if (_session != null && _isVoIPActive) {
        // 🎯 WebView音声を邪魔しない軽量メンテナンス
        // setActive(true)は呼ばない（音声フォーカスを奪わない）
        print('Lightweight VoIP session maintained (non-intrusive)');
        
        // Spotifyとの両立のため、設定のみ確認
        await _session!.configure(AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.playback,
          avAudioSessionCategoryOptions: 
            AVAudioSessionCategoryOptions.mixWithOthers |
            AVAudioSessionCategoryOptions.duckOthers |
            AVAudioSessionCategoryOptions.allowBluetooth,
          avAudioSessionMode: AVAudioSessionMode.spokenAudio,
        ));
      }
    } catch (e) {
      print('Lightweight session maintenance error: $e');
      // エラー時もWebViewを阻害しない復旧処理
      try {
        await _session!.configure(AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.playback,
          avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.mixWithOthers,
          avAudioSessionMode: AVAudioSessionMode.defaultMode,
        ));
        // setActive(false)でパッシブ維持
        await _session!.setActive(false);
      } catch (reinitError) {
        print('Lightweight session recovery error: $reinitError');
      }
    }
  }
  
  static bool get isVoIPActive => _isVoIPActive;
  static bool get isInitialized => _session != null;
  
  static Future<void> dispose() async {
    await disableVoIPMixing();
    _session = null;
  }
  
  // アプリがバックグラウンドに移行する際の処理
  static Future<void> handleAppStateChange(bool isBackground) async {
    if (isBackground && _isVoIPActive) {
      // バックグラウンドでもVoIPセッションを維持
      print('Maintaining VoIP session in background');
    } else if (!isBackground && _isVoIPActive) {
      // フォアグラウンド復帰時の処理
      print('VoIP session resumed in foreground');
    }
  }
}