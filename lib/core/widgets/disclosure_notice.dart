import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../theme/text_styles.dart';

class DisclosureNotice extends StatelessWidget {
  final String text;

  const DisclosureNotice({
    super.key,
    this.text =
        "FPL Lens is an independent analytics tool. It is not affiliated with, endorsed by, or sponsored by the Football Association Premier League Limited or Fantasy Premier League.",
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTokens.bgElevated,
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        border: Border.all(color: AppTokens.borderSubtle, width: 1.0),
      ),
      padding: const EdgeInsets.all(AppTokens.space16),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(
          color: AppTokens.textSecondary,
          height: 1.4,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
