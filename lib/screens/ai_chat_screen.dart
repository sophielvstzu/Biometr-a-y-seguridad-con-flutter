import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import '../services/token_storage.dart';

class _Msg {
  final bool isUser;
  final String text;
  _Msg(this.isUser, this.text);
}

/// Chat con un modelo de IA real. Solo se llega aquí DESPUÉS de pasar la huella,
/// y la API key se lee del almacenamiento cifrado.
class AiChatScreen extends StatefulWidget {
  final String username; // la API key es de este usuario
  const AiChatScreen({super.key, required this.username});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _ai = AiService();
  final _storage = TokenStorage();
  final _ctrl = TextEditingController();
  final List<_Msg> _msgs = [];
  bool _loading = false;

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _loading) return;

    final apiKey = await _storage.readApiKey(widget.username); // <- lectura segura
    if (apiKey == null) {
      setState(() => _msgs.add(_Msg(false, '⚠️ Primero guarda tu API key en la pantalla anterior.')));
      return;
    }

    setState(() {
      _msgs.add(_Msg(true, text));
      _loading = true;
      _ctrl.clear();
    });

    try {
      final answer = await _ai.ask(apiKey, text);
      setState(() => _msgs.add(_Msg(false, answer)));
    } catch (e) {
      setState(() => _msgs.add(_Msg(false, '❌ ${e.toString().replaceFirst('Exception: ', '')}')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Asistente IA 🤖')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _msgs.length,
              itemBuilder: (_, i) {
                final m = _msgs[i];
                return Align(
                  alignment: m.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                    decoration: BoxDecoration(
                      color: m.isUser
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(m.text),
                  ),
                );
              },
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    onSubmitted: (_) => _send(),
                    decoration: const InputDecoration(
                      hintText: 'Pregunta algo (ej. ¿Qué es el Keychain?)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(onPressed: _send, icon: const Icon(Icons.send)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}