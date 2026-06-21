import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kids_tracing_app/constants/app_constants.dart';

/// Shows how much of the current number the child has traced.
class ProgressIndicatorWidget extends StatelessWidget {
  const ProgressIndicatorWidget({super.key, required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).clamp(0, 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'Progress',
              style: GoogleFonts.baloo2(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppConstants.primaryColor,
              ),
            ),
            const Spacer(),
            Text(
              '$percent%',
              style: GoogleFonts.baloo2(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppConstants.secondaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 14,
            backgroundColor: AppConstants.guideDotColor.withValues(alpha: 0.25),
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppConstants.successColor,
            ),
          ),
        ),
      ],
    );
  }
}
