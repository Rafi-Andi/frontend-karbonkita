import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/register_region/register_region_cubit.dart';
import '../../core/utils/address_normalize.dart';
import '../../data/datasources/region_remote_datasource.dart';
import '../../data/repositories/region_repository.dart';
import '../widgets/region_cascading_dropdowns.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;
  late final TextEditingController _rtController;
  late final TextEditingController _rwController;
  late final RegisterRegionCubit _regionCubit;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTnc = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _rtController = TextEditingController();
    _rwController = TextEditingController();
    _regionCubit = RegisterRegionCubit(
      RegionRepository(RegionRemoteDatasource()),
    )..loadProvinces();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _rtController.dispose();
    _rwController.dispose();
    _regionCubit.close();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _submit() {
    FocusScope.of(context).unfocus();

    final name = _nameController.text.trim();
    final phone = normalizePhone('+62${_phoneController.text}');
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;
    final region = _regionCubit.state;

    if (name.isEmpty) return _showError('Nama wajib diisi.');
    if (!isValidPhone(phone)) {
      return _showError('No HP tidak valid. Contoh: 8123456789.');
    }
    if (!isValidEmail(email)) return _showError('Email tidak valid.');
    if (password.length < 8) {
      return _showError('Kata sandi minimal 8 karakter.');
    }
    if (password != confirm) {
      return _showError('Konfirmasi kata sandi tidak sama.');
    }
    if (!region.isComplete) {
      return _showError('Pilih provinsi, kota, kecamatan, dan kelurahan.');
    }
    if (!isValidRt(_rtController.text)) {
      return _showError('RT tidak valid (1-3 digit angka).');
    }
    if (!isValidRw(_rwController.text)) {
      return _showError('RW tidak valid (1-2 digit angka).');
    }
    if (!_agreedToTnc) {
      return _showError('Centang persetujuan Syarat & Ketentuan dulu.');
    }

    context.read<AuthBloc>().add(
      RegisterSubmitted(
        name: name,
        phone: phone,
        email: email,
        password: password,
        passwordConfirmation: confirm,
        city: canonicalName(region.regency!.name),
        district: canonicalName(region.district!.name),
        subDistrict: canonicalName(region.village!.name),
        rt: normalizeRt(_rtController.text),
        rw: normalizeRw(_rwController.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (prev, curr) =>
          curr.status == AuthStatus.authenticated ||
          (curr.message != null && curr.message != prev.message),
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          // SessionGate di main akan menampilkan Home; tutup tumpukan
          // register agar user langsung masuk.
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else if (state.message != null) {
          _showError(state.message!);
        }
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
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black87),
                      onPressed: () => Navigator.of(context).maybePop(),
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
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Daftar Akun Baru',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B8039),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Isi data di bawah ini untuk membuat akunmu',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 32),

                      // Name Field
                      _buildTextField(
                        hint: 'John Doe',
                        icon: Icons.person_outline,
                        controller: _nameController,
                        keyboardType: TextInputType.name,
                      ),
                      const SizedBox(height: 16),

                      // Phone Field
                      _buildPhoneField(),
                      const SizedBox(height: 16),

                      // Email Field
                      _buildTextField(
                        hint: 'user@email.com',
                        icon: Icons.email_outlined,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),

                      // Password Field
                      _buildTextField(
                        hint: '********',
                        icon: Icons.lock_outline,
                        controller: _passwordController,
                        isPassword: true,
                        obscureText: _obscurePassword,
                        onTogglePassword: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Confirm Password Field
                      _buildTextField(
                        hint: 'Konfirmasi Kata Sandi',
                        icon: Icons.lock_outline,
                        controller: _confirmPasswordController,
                        isPassword: true,
                        obscureText: _obscureConfirmPassword,
                        onTogglePassword: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      const SizedBox(height: 24),

                      // Location Section
                      RegionCascadingDropdowns(
                        cubit: _regionCubit,
                        helperText:
                            'Pilih dari daftar agar datamu konsisten (default: Surabaya)',
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildRtRwField(
                              hint: 'RT (cth: 005)',
                              controller: _rtController,
                              maxLength: 3,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildRtRwField(
                              hint: 'RW (cth: 02)',
                              controller: _rwController,
                              maxLength: 2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Checkbox
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _agreedToTnc,
                              activeColor: const Color(0xFF1B8039),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              onChanged: (val) {
                                setState(() {
                                  _agreedToTnc = val ?? false;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: RichText(
                              text: const TextSpan(
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 12,
                                  height: 1.5,
                                ),
                                children: [
                                  TextSpan(text: 'Saya menyetujui '),
                                  TextSpan(
                                    text: 'Syarat & Ketentuan\n',
                                    style: TextStyle(color: Color(0xFF1B8039)),
                                  ),
                                  TextSpan(text: 'serta '),
                                  TextSpan(
                                    text: 'Kebijakan Privasi ',
                                    style: TextStyle(color: Color(0xFF1B8039)),
                                  ),
                                  TextSpan(text: 'KarbonKita'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Submit Button
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, auth) {
                          final loading = auth.status == AuthStatus.loading;
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
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Buat Akun',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Navigation to Login
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Sudah punya akun? ',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      GestureDetector(
                        onTap: () {
                          // Kembali ke Login di bawah tanpa membunuh
                          // SessionGate. Register dibuka via push dari Login,
                          // jadi cukup pop. Fallback pushReplacement hanya
                          // untuk edge case Register jadi route pertama.
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          } else {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                            );
                          }
                        },
                        child: const Text(
                          'Masuk di sini',
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
                const SizedBox(height: 24), // Bottom padding
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
    required TextEditingController controller,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onTogglePassword,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
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
    );
  }

  Widget _buildPhoneField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Icon(
              Icons.phone_outlined,
              color: Colors.grey.shade600,
              size: 20,
            ),
          ),
          Expanded(
            child: TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                LengthLimitingTextInputFormatter(14),
              ],
              decoration: InputDecoration(
                hintText: '812-3456-789',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          Container(height: 24, width: 1, color: Colors.grey.shade300),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                // Flag placeholder (red rectangle for IND flag)
                Container(
                  width: 16,
                  height: 10,
                  color: Colors.red,
                  alignment: Alignment.bottomCenter,
                  child: Container(height: 5, color: Colors.white),
                ),
                const SizedBox(width: 8),
                const Text(
                  '+62',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.grey.shade600,
                  size: 16,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRtRwField({
    required String hint,
    required TextEditingController controller,
    required int maxLength,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(maxLength),
        ],
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
          prefixIcon: Icon(Icons.people_outline, color: Colors.green, size: 16),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 4,
          ),
        ),
      ),
    );
  }
}
