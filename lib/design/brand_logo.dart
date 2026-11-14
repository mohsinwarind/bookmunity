import 'package:flutter/material.dart';

/// The reading-bunny mark (transparent PNG, blends with any background).
class BrandLogo extends StatelessWidget {
  const BrandLogo({this.height = 120, super.key});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/branding/logo.png',
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      semanticLabel: 'Bookmunity',
    );
  }
}

/// Full-screen loading state with the logo, matching the native splash.
class BrandLoading extends StatelessWidget {
  const BrandLoading({this.message, super.key});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BrandLogo(height: 140),
            const SizedBox(height: 24),
            const SizedBox.square(
              dimension: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            if (message != null) ...[
              const SizedBox(height: 12),
              Text(message!, style: theme.textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}
