import 'package:flutter/material.dart';
import 'package:second_brain/core/theme/app_colors.dart';
import 'package:second_brain/core/theme/app_shadows.dart';
import 'package:second_brain/core/theme/app_spacing.dart';
import 'package:second_brain/core/theme/app_text_styles.dart';

/// Single, reusable application-level bottom navigation component.
class AppBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1.0),
        ),
        boxShadow: AppShadows.navigation,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _NavItem(
                index: 0,
                selectedIndex: currentIndex,
                label: 'Home',
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                onTap: onTap,
              ),
              _NavItem(
                index: 1,
                selectedIndex: currentIndex,
                label: 'Expenses',
                icon: Icons.account_balance_wallet_outlined,
                activeIcon: Icons.account_balance_wallet,
                onTap: onTap,
              ),
              _NavItem(
                index: 2,
                selectedIndex: currentIndex,
                label: 'Investments',
                icon: Icons.trending_up,
                activeIcon: Icons.trending_up,
                onTap: onTap,
              ),
              _NavItem(
                index: 3,
                selectedIndex: currentIndex,
                label: 'Documents',
                icon: Icons.folder_outlined,
                activeIcon: Icons.folder,
                onTap: onTap,
              ),
              _NavItem(
                index: 4,
                selectedIndex: currentIndex,
                label: 'Settings',
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                onTap: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final int selectedIndex;
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.index,
    required this.selectedIndex,
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == selectedIndex;
    final color = isSelected ? AppColors.darkBlue : AppColors.secondaryText;

    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        splashColor: Colors.transparent,
        highlightColor: AppColors.veryLightBlue.withValues(alpha: 0.5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 24,
              color: color,
            ),
            const SizedBox(height: AppSpacing.space4),
            Text(
              label,
              style: AppTextStyles.navigation.copyWith(
                color: color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
