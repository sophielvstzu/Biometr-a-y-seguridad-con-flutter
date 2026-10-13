import 'package:flutter/material.dart';
import '../models/access_method.dart';
import '../models/user_account.dart';
import '../services/biometric_service.dart';
import '../services/token_storage.dart';
import 'ai_chat_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  final UserAccount user;    // quién entró
  final AccessMethod method; // cómo entró
  final String token;        // token de ESE usuario
  const HomeScreen({super.key, required this.user, required this.method, required this.token});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _storage = TokenStorage();
  final _bio = BiometricService();
  final _apiKeyCtrl = TextEditingController();
  final DateTime _enteredAt = DateTime.now();

  bool _showToken = false;
  String? _savedApiKeyMasked;

  @override
  void initState() {
    super.initState();
    _loadKey();
  }

  String _mask(String k) => '••••${k.substring(k.length > 4 ? k.length - 4 : 0)}';

  Future<void> _loadKey() async {
    final k = await _storage.readApiKey(widget.user.username);
    if (k != null && mounted) setState(() => _savedApiKeyMasked = _mask(k));
  }

  /// Pedimos biometría OTRA VEZ antes de mostrar un dato sensible.
  Future<void> _revealToken() async {
    final r = await _bio.authenticate(reason: 'Confirma para ver tu token');
    if (r == BiometricResult.success) setState(() => _showToken = true);
  }

  /// Caso de uso IA: guardar la API key de un LLM sin ponerla en el código.
  Future<void> _saveApiKey() async {
    if (_apiKeyCtrl.text.isEmpty) return;
    await _storage.saveApiKey(widget.user.username, _apiKeyCtrl.text);
    final k = await _storage.readApiKey(widget.user.username);
    if (k == null) return;
    setState(() => _savedApiKeyMasked = _mask(k));
    _apiKeyCtrl.clear();
  }

  /// Abrir el asistente IA solo si pasa la huella.
  Future<void> _openAssistant() async {
    final r = await _bio.authenticate(reason: 'Confirma tu identidad para abrir el asistente');
    if (r == BiometricResult.success && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => AiChatScreen(username: widget.user.username)),
      );
    }
  }

  /// Cerrar sesión: solo vuelve al login. NO borra usuarios ni tokens,
  /// por eso la huella y el PIN siguen funcionando después.
  void _logout() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.token;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sesión iniciada'),
        actions: [IconButton(tooltip: 'Cerrar sesión', onPressed: _logout, icon: const Icon(Icons.logout))],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            // ---- Quién ingresó y con qué método ----
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(widget.method.icon, size: 40),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Ingresó ${widget.user.displayName}',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          Text('con ${widget.method.label}', style: const TextStyle(fontSize: 16)),
                          Text('a las ${TimeOfDay.fromDateTime(_enteredAt).format(context)}'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('🔐 Token guardado de forma segura',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Cada usuario tiene su propio token; es el mismo sin importar el método de acceso.',
                style: TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            SelectableText(_showToken ? t : '${t.substring(0, 8)}••••••••••••'),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _revealToken,
              icon: const Icon(Icons.visibility),
              label: const Text('Ver token completo (pide huella)'),
            ),
            const Divider(height: 40),
            const Text('🤖 API key de un modelo de IA',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _apiKeyCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'API key (ej. AIza...)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            FilledButton(onPressed: _saveApiKey, child: const Text('Guardar cifrada')),
            if (_savedApiKeyMasked != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Guardada: $_savedApiKeyMasked'),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _openAssistant,
              icon: const Icon(Icons.smart_toy),
              label: const Text('Abrir asistente IA (pide huella)'),
            ),
          ],
        ),
      ),
    );
  }
}