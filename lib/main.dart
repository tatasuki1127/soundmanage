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
  
  late WebViewController _webViewController1;
  late WebViewController _webViewController2;
  bool _isWebView1Ready = false;
  bool _isWebView2Ready = false;
  String _webView1Url = 'https://m.youtube.com';
  String _webView2Url = 'https://m.youtube.com';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeWebViews();
    _initializeVolumeController();
    
    // 🎯 Ultra Think Solution: アプリ起動時即座にVoIPセッション開始
    // Spotify保護のための予防的措置
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _enablePreventiveVoIPSession();
    });
  }
  
  // 🛡️ 予防的VoIPセッション（Dual WebView用）
  Future<void> _enablePreventiveVoIPSession() async {
    print('🛡️ Enabling preventive VoIP session for Dual WebView...');
    final success = await AudioMixerService.enableVoIPMixing();
    if (success) {
      setState(() {
        _isVoIPEnabled = true;
        _currentStatus = 'Dual WebView: 自動準備完了 - 両YouTube対応';
      });
      print('✅ Preventive VoIP session active - Dual WebView ready');
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
        
        // 両WebViewに保護強化を通知
        if (_isWebView1Ready) {
          _webViewController1.runJavaScript('''
            console.log('🛡️ WebView1: Dual system protection reinforced');
            if (typeof window.spotifyProtectiveAudioSystem !== 'undefined') {
              window.spotifyProtectiveAudioSystem.initAudioSystem();
              console.log('✅ WebView1: Audio system reactivated');
            }
          ''');
        }
        
        if (_isWebView2Ready) {
          _webViewController2.runJavaScript('''
            console.log('🛡️ WebView2: Dual system protection reinforced');
            if (typeof window.webView2AudioSystem !== 'undefined') {
              window.webView2AudioSystem.initAudioSystem();
              console.log('✅ WebView2: Audio system reactivated');
            }
          ''');
        }
      } catch (e) {
        print('⚠️ VoIP session reinforcement failed: $e');
      }
    }
  }
  
  // 🎯 WebView1タッチ時の処理
  void _onWebView1Interaction() {
    print('👆 WebView1 interaction detected');
    
    // 音声システム状態表示
    setState(() {
      _currentStatus = 'WebView1タッチ検出 - 音声システム確認中';
    });
    
    if (_isWebView1Ready) {
      _webViewController1.runJavaScript('''
        console.log('👆 WebView1 UI interaction processing');
        if (typeof window.webView1AudioSystem !== 'undefined') {
          window.webView1AudioSystem.initAudioSystem();
          console.log('✅ WebView1 audio system reactivated');
        }
      ''');
      
      if (_isVoIPEnabled) {
        _reinforceSpotifyProtection();
      }
      
      // 状態更新
      Future.delayed(Duration(milliseconds: 500), () {
        setState(() {
          _currentStatus = 'WebView1: 音声システム更新完了';
        });
      });
    }
  }
  
  // 🎯 WebView2タッチ時の処理
  void _onWebView2Interaction() {
    print('👆 WebView2 interaction detected');
    
    // 音声システム状態表示
    setState(() {
      _currentStatus = 'WebView2タッチ検出 - 音声システム確認中';
    });
    
    if (_isWebView2Ready) {
      _webViewController2.runJavaScript('''
        console.log('👆 WebView2 UI interaction processing');
        if (typeof window.webView2AudioSystem !== 'undefined') {
          window.webView2AudioSystem.initAudioSystem();
          console.log('✅ WebView2 audio system reactivated');
        }
      ''');
      
      if (_isVoIPEnabled) {
        _reinforceSpotifyProtection();
      }
      
      // 状態更新
      Future.delayed(Duration(milliseconds: 500), () {
        setState(() {
          _currentStatus = 'WebView2: 音声システム更新完了';
        });
      });
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

  void _initializeWebViews() {
    _initializeWebView1();
    _initializeWebView2();
  }

  void _initializeWebView1() {
    _webViewController1 = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {},
          onPageStarted: (String url) {
            print('WebView started loading: $url');
          },
          onPageFinished: (String url) {
            print('WebView1 finished loading: $url');
            setState(() {
              _isWebView1Ready = true;
              _webView1Url = url;
            });
            
            // 🚀 Ultra Think: WebView1 Independent Audio System
            _webViewController1.runJavaScript('''
              try {
                console.log('🎵 Initializing WebView1 Independent Audio System...');
                
                // 🎛️ グローバル音声制御システム
                window.spotifyProtectiveAudioSystem = {
                  audioContext: null,
                  masterGainNode: null,
                  isInitialized: false,
                  hijackedVideos: new Map(),
                  
                  // Web Audio API初期化
                  initAudioSystem: function() {
                    if (this.isInitialized) return;
                    
                    try {
                      // AudioContextを効果音レベルで作成
                      this.audioContext = new (window.AudioContext || window.webkitAudioContext)({
                        latencyHint: 'interactive', // 低遅延設定
                        sampleRate: 44100
                      });
                      
                      // マスター音量制御ノード（Spotify配慮型）
                      this.masterGainNode = this.audioContext.createGain();
                      this.masterGainNode.gain.value = 0.25; // 25%でSpotifyと共存
                      this.masterGainNode.connect(this.audioContext.destination);
                      
                      console.log('✅ Web Audio System initialized for Spotify coexistence');
                      this.isInitialized = true;
                      
                      // AudioContextを「ユーザージェスチャー」なしで開始
                      this.audioContext.resume().then(() => {
                        console.log('🎵 AudioContext started in background-friendly mode');
                      }).catch(err => {
                        console.log('⚠️ AudioContext resume pending user interaction');
                      });
                      
                    } catch (e) {
                      console.log('❌ Web Audio System init failed:', e);
                    }
                  },
                  
                  // 🎯 ビデオ音声の完全乗っ取り
                  hijackVideoAudio: function(video, videoIndex) {
                    if (this.hijackedVideos.has(video)) {
                      console.log('🔄 Video already hijacked, skipping...', videoIndex);
                      return;
                    }
                    
                    try {
                      console.log('🚀 Hijacking video audio stream...', videoIndex);
                      
                      // 1. 元のビデオ音声を無効化
                      video.muted = true;
                      
                      // 2. MediaStream取得と音声トラック処理
                      if (video.captureStream) {
                        const stream = video.captureStream();
                        const audioTracks = stream.getAudioTracks();
                        
                        if (audioTracks.length > 0) {
                          console.log('🎤 Audio tracks found:', audioTracks.length);
                          
                          // 3. Web Audio APIで音声ストリームを制御
                          const mediaStreamSource = this.audioContext.createMediaStreamSource(stream);
                          
                          // 4. Spotify配慮型音量制御
                          const videoGainNode = this.audioContext.createGain();
                          videoGainNode.gain.value = 0.3; // 30%音量でSpotifyと調和
                          
                          // 5. 動的音量調整（Spotify保護）
                          const dynamicController = this.audioContext.createGain();
                          dynamicController.gain.value = 1.0;
                          
                          // 6. 音声ルーティング: Video → Gain → Master → Output
                          mediaStreamSource.connect(videoGainNode);
                          videoGainNode.connect(dynamicController);
                          dynamicController.connect(this.masterGainNode);
                          
                          // 7. 乗っ取り完了記録
                          this.hijackedVideos.set(video, {
                            source: mediaStreamSource,
                            gainNode: videoGainNode,
                            dynamicController: dynamicController,
                            stream: stream
                          });
                          
                          console.log('✅ Video audio successfully hijacked and routed through Web Audio', videoIndex);
                          
                          // 8. Spotify保護のための音量監視
                          this.startSpotifyProtectiveMonitoring(video, videoGainNode);
                          
                        } else {
                          console.log('⚠️ No audio tracks found in video stream', videoIndex);
                        }
                      } else {
                        console.log('⚠️ captureStream not supported, fallback mode...', videoIndex);
                        this.fallbackAudioControl(video, videoIndex);
                      }
                      
                    } catch (e) {
                      console.log('❌ Video audio hijack failed:', e, 'videoIndex:', videoIndex);
                      this.fallbackAudioControl(video, videoIndex);
                    }
                  },
                  
                  // 🛡️ Spotify保護監視システム
                  startSpotifyProtectiveMonitoring: function(video, gainNode) {
                    // リアルタイム音量調整でSpotifyを保護
                    const monitoringInterval = setInterval(() => {
                      if (video.ended || video.error) {
                        clearInterval(monitoringInterval);
                        return;
                      }
                      
                      // 動画の再生状態に応じてSpotify配慮調整
                      if (!video.paused && !video.muted) {
                        // アクティブ再生中: より控えめに
                        gainNode.gain.exponentialRampToValueAtTime(0.2, this.audioContext.currentTime + 0.1);
                      } else {
                        // 一時停止中: 少し音量復帰
                        gainNode.gain.exponentialRampToValueAtTime(0.3, this.audioContext.currentTime + 0.1);
                      }
                    }, 500);
                  },
                  
                  // 🔄 フォールバック音声制御
                  fallbackAudioControl: function(video, videoIndex) {
                    console.log('🔄 Using fallback audio control for video', videoIndex);
                    
                    // 元のビデオ音量をSpotify配慮レベルに固定
                    video.muted = false;
                    video.volume = 0.2; // 20%でSpotifyと共存
                    
                    // 🛡️ Spotify保護用安全音量監視（無限ループ防止）
                    let webView1SpotifyProtecting = false;
                    video.addEventListener('volumechange', () => {
                      if (webView1SpotifyProtecting) return; // 調整中は無視
                      
                      if (video.volume > 0.25) {
                        console.log('🛡️ WebView1 volume cap for Spotify protection');
                        webView1SpotifyProtecting = true;
                        
                        setTimeout(() => {
                          if (!video.ended && !video.error) {
                            video.volume = 0.2;
                          }
                          webView1SpotifyProtecting = false;
                        }, 150); // 150ms後に調整
                      }
                    });
                  },
                  
                  // 🚀 Ultra Think: WebView1超攻撃的監視システム
                  startUltraAggressiveMonitoring: function(video, videoIndex) {
                    console.log('🚀 Starting ultra-aggressive monitoring for WebView1...', videoIndex);
                    
                    const ultraInterval = setInterval(() => {
                      if (video.ended || video.error) {
                        clearInterval(ultraInterval);
                        return;
                      }
                      
                      // 超高頻度監視 (25ms間隔 - WebView2より高速)
                      if (video.paused && !video.ended) {
                        console.log('🔥 WebView1 ultra-aggressive restart...', videoIndex);
                        video.play().catch(() => {
                          // 失敗時の即座再試行
                          setTimeout(() => video.play().catch(() => {}), 10);
                        });
                      }
                      
                      // 音量・ミュート状態の強制維持（Spotify配慮）
                      if (video.muted || video.volume < 0.15) {
                        video.muted = false;
                        video.volume = 0.25; // Spotify配慮レベル
                      }
                    }, 25); // 25ms超高頻度監視 (WebView2の50msより高速)
                    
                    // 8秒後に通常監視に戻す（WebView2より短い）
                    setTimeout(() => {
                      clearInterval(ultraInterval);
                      console.log('✅ WebView1 ultra-aggressive monitoring completed');
                    }, 8000);
                  }
                };
                
                // 🎯 Enhanced Video Detection & Hijacking
                function setupSpotifyCoexistentVideo() {
                  const videos = document.querySelectorAll('video');
                  
                  videos.forEach((video, index) => {
                    console.log('🎬 Processing video element', index);
                    
                    // Web Audio System初期化
                    window.spotifyProtectiveAudioSystem.initAudioSystem();
                    
                    // loadstart: 音声乗っ取り準備
                    video.addEventListener('loadstart', () => {
                      console.log('📡 Video loadstart - preparing audio hijack...', index);
                      setTimeout(() => {
                        window.spotifyProtectiveAudioSystem.hijackVideoAudio(video, index);
                      }, 100);
                    });
                    
                    // canplay: 音声乗っ取り実行
                    video.addEventListener('canplay', () => {
                      console.log('🎵 Video canplay - executing audio hijack...', index);
                      window.spotifyProtectiveAudioSystem.hijackVideoAudio(video, index);
                    });
                    
                    // play: Spotify共存モード開始
                    video.addEventListener('play', () => {
                      console.log('▶️ Video play - Spotify coexistence mode active...', index);
                      
                      // AudioContextの確実な開始
                      if (window.spotifyProtectiveAudioSystem.audioContext && 
                          window.spotifyProtectiveAudioSystem.audioContext.state === 'suspended') {
                        window.spotifyProtectiveAudioSystem.audioContext.resume();
                      }
                      
                      // 音声乗っ取りの再確認
                      setTimeout(() => {
                        window.spotifyProtectiveAudioSystem.hijackVideoAudio(video, index);
                      }, 50);
                    });
                    
                    // pause: WebView1超高速復旧システム
                    video.addEventListener('pause', () => {
                      console.log('⏸️ WebView1 video paused, ULTRA-FAST recovery...', index);
                      
                      // 即座復旧試行 (5ms) - WebView2より高速
                      setTimeout(() => {
                        if (video.paused && !video.ended) {
                          console.log('🚀 WebView1 immediate recovery attempt...', index);
                          video.play().catch(() => {
                            console.log('WebView1 immediate failed, trying sequential recovery...');
                          });
                        }
                      }, 5);
                      
                      // 第2段階復旧 (25ms)
                      setTimeout(() => {
                        if (video.paused && !video.ended) {
                          console.log('🔄 WebView1 second-stage recovery...', index);
                          video.play().catch(() => {
                            console.log('WebView1 second-stage failed, trying aggressive...');
                          });
                        }
                      }, 25);
                      
                      // 第3段階復旧 (75ms)
                      setTimeout(() => {
                        if (video.paused && !video.ended) {
                          console.log('⚡ WebView1 third-stage aggressive recovery...', index);
                          video.play().catch(() => {
                            console.log('WebView1 third-stage failed, starting continuous monitoring...');
                            
                            // 継続監視開始
                            window.spotifyProtectiveAudioSystem.startUltraAggressiveMonitoring(video, index);
                          });
                        }
                      }, 75);
                    });
                    
                    // 既に読み込み済みの場合は即座に処理
                    if (video.readyState >= 1) {
                      console.log('🚀 Video already loaded, immediate hijack...', index);
                      window.spotifyProtectiveAudioSystem.hijackVideoAudio(video, index);
                    }
                  });
                }
                
                // 🎵 Global Audio Focus Protection
                function preventSystemAudioFocus() {
                  // AudioContextの作成を制御してSpotify保護
                  const originalAudioContext = window.AudioContext || window.webkitAudioContext;
                  
                  window.AudioContext = window.webkitAudioContext = function(...args) {
                    console.log('🚫 Intercepting AudioContext creation for Spotify protection');
                    const ctx = new originalAudioContext(...args);
                    
                    // 新しいAudioContextは低音量で開始
                    const gainNode = ctx.createGain();
                    gainNode.gain.value = 0.2;
                    gainNode.connect(ctx.destination);
                    
                    return ctx;
                  };
                  
                  // MediaSession API無効化
                  if ('mediaSession' in navigator) {
                    navigator.mediaSession.metadata = null;
                    navigator.mediaSession.setActionHandler('play', null);
                    navigator.mediaSession.setActionHandler('pause', null);
                    navigator.mediaSession.setActionHandler('seekbackward', null);
                    navigator.mediaSession.setActionHandler('seekforward', null);
                  }
                }
                
                // 🚀 システム初期化
                preventSystemAudioFocus();
                setupSpotifyCoexistentVideo();
                
                // DOM変更監視でリアルタイム対応
                const observer = new MutationObserver((mutations) => {
                  mutations.forEach((mutation) => {
                    mutation.addedNodes.forEach((node) => {
                      if (node.nodeType === 1) { // Element node
                        const videos = node.querySelectorAll ? node.querySelectorAll('video') : [];
                        if (videos.length > 0) {
                          console.log('🔍 New videos detected, applying Spotify protection...');
                          setTimeout(() => {
                            setupSpotifyCoexistentVideo();
                          }, 100);
                        }
                      }
                    });
                  });
                });
                
                observer.observe(document.body, { childList: true, subtree: true });
                
                // WebView1ユーザーインタラクション時の音声システム活性化
                document.addEventListener('click', () => {
                  console.log('👆 WebView1 user interaction detected');
                  if (window.webView1AudioSystem.audioContext) {
                    window.webView1AudioSystem.audioContext.resume();
                  }
                  
                  // クリック時に動画の継続再生を確認
                  setTimeout(() => {
                    const videos = document.querySelectorAll('video');
                    videos.forEach((video, index) => {
                      if (video.paused && !video.ended) {
                        console.log('🔄 WebView1 click-triggered video restart...', index);
                        video.play();
                      }
                    });
                  }, 100);
                });
                
                console.log('🎉 WebView1 Independent Audio System ready');
                
              } catch (e) {
                console.log('❌ WebView1 Independent Audio setup error:', e);
              }
            ''');
          },
          onWebResourceError: (WebResourceError error) {
            print('WebView1 error: ${error.description}');
          },
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse('https://m.youtube.com'));
  }

  void _initializeWebView2() {
    _webViewController2 = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {},
          onPageStarted: (String url) {
            print('WebView2 started loading: $url');
          },
          onPageFinished: (String url) {
            print('WebView2 finished loading: $url');
            setState(() {
              _isWebView2Ready = true;
              _webView2Url = url;
            });
            
            // 🚀 Ultra Think: WebView2 Audio System
            _webViewController2.runJavaScript('''
              try {
                console.log('🎵 Initializing WebView2 Independent Audio System...');
                
                // 🎛️ WebView2専用独立音声制御システム
                window.webView2AudioSystem = {
                  audioContext: null,
                  masterGainNode: null,
                  isInitialized: false,
                  hijackedVideos: new Map(),
                  webViewId: 'WebView2',
                  
                  // WebView2専用 Audio API初期化
                  initAudioSystem: function() {
                    if (this.isInitialized) return;
                    
                    try {
                      // WebView2専用AudioContext（WebView1と独立）
                      this.audioContext = new (window.AudioContext || window.webkitAudioContext)({
                        latencyHint: 'interactive',
                        sampleRate: 44100
                      });
                      
                      // WebView2専用音量制御ノード
                      this.masterGainNode = this.audioContext.createGain();
                      this.masterGainNode.gain.value = 0.5; // WebView2: 50%
                      this.masterGainNode.connect(this.audioContext.destination);
                      
                      console.log('✅ WebView2 Audio System initialized independently');
                      this.isInitialized = true;
                      
                      // 独立AudioContext開始
                      this.audioContext.resume().then(() => {
                        console.log('🎵 WebView2 AudioContext started independently');
                      }).catch(err => {
                        console.log('⚠️ WebView2 AudioContext resume pending user interaction');
                      });
                      
                    } catch (e) {
                      console.log('❌ WebView2 Audio System init failed:', e);
                    }
                  },
                  
                  // 🎯 WebView2独立動画音声制御
                  hijackVideoAudio: function(video, videoIndex) {
                    if (this.hijackedVideos.has(video)) {
                      console.log('🔄 WebView2 video already hijacked, skipping...', videoIndex);
                      return;
                    }
                    
                    try {
                      console.log('🚀 WebView2 hijacking video audio...', videoIndex);
                      
                      // WebView2動画の独立音声制御
                      this.setupIndependentVideoAudio(video, videoIndex);
                      
                    } catch (e) {
                      console.log('❌ WebView2 video audio hijack failed:', e, 'videoIndex:', videoIndex);
                      this.fallbackAudioControl(video, videoIndex);
                    }
                  },
                  
                  // 🔧 WebView2独立音声セットアップ
                  setupIndependentVideoAudio: function(video, videoIndex) {
                    // WebView2動画の音声をWebView1と分離
                    video.muted = false;
                    video.volume = 0.7; // WebView2: 70%音量
                    
                    // 音声フォーカス競合回避
                    video.addEventListener('play', () => {
                      console.log('▶️ WebView2 video play - maintaining independence', videoIndex);
                      
                      // 他のWebViewとの音声競合を防ぐ
                      setTimeout(() => {
                        if (video.paused) {
                          video.play().catch(err => {
                            console.log('WebView2 video restart failed:', err);
                          });
                        }
                      }, 150); // WebView1より少し遅く
                    });
                    
                    // 🚀 Ultra Think: WebView2超高速復旧システム
                    video.addEventListener('pause', () => {
                      console.log('⏸️ WebView2 video paused, ULTRA-FAST recovery...', videoIndex);
                      
                      // 即座復旧試行 (10ms)
                      setTimeout(() => {
                        if (video.paused && !video.ended) {
                          console.log('🚀 WebView2 immediate recovery attempt...', videoIndex);
                          video.play().catch(() => {
                            console.log('WebView2 immediate failed, trying sequential recovery...');
                          });
                        }
                      }, 10);
                      
                      // 第2段階復旧 (50ms)
                      setTimeout(() => {
                        if (video.paused && !video.ended) {
                          console.log('🔄 WebView2 second-stage recovery...', videoIndex);
                          video.play().catch(() => {
                            console.log('WebView2 second-stage failed, trying aggressive...');
                          });
                        }
                      }, 50);
                      
                      // 第3段階復旧 (100ms)
                      setTimeout(() => {
                        if (video.paused && !video.ended) {
                          console.log('⚡ WebView2 third-stage aggressive recovery...', videoIndex);
                          video.play().catch(() => {
                            console.log('WebView2 third-stage failed, starting continuous monitoring...');
                            
                            // 継続監視開始
                            window.webView2AudioSystem.startUltraAggressiveMonitoring(video, videoIndex);
                          });
                        }
                      }, 100);
                    });
                    
                    // 🛡️ 安全な音量変更イベント監視（無限ループ防止）
                    let webView2VolumeRestoring = false;
                    video.addEventListener('volumechange', () => {
                      if (webView2VolumeRestoring) return; // 復元中は無視
                      
                      if (video.volume === 0 || video.muted) {
                        console.log('🔊 WebView2 volume reset detected, safe restoring...');
                        webView2VolumeRestoring = true;
                        
                        setTimeout(() => {
                          if (!video.ended && !video.error) {
                            video.muted = false;
                            video.volume = 0.7;
                          }
                          webView2VolumeRestoring = false;
                        }, 200); // 200ms後に復元、無限ループ防止
                      }
                    });
                    
                    this.hijackedVideos.set(video, {
                      webViewId: this.webViewId,
                      videoIndex: videoIndex,
                      setupTime: Date.now()
                    });
                    
                    console.log('✅ WebView2 independent video audio setup complete', videoIndex);
                  },
                  
                  // 🛡️ WebView2継続再生監視システム
                  startContinuousPlayMonitoring: function(video, videoIndex) {
                    const monitoringInterval = setInterval(() => {
                      if (video.ended || video.error) {
                        clearInterval(monitoringInterval);
                        return;
                      }
                      
                      // WebView2の継続再生を保証
                      if (video.paused && !video.ended) {
                        console.log('🚨 WebView2 video unexpectedly paused, restarting...', videoIndex);
                        video.play().catch(err => {
                          console.log('WebView2 monitoring restart failed:', err);
                        });
                      }
                      
                      // 音量維持
                      if (video.volume < 0.6) {
                        video.volume = 0.7;
                      }
                    }, 400); // WebView1より少し遅い監視間隔
                  },
                  
                  // 🚀 Ultra Think: 超攻撃的監視システム
                  startUltraAggressiveMonitoring: function(video, videoIndex) {
                    console.log('🚀 Starting ultra-aggressive monitoring for WebView2...', videoIndex);
                    
                    const ultraInterval = setInterval(() => {
                      if (video.ended || video.error) {
                        clearInterval(ultraInterval);
                        return;
                      }
                      
                      // 超高頻度監視 (50ms間隔)
                      if (video.paused && !video.ended) {
                        console.log('🔥 WebView2 ultra-aggressive restart...', videoIndex);
                        video.play().catch(() => {
                          // 失敗時の即座再試行
                          setTimeout(() => video.play().catch(() => {}), 20);
                        });
                      }
                      
                      // 音量・ミュート状態の強制維持
                      if (video.muted || video.volume < 0.5) {
                        video.muted = false;
                        video.volume = 0.7;
                      }
                    }, 50); // 50ms超高頻度監視
                    
                    // 10秒後に通常監視に戻す
                    setTimeout(() => {
                      clearInterval(ultraInterval);
                      console.log('✅ WebView2 ultra-aggressive monitoring completed, switching to normal');
                      this.startContinuousPlayMonitoring(video, videoIndex);
                    }, 10000);
                  },
                  
                  // 🔄 WebView2フォールバック音声制御
                  fallbackAudioControl: function(video, videoIndex) {
                    console.log('🔄 WebView2 using fallback audio control', videoIndex);
                    
                    // WebView2基本音声設定
                    video.muted = false;
                    video.volume = 0.7; // WebView2: 70%
                    
                    // 🛡️ WebView2安全イベント監視（無限ループ防止）
                    let webView2FallbackRestoring = false;
                    video.addEventListener('volumechange', () => {
                      if (webView2FallbackRestoring) return; // 復元中は無視
                      
                      if (video.muted || video.volume < 0.4) {
                        console.log('🛡️ WebView2 fallback volume restore triggered');
                        webView2FallbackRestoring = true;
                        
                        setTimeout(() => {
                          if (!video.ended && !video.error) {
                            video.muted = false;
                            video.volume = 0.7;
                          }
                          webView2FallbackRestoring = false;
                        }, 300); // 300ms後に復元
                      }
                    });
                    
                    // 継続再生監視開始
                    this.startContinuousPlayMonitoring(video, videoIndex);
                  },
                  
                  // 🎯 WebView2動画検出・制御
                  setupVideoAudio: function() {
                    const videos = document.querySelectorAll('video');
                    videos.forEach((video, index) => {
                      console.log('🎬 WebView2 processing video', index);
                      
                      // WebView2動画の独立制御開始
                      this.hijackVideoAudio(video, index);
                    });
                  }
                };
                
                // 🎯 WebView2独立動画検出・制御
                function setupWebView2IndependentVideo() {
                  const videos = document.querySelectorAll('video');
                  
                  videos.forEach((video, index) => {
                    console.log('🎬 WebView2 processing video element', index);
                    
                    // WebView2 Audio System初期化
                    window.webView2AudioSystem.initAudioSystem();
                    
                    // loadstart: WebView2独立音声準備
                    video.addEventListener('loadstart', () => {
                      console.log('📡 WebView2 video loadstart - preparing independent audio...', index);
                      setTimeout(() => {
                        window.webView2AudioSystem.hijackVideoAudio(video, index);
                      }, 100); // WebView1より少し遅く
                    });
                    
                    // canplay: WebView2独立音声実行
                    video.addEventListener('canplay', () => {
                      console.log('🎵 WebView2 video canplay - executing independent audio...', index);
                      window.webView2AudioSystem.hijackVideoAudio(video, index);
                    });
                    
                    // play: WebView2独立再生モード開始
                    video.addEventListener('play', () => {
                      console.log('▶️ WebView2 video play - independent mode active...', index);
                      
                      // WebView2 AudioContextの確実な開始
                      if (window.webView2AudioSystem.audioContext && 
                          window.webView2AudioSystem.audioContext.state === 'suspended') {
                        window.webView2AudioSystem.audioContext.resume();
                      }
                      
                      // WebView2音声制御の再確認
                      setTimeout(() => {
                        window.webView2AudioSystem.hijackVideoAudio(video, index);
                      }, 80); // WebView1より少し遅く
                    });
                    
                    // 既に読み込み済みの場合は即座に処理
                    if (video.readyState >= 1) {
                      console.log('🚀 WebView2 video already loaded, immediate setup...', index);
                      setTimeout(() => {
                        window.webView2AudioSystem.hijackVideoAudio(video, index);
                      }, 120); // WebView1より遅く実行
                    }
                  });
                }
                
                // 🎵 WebView2専用音声フォーカス制御
                function preventWebView2AudioConflict() {
                  // WebView2専用MediaSession制御
                  if ('mediaSession' in navigator) {
                    console.log('🎛️ WebView2 MediaSession control initialized');
                    
                    // WebView2のMediaSessionを独立設定
                    navigator.mediaSession.metadata = new MediaMetadata({
                      title: 'WebView2 YouTube',
                      artist: 'Dual Player',
                      album: 'Independent Audio B'
                    });
                    
                    // WebView2専用アクションハンドラ
                    navigator.mediaSession.setActionHandler('play', () => {
                      console.log('🎵 WebView2 MediaSession play triggered');
                      const videos = document.querySelectorAll('video');
                      videos.forEach(video => {
                        if (video.paused) {
                          setTimeout(() => video.play(), 150); // WebView1より遅く
                        }
                      });
                    });
                    
                    navigator.mediaSession.setActionHandler('pause', () => {
                      console.log('⏸️ WebView2 MediaSession pause triggered');
                      // WebView2は一時停止を許可するが、すぐ復旧
                      setTimeout(() => {
                        const videos = document.querySelectorAll('video');
                        videos.forEach(video => {
                          if (video.paused && !video.ended) {
                            video.play();
                          }
                        });
                      }, 700); // WebView1より長い復旧時間
                    });
                  }
                  
                  // WebView2専用音声競合回避
                  document.addEventListener('visibilitychange', () => {
                    if (!document.hidden) {
                      console.log('👁️ WebView2 visibility restored, checking videos...');
                      setTimeout(() => {
                        const videos = document.querySelectorAll('video');
                        videos.forEach(video => {
                          if (video.paused && !video.ended) {
                            console.log('🔄 WebView2 restarting video after visibility change...');
                            video.play();
                          }
                        });
                      }, 300); // WebView1より遅く
                    }
                  });
                }
                
                // 🚀 WebView2システム初期化
                preventWebView2AudioConflict();
                setupWebView2IndependentVideo();
                
                // WebView2 DOM変更監視
                const observer = new MutationObserver((mutations) => {
                  mutations.forEach((mutation) => {
                    mutation.addedNodes.forEach((node) => {
                      if (node.nodeType === 1) { // Element node
                        const videos = node.querySelectorAll ? node.querySelectorAll('video') : [];
                        if (videos.length > 0) {
                          console.log('🔍 WebView2 new videos detected, applying independent control...');
                          setTimeout(() => {
                            setupWebView2IndependentVideo();
                          }, 100);
                        }
                      }
                    });
                  });
                });
                
                observer.observe(document.body, { childList: true, subtree: true });
                
                // WebView2ユーザーインタラクション対応
                document.addEventListener('click', () => {
                  console.log('👆 WebView2 user interaction detected');
                  if (window.webView2AudioSystem.audioContext) {
                    window.webView2AudioSystem.audioContext.resume();
                  }
                  
                  // クリック時に動画の継続再生を確認
                  setTimeout(() => {
                    const videos = document.querySelectorAll('video');
                    videos.forEach((video, index) => {
                      if (video.paused && !video.ended) {
                        console.log('🔄 WebView2 click-triggered video restart...', index);
                        setTimeout(() => video.play(), 150); // WebView1より遅く
                      }
                    });
                  }, 150);
                });
                
                console.log('🎉 WebView2 Independent Audio System ready');
                
              } catch (e) {
                console.log('❌ WebView2 Audio setup error:', e);
              }
            ''');
          },
          onWebResourceError: (WebResourceError error) {
            print('WebView2 error: ${error.description}');
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
          _currentStatus = 'Dual WebView: 停止中';
        });
      }
    } else {
      // 🎯 両WebView準備完了まで待機
      if (!_isWebView1Ready || !_isWebView2Ready) {
        print('WebViews not ready, waiting...');
        setState(() {
          _currentStatus = 'WebViews準備中...';
        });
        
        // WebView準備完了まで最大10秒待機
        int attempts = 0;
        while ((!_isWebView1Ready || !_isWebView2Ready) && attempts < 100) {
          await Future.delayed(Duration(milliseconds: 100));
          attempts++;
        }
        
        if (!_isWebView1Ready || !_isWebView2Ready) {
          print('WebViews preparation timeout');
          setState(() {
            _isLoading = false;
            _currentStatus = 'Dual WebView準備がタイムアウトしました';
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
          _currentStatus = 'Dual WebView: 両YouTube同時再生モード';
        });
        
        // 🎯 Ultra Think: VoIPセッション後のSpotify保護強化
        await _reinforceSpotifyProtection();
        
        // 両WebViewの動画再開処理
        _webViewController1.runJavaScript('''
          console.log('🛡️ WebView1 VoIP session started');
          
          var videos = document.querySelectorAll('video');
          videos.forEach(function(video, index) {
            if (video.paused && !video.ended) {
              console.log('🔄 Resuming WebView1 video...', index);
              setTimeout(function() {
                video.play().catch(function(err) {
                  console.log('WebView1 video resume failed:', err);
                });
              }, 100);
            }
          });
        ''');
        
        _webViewController2.runJavaScript('''
          console.log('🛡️ WebView2 VoIP session started');
          
          var videos = document.querySelectorAll('video');
          videos.forEach(function(video, index) {
            if (video.paused && !video.ended) {
              console.log('🔄 Resuming WebView2 video...', index);
              setTimeout(function() {
                video.play().catch(function(err) {
                  console.log('WebView2 video resume failed:', err);
                });
              }, 150); // WebView2は少し遅らせて開始
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
          content: Text('Dual WebViewシステムの設定に失敗しました'),
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
          title: const Text('🎭 Dual YouTube Player'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🎯 2つのYouTube動画同時再生システム開始！'),
              const SizedBox(height: 16),
              const Text('1. 📺 YouTube A: 左側のWebView'),
              const Text('2. 📺 YouTube B: 右側のWebView'),
              const Text('3. 🔊 音量スライダーで両方調整'),
              const SizedBox(height: 16),
              const Text('✅ 2つの動画が同時再生可能！', 
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('⚡ 各WebViewは独立して動作します', 
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
    
    // 🚀 Ultra Think: 微分音量で音声分散効果
    final webView1Volume = volume * 0.85; // WebView1は少し低く
    final webView2Volume = volume * 1.0;  // WebView2は基準値
    
    // WebView1の音量調整（微分設定）
    if (_isWebView1Ready) {
      _webViewController1.runJavaScript('''
        try {
          var videos = document.querySelectorAll('video');
          videos.forEach(function(video) {
            if (!video.paused && !video.ended) {
              video.volume = Math.max(0, Math.min(1, $webView1Volume));
              console.log('WebView1 volume set to: $webView1Volume');
            }
          });
        } catch (e) {
          console.log('WebView1 volume adjustment error:', e);
        }
      ''').catchError((error) {
        print('WebView1 JavaScript execution error: $error');
      });
    }
    
    // WebView2の音量調整（基準設定）
    if (_isWebView2Ready) {
      _webViewController2.runJavaScript('''
        try {
          var videos = document.querySelectorAll('video');
          videos.forEach(function(video) {
            if (!video.paused && !video.ended) {
              video.volume = Math.max(0, Math.min(1, $webView2Volume));
              console.log('WebView2 volume set to: $webView2Volume');
            }
          });
        } catch (e) {
          console.log('WebView2 volume adjustment error:', e);
        }
      ''').catchError((error) {
        print('WebView2 JavaScript execution error: $error');
      });
    }
  }

  Widget _buildVoIPControlCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
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
              _isVoIPEnabled ? 'Dual WebView: アクティブ' : 'Dual WebView: 停止中',
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
                        _isVoIPEnabled ? 'システム停止' : 'システム開始',
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
              '🔊 音量調整 (両WebView)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text('YouTube A&B 音量: ${(_youtubeVolume * 100).round()}%'),
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
          'Dual YouTube Player - A × B',
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
          
          // 🎭 Dual YouTube WebViews
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  // 📺 WebView1 (Left)
                  Expanded(
                    child: Card(
                      elevation: 4,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              color: const Color(0xFFFF0000),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.play_circle_filled, color: Colors.white, size: 16),
                                  SizedBox(width: 4),
                                  Text(
                                    'YouTube A',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Stack(
                                children: [
                                  WebViewWidget(controller: _webViewController1),
                                  // 🎯 WebView操作を阻害しない軽量タッチ検出
                                  Positioned(
                                    top: 0,
                                    left: 0,
                                    right: 0,
                                    height: 40,
                                    child: GestureDetector(
                                      onTap: () {
                                        print('📱 WebView1 header tapped');
                                        _onWebView1Interaction();
                                      },
                                      behavior: HitTestBehavior.opaque,
                                      child: Container(
                                        color: Colors.black.withOpacity(0.1),
                                        child: const Center(
                                          child: Text(
                                            '👆 Tap here for audio control',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // 📺 WebView2 (Right)
                  Expanded(
                    child: Card(
                      elevation: 4,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              color: const Color(0xFF1DB954),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.play_circle_filled, color: Colors.white, size: 16),
                                  SizedBox(width: 4),
                                  Text(
                                    'YouTube B',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Stack(
                                children: [
                                  WebViewWidget(controller: _webViewController2),
                                  // 🎯 WebView操作を阻害しない軽量タッチ検出
                                  Positioned(
                                    top: 0,
                                    left: 0,
                                    right: 0,
                                    height: 40,
                                    child: GestureDetector(
                                      onTap: () {
                                        print('📱 WebView2 header tapped');
                                        _onWebView2Interaction();
                                      },
                                      behavior: HitTestBehavior.opaque,
                                      child: Container(
                                        color: Colors.black.withOpacity(0.1),
                                        child: const Center(
                                          child: Text(
                                            '👆 Tap here for audio control',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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
                              'WebView Status',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1DB954),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'WebView1: ${_isWebView1Ready ? "✅ Ready" : "⏳ Loading"}\n'
                              'WebView2: ${_isWebView2Ready ? "✅ Ready" : "⏳ Loading"}',
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
