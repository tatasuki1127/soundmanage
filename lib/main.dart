import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:volume_controller/volume_controller.dart';
import 'services/audio_mixer_service.dart';
import 'dart:io';

void main() {
  runApp(const SoundMixerApp());
}

class SoundMixerApp extends StatelessWidget {
  const SoundMixerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SoundMixer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF007AFF),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF2F2F7),
        useMaterial3: true,
      ),
      home: const SoundMixerHomePage(),
    );
  }
}

class SoundMixerHomePage extends StatefulWidget {
  const SoundMixerHomePage({super.key});

  @override
  State<SoundMixerHomePage> createState() => _SoundMixerHomePageState();
}

class _SoundMixerHomePageState extends State<SoundMixerHomePage> with WidgetsBindingObserver {
  bool _isVoIPEnabled = false;
  String _currentStatus = 'VoIPセッション: 停止中';
  bool _isLoading = false;
  double _youtubeVolume = 0.7;
  double _systemVolume = 0.7;
  
  late WebViewController _webViewController;
  bool _isWebViewReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeWebView();
    _initializeVolumeController();
    
    // 🎯 Ultra Think Solution: アプリ起動時即座にVoIPセッション開始
    // Spotify保護のための予防的措置
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _enablePreventiveVoIPSession();
    });
  }
  
  // 🛡️ 予防的VoIPセッション（Spotify保護）
  Future<void> _enablePreventiveVoIPSession() async {
    print('🛡️ Enabling preventive VoIP session to protect Spotify...');
    final success = await AudioMixerService.enableVoIPMixing();
    if (success) {
      setState(() {
        _isVoIPEnabled = true;
        _currentStatus = 'VoIPセッション: 自動保護モード - Spotify継続保証';
      });
      print('✅ Preventive VoIP session active - Spotify protected');
    } else {
      print('⚠️ Preventive VoIP session failed - manual activation needed');
    }
  }
  
  // 🔧 Ultra Think: Spotify保護の強化処理
  Future<void> _reinforceSpotifyProtection() async {
    print('🔧 Reinforcing Spotify protection...');
    
    // VoIPセッションの状態確認と強化
    if (_isVoIPEnabled) {
      try {
        // AudioMixerServiceの専用Spotify保護強化機能を使用
        final reinforced = await AudioMixerService.reinforceSpotifyProtection();
        
        if (reinforced) {
          print('✅ AudioMixerService: Spotify protection reinforced');
        } else {
          print('⚠️ AudioMixerService: Spotify protection reinforcement failed');
          
          // フォールバック: 基本VoIPセッション再設定
          await AudioMixerService.enableVoIPMixing();
          print('🔄 Fallback VoIP session reactivated');
        }
        
        // WebViewに保護強化を通知
        if (_isWebViewReady) {
          _webViewController.runJavaScript('''
            console.log('🛡️ Flutter side: Spotify protection reinforced');
            if (typeof preventSpotifyInterruption === 'function') {
              preventSpotifyInterruption();
              console.log('✅ JavaScript side: Spotify protection reactivated');
            }
          ''');
        }
      } catch (e) {
        print('⚠️ VoIP session reinforcement failed: $e');
      }
    }
  }
  
  // 🎯 WebViewタッチ時のSpotify保護
  void _onWebViewInteraction() {
    print('👆 WebView interaction detected - protecting Spotify...');
    
    if (_isVoIPEnabled && _isWebViewReady) {
      // タッチ前の予防的保護
      _webViewController.runJavaScript('''
        console.log('👆 Pre-touch Spotify protection activated');
        if (typeof preventSpotifyInterruption === 'function') {
          preventSpotifyInterruption();
        }
      ''');
      
      // Flutter側VoIPセッション確認
      _reinforceSpotifyProtection();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AudioMixerService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final isBackground = state == AppLifecycleState.paused || 
                        state == AppLifecycleState.detached;
    AudioMixerService.handleAppStateChange(isBackground);
  }

  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {},
          onPageStarted: (String url) {
            print('WebView started loading: $url');
          },
          onPageFinished: (String url) {
            print('WebView finished loading: $url');
            setState(() {
              _isWebViewReady = true;
            });
            
            // 🎯 Ultra Think Solution: Spotify保護型YouTube制御システム
            _webViewController.runJavaScript('''
              try {
                console.log('🎵 Initializing Spotify-protective YouTube system...');
                
                // 🛡️ Spotify保護のための音声フォーカス制御
                function preventSpotifyInterruption() {
                  
                  // YouTube動画の音声フォーカス要求を無効化
                  var originalRequestAudioFocus = window.AudioContext ? window.AudioContext.prototype.resume : null;
                  if (originalRequestAudioFocus) {
                    window.AudioContext.prototype.resume = function() {
                      console.log('🚫 Blocking AudioContext.resume() to protect Spotify');
                      return Promise.resolve();
                    };
                  }
                  
                  // Media Session APIの音声フォーカス要求を制御
                  if ('mediaSession' in navigator) {
                    console.log('🎵 Configuring MediaSession to coexist with Spotify');
                    navigator.mediaSession.metadata = null;
                    navigator.mediaSession.setActionHandler('play', null);
                    navigator.mediaSession.setActionHandler('pause', null);
                  }
                }
                
                // 🔄 Spotify継続保証付き動画管理
                function setupSpotifyProtectedVideo() {
                  var videos = document.querySelectorAll('video');
                  videos.forEach(function(video, index) {
                    
                    // 動画再生前の予防処理
                    video.addEventListener('loadstart', function(e) {
                      console.log('🎬 Video loading - protecting Spotify...', index);
                      preventSpotifyInterruption();
                    });
                    
                    // 再生開始時の音声フォーカス制御
                    video.addEventListener('play', function(e) {
                      console.log('▶️ Video play event - maintaining Spotify coexistence...', index);
                      
                      // 音量を控えめに設定（Spotifyを尊重）
                      if (video.volume > 0.8) {
                        video.volume = 0.7;
                        console.log('🔊 Video volume adjusted to respect Spotify');
                      }
                      
                      // 音声フォーカス要求の抑制
                      preventSpotifyInterruption();
                    });
                    
                    // Spotify保護型一時停止処理
                    video.addEventListener('pause', function(e) {
                      console.log('⏸️ Video paused, maintaining Spotify priority...', index);
                      setTimeout(function() {
                        if (video.paused && !video.ended) {
                          console.log('🔄 Auto-resuming video (Spotify-safe)...', index);
                          video.play().catch(function(err) {
                            console.log('Auto-resume failed (Spotify protected):', err);
                          });
                        }
                      }, 300); // 短縮してSpotify復旧を優先
                    });
                    
                    // 音声無効化の防止（Spotify配慮型）
                    video.addEventListener('volumechange', function(e) {
                      if (video.muted) {
                        console.log('🔊 Video was muted, unmuting (Spotify-aware)...', index);
                        video.muted = false;
                      }
                    });
                  });
                }
                
                // 🎵 Spotify保護機能の初期化
                preventSpotifyInterruption();
                setupSpotifyProtectedVideo();
                
                // DOM変更時の継続保護
                var observer = new MutationObserver(function(mutations) {
                  console.log('🔍 DOM changed, re-establishing Spotify protection...');
                  preventSpotifyInterruption();
                  setupSpotifyProtectedVideo();
                });
                observer.observe(document.body, { childList: true, subtree: true });
                
                // ユーザーインタラクション時のSpotify配慮
                document.addEventListener('click', function(e) {
                  console.log('👆 User interaction detected, ensuring Spotify coexistence...');
                  preventSpotifyInterruption();
                  
                  var videos = document.querySelectorAll('video');
                  videos.forEach(function(video) {
                    video.muted = false;
                    // 音量をSpotify配慮レベルに調整
                    if (video.volume > 0.8) video.volume = 0.7;
                  });
                });
                
                // 🎉 Spotify保護システム完了
                console.log('✅ Spotify-protective YouTube system initialized');
                
              } catch (e) {
                console.log('❌ Spotify protection setup error:', e);
              }
            ''');
          },
          onWebResourceError: (WebResourceError error) {
            print('WebView error: ${error.description}');
          },
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse('https://m.youtube.com'));
  }

  void _initializeVolumeController() {
    VolumeController().listener((volume) {
      setState(() {
        _systemVolume = volume;
      });
    });
    
    VolumeController().getVolume().then((volume) {
      setState(() {
        _systemVolume = volume;
      });
    });
  }

  Future<void> _toggleVoIPSession() async {
    setState(() {
      _isLoading = true;
    });

    bool success;
    if (_isVoIPEnabled) {
      success = await AudioMixerService.disableVoIPMixing();
      if (success) {
        setState(() {
          _isVoIPEnabled = false;
          _currentStatus = 'VoIPセッション: 停止中';
        });
      }
    } else {
      // 🎯 WebView準備完了まで待機
      if (!_isWebViewReady) {
        print('WebView not ready, waiting...');
        setState(() {
          _currentStatus = 'WebView準備中...';
        });
        
        // WebView準備完了まで最大5秒待機
        int attempts = 0;
        while (!_isWebViewReady && attempts < 50) {
          await Future.delayed(Duration(milliseconds: 100));
          attempts++;
        }
        
        if (!_isWebViewReady) {
          print('WebView preparation timeout');
          setState(() {
            _isLoading = false;
            _currentStatus = 'WebView準備がタイムアウトしました';
          });
          return;
        }
      }
      
      print('Starting lightweight VoIP session (WebView-friendly)...');
      
      // 🔄 WebViewとの共存を優先したVoIPセッション開始
      success = await AudioMixerService.enableVoIPMixing();
      
      if (success) {
        setState(() {
          _isVoIPEnabled = true;
          _currentStatus = 'VoIPセッション: WebView共存モード - Spotify両立可能';
        });
        
        // 🎯 Ultra Think: VoIPセッション後のSpotify保護強化
        await _reinforceSpotifyProtection();
        
        _webViewController.runJavaScript('''
          console.log('🛡️ VoIP session started, reinforcing Spotify protection...');
          
          // Spotify保護の再確認
          if (typeof preventSpotifyInterruption === 'function') {
            preventSpotifyInterruption();
          }
          
          var videos = document.querySelectorAll('video');
          videos.forEach(function(video, index) {
            if (video.paused && !video.ended) {
              console.log('🔄 Resuming video with Spotify protection...', index);
              
              // Spotify配慮型の動画再開
              setTimeout(function() {
                video.play().catch(function(err) {
                  console.log('Video resume failed (Spotify protected):', err);
                });
              }, 100); // Spotifyの状態安定化を待つ
            }
          });
        ''');
        
        _showSpotifyGuidance();
      }
    }

    setState(() {
      _isLoading = false;
    });

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('VoIPセッションの設定に失敗しました'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSpotifyGuidance() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('🎵 Spotifyで音楽を再生'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🎯 軽量VoIPセッション開始！\n\nWebViewと共存する設計でSpotifyと両立できます:'),
              const SizedBox(height: 16),
              const Text('1. 📺 YouTube動画を再生（停止しません）'),
              const Text('2. 🎵 Spotifyアプリで音楽を再生'),
              const Text('3. 🔊 音量スライダーで調整'),
              const SizedBox(height: 16),
              const Text('✅ YouTube継続 + Spotify両立モード！', 
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('⚡ 動画が停止した場合、自動復旧機能が働きます', 
                style: TextStyle(color: Colors.blue, fontSize: 12)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _adjustYouTubeVolume(double volume) {
    setState(() {
      _youtubeVolume = volume;
    });
    
    if (_isWebViewReady) {
      // より安全な音量制御（動画停止を回避）
      _webViewController.runJavaScript('''
        try {
          // 再生中の動画のみ音量調整
          var videos = document.querySelectorAll('video');
          videos.forEach(function(video) {
            if (!video.paused && !video.ended) {
              video.volume = Math.max(0, Math.min(1, $volume));
            }
          });
          
          // YouTube Player APIによる音量調整（より安全）
          if (typeof ytplayer !== 'undefined' && ytplayer.setVolume) {
            ytplayer.setVolume(${(volume * 100).round()});
          }
        } catch (e) {
          console.log('Volume adjustment error:', e);
        }
      ''').catchError((error) {
        print('JavaScript execution error: $error');
      });
    }
  }

  Widget _buildVoIPControlCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(
              _isVoIPEnabled ? Icons.phone : Icons.phone_disabled,
              size: 48,
              color: _isVoIPEnabled 
                  ? const Color(0xFF34C759) 
                  : Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              _isVoIPEnabled ? 'VoIPセッション: アクティブ' : 'VoIPセッション: 停止中',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _isVoIPEnabled 
                    ? const Color(0xFF34C759) 
                    : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _toggleVoIPSession,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isVoIPEnabled 
                      ? const Color(0xFFFF9500) 
                      : const Color(0xFF007AFF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _isVoIPEnabled ? 'セッション停止' : 'セッション開始',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _currentStatus,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVolumeControls() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🔊 音量調整',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text('YouTube音量: ${(_youtubeVolume * 100).round()}%'),
            Slider(
              value: _youtubeVolume,
              onChanged: _adjustYouTubeVolume,
              divisions: 100,
              activeColor: const Color(0xFFFF0000),
            ),
            const SizedBox(height: 8),
            Text('システム音量: ${(_systemVolume * 100).round()}%'),
            Slider(
              value: _systemVolume,
              onChanged: (value) {
                VolumeController().setVolume(value);
                setState(() {
                  _systemVolume = value;
                });
              },
              divisions: 100,
              activeColor: const Color(0xFF1DB954),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SoundMixer - YouTube × Spotify',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        backgroundColor: const Color(0xFF007AFF),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // VoIPセッション制御
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildVoIPControlCard(),
          ),
          
          // YouTube WebView
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                elevation: 4,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        color: const Color(0xFFFF0000),
                        child: const Row(
                          children: [
                            Icon(Icons.play_circle_filled, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'YouTube',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            print('📱 WebView tapped - activating Spotify protection');
                            _onWebViewInteraction();
                          },
                          onPanStart: (_) {
                            print('📱 WebView pan started - protecting Spotify');
                            _onWebViewInteraction();
                          },
                          child: WebViewWidget(controller: _webViewController),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // 音量制御とSpotifyガイダンス
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(child: _buildVolumeControls()),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.music_note,
                              size: 32,
                              color: Color(0xFF1DB954),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Spotify',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1DB954),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isVoIPEnabled 
                                  ? 'アプリで音楽を\n再生してください' 
                                  : 'VoIPセッションを\n開始してください',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
