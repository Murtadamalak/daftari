import 'package:flutter/material.dart';

class AppBarLogo extends StatelessWidget {
  const AppBarLogo({super.key, this.forceWhite = false});
  final bool forceWhite;

  @override
  Widget build(BuildContext context) {
    final isDark = forceWhite || Theme.of(context).brightness == Brightness.dark;
    final logoAsset = isDark ? 'assets/images/night.png' : 'assets/images/light.png';
    return Image.asset(
      logoAsset,
      height: 44,
      fit: BoxFit.contain,
    );
  }
}
