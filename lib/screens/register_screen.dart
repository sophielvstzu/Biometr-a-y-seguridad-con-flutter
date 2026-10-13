import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/user_repository.dart';

/// Crea un usuario nuevo en este dispositivo.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _repo = UserRepository();
  final _nameCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  String? _error;
  bool _busy = false;

  Future<void> _create() async {
    final name = _nameCtrl.text.trim();
    final user = _userCtrl.text.trim();
    final pass = _passCtrl.text;
    final pin = _pinCtrl.text;

    if (name.isEmpty || user.isEmpty) {
      setState(() => _error = 'Escribe tu nombre y un usuario');
      return;
    }
    if (pass.length < 4) {
      setState(() => _error = 'La contraseña debe tener mínimo 4 caracteres');
      return;
    }
    if (pin.length != 4) {
      setState(() => _error = 'El PIN debe tener exactamente 4 dígitos');
      return;
    }

    setState(() { _busy = true; _error = null; });
    try {
      final u = await _repo.register(username: user, displayName: name, password: pass, pin: pin);
      if (mounted) Navigator.pop(context, u.username);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear usuario')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Nombre (el que se mostrará)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _userCtrl,
            decoration: const InputDecoration(labelText: 'Usuario o correo', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passCtrl,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Contraseña', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pinCtrl,
            obscureText: true,
            maxLength: 4,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'PIN de 4 dígitos', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _busy ? null : _create,
            child: _busy
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Crear usuario'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ],
      ),
    );
  }
}