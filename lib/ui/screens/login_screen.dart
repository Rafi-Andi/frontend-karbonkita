import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import 'register_screen.dart';
import 'mitra_register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final TextEditingController _phoneOrEmailController;
  late final TextEditingController _passwordController;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _phoneOrEmailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _phoneOrEmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(
      LoginSubmitted(
        phoneOrEmail: _phoneOrEmailController.text,
        password: _passwordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // SessionGate di main adalah penentu root (Login <-> Home berdasar
    // AuthBloc). Listener ini hanya mengembalikan tumpukan ke route pertama
    // (SessionGate) saat login sukses, TANPA push manual ke Home.
    // Ini memperbaiki bug "stuck di login setelah logout + login lagi"
    // yang terjadi saat SessionGate sempat ter-replace.
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (prev, curr) =>
          curr.status == AuthStatus.authenticated &&
          prev.status != AuthStatus.authenticated,
      listener: (context, state) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF4FAF5), // Light green background
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back Button
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, top: 16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black87),
                      onPressed: () {
                        // Handle back if necessary
                      },
                    ),
                  ),
                ),

                // Header Section
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Image.asset(
                              'assets/images/logoapp.png',
                              height: 40,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                    Icons.eco,
                                    size: 40,
                                    color: Colors.green,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Buat akun dan mulai perjalanan hijau bersama ribuan warga!',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF333333),
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(
                                  Icons.verified,
                                  color: Colors.green,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Akunmu aman dan terlindungi',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Image.asset(
                          'assets/images/totebagandphone.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const SizedBox(height: 120),
                        ),
                      ),
                    ],
                  ),
                ),

                // Form Section
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Masuk ke Akunmu',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B8039),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Yuk, lanjutkan aksi hijaumu!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 32),

                      // Bloc-driven error banner (401/403/429/jaringan)
                      BlocBuilder<AuthBloc, AuthState>(
                        buildWhen: (prev, curr) =>
                            prev.message != curr.message ||
                            prev.status != curr.status,
                        builder: (context, state) {
                          if (state.message == null ||
                              state.status == AuthStatus.loading) {
                            return const SizedBox.shrink();
                          }
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFDECEA),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Color(0xFFC62828),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    state.message!,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFFC62828),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      // Single field: No HP atau Email
                      BlocSelector<AuthBloc, AuthState, String?>(
                        selector: (state) {
                          final list = state.fieldErrors['phone_or_email'];
                          return (list != null && list.isNotEmpty)
                              ? list.first
                              : null;
                        },
                        builder: (context, fieldError) {
                          return _buildTextField(
                            hint: 'No HP (+628...) atau Email',
                            helper:
                                'Bisa nomor HP format +62 atau alamat email',
                            icon: Icons.person_outline,
                            controller: _phoneOrEmailController,
                            keyboardType: TextInputType.emailAddress,
                            errorText: fieldError,
                            onSubmitted: (_) => _submit(),
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password Field
                      BlocSelector<AuthBloc, AuthState, String?>(
                        selector: (state) {
                          final list = state.fieldErrors['password'];
                          return (list != null && list.isNotEmpty)
                              ? list.first
                              : null;
                        },
                        builder: (context, fieldError) {
                          return _buildTextField(
                            hint: 'Kata sandi',
                            icon: Icons.lock_outline,
                            isPassword: true,
                            obscureText: _obscurePassword,
                            controller: _passwordController,
                            errorText: fieldError,
                            onSubmitted: (_) => _submit(),
                            onTogglePassword: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      const SizedBox(height: 32),

                      // Submit Button
                      BlocBuilder<AuthBloc, AuthState>(
                        buildWhen: (prev, curr) => prev.status != curr.status,
                        builder: (context, state) {
                          final loading = state.status == AuthStatus.loading;
                          return ElevatedButton(
                            onPressed: loading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1B8039),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(100),
                              ),
                              elevation: 0,
                            ),
                            child: loading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Masuk',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      Divider(color: Colors.grey.shade200, thickness: 1),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),

                // Navigation to Register
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Belum punya akun? ',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      GestureDetector(
                        onTap: () {
                          // push (bukan pushReplacement) agar route SessionGate
                          // tetap hidup di bawah; kembali via popUntil(isFirst)
                          // saat AuthBloc -> authenticated.
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Daftar di sini',
                          style: TextStyle(
                            color: Color(0xFF1B8039),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Link daftar mitra UMKM (form + dokumen terpisah).
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Punya usaha? ',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MitraRegisterScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Daftar sebagai Mitra',
                          style: TextStyle(
                            color: Color(0xFF1B8039),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String hint,
    required IconData icon,
    TextEditingController? controller,
    String? helper,
    String? errorText,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onTogglePassword,
    TextInputType? keyboardType,
    void Function(String)? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: errorText != null
                  ? const Color(0xFFC62828)
                  : Colors.grey.shade300,
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            textInputAction: isPassword
                ? TextInputAction.done
                : TextInputAction.next,
            onSubmitted: onSubmitted,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400),
              prefixIcon: Icon(icon, color: Colors.grey.shade600, size: 20),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        obscureText
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.grey.shade600,
                        size: 20,
                      ),
                      onPressed: onTogglePassword,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        if (helper != null && errorText == null)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 6),
            child: Text(
              helper,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 6),
            child: Text(
              errorText,
              style: const TextStyle(fontSize: 12, color: Color(0xFFC62828)),
            ),
          ),
      ],
    );
  }
}
