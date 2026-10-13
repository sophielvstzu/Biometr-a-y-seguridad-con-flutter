import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/access_method.dart';
import '../models/user_account.dart';
import '../services/biometric_service.dart';
import '../services/fake_auth_api.dart';
import '../services/token_storage.dart';
import '../services/user_repository.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _bio = BiometricService();
  final _repo = UserRepository();
  final _storage = TokenStorage();
  final _api = FakeAuthApi();
  final _passCtrl = TextEditingController();

  List<UserAccount> _users = [];
  UserAccount? _selected; // quién va a entrar
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers({String? select}) async {
    final users = await _repo.all();
    final wanted = select ?? await _repo.lastUser();
    UserAccount? sel;
    for (final u in users) {
      if (u.username == wanted) sel = u;
    }
    sel ??= users.isNotEmpty ? users.first : null;
    if (!mounted) return;
    setState(() {
      _users = users;
      _selected = sel;
      _loading = false;
    });
  }

  // ---------------------------------------------------------------
  // Entrada común. Si por algún motivo no hay token guardado, se emite
  // uno nuevo: así NUNCA se vuelve a pedir "entra primero con contraseña".
  // ---------------------------------------------------------------
  Future<void> _enter(UserAccount user, AccessMethod method) async {
    var token = await _storage.readToken(user.username);
    if (token == null) {
      token = await _api.issueToken(user.username);
      await _storage.saveToken(user.username, token);
    }
    await _repo.setLastUser(user.username);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => HomeScreen(user: user, method: method, token: token!),
      ),
    );
  }

  // 1) Contraseña: verifica el hash y emite un token nuevo
  Future<void> _loginWithPassword() async {
    final u = _selected;
    if (u == null) return;
    setState(() { _busy = true; _error = null; });
    try {
      if (!_repo.checkPassword(u, _passCtrl.text)) {
        setState(() => _error = 'Contraseña incorrecta');
        return;
      }
      final token = await _api.issueToken(u.username);
      await _storage.saveToken(u.username, token);
      _passCtrl.clear();
      await _enter(u, AccessMethod.password);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // 2) Huella o rostro
  Future<void> _loginWithBiometric(AccessMethod method) async {
    final u = _selected;
    if (u == null) return;
    setState(() => _error = null);

    if (!await _bio.supports(method)) {
      setState(() => _error = 'No hay ${method.label} disponible o registrada en este dispositivo.');
      return;
    }

    final result = await _bio.authenticate(reason: 'Ingresa como ${u.displayName} con tu ${method.label}');
    switch (result) {
      case BiometricResult.success:
        await _enter(u, method);
        break;
      case BiometricResult.failed:
        setState(() => _error = 'Autenticación fallida o cancelada');
        break;
      case BiometricResult.notAvailable:
        setState(() => _error = 'Biometría no disponible en este dispositivo');
        break;
      case BiometricResult.error:
        setState(() => _error = 'Error de biometría (¿demasiados intentos?)');
        break;
    }
  }

  // 3) PIN del usuario seleccionado
  Future<void> _loginWithPin() async {
    final u = _selected;
    if (u == null) return;
    setState(() => _error = null);

    final entered = await _askPin('PIN de ${u.displayName}');
    if (entered == null) return;
    if (_repo.checkPin(u, entered)) {
      await _enter(u, AccessMethod.pin);
    } else {
      setState(() => _error = 'PIN incorrecto');
    }
  }

  Future<String?> _askPin(String title) {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          obscureText: true,
          maxLength: 4,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(counterText: '', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('Aceptar')),
        ],
      ),
    );
  }

  Future<void> _openRegister() async {
    final created = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
    if (created != null) {
      await _loadUsers(select: created);
      if (mounted) setState(() => _error = null);
    }
  }

  Future<void> _deleteSelected() async {
    final u = _selected;
    if (u == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('¿Eliminar a ${u.displayName}?'),
        content: const Text('Se borrarán su PIN, token y API key de este dispositivo.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok != true) return;
    await _repo.delete(u.username);
    await _storage.deleteToken(u.username);
    await _storage.deleteApiKey(u.username);
    await _loadUsers();
  }

  Widget _methodButton(AccessMethod m, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(m.icon),
        label: Text('Entrar con ${m.label}'),
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Primera vez: no hay usuarios
    if (_users.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bienvenido')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 72),
                const SizedBox(height: 16),
                const Text('Aún no hay usuarios en este dispositivo.', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _openRegister,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Crear primer usuario'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar sesión')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('¿Quién eres?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final u in _users)
                ChoiceChip(
                  avatar: const Icon(Icons.person, size: 18),
                  label: Text(u.displayName),
                  selected: u.username == _selected?.username,
                  onSelected: (_) => setState(() {
                    _selected = u;
                    _error = null;
                    _passCtrl.clear();
                  }),
                ),
            ],
          ),
          const SizedBox(height: 20),
          _methodButton(AccessMethod.fingerprint, () => _loginWithBiometric(AccessMethod.fingerprint)),
          _methodButton(AccessMethod.face, () => _loginWithBiometric(AccessMethod.face)),
          _methodButton(AccessMethod.pin, _loginWithPin),
          ExpansionTile(
            leading: const Icon(Icons.password),
            title: const Text('Entrar con contraseña'),
            children: [
              TextField(
                controller: _passCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Contraseña', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _busy ? null : _loginWithPassword,
                child: const Text('Entrar'),
              ),
              const SizedBox(height: 8),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const Divider(height: 32),
          OutlinedButton.icon(
            onPressed: _openRegister,
            icon: const Icon(Icons.person_add),
            label: const Text('Crear nuevo usuario'),
          ),
          TextButton.icon(
            onPressed: _deleteSelected,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Eliminar usuario seleccionado'),
          ),
        ],
      ),
    );
  }
}