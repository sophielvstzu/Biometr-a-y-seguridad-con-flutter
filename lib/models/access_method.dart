import 'package:flutter/material.dart';

/// Formas de entrar a la app.
enum AccessMethod {
  password('contraseña', Icons.password),
  fingerprint('huella', Icons.fingerprint),
  face('rostro', Icons.face),
  pin('PIN', Icons.pin);

  final String label;
  final IconData icon;
  const AccessMethod(this.label, this.icon);
}