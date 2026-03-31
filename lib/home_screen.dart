// home_screen.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:android_intent_plus/android_intent.dart';
import '../widgets/orb_widget.dart';
import '../widgets/status_cards.dart';
import '../services/command_processor.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // TTS & STT
  final FlutterTts _tts = FlutterTts();
  final SpeechToText _stt = SpeechToText();

  // Screenshot
  final ScreenshotController _screenshotController = ScreenshotController();

  // Battery
  final Battery _battery = Battery();

  // State
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _serviceRunning = false;
  bool _sttAvailable = false;
  String _transcribed = '';
  String _statusText = 'Say something, Boss...';
  String _assistantName = 'JARVIS';
  int _batteryLevel = 100;
  double _brightness = 0.5;
  double _volume = 0.5;
  String _cpuInfo = 'Active';

  // Music state (mocked — real control via media intent)
  bool _musicPlaying = false;

  // Animation
  late AnimationController _bgAnimController;
  late AnimationController _textGlowController;
  late Animation<double> _textGlowAnim;
  Timer? _statusTimer;
  Timer? _batteryTimer;

  CommandProcessor? _processor;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initApp();
  }

  void _initAnimations() {
    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _textGlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _textGlowAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _textGlowController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initApp() async {
    await _loadPreferences();
    await _initTts();
    await _initStt();
    await _loadSystemInfo();
    _startBatteryTimer();
    _checkServiceStatus();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _assistantName = prefs.getString('assistant_name') ?? 'JARVIS';
    });
    _processor = CommandProcessor(assistantName: _assistantName);
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setPitch(1.2);    // Higher pitch = more feminine
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);

    // Try to pick a female voice
    final voices = await _tts.getVoices;
    if (voices is List) {
      for (final v in voices) {
        final name = (v['name'] ?? '').toString().toLowerCase();
        if (name.contains('female') || name.contains('woman') ||
            name.contains('samantha') || name.contains('fiona') ||
            name.contains('en-us-x-tpf') || name.contains('en-us-x-sfg')) {
          await _tts.setVoice({'name': v['name'], 'locale': 'en-US'});
          break;
        }
      }
    }

    _tts.setStartHandler(() => setState(() => _isSpeaking = true));
    _tts.setCompletionHandler(() => setState(() => _isSpeaking = false));

    // Welcome greeting
    await Future.delayed(const Duration(milliseconds: 800));
    await _speak('Welcome back, Boss. ${_assistantName} is online and fully operational.');
  }

  Future<void> _initStt() async {
    _sttAvailable = await _stt.initialize(
      onError: (e) => setState(() {
        _isListening = false;
        _statusText = 'Voice error. Please try again.';
      }),
    );
  }

  Future<void> _loadSystemInfo() async {
    try {
      final level = await _battery.batteryLevel;
      final bright = await ScreenBrightness().current;
      setState(() {
        _batteryLevel = level;
        _brightness = bright;
        _cpuInfo = 'Optimal';
      });
    } catch (_) {}
  }

  void _startBatteryTimer() {
    _batteryTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      try {
        final level = await _battery.batteryLevel;
        setState(() => _batteryLevel = level);
      } catch (_) {}
    });
  }

  void _checkServiceStatus() async {
    final running = await FlutterBackgroundService().isRunning();
    setState(() => _serviceRunning = running);
  }

  Future<void> _speak(String text) async {
    setState(() {
      _isSpeaking = true;
      _statusText = text;
    });
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 30, amplitude: 50);
    }
    await _tts.speak(text);
  }

  Future<void> _startListening() async {
    if (!_sttAvailable) {
      await _speak('Voice recognition is not available on this device, Boss.');
      return;
    }
    if (_isListening) {
      await _stopListening();
      return;
    }

    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 60, amplitude: 80);
    }

    setState(() {
      _isListening = true;
      _transcribed = '';
      _statusText = 'Listening, Boss...';
    });

    await _stt.listen(
      onResult: (result) {
        setState(() {
          _transcribed = result.recognizedWords;
          if (result.finalResult) {
            _isListening = false;
            _processCommand(_transcribed);
          }
        });
      },
      listenMode: ListenMode.confirmation,
      cancelOnError: true,
      partialResults: true,
    );
  }

  Future<void> _stopListening() async {
    await _stt.stop();
    setState(() => _isListening = false);
  }

  Future<void> _processCommand(String command) async {
    if (command.isEmpty) {
      setState(() => _statusText = 'I didn\'t catch that, Boss. Please try again.');
      return;
    }

    setState(() => _statusText = 'Processing: "$command"');

    _processor ??= CommandProcessor(assistantName: _assistantName);
    final result = await _processor!.process(command);

    // Handle special actions
    switch (result.action) {
      case 'take_screenshot':
        await _takeScreenshot();
        break;
      case 'open_settings':
        _openSystemSettings();
        break;
      case 'check_battery':
        final level = await _battery.batteryLevel;
        await _speak('Battery level is $level percent, Boss.');
        return;
      case 'play_music':
        _sendMediaKey(KeyEvent.logicalKey.toString());
        _musicPlaying = true;
        break;
      case 'pause_music':
        _musicPlaying = false;
        break;
      case 'open_wifi':
        const AndroidIntent(
          action: 'android.settings.WIFI_SETTINGS',
        ).launch();
        break;
    }

    await _speak(result.response);
  }

  Future<void> _takeScreenshot() async {
    final image = await _screenshotController.capture();
    if (image != null) {
      await _speak('Screenshot captured, Boss.');
    }
  }

  void _openSystemSettings() {
    const AndroidIntent(
      action: 'android.settings.SETTINGS',
    ).launch();
  }

  void _sendMediaKey(String key) {
    // Media button intent for play/pause
    const AndroidIntent(
      action: 'android.intent.action.MEDIA_BUTTON',
    ).launch().catchError((_) {});
  }

  Future<void> _toggleService() async {
    final service = FlutterBackgroundService();
    final running = await service.isRunning();

    if (running) {
      service.invoke('stopService');
      setState(() => _serviceRunning = false);
      await _speak('Background service stopped, Boss. I will only work when you open me.');
    } else {
      await service.startService();
      setState(() => _serviceRunning = true);
      await _speak('Background service activated, Boss. I am now running in the notification bar.');
    }
  }

  void _onNameChanged(String name) {
    setState(() {
      _assistantName = name;
      _processor = CommandProcessor(assistantName: name);
    });
    _speak('My name has been updated to $name, Boss. I will remember this.');
  }

  @override
  void dispose() {
    _bgAnimController.dispose();
    _textGlowController.dispose();
    _batteryTimer?.cancel();
    _statusTimer?.cancel();
    _tts.stop();
    _stt.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Screenshot(
      controller: _screenshotController,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // ── Animated deep space background ──
            _buildBackground(size),

            // ── Main content ──
            SafeArea(
              child: Column(
                children: [
                  _buildTopBar(),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          _buildGreeting(),
                          const SizedBox(height: 20),
                          _buildOrb(),
                          const SizedBox(height: 20),
                          _buildStatusText(),
                          if (_transcribed.isNotEmpty && _isListening)
                            _buildTranscribed(),
                          const SizedBox(height: 20),
                          _buildStatusCards(),
                          const SizedBox(height: 20),
                          _buildControlButtons(),
                          const SizedBox(height: 20),
                          _buildAppGrid(),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                  _buildBottomBar(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground(Size size) {
    return AnimatedBuilder(
      animation: _bgAnimController,
      builder: (_, __) {
        return CustomPaint(
          size: size,
          painter: _BackgroundPainter(_bgAnimController.value),
        );
      },
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Service toggle
          GestureDetector(
            onTap: _toggleService,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _serviceRunning
                      ? const Color(0xFF00E676)
                      : Colors.white30,
                ),
                color: _serviceRunning
                    ? const Color(0xFF00E676).withOpacity(0.1)
                    : Colors.white.withOpacity(0.05),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _serviceRunning
                          ? const Color(0xFF00E676)
                          : Colors.white30,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _serviceRunning ? 'ONLINE' : 'OFFLINE',
                    style: TextStyle(
                      color: _serviceRunning
                          ? const Color(0xFF00E676)
                          : Colors.white38,
                      fontSize: 10,
                      letterSpacing: 1.5,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // Name display
          AnimatedBuilder(
            animation: _textGlowAnim,
            builder: (_, __) => Text(
              _assistantName,
              style: TextStyle(
                color: const Color(0xFF00E5FF).withOpacity(_textGlowAnim.value),
                fontSize: 14,
                letterSpacing: 6,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const Spacer(),

          // Settings button
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SettingsScreen(
                  currentName: _assistantName,
                  onNameChanged: _onNameChanged,
                ),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF00B0FF).withOpacity(0.3)),
                color: const Color(0xFF00B0FF).withOpacity(0.05),
              ),
              child: const Icon(Icons.settings_outlined,
                  color: Color(0xFF00B0FF), size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreeting() {
    return AnimatedBuilder(
      animation: _textGlowAnim,
      builder: (_, __) {
        final glow = _textGlowAnim.value;
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 30, height: 1, color: const Color(0xFF0288D1).withOpacity(0.5)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '[ SYS.ACTIVE ]',
                    style: TextStyle(
                      color: const Color(0xFF4FC3F7).withOpacity(0.55),
                      fontSize: 9, letterSpacing: 2, fontFamily: 'monospace',
                    ),
                  ),
                ),
                Container(width: 30, height: 1, color: const Color(0xFF0288D1).withOpacity(0.5)),
              ],
            ),
            const SizedBox(height: 8),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF4FC3F7), Colors.white, Color(0xFF00B0FF)],
              ).createShader(bounds),
              child: Text(
                'Hello, Boss',
                style: TextStyle(
                  fontSize: 38, fontWeight: FontWeight.w200, letterSpacing: 5,
                  color: Colors.white,
                  shadows: [Shadow(color: const Color(0xFF00E5FF).withOpacity(glow * 0.8), blurRadius: 24)],
                ),
              ),
            ),
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF0288D1).withOpacity(0.4)),
                borderRadius: BorderRadius.circular(4),
                color: const Color(0xFF0288D1).withOpacity(0.06),
              ),
              child: Text(
                _getGreetingTime(),
                style: TextStyle(
                  color: const Color(0xFF4FC3F7).withOpacity(0.7 + glow * 0.15),
                  fontSize: 10, letterSpacing: 3, fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _getGreetingTime() {
    final h = DateTime.now().hour;
    if (h < 12) return 'GOOD MORNING';
    if (h < 17) return 'GOOD AFTERNOON';
    if (h < 21) return 'GOOD EVENING';
    return 'GOOD NIGHT';
  }

  Widget _buildOrb() {
    return GestureDetector(
      onTap: _startListening,
      child: JarvisOrb(
        isListening: _isListening,
        isSpeaking: _isSpeaking,
        size: 160,
      ),
    );
  }

  Widget _buildStatusText() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: const Color(0xFF0288D1).withOpacity(0.06),
          border: Border.all(color: const Color(0xFF0288D1).withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 6, height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isListening
                    ? const Color(0xFF00E5FF)
                    : _isSpeaking
                        ? const Color(0xFF29B6F6)
                        : const Color(0xFF0288D1).withOpacity(0.6),
                boxShadow: [BoxShadow(
                  color: const Color(0xFF00B0FF).withOpacity(0.6),
                  blurRadius: 6,
                )],
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                _statusText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF90CAF9),
                  fontSize: 12,
                  height: 1.5,
                  fontFamily: 'monospace',
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTranscribed() {
    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 32, right: 32),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFF00E5FF).withOpacity(0.05),
          border:
              Border.all(color: const Color(0xFF00E5FF).withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mic, color: Color(0xFF00E5FF), size: 14),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _transcribed,
                style: const TextStyle(
                  color: Color(0xFF00E5FF),
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: StatusCard(
              icon: Icons.battery_charging_full,
              label: 'BATTERY',
              value: '$_batteryLevel%',
              color: _batteryLevel > 30
                  ? const Color(0xFF00E676)
                  : const Color(0xFFFF5252),
              progress: _batteryLevel / 100,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: StatusCard(
              icon: Icons.memory,
              label: 'CPU',
              value: _cpuInfo,
              color: const Color(0xFF00B0FF),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: StatusCard(
              icon: Icons.brightness_6,
              label: 'BRIGHT',
              value: '${(_brightness * 100).toInt()}%',
              color: const Color(0xFF40C4FF),
              progress: _brightness,
              onIncrease: () async {
                final v = (_brightness + 0.15).clamp(0.0, 1.0);
                await ScreenBrightness().setScreenBrightness(v);
                setState(() => _brightness = v);
              },
              onDecrease: () async {
                final v = (_brightness - 0.15).clamp(0.0, 1.0);
                await ScreenBrightness().setScreenBrightness(v);
                setState(() => _brightness = v);
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: StatusCard(
              icon: Icons.volume_up,
              label: 'SOUND',
              value: '${(_volume * 100).toInt()}%',
              color: const Color(0xFF80D8FF),
              progress: _volume,
              onIncrease: () {
                final v = (_volume + 0.15).clamp(0.0, 1.0);
                VolumeController().setVolume(v);
                setState(() => _volume = v);
              },
              onDecrease: () {
                final v = (_volume - 0.15).clamp(0.0, 1.0);
                VolumeController().setVolume(v);
                setState(() => _volume = v);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ctrlBtn(
            icon: _musicPlaying ? Icons.pause_circle : Icons.play_circle,
            label: _musicPlaying ? 'PAUSE' : 'PLAY',
            color: const Color(0xFF00B0FF),
            onTap: () {
              setState(() => _musicPlaying = !_musicPlaying);
              _speak(_musicPlaying ? 'Playing music, Boss.' : 'Music paused, Boss.');
            },
          ),
          _ctrlBtn(
            icon: Icons.screenshot,
            label: 'SNAP',
            color: const Color(0xFF40C4FF),
            onTap: () async {
              await _speak('Taking screenshot, Boss.');
              await _takeScreenshot();
            },
          ),
          _ctrlBtn(
            icon: Icons.mic,
            label: _isListening ? 'STOP' : 'LISTEN',
            color: _isListening ? const Color(0xFFFF5252) : const Color(0xFF00E5FF),
            onTap: _startListening,
          ),
          _ctrlBtn(
            icon: Icons.settings,
            label: 'CONFIG',
            color: const Color(0xFF80D8FF),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SettingsScreen(
                  currentName: _assistantName,
                  onNameChanged: _onNameChanged,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ctrlBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.4)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.08),
              color.withOpacity(0.02),
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color.withOpacity(0.8),
                fontSize: 9,
                letterSpacing: 1.2,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppGrid() {
    final apps = [
      _AppItem('WhatsApp', Icons.message, 'whatsapp'),
      _AppItem('Instagram', Icons.camera_alt, 'instagram'),
      _AppItem('YouTube', Icons.play_arrow, 'youtube'),
      _AppItem('Maps', Icons.map, 'maps'),
      _AppItem('Gmail', Icons.email, 'gmail'),
      _AppItem('Chrome', Icons.language, 'chrome'),
      _AppItem('Drive', Icons.cloud, 'drive'),
      _AppItem('LinkedIn', Icons.work, 'linkedin'),
      _AppItem('GPay', Icons.payment, 'gpay'),
      _AppItem('Flipkart', Icons.shopping_bag, 'flipkart'),
      _AppItem('Play Store', Icons.store, 'play store'),
      _AppItem('ChatGPT', Icons.smart_toy, 'chatgpt'),
      _AppItem('MX Player', Icons.video_library, 'mx player'),
      _AppItem('IRCTC', Icons.train, 'rail'),
      _AppItem('Airtel', Icons.signal_cellular_alt, 'airtel'),
      _AppItem('Camera', Icons.camera, 'camera'),
      _AppItem('Calculator', Icons.calculate, 'calculator'),
      _AppItem('Clock', Icons.access_time, 'clock'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'QUICK LAUNCH',
              style: TextStyle(
                color: Color(0xFF00E5FF),
                fontSize: 10,
                letterSpacing: 3,
                fontFamily: 'monospace',
              ),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              crossAxisSpacing: 8,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemCount: apps.length,
            itemBuilder: (_, i) => _buildAppIcon(apps[i]),
          ),
        ],
      ),
    );
  }

  Widget _buildAppIcon(_AppItem app) {
    return GestureDetector(
      onTap: () async {
        if (await Vibration.hasVibrator() ?? false) {
          Vibration.vibrate(duration: 20);
        }
        final result = await AppLauncherService.handleCommand(app.command);
        if (result.isNotEmpty) await _speak(result);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0D2137), Color(0xFF0A1929)],
              ),
              border: Border.all(
                color: const Color(0xFF00B0FF).withOpacity(0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00B0FF).withOpacity(0.08),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Icon(app.icon, color: const Color(0xFF40C4FF), size: 20),
          ),
          const SizedBox(height: 4),
          Text(
            app.name,
            style: const TextStyle(color: Colors.white54, fontSize: 8),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        border: Border(
          top: BorderSide(
            color: const Color(0xFF00B0FF).withOpacity(0.15),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'TAP ORB TO SPEAK',
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 9,
              letterSpacing: 2,
              fontFamily: 'monospace',
            ),
          ),
          GestureDetector(
            onTap: _startListening,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _isListening
                      ? [const Color(0xFFFF1744), const Color(0xFFFF5252)]
                      : [const Color(0xFF0288D1), const Color(0xFF00B0FF)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_isListening
                            ? const Color(0xFFFF1744)
                            : const Color(0xFF00B0FF))
                        .withOpacity(0.4),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                _isListening ? Icons.stop : Icons.mic,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          Text(
            _serviceRunning ? 'BG: ACTIVE' : 'BG: OFF',
            style: TextStyle(
              color: _serviceRunning
                  ? const Color(0xFF00E676).withOpacity(0.6)
                  : Colors.white.withOpacity(0.3),
              fontSize: 9,
              letterSpacing: 2,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

// ── App model ──
class _AppItem {
  final String name;
  final IconData icon;
  final String command;
  const _AppItem(this.name, this.icon, this.command);
}

// ── Background painter — Robot HUD / Circuit Board ──
class _BackgroundPainter extends CustomPainter {
  final double t;
  _BackgroundPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── Base gradient: deep navy → dark steel blue ──
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF020C1B),
          Color(0xFF041628),
          Color(0xFF061E35),
          Color(0xFF030F1E),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // ── Animated sky-blue radial glow (reactor core effect) ──
    final glowX = w * 0.5;
    final glowY = h * (0.32 + sin(t * 2 * pi) * 0.03);
    for (int i = 0; i < 3; i++) {
      final radius = w * (0.6 + i * 0.25);
      final opacity = (0.055 - i * 0.015) * (0.8 + sin(t * 2 * pi + i) * 0.2);
      final glowPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF0288D1).withOpacity(opacity),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: Offset(glowX, glowY), radius: radius));
      canvas.drawCircle(Offset(glowX, glowY), radius, glowPaint);
    }

    // ── HUD perspective grid ──
    final gridPaint = Paint()
      ..color = const Color(0xFF0288D1).withOpacity(0.055)
      ..strokeWidth = 0.6;

    // Horizontal lines (vanishing point perspective)
    const hLines = 18;
    final vpy = h * 0.42; // vanishing point Y
    for (int i = 0; i <= hLines; i++) {
      final y = vpy + (h - vpy) * (i / hLines);
      final fade = (i / hLines);
      gridPaint.color = const Color(0xFF0288D1).withOpacity(0.04 + fade * 0.06);
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    // Vertical lines with perspective spread
    const vLines = 14;
    for (int i = 0; i <= vLines; i++) {
      final frac = i / vLines;
      final topX = w * 0.2 + frac * w * 0.6;
      final botX = frac * w;
      gridPaint.color = const Color(0xFF0288D1).withOpacity(0.04);
      canvas.drawLine(Offset(topX, vpy), Offset(botX, h), gridPaint);
    }

    // ── Upper flat grid (ceiling panel) ──
    final flatPaint = Paint()
      ..color = const Color(0xFF4FC3F7).withOpacity(0.028)
      ..strokeWidth = 0.5;
    const spacing = 36.0;
    for (double x = 0; x < w; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, vpy), flatPaint);
    }
    for (double y = 0; y < vpy; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(w, y), flatPaint);
    }

    // ── Circuit traces (random fixed paths) ──
    final tracePaint = Paint()
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final traceNodes = [
      [Offset(w * 0.05, h * 0.15), Offset(w * 0.05, h * 0.28), Offset(w * 0.18, h * 0.28)],
      [Offset(w * 0.95, h * 0.12), Offset(w * 0.95, h * 0.22), Offset(w * 0.82, h * 0.22)],
      [Offset(w * 0.08, h * 0.72), Offset(w * 0.08, h * 0.82), Offset(w * 0.22, h * 0.82)],
      [Offset(w * 0.92, h * 0.75), Offset(w * 0.92, h * 0.86), Offset(w * 0.78, h * 0.86)],
      [Offset(w * 0.12, h * 0.45), Offset(w * 0.24, h * 0.45), Offset(w * 0.24, h * 0.52)],
      [Offset(w * 0.88, h * 0.48), Offset(w * 0.76, h * 0.48), Offset(w * 0.76, h * 0.55)],
    ];

    for (int ti = 0; ti < traceNodes.length; ti++) {
      final nodes = traceNodes[ti];
      // Animate a travelling dot along the trace
      final progress = (t * 1.2 + ti * 0.18) % 1.0;
      final baseOpacity = 0.18 + sin(t * 2 * pi + ti) * 0.07;
      tracePaint.color = const Color(0xFF00B0FF).withOpacity(baseOpacity);

      final path = Path()..moveTo(nodes[0].dx, nodes[0].dy);
      for (int j = 1; j < nodes.length; j++) {
        path.lineTo(nodes[j].dx, nodes[j].dy);
      }
      canvas.drawPath(path, tracePaint);

      // Node dots
      for (final node in nodes) {
        canvas.drawCircle(
          node, 2.5,
          Paint()..color = const Color(0xFF0288D1).withOpacity(0.35),
        );
        canvas.drawCircle(
          node, 1.2,
          Paint()..color = const Color(0xFF4FC3F7).withOpacity(0.7),
        );
      }

      // Travelling glow dot
      final totalLen = nodes.length - 1;
      final segIdx = (progress * totalLen).floor().clamp(0, totalLen - 1);
      final segProgress = (progress * totalLen) - segIdx;
      final from = nodes[segIdx];
      final to = nodes[(segIdx + 1).clamp(0, nodes.length - 1)];
      final dotX = from.dx + (to.dx - from.dx) * segProgress;
      final dotY = from.dy + (to.dy - from.dy) * segProgress;
      canvas.drawCircle(
        Offset(dotX, dotY), 3.5,
        Paint()
          ..color = const Color(0xFF00E5FF).withOpacity(0.9)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }

    // ── Corner HUD decorations ──
    final hudPaint = Paint()
      ..color = const Color(0xFF0288D1).withOpacity(0.35)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final cLen = 22.0;
    final cPad = 12.0;

    // Top-left
    canvas.drawLine(Offset(cPad, cPad + cLen), Offset(cPad, cPad), hudPaint);
    canvas.drawLine(Offset(cPad, cPad), Offset(cPad + cLen, cPad), hudPaint);
    // Top-right
    canvas.drawLine(Offset(w - cPad - cLen, cPad), Offset(w - cPad, cPad), hudPaint);
    canvas.drawLine(Offset(w - cPad, cPad), Offset(w - cPad, cPad + cLen), hudPaint);
    // Bottom-left
    canvas.drawLine(Offset(cPad, h - cPad - cLen), Offset(cPad, h - cPad), hudPaint);
    canvas.drawLine(Offset(cPad, h - cPad), Offset(cPad + cLen, h - cPad), hudPaint);
    // Bottom-right
    canvas.drawLine(Offset(w - cPad - cLen, h - cPad), Offset(w - cPad, h - cPad), hudPaint);
    canvas.drawLine(Offset(w - cPad, h - cPad), Offset(w - cPad, h - cPad - cLen), hudPaint);

    // ── Side panel tick marks ──
    final tickPaint = Paint()
      ..color = const Color(0xFF4FC3F7).withOpacity(0.22)
      ..strokeWidth = 1.0;
    for (int i = 0; i < 8; i++) {
      final y = h * 0.15 + i * h * 0.09;
      final tickLen = i % 3 == 0 ? 10.0 : 5.0;
      canvas.drawLine(Offset(cPad, y), Offset(cPad + tickLen, y), tickPaint);
      canvas.drawLine(Offset(w - cPad, y), Offset(w - cPad - tickLen, y), tickPaint);
    }

    // ── Animated horizontal scan bar (top portion) ──
    final scanY = h * (0.08 + (sin(t * 2 * pi) * 0.5 + 0.5) * 0.25);
    final scanPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          const Color(0xFF0288D1).withOpacity(0.06),
          const Color(0xFF00B0FF).withOpacity(0.12),
          const Color(0xFF0288D1).withOpacity(0.06),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, scanY - 8, w, 16));
    canvas.drawRect(Rect.fromLTWH(0, scanY - 8, w, 16), scanPaint);

    // ── Hexagonal pattern (subtle, top-right area) ──
    _drawHexGrid(canvas, Offset(w * 0.78, h * 0.08), 3, 14, const Color(0xFF0288D1).withOpacity(0.08));
    _drawHexGrid(canvas, Offset(w * 0.16, h * 0.88), 3, 14, const Color(0xFF0288D1).withOpacity(0.06));
  }

  void _drawHexGrid(Canvas canvas, Offset origin, int rows, double hexSize, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.7
      ..style = PaintingStyle.stroke;
    final hexH = hexSize * sqrt(3);
    for (int row = -rows; row <= rows; row++) {
      for (int col = -rows; col <= rows; col++) {
        final cx = origin.dx + col * hexSize * 1.5;
        final cy = origin.dy + row * hexH + (col.isOdd ? hexH / 2 : 0);
        final path = Path();
        for (int i = 0; i < 6; i++) {
          final angle = pi / 180 * (60 * i - 30);
          final x = cx + hexSize * cos(angle);
          final y = cy + hexSize * sin(angle);
          if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
        }
        path.close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_BackgroundPainter old) => old.t != t;
}