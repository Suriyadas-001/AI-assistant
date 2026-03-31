// app_launcher_service.dart
import 'package:android_intent_plus/android_intent.dart';
import 'package:url_launcher/url_launcher.dart';

class AppLauncherService {
  // Map of voice keywords to package names / URLs
  static const Map<String, String> _packageMap = {
    'whatsapp': 'com.whatsapp',
    'instagram': 'com.instagram.android',
    'youtube': 'com.google.android.youtube',
    'gmail': 'com.google.android.gm',
    'maps': 'com.google.android.apps.maps',
    'google maps': 'com.google.android.apps.maps',
    'drive': 'com.google.android.apps.docs',
    'google drive': 'com.google.android.apps.docs',
    'chrome': 'com.android.chrome',
    'linkedin': 'com.linkedin.android',
    'gpay': 'com.google.android.apps.nbu.paisa.user',
    'google pay': 'com.google.android.apps.nbu.paisa.user',
    'flipkart': 'com.flipkart.android',
    'play store': 'com.android.vending',
    'chatgpt': 'com.openai.chatgpt',
    'mx player': 'com.mxtech.videoplayer.ad',
    'irctc': 'in.gov.irctc.StarterKit',
    'rail': 'in.gov.irctc.StarterKit',
    'railone': 'in.gov.irctc.StarterKit',
    'airtel': 'com.airtel.android.phone',
    'google chat': 'com.google.android.talk',
    'music': 'com.google.android.music',
    'spotify': 'com.spotify.music',
    'calculator': 'com.google.android.calculator',
    'clock': 'com.google.android.deskclock',
    'camera': 'android.intent.action.LAUNCH_CAMERA',
    'gallery': 'com.google.android.apps.photos',
    'photos': 'com.google.android.apps.photos',
    'settings': 'com.android.settings',
    'messages': 'com.google.android.apps.messaging',
    'phone': 'com.google.android.dialer',
    'dialer': 'com.google.android.dialer',
    'contacts': 'com.google.android.contacts',
    'files': 'com.google.android.apps.nbu.files',
    'maps': 'com.google.android.apps.maps',
  };

  static const Map<String, String> _urlMap = {
    'google': 'https://www.google.com',
    'facebook': 'https://www.facebook.com',
    'twitter': 'https://www.twitter.com',
  };

  /// Try to launch app by package name
  static Future<bool> _launchPackage(String packageName) async {
    try {
      if (packageName == 'android.intent.action.LAUNCH_CAMERA') {
        const intent = AndroidIntent(
          action: 'android.media.action.IMAGE_CAPTURE',
        );
        await intent.launch();
        return true;
      }
      final intent = AndroidIntent(
        action: 'android.intent.action.MAIN',
        package: packageName,
        flags: [0x10200000],
      );
      await intent.launch();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Launch URL in browser
  static Future<bool> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return true;
    }
    return false;
  }

  /// Main method: parse command and launch the right app
  static Future<String> handleCommand(String command) async {
    final lower = command.toLowerCase();

    // Check app packages
    for (final entry in _packageMap.entries) {
      if (lower.contains(entry.key)) {
        final launched = await _launchPackage(entry.value);
        if (launched) {
          return 'Opening ${_capitalize(entry.key)}, Boss.';
        } else {
          // Fallback: try play store
          await _launchUrl(
              'https://play.google.com/store/search?q=${entry.key}');
          return '${_capitalize(entry.key)} is not installed. Opening Play Store, Boss.';
        }
      }
    }

    // Check URLs
    for (final entry in _urlMap.entries) {
      if (lower.contains(entry.key)) {
        final launched = await _launchUrl(entry.value);
        if (launched) return 'Opening ${_capitalize(entry.key)}, Boss.';
      }
    }

    return '';
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
