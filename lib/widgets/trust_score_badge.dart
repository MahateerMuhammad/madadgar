import 'package:flutter/material.dart';

class TrustScoreBadge extends StatelessWidget {
  final int score;
  final double size;
  final bool showLabel;

  const TrustScoreBadge({
    super.key,
    required this.score,
    this.size = 24.0,
    this.showLabel = false,
  });

  Color _getBadgeColor() {
    if (score >= 71) return const Color(0xFFFFD700); // Gold
    if (score >= 31) return const Color(0xFFC0C0C0); // Silver
    return const Color(0xFFCD7F32); // Bronze
  }

  String _getTierName() {
    if (score >= 71) return 'Gold Tier';
    if (score >= 31) return 'Silver Tier';
    return 'Bronze Tier';
  }

  IconData _getIcon() {
    if (score >= 71) return Icons.stars;
    if (score >= 31) return Icons.verified;
    return Icons.shield;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getBadgeColor();
    
    return Tooltip(
      message: 'Trust Score: $score/100\n${_getTierName()}',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getIcon(),
            color: color,
            size: size,
          ),
          if (showLabel) ...[
            const SizedBox(width: 4),
            Text(
              _getTierName(),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: size * 0.6,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
