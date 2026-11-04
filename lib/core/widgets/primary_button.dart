// File: lib/core/widgets/primary_button.dart
import 'package:flutter/material.dart';
import '../themes.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.leadingIcon,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppDimensions.primaryButtonHeight,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnImage,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leadingIcon != null) ...[
              Icon(
                leadingIcon,
                size: AppDimensions.iconSizeMd,
                color: AppColors.textOnImage,
              ),
              const SizedBox(width: AppDimensions.spacingSm),
            ],
            Text(
              label,
              style: AppTextStyles.buttonLabel,
            ),
          ],
        ),
      ),
    );
  }
}