/// Un usuario registrado en ESTE dispositivo.
/// Nunca guardamos la contraseña ni el PIN: solo su hash con sal (SHA-256).
class UserAccount {
  final String username;     // correo o nombre de usuario (único)
  final String displayName;  // nombre que se muestra: "Ingresó Ana"
  final String salt;
  final String passwordHash;
  final String pinHash;

  const UserAccount({
    required this.username,
    required this.displayName,
    required this.salt,
    required this.passwordHash,
    required this.pinHash,
  });

  Map<String, dynamic> toJson() => {
        'username': username,
        'displayName': displayName,
        'salt': salt,
        'passwordHash': passwordHash,
        'pinHash': pinHash,
      };

  factory UserAccount.fromJson(Map<String, dynamic> j) => UserAccount(
        username: j['username'] as String,
        displayName: j['displayName'] as String,
        salt: j['salt'] as String,
        passwordHash: j['passwordHash'] as String,
        pinHash: j['pinHash'] as String,
      );
}