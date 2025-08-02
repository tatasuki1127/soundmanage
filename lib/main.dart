import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
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
      title: 'SoundMixer - Native Dual Player',
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
  // 🎯 ULTRA THINK HYBRID DUAL PLAYER SYSTEM
  VlcPlayerController? _vlcController1;
  VlcPlayerController? _vlcController2;
  AudioPlayer? _audioPlayer1;
  AudioPlayer? _audioPlayer2;
  bool _isPlayer1Ready = false;
  bool _isPlayer2Ready = false;
  bool _isPlayer1Playing = false;
  bool _isPlayer2Playing = false;
  bool _useAudioMode = false; // Toggle between video+audio vs audio-only
  String _currentStatus = 'Hybrid Dual Player: 初期化中';
  
  // YouTube URL inputs
  final TextEditingController _urlController1 = TextEditingController();
  final TextEditingController _urlController2 = TextEditingController();
  
  // Audio session management
  bool _isVoIPEnabled = false;
  double _player1Volume = 0.8;
  double _player2Volume = 0.8;
  
  // YouTube explode instance
  final YoutubeExplode _youtubeExplode = YoutubeExplode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeHybridDualPlayer();
    _initializeVolumeController();
    
    // Default YouTube URLs for testing
    _urlController1.text = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ';
    _urlController2.text = 'https://www.youtube.com/watch?v=jNQXAC9IVRw';
    
    // Enable VoIP session for audio mixing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _enableNativeAudioMixing();
    });
  }

  // 🚀 ULTRA THINK: Hybrid Dual Player初期化
  Future<void> _initializeHybridDualPlayer() async {
    print('🚀 Initializing ULTRA THINK Hybrid Dual Player System...');
    
    // Initialize audio players for guaranteed audio output
    _audioPlayer1 = AudioPlayer();
    _audioPlayer2 = AudioPlayer();
    
    // Configure audio players for simultaneous playback
    await _audioPlayer1!.setLoopMode(LoopMode.off);
    await _audioPlayer2!.setLoopMode(LoopMode.off);
    await _audioPlayer1!.setVolume(0.8);
    await _audioPlayer2!.setVolume(0.8);
    
    print('✅ Audio players initialized');
    
    try {
      // Player 1 初期化 - 🎯 ULTRA THINK: 音声出力強制有効化
      _vlcController1 = VlcPlayerController.network(
        '',
        hwAcc: HwAcc.full,
        autoPlay: false,
        options: VlcPlayerOptions(
          advanced: VlcAdvancedOptions([
            VlcAdvancedOptions.networkCaching(300),
            VlcAdvancedOptions.clockJitter(0),
          ]),
          audio: VlcAudioOptions([
            VlcAudioOptions.audioTimeStretch(true),
            '--aout=opensles', // Android audio output
            '--audiofile-format=s16l', // Audio format
            '--audio-language=en', // Audio language
          ]),
          video: VlcVideoOptions([
            VlcVideoOptions.dropLateFrames(true),
            VlcVideoOptions.skipFrames(true),
          ]),
          subtitle: VlcSubtitleOptions([
            '--no-spu', // Disable subtitles for performance
          ]),
          rtp: VlcRtpOptions([
            '--rtsp-tcp', // Force TCP for streams
          ]),
        ),
      );

      // Player 2 初期化 - 🎯 ULTRA THINK: 音声出力強制有効化
      _vlcController2 = VlcPlayerController.network(
        '',
        hwAcc: HwAcc.full,
        autoPlay: false,
        options: VlcPlayerOptions(
          advanced: VlcAdvancedOptions([
            VlcAdvancedOptions.networkCaching(300),
            VlcAdvancedOptions.clockJitter(0),
          ]),
          audio: VlcAudioOptions([
            VlcAudioOptions.audioTimeStretch(true),
            '--aout=opensles', // Android audio output
            '--audiofile-format=s16l', // Audio format
            '--audio-language=en', // Audio language
          ]),
          video: VlcVideoOptions([
            VlcVideoOptions.dropLateFrames(true),
            VlcVideoOptions.skipFrames(true),
          ]),
          subtitle: VlcSubtitleOptions([
            '--no-spu', // Disable subtitles for performance
          ]),
          rtp: VlcRtpOptions([
            '--rtsp-tcp', // Force TCP for streams
          ]),
        ),
      );

      // Event listeners with audio activation
      _vlcController1!.addOnInitListener(() {
        setState(() {
          _isPlayer1Ready = true;
          _currentStatus = 'Player1: 準備完了';
        });
        print('✅ VLC Player 1 initialized');
        
        // 🎯 ULTRA THINK: 音声出力を強制的に有効化
        _vlcController1!.setVolume(80); // Set initial volume
        print('🔊 Player1 audio output enabled');
      });

      _vlcController2!.addOnInitListener(() {
        setState(() {
          _isPlayer2Ready = true;
          _currentStatus = 'Player2: 準備完了';
        });
        print('✅ VLC Player 2 initialized');
        
        // 🎯 ULTRA THINK: 音声出力を強制的に有効化
        _vlcController2!.setVolume(80); // Set initial volume
        print('🔊 Player2 audio output enabled');
      });

      // Playing state listeners
      _vlcController1!.addListener(() {
        setState(() {
          _isPlayer1Playing = _vlcController1!.value.isPlaying;
        });
        print('🎵 Player1 playing: ${_vlcController1!.value.isPlaying}');
      });

      _vlcController2!.addListener(() {
        setState(() {
          _isPlayer2Playing = _vlcController2!.value.isPlaying;
        });
        print('🎵 Player2 playing: ${_vlcController2!.value.isPlaying}');
      });

      setState(() {
        _currentStatus = 'Hybrid Dual Player: 初期化完了 - 音声保証';
      });

    } catch (e) {
      print('❌ Native Dual Player initialization failed: $e');
      setState(() {
        _currentStatus = 'Native Dual Player: 初期化失敗';
      });
    }
  }

  // 🔊 Native Audio Mixing有効化
  Future<void> _enableNativeAudioMixing() async {
    print('🔊 Enabling native audio mixing...');
    final success = await AudioMixerService.enableVoIPMixing();
    if (success) {
      setState(() {
        _isVoIPEnabled = true;
        _currentStatus = 'Native Audio Mixing: 有効';
      });
      print('✅ Native audio mixing enabled');
    } else {
      print('⚠️ Native audio mixing failed');
    }
  }

  // 🎯 ULTRA THINK: YouTube URL extraction for Hybrid System
  Future<Map<String, String?>> _extractYouTubeStreams(String youtubeUrl) async {
    try {
      print('🔍 Extracting streams from: $youtubeUrl');
      
      final video = await _youtubeExplode.videos.get(youtubeUrl);
      final manifest = await _youtubeExplode.videos.streamsClient.getManifest(video.id);
      
      String? videoUrl;
      String? audioUrl;
      
      // Get video stream (preferably muxed for VLC)
      if (manifest.muxed.isNotEmpty) {
        final muxedStream = manifest.muxed.last;
        videoUrl = muxedStream.url.toString();
        print('✅ Muxed stream for video: ${muxedStream.videoQuality}');
      } else if (manifest.videoOnly.isNotEmpty) {
        final videoStream = manifest.videoOnly.last;
        videoUrl = videoStream.url.toString();
        print('✅ Video-only stream: ${videoStream.videoQuality}');
      }
      
      // Get audio stream for just_audio (guaranteed to work)
      final audioStream = manifest.audioOnly.withHighestBitrate();
      if (audioStream != null) {
        audioUrl = audioStream.url.toString();
        print('✅ Audio stream for just_audio: ${audioStream.bitrate}');
      }
      
      return {
        'video': videoUrl,
        'audio': audioUrl,
      };
    } catch (e) {
      print('❌ YouTube stream extraction failed: $e');
      return {
        'video': null,
        'audio': null,
      };
    }
  }

  // 🎯 ULTRA THINK: Hybrid Player 1 再生
  Future<void> _playYouTubeOnPlayer1() async {
    if (!_isPlayer1Ready || _urlController1.text.isEmpty) return;

    setState(() {
      _currentStatus = 'Player1: Hybrid再生開始中...';
    });

    final streams = await _extractYouTubeStreams(_urlController1.text);
    
    try {
      // Start audio playback with just_audio (guaranteed to work)
      if (streams['audio'] != null) {
        await _audioPlayer1!.setAudioSource(AudioSource.uri(Uri.parse(streams['audio']!)));
        await _audioPlayer1!.play();
        print('🔊 Player1 audio started with just_audio');
      }
      
      // Start video playback with VLC (visual only, audio handled by just_audio)
      if (streams['video'] != null) {
        await _vlcController1!.setMediaFromNetwork(streams['video']!);
        await _vlcController1!.setVolume(0); // Mute VLC to avoid conflict
        await _vlcController1!.play();
        print('📺 Player1 video started with VLC (muted)');
      }
      
      setState(() {
        _currentStatus = 'Player1: Hybrid再生中 (映像+音声分離)';
      });
      print('🎉 Player1 hybrid playback started successfully!');
    } catch (e) {
      print('❌ Player1 hybrid playback failed: $e');
      setState(() {
        _currentStatus = 'Player1: Hybrid再生失敗';
      });
    }
  }

  // 🎯 ULTRA THINK: Hybrid Player 2 再生
  Future<void> _playYouTubeOnPlayer2() async {
    if (!_isPlayer2Ready || _urlController2.text.isEmpty) return;

    setState(() {
      _currentStatus = 'Player2: Hybrid再生開始中...';
    });

    final streams = await _extractYouTubeStreams(_urlController2.text);
    
    try {
      // Start audio playback with just_audio (guaranteed to work)
      if (streams['audio'] != null) {
        await _audioPlayer2!.setAudioSource(AudioSource.uri(Uri.parse(streams['audio']!)));
        await _audioPlayer2!.play();
        print('🔊 Player2 audio started with just_audio');
      }
      
      // Start video playback with VLC (visual only, audio handled by just_audio)
      if (streams['video'] != null) {
        await _vlcController2!.setMediaFromNetwork(streams['video']!);
        await _vlcController2!.setVolume(0); // Mute VLC to avoid conflict
        await _vlcController2!.play();
        print('📺 Player2 video started with VLC (muted)');
      }
      
      setState(() {
        _currentStatus = 'Player2: Hybrid再生中 (映像+音声分離)';
      });
      print('🎉 Player2 hybrid playback started successfully!');
    } catch (e) {
      print('❌ Player2 hybrid playback failed: $e');
      setState(() {
        _currentStatus = 'Player2: Hybrid再生失敗';
      });
    }
  }

  // 🎯 ULTRA THINK: Hybrid同時再生開始
  Future<void> _startDualPlayback() async {
    print('🎯 ULTRA THINK: Starting Hybrid simultaneous dual playback...');
    
    setState(() {
      _currentStatus = 'Hybrid Dual: 完全同期開始中...';
    });

    try {
      // Extract streams for both players
      final streams1 = await _extractYouTubeStreams(_urlController1.text);
      final streams2 = await _extractYouTubeStreams(_urlController2.text);

      if (streams1['audio'] != null && streams2['audio'] != null) {
        // 🎯 ULTRA THINK: 音声を先に同期開始
        await Future.wait([
          _audioPlayer1!.setAudioSource(AudioSource.uri(Uri.parse(streams1['audio']!))),
          _audioPlayer2!.setAudioSource(AudioSource.uri(Uri.parse(streams2['audio']!))),
        ]);
        
        // 完全同期音声再生
        await Future.wait([
          _audioPlayer1!.play(),
          _audioPlayer2!.play(),
        ]);
        print('🔊 Both audio players started simultaneously!');
        
        // 映像も同期開始（音声はミュート）
        if (streams1['video'] != null && streams2['video'] != null) {
          await Future.wait([
            _vlcController1!.setMediaFromNetwork(streams1['video']!),
            _vlcController2!.setMediaFromNetwork(streams2['video']!),
          ]);
          
          await Future.wait([
            _vlcController1!.setVolume(0), // Muted for video only
            _vlcController2!.setVolume(0), // Muted for video only
          ]);
          
          await Future.wait([
            _vlcController1!.play(),
            _vlcController2!.play(),
          ]);
          print('📺 Both video players started simultaneously (muted)!');
        }

        setState(() {
          _currentStatus = '🎉 HYBRID DUAL PLAYBACK: 完全同時再生成功！';
        });
        print('🎉 ULTRA THINK: Hybrid dual playback started successfully!');
      } else {
        setState(() {
          _currentStatus = 'Hybrid Dual: ストリーム取得失敗';
        });
      }
    } catch (e) {
      print('❌ Hybrid dual playback failed: $e');
      setState(() {
        _currentStatus = 'Hybrid Dual: 失敗';
      });
    }
  }

  // Volume control
  Future<void> _initializeVolumeController() async {
    VolumeController().listener((volume) {
      setState(() {
        // System volume changes affect both players proportionally
      });
    });

    final currentVolume = await VolumeController().getVolume();
    setState(() {
      _player1Volume = currentVolume;
      _player2Volume = currentVolume;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _vlcController1?.dispose();
    _vlcController2?.dispose();
    _audioPlayer1?.dispose();
    _audioPlayer2?.dispose();
    _youtubeExplode.close();
    AudioMixerService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final isBackground = state == AppLifecycleState.paused || 
                        state == AppLifecycleState.detached;
    AudioMixerService.handleAppStateChange(isBackground);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: const Text('🎯 ULTRA THINK Native Dual Player'),
        backgroundColor: const Color(0xFF007AFF),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Status indicator
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isVoIPEnabled ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isVoIPEnabled ? Colors.green : Colors.orange,
                  width: 2,
                ),
              ),
              child: Text(
                _currentStatus,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _isVoIPEnabled ? Colors.green.shade800 : Colors.orange.shade800,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // URL inputs
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _urlController1,
                    decoration: const InputDecoration(
                      labelText: '🎵 YouTube URL 1',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.music_video),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _urlController2,
                    decoration: const InputDecoration(
                      labelText: '🎵 YouTube URL 2',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.music_video),
                    ),
                  ),
                ],
              ),
            ),

            // Control buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isPlayer1Ready ? _playYouTubeOnPlayer1 : null,
                          icon: Icon(_isPlayer1Playing ? Icons.pause : Icons.play_arrow),
                          label: Text('Player 1 ${_isPlayer1Playing ? "停止" : "再生"}'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isPlayer1Playing ? Colors.orange : Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isPlayer2Ready ? _playYouTubeOnPlayer2 : null,
                          icon: Icon(_isPlayer2Playing ? Icons.pause : Icons.play_arrow),
                          label: Text('Player 2 ${_isPlayer2Playing ? "停止" : "再生"}'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isPlayer2Playing ? Colors.orange : Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // 🎯 ULTRA THINK: Dual playback button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: (_isPlayer1Ready && _isPlayer2Ready) ? _startDualPlayback : null,
                      icon: const Icon(Icons.play_circle_filled, size: 32),
                      label: const Text(
                        '🎯 ULTRA THINK: 同時再生開始',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Volume controls
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text('Player 1 Volume: ${(_player1Volume * 100).round()}%'),
                        Slider(
                          value: _player1Volume,
                          onChanged: (value) {
                            setState(() {
                              _player1Volume = value;
                            });
                            _vlcController1?.setVolume((value * 100).round());
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        Text('Player 2 Volume: ${(_player2Volume * 100).round()}%'),
                        Slider(
                          value: _player2Volume,
                          onChanged: (value) {
                            setState(() {
                              _player2Volume = value;
                            });
                            _vlcController2?.setVolume((value * 100).round());
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Video players
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _vlcController1 != null
                            ? VlcPlayer(
                                controller: _vlcController1!,
                                aspectRatio: 16 / 9,
                                placeholder: const Center(
                                  child: Text(
                                    'Player 1\n🎵',
                                    style: TextStyle(color: Colors.white, fontSize: 24),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              )
                            : const Center(
                                child: CircularProgressIndicator(),
                              ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _vlcController2 != null
                            ? VlcPlayer(
                                controller: _vlcController2!,
                                aspectRatio: 16 / 9,
                                placeholder: const Center(
                                  child: Text(
                                    'Player 2\n🎵',
                                    style: TextStyle(color: Colors.white, fontSize: 24),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              )
                            : const Center(
                                child: CircularProgressIndicator(),
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
    );
  }
}