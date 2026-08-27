import 'package:flutter/material.dart';
import '../theme/asha_theme.dart';
import '../services/api_service.dart';

class ChatMessage { final String text; final bool fromUser; ChatMessage(this.text, this.fromUser); }

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final List<ChatMessage> _messages = [ChatMessage('Hi 🌼 how are you feeling today?', false)];
  bool sending = false;

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() { _messages.add(ChatMessage(text, true)); _controller.clear(); sending = true; });
    try {
      final reply = await ApiService.sendChatMessage(text);
      setState(() => _messages.add(ChatMessage(reply, false)));
    } catch (_) {
      setState(() => _messages.add(ChatMessage('(offline) could not reach Asha right now.', false)));
    } finally {
      setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            const AshaMascot(),
            const Padding(padding: EdgeInsets.all(8.0), child: Text('Asha offers wellness guidance, not medical diagnosis.', style: TextStyle(fontSize: 11), textAlign: TextAlign.center)),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (_, i) {
                  final m = _messages[i];
                  return Align(
                    alignment: m.fromUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                      decoration: BoxDecoration(color: m.fromUser ? AshaColors.coral : AshaColors.peach, borderRadius: BorderRadius.circular(16)),
                      child: Text(m.text, style: TextStyle(color: m.fromUser ? Colors.white : AshaColors.ink, fontSize: 13)),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Expanded(child: TextField(controller: _controller, decoration: const InputDecoration(hintText: 'Ask Asha anything…', contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)), onSubmitted: (_) => _send())),
                IconButton(
                  icon: sending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send_rounded, color: AshaColors.coral),
                  onPressed: sending ? null : _send,
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}