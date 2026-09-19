import 'package:flutter/material.dart';
import '../../../models/arabic_letter.dart';

extension MahrecColor on Mahrec {
  Color get color => switch (this) {
    Mahrec.bogaz => const Color(0xFFB83C45),
    Mahrec.dil => const Color(0xFF1674B5),
    Mahrec.dudak => const Color(0xFF21834D),
  };
}

class MahrecBanner extends StatelessWidget {
  const MahrecBanner({super.key, required this.mahrec});
  final Mahrec mahrec;

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.ltr,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          mahrec.color.withValues(alpha: 0.09),
          Colors.white,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: mahrec.color, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            mahrec.label,
            style: TextStyle(
              color: mahrec.color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            mahrec.description,
            style: const TextStyle(
              color: Color(0xFF23324A),
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    ),
  );
}
