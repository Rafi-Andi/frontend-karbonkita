import 'package:image_picker/image_picker.dart';

/// Event AuthBloc.
sealed class AuthEvent {
  const AuthEvent();
}

/// Cek token tersimpan saat app dibuka (auto-login).
class SessionChecked extends AuthEvent {
  const SessionChecked();
}

/// Submit form login 1 field + password.
class LoginSubmitted extends AuthEvent {
  const LoginSubmitted({required this.phoneOrEmail, required this.password});

  final String phoneOrEmail;
  final String password;
}

/// Submit form register mitra (multipart + foto dokumen/toko).
class MitraRegisterSubmitted extends AuthEvent {
  const MitraRegisterSubmitted({required this.fields, required this.files});

  /// Field teks sesuai kontrak register-mitra (termasuk password_confirmation).
  final Map<String, dynamic> fields;

  /// File asli (bukan path string) agar web bisa kirim via bytes.
  /// Kunci: foto_ktp, foto_nib, foto_toko (wajib),
  /// foto_toko_2, foto_toko_3 (opsional/null).
  final Map<String, XFile?> files;
}

/// Submit form register warga (wilayah sudah dinormalisasi di UI).
class RegisterSubmitted extends AuthEvent {
  const RegisterSubmitted({
    required this.name,
    required this.phone,
    required this.email,
    required this.password,
    required this.passwordConfirmation,
    required this.city,
    required this.district,
    required this.subDistrict,
    required this.rt,
    required this.rw,
  });

  final String name;
  final String phone;
  final String email;
  final String password;
  final String passwordConfirmation;
  final String city;
  final String district;
  final String subDistrict;
  final String rt;
  final String rw;
}

/// Hapus token permanen + kembali ke login.
class LoggedOut extends AuthEvent {
  const LoggedOut();
}
