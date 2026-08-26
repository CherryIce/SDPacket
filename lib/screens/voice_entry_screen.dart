import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../app.dart';

class VoiceEntryScreen extends StatefulWidget {
  const VoiceEntryScreen({super.key, required this.projectId});

  final String projectId;

  @override
  State<VoiceEntryScreen> createState() => _VoiceEntryScreenState();
}

class _VoiceEntryScreenState extends State<VoiceEntryScreen> {
  final _speech = SpeechToText();
  final _transcript = TextEditingController();
  bool _initialized = false;
  bool _available = true;
  bool _saving = false;

  @override
  void dispose() {
    _speech.cancel();
    _transcript.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (!_initialized) {
      _available = await _speech.initialize(
        onError: (_) {
          if (mounted) setState(() => _available = false);
        },
        onStatus: (_) {
          if (mounted) setState(() {});
        },
      );
      _initialized = true;
    }
    if (!_available) {
      if (mounted) setState(() {});
      return;
    }
    await _speech.listen(
      onResult: _onResult,
      listenOptions: SpeechListenOptions(
        partialResults: true,
        listenMode: ListenMode.confirmation,
        onDevice: true,
      ),
    );
    if (mounted) setState(() {});
  }

  void _onResult(SpeechRecognitionResult result) {
    _transcript.value = TextEditingValue(
      text: result.recognizedWords,
      selection: TextSelection.collapsed(offset: result.recognizedWords.length),
    );
    if (mounted) setState(() {});
  }

  Future<void> _stop() async {
    await _speech.stop();
    if (mounted) setState(() {});
  }

  Future<void> _create() async {
    if (_transcript.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.voiceEmpty)));
      return;
    }
    setState(() => _saving = true);
    try {
      final box = await StoreScope.of(
        context,
      ).createBox(projectId: widget.projectId, memo: _transcript.text);
      if (mounted) Navigator.pop(context, box.id);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.voiceTitle)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(context.l10n.voiceHint),
          const SizedBox(height: 18),
          if (!_available)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.speechUnavailable,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(context.l10n.speechUnavailableHint),
                  ],
                ),
              ),
            ),
          TextField(
            controller: _transcript,
            minLines: 7,
            maxLines: 12,
            decoration: InputDecoration(
              labelText: context.l10n.transcript,
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.tonalIcon(
            onPressed: _speech.isListening ? _stop : _start,
            icon: Icon(_speech.isListening ? Icons.stop : Icons.mic),
            label: Text(
              _speech.isListening
                  ? context.l10n.stopListening
                  : context.l10n.startListening,
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.pop(context, 'manual'),
            child: Text(context.l10n.switchManual),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: FilledButton(
          onPressed: _saving ? null : _create,
          child: _saving
              ? const CircularProgressIndicator(strokeWidth: 2)
              : Text(context.l10n.createFromVoice),
        ),
      ),
    );
  }
}
