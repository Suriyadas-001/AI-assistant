// settings_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  final String currentName;
  final Function(String) onNameChanged;

  const SettingsScreen({
    super.key,
    required this.currentName,
    required this.onNameChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _nameController;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('assistant_name', name);
    widget.onNameChanged(name);
    setState(() => _saved = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _saved = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF03060E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF00B0FF)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'S Y S T E M  S E T T I N G S',
          style: TextStyle(
            color: Color(0xFF00B0FF),
            fontSize: 14,
            letterSpacing: 3,
            fontFamily: 'monospace',
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('ASSISTANT IDENTITY'),
            const SizedBox(height: 16),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Change Assistant Name',
                    style: TextStyle(
                      color: Color(0xFF00B0FF),
                      fontSize: 13,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This name will be remembered forever, even after closing the app.',
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      letterSpacing: 2,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter new name...',
                      hintStyle: const TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF00B0FF), width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: const Color(0xFF00B0FF).withOpacity(0.4)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF00E5FF), width: 1.5),
                      ),
                      prefixIcon: const Icon(Icons.edit, color: Color(0xFF00B0FF), size: 18),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveName,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00B0FF).withOpacity(0.2),
                        foregroundColor: const Color(0xFF00E5FF),
                        side: const BorderSide(color: Color(0xFF00B0FF)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        _saved ? '✓ SAVED SUCCESSFULLY' : 'SAVE NAME',
                        style: const TextStyle(letterSpacing: 2, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            _sectionTitle('VOICE COMMANDS GUIDE'),
            const SizedBox(height: 16),
            _card(
              child: Column(
                children: [
                  _commandRow('Open WhatsApp', 'Opens WhatsApp'),
                  _commandRow('What time is it?', 'Tells current time'),
                  _commandRow('Take a screenshot', 'Captures screen'),
                  _commandRow('Increase brightness', 'Raises screen brightness'),
                  _commandRow('Volume up / down', 'Controls volume'),
                  _commandRow('Play / Pause music', 'Media controls'),
                  _commandRow('Open Settings', 'System settings'),
                  _commandRow('Tell me a joke', 'Tells a joke'),
                  _commandRow('What\'s today\'s date?', 'Tells the date'),
                ],
              ),
            ),

            const SizedBox(height: 24),
            _sectionTitle('APP INFO'),
            const SizedBox(height: 16),
            _card(
              child: Column(
                children: [
                  _infoRow('Version', '1.0.0'),
                  _infoRow('Mode', 'Fully Offline'),
                  _infoRow('Speech', 'Android Built-in'),
                  _infoRow('TTS', 'Female Voice'),
                  _infoRow('Made for', 'Android 15'),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF00E5FF),
        fontSize: 11,
        letterSpacing: 3,
        fontFamily: 'monospace',
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0D1B2A).withOpacity(0.9),
            const Color(0xFF0A2540).withOpacity(0.8),
          ],
        ),
        border: Border.all(color: const Color(0xFF00B0FF).withOpacity(0.2)),
      ),
      child: child,
    );
  }

  Widget _commandRow(String command, String action) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          const Icon(Icons.mic, color: Color(0xFF00B0FF), size: 12),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '"$command"',
              style: const TextStyle(
                color: Color(0xFF00E5FF),
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
          Text(
            action,
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String key, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(key, style: const TextStyle(color: Colors.white38, fontSize: 12)),
          Text(value,
              style: const TextStyle(
                color: Color(0xFF00E5FF),
                fontSize: 12,
                fontFamily: 'monospace',
              )),
        ],
      ),
    );
  }
}
