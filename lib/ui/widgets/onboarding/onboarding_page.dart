import 'package:flutter/material.dart';

/// Satu halaman onboarding: ilustrasi + judul + deskripsi.
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({
    super.key,
    required this.imagePath,
    required this.titleLeading,
    required this.titleHighlight,
    required this.titleTrailing,
    required this.description,
  });

  final String imagePath;
  final String titleLeading;
  final String titleHighlight;
  final String titleTrailing;
  final String description;

  static const Color primaryColor = Color(0xFF32A231);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _IllustrationCard(imagePath: imagePath),
          const SizedBox(height: 32),
          _Title(
            leading: titleLeading,
            highlight: titleHighlight,
            trailing: titleTrailing,
          ),
          const SizedBox(height: 12),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.black.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _IllustrationCard extends StatelessWidget {
  const _IllustrationCard({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      imagePath,
      height: 320,
      width: double.infinity,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return const SizedBox(
          height: 320,
          child: Center(
            child: Icon(Icons.eco, size: 96, color: Color(0xFF32A231)),
          ),
        );
      },
    );
  }
}

class _Title extends StatelessWidget {
  const _Title({
    required this.leading,
    required this.highlight,
    required this.trailing,
  });

  final String leading;
  final String highlight;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
          height: 1.3,
        ),
        children: [
          TextSpan(text: leading),
          TextSpan(
            text: highlight,
            style: const TextStyle(color: OnboardingPage.primaryColor),
          ),
          TextSpan(text: trailing),
        ],
      ),
    );
  }
}
