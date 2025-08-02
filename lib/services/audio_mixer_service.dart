import 'package:audio_session/audio_session.dart';
import 'dart:async';

class AudioMixerService {
  static AudioSession? _session;
  static Timer? _keepAliveTimer;
  static bool _isVoIPActive = false;
  
  static Future<bool> enableVoIPMixing() async {
    try {
      _session = await AudioSession.instance;
      
      // 🎯 WebView音声を阻害しない「共存型」VoIP設定
      await _session!.configure(AudioSessionConfiguration(
        // ambientからplaybackに変更（音声フォーカスを奪わない）
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions: 
          AVAudioSessionCategoryOptions.mixWithOthers |
          AVAudioSessionCategoryOptions.duckOthers |
          AVAudioSessionCategoryOptions.allowBluetooth,
        // 通常の再生モード（VoIP感を残しつつWebViewと共存）
        avAudioSessionMode: AVAudioSessionMode.spokenAudio,
      ));
      
      // ⚠️ setActive(false)でWebViewの音声フォーカスを尊重
      await _session!.setActive(false);
      
      // 軽量キープアライブ（音声フォーカスを奪わない）
      _startLightweightKeepAlive();
      
      _isVoIPActive = true;
      print('Lightweight VoIP session enabled (WebView-friendly)');
      return true;
    } catch (e) {
      print('VoIP session error: $e');
      return false;
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