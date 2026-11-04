// File: lib/core/widgets/app_bottom_nav_bar.dart
import 'package:flutter/material.dart';
import '../constants/app_strings.dart';
import '../themes.dart';

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.borderSubtle,
            width: AppDimensions.borderThin,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppDimensions.spacingSm,
            horizontal: AppDimensions.spacingLg,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BottomNavTabItem(
                label: AppStrings.navMap,
                icon: Icons.map_outlined,
                isSelected: currentIndex == 0,
                onTap: () => onTabSelected(0),
              ),
              _BottomNavTabItem(
                label: AppStrings.navRostau,
                icon: Icons.route_outlined,
                isSelected: currentIndex == 1,
                onTap: () => onTabSelected(1),
              ),
              _BottomNavTabItem(
                label: AppStrings.navParty,
                icon: Icons.group_outlined,
                isSelected: currentIndex == 2,
                onTap: () => onTabSelected(2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavTabItem extends StatelessWidget {
  const _BottomNavTabItem({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: AppDimensions.navPillWidth,
            height: AppDimensions.navPillHeight,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.surfaceSubtle : Colors.transparent,
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: AppDimensions.iconSizeMd,
              color: isSelected
                  ? AppColors.secondary
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingXs),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: isSelected
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}