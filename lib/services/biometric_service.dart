import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import '../models/access_method.dart';

enum BiometricResult { success, failed, notAvailable, error }

/// Envuelve el paquete local_auth para que la UI no dependa de él.
class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// ¿El dispositivo soporta biometría y tiene algo registrado?
  Future<bool> isAvailable() async {
    try {
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      if (!supported || !canCheck) return false;
      final types = await _auth.getAvailableBiometrics(); // fingerprint, face...
      return types.isNotEmpty;
    } on PlatformException {
      return false;
    }
  }

  /// ¿Se puede ofrecer este método (huella / rostro) en este dispositivo?
  /// OJO: en Android el sistema a veces solo informa "strong/weak" (genérico),
  /// y la app NO puede exigir un tipo concreto de biometría.
  Future<bool> supports(AccessMethod method) async {
    if (!await isAvailable()) return false;
    try {
      final t = (await _auth.getAvailableBiometrics()).toSet();
      final generic = t.contains(BiometricType.strong) || t.contains(BiometricType.weak);
      switch (method) {
        case AccessMethod.fingerprint:
          return t.contains(BiometricType.fingerprint) || generic;
        case AccessMethod.face:
          return t.contains(BiometricType.face) || generic;
        default:
          return false;
      }
    } on PlatformException {
      return false;
    }
  }

  /// Muestra el diálogo nativo de huella / Face ID.
  Future<BiometricResult> authenticate({String reason = 'Confirma tu identidad para continuar'}) async {
    if (!await isAvailable()) return BiometricResult.notAvailable;
    try {
      final ok = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true, // true = sin PIN/patrón como alternativa
          stickyAuth: true,    // sigue válido si la app pasa a segundo plano
        ),
      );
      return ok ? BiometricResult.success : BiometricResult.failed;
    } on PlatformException {
      // Ej.: bloqueado por demasiados intentos, cancelado, etc.
      return BiometricResult.error;
    }
  }
}