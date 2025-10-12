import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/subject.dart';

class SubjectProgressCard extends StatelessWidget {
  const SubjectProgressCard({
    super.key,
    required this.subject,
    required this.percentage,
    required this.held,
    required this.attended,
    required this.missed,
  });

  final Subject subject;
  final double percentage;
  final int held;
  final int attended;
  final int missed;

  Color _statusColor(double percentage) {
    if (percentage >= 85) {
      return AppColors.safeGreen;
    }
    if (percentage >= 75) {
      return AppColors.warningYellow;
    }
    return AppColors.dangerRed;
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse('0xff${subject.color.replaceAll('#', '')}'));

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    subject.code.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subject.professor,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: _statusColor(percentage).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: held == 0
                    ? Text('No record', style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w600))
                    : Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: _statusColor(percentage),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: held == 0 ? 0.0 : (percentage / 100).clamp(0.0, 1.0),
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(held == 0 ? Colors.grey : _statusColor(percentage)),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statChip('Held', held, color),
              _statChip('Attended', attended, AppColors.safeGreen),
              _statChip('Missed', missed, AppColors.dangerRed),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip(String label, int value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$value',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
