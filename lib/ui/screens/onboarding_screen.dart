import 'package:flutter/material.dart';

import '../../core/storage/onboarding_storage.dart';
import '../widgets/onboarding/onboarding_dots.dart';
import '../widgets/onboarding/onboarding_page.dart';
import '../widgets/onboarding/onboarding_progress_button.dart';
import 'login_screen.dart';

/// Onboarding 3 halaman, tampil sekali sebelum [LoginScreen].
///
/// Navigasi: swipe [PageView] atau tombol progres melingkar.
/// Halaman terakhir (centang) menyimpan flag lalu ke Login.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, OnboardingStorage? storage})
    : _storage = storage;

  final OnboardingStorage? _storage;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _pageController;
  int _currentPage = 0;

  static const List<OnboardingPage> _pages = [
    OnboardingPage(
      imagePath: 'assets/images/onboarding_1.png',
      titleLeading: 'Mulai Aksi ',
      titleHighlight: 'HIJAU',
      titleTrailing: 'mu',
      description:
          'Selesaikan misi harian seperti memilah sampah, berjalan kaki, atau menjawab kuis edukasi untuk bumi yang lebih sehat.',
    ),
    OnboardingPage(
      imagePath: 'assets/images/onboarding_2.png',
      titleLeading: 'Kumpulkan Poin & Naik ',
      titleHighlight: 'LEVEL',
      titleTrailing: '',
      description:
          'Dapatkan Eco Points dan XP dari setiap aksimu. Jaga streak harian dan jadilah juara di papan peringkat RT/RW!',
    ),
    OnboardingPage(
      imagePath: 'assets/images/onboarding_3.png',
      titleLeading: 'Dukung ',
      titleHighlight: 'UMKM',
      titleTrailing: ' & Lingkungan',
      description:
          'Tukarkan Eco Points dengan voucher diskon di UMKM lokal, atau salurkan poinmu untuk donasi kampanye lingkungan.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final storage = widget._storage ?? OnboardingStorage();
    await storage.setOnboardingSeen();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) => _pages[index],
              ),
            ),
            OnboardingDots(currentPage: _currentPage),
            const SizedBox(height: 24),
            OnboardingProgressButton(
              currentPage: _currentPage,
              pageCount: _pages.length,
              onPressed: _next,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
