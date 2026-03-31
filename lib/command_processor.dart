// command_processor.dart
import 'package:android_intent_plus/android_intent.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:volume_controller/volume_controller.dart';
import 'app_launcher_service.dart';

class CommandResult {
  final String response;
  final String? action; // 'take_screenshot', 'open_settings', 'toggle_music', etc.
  CommandResult(this.response, {this.action});
}

class CommandProcessor {
  final String assistantName;

  CommandProcessor({required this.assistantName});

  Future<CommandResult> process(String command) async {
    final lower = command.toLowerCase().trim();

    // ── Greetings ──
    if (_matches(lower, ['hello', 'hi', 'hey', 'good morning', 'good evening', 'good night', 'good afternoon'])) {
      return CommandResult(_greeting());
    }

    // ── How are you ──
    if (_matches(lower, ['how are you', 'how do you do', 'what\'s up', 'wassup'])) {
      return CommandResult('All systems are fully operational, Boss. Ready to serve you.');
    }

    // ── Name queries ──
    if (_matches(lower, ['what is your name', 'who are you', 'your name'])) {
      return CommandResult('I am $assistantName, your personal AI assistant. At your service, Boss.');
    }

    // ── Time ──
    if (_matches(lower, ['what time', 'current time', 'time now'])) {
      final now = DateTime.now();
      final hour = now.hour > 12 ? now.hour - 12 : now.hour;
      final min = now.minute.toString().padLeft(2, '0');
      final ampm = now.hour >= 12 ? 'PM' : 'AM';
      return CommandResult('The time is $hour:$min $ampm, Boss.');
    }

    // ── Date ──
    if (_matches(lower, ['what date', 'today\'s date', 'what day', 'current date'])) {
      final now = DateTime.now();
      final months = ['January','February','March','April','May','June','July','August','September','October','November','December'];
      final days = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
      return CommandResult('Today is ${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}, ${now.year}, Boss.');
    }

    // ── Screenshot ──
    if (_matches(lower, ['take screenshot', 'screenshot', 'capture screen', 'take a screenshot'])) {
      return CommandResult('Taking a screenshot now, Boss.', action: 'take_screenshot');
    }

    // ── Open Settings ──
    if (_matches(lower, ['open settings', 'settings', 'go to settings'])) {
      return CommandResult('Opening settings, Boss.', action: 'open_settings');
    }

    // ── Brightness ──
    if (_matches(lower, ['increase brightness', 'brightness up', 'more brightness', 'brighter'])) {
      try {
        final current = await ScreenBrightness().current;
        final newVal = (current + 0.2).clamp(0.0, 1.0);
        await ScreenBrightness().setScreenBrightness(newVal);
        return CommandResult('Brightness increased, Boss.');
      } catch (e) {
        return CommandResult('Unable to change brightness, Boss.');
      }
    }

    if (_matches(lower, ['decrease brightness', 'brightness down', 'less brightness', 'darker', 'dim'])) {
      try {
        final current = await ScreenBrightness().current;
        final newVal = (current - 0.2).clamp(0.0, 1.0);
        await ScreenBrightness().setScreenBrightness(newVal);
        return CommandResult('Brightness decreased, Boss.');
      } catch (e) {
        return CommandResult('Unable to change brightness, Boss.');
      }
    }

    // ── Volume ──
    if (_matches(lower, ['volume up', 'increase volume', 'louder', 'turn up'])) {
      try {
        final current = await VolumeController().getVolume();
        VolumeController().setVolume((current + 0.2).clamp(0.0, 1.0));
        return CommandResult('Volume increased, Boss.');
      } catch (e) {
        return CommandResult('Volume adjusted, Boss.');
      }
    }

    if (_matches(lower, ['volume down', 'decrease volume', 'quieter', 'turn down', 'lower volume'])) {
      try {
        final current = await VolumeController().getVolume();
        VolumeController().setVolume((current - 0.2).clamp(0.0, 1.0));
        return CommandResult('Volume decreased, Boss.');
      } catch (e) {
        return CommandResult('Volume adjusted, Boss.');
      }
    }

    if (_matches(lower, ['mute', 'silent', 'silence', 'no sound'])) {
      try {
        VolumeController().setVolume(0.0);
        return CommandResult('Device muted, Boss.');
      } catch (e) {
        return CommandResult('Muted, Boss.');
      }
    }

    // ── Music Controls ──
    if (_matches(lower, ['play music', 'play song', 'start music', 'play'])) {
      return CommandResult('Playing music, Boss.', action: 'play_music');
    }

    if (_matches(lower, ['pause music', 'pause song', 'stop music', 'pause'])) {
      return CommandResult('Pausing music, Boss.', action: 'pause_music');
    }

    if (_matches(lower, ['next song', 'next track', 'skip song', 'next'])) {
      return CommandResult('Skipping to next track, Boss.', action: 'next_song');
    }

    // ── Battery ──
    if (_matches(lower, ['battery', 'battery level', 'how much battery', 'charge'])) {
      return CommandResult('Checking battery level now, Boss.', action: 'check_battery');
    }

    // ── WiFi ──
    if (_matches(lower, ['wifi on', 'turn on wifi', 'enable wifi'])) {
      return CommandResult('Opening Wi-Fi settings, Boss. You can toggle it from there.', action: 'open_wifi');
    }

    // ── Torch / Flashlight ──
    if (_matches(lower, ['torch on', 'flashlight on', 'turn on torch', 'flashlight'])) {
      return CommandResult('Torch control is available through your camera app, Boss.', action: 'open_camera');
    }

    // ── Thanks ──
    if (_matches(lower, ['thank you', 'thanks', 'thank u', 'good job', 'well done'])) {
      return CommandResult('Always a pleasure, Boss. I am here for you.');
    }

    // ── Jokes ──
    if (_matches(lower, ['joke', 'tell me a joke', 'make me laugh', 'funny'])) {
      final jokes = [
        'Why do programmers prefer dark mode? Because light attracts bugs, Boss!',
        'I told my wife she should embrace her mistakes. She gave me a hug, Boss.',
        'Why did the AI go to school? To improve its neural network, Boss!',
      ];
      jokes.shuffle();
      return CommandResult(jokes.first);
    }

    // ── App Launching ──
    final appResult = await AppLauncherService.handleCommand(lower);
    if (appResult.isNotEmpty) {
      return CommandResult(appResult);
    }

    // ── Unknown ──
    return CommandResult(
        'I\'m sorry Boss, I did not understand that command. Could you please repeat?');
  }

  bool _matches(String input, List<String> keywords) {
    return keywords.any((k) => input.contains(k));
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning, Boss! Systems are ready.';
    if (hour < 17) return 'Good afternoon, Boss! How may I assist you?';
    if (hour < 21) return 'Good evening, Boss! All systems are online.';
    return 'Good night, Boss. I hope you had a wonderful day.';
  }
}
