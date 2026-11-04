// File: lib/features/rostau/presentation/screens/rostau_paths_screen.dart
import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/themes.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../data/models/journey_path_model.dart';
import '../widgets/journey_details_sheet.dart';
import '../widgets/journey_path_card.dart';

class RostauPathsScreen extends StatefulWidget {
  const RostauPathsScreen({super.key});

  @override
  State<RostauPathsScreen> createState() => _RostauPathsScreenState();
}

class _RostauPathsScreenState extends State<RostauPathsScreen> {
  int _selectedNavIndex = 1;
  final List<JourneyPathModel> _journeyPaths = JourneyPathModel.defaultJourneys;

  void _onTabSelected(int index) {
    setState(() {
      _selectedNavIndex = index;
    });
  }

  void _onSearchPressed() {
    // Handle search modal / route navigation
  }

  void _onJourneySelected(JourneyPathModel selectedJourney) {
    JourneyDetailsSheet.show(
      context: context,
      journeyPath: selectedJourney,
      onViewFullRoutePressed: _onViewFullRoutePressed,
    );
  }

  void _onViewFullRoutePressed(JourneyPathModel selectedJourney) {
    // Navigate to full route map screen for selectedJourney
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _RostauTopAppBar(
              onSearchPressed: _onSearchPressed,
            ),
            const Divider(
              color: AppColors.borderSubtle,
              height: AppDimensions.borderThin,
              thickness: AppDimensions.borderThin,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingLg,
                  vertical: AppDimensions.spacingLg,
                ),
                children: [
                  const _RostauHeroSection(),
                  const SizedBox(height: AppDimensions.spacingLg),
                  const Divider(
                    color: AppColors.borderSubtle,
                    height: AppDimensions.borderThin,
                    thickness: AppDimensions.borderThin,
                  ),
                  const SizedBox(height: AppDimensions.spacingMd),
                  _JourneyListHeader(
                    totalJourneysCount: _journeyPaths.length,
                  ),
                  const SizedBox(height: AppDimensions.spacingMd),
                  ..._journeyPaths.map(
                    (journeyPath) => Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppDimensions.spacingMd,
                      ),
                      child: JourneyPathCard(
                        journeyPath: journeyPath,
                        onJourneySelected: _onJourneySelected,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _selectedNavIndex,
        onTabSelected: _onTabSelected,
      ),
    );
  }
}

class _RostauTopAppBar extends StatelessWidget {
  const _RostauTopAppBar({
    required this.onSearchPressed,
  });

  final VoidCallback onSearchPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingLg,
        vertical: AppDimensions.spacingMd,
      ),
      child: Row(
        children: [
          Container(
            width: AppDimensions.headerIconSize,
            height: AppDimensions.headerIconSize,
              decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.visibility_outlined,
              color: AppColors.secondary,
              size: AppDimensions.iconSizeMd,
            ),
          ),
          const SizedBox(width: AppDimensions.spacingMd),
          const Expanded(
            child: Text(
              AppStrings.rostauPathsTitle,
              style: AppTextStyles.headingMedium,
            ),
          ),
          GestureDetector(
            onTap: onSearchPressed,
            child: Container(
              width: AppDimensions.headerIconSize,
              height: AppDimensions.headerIconSize,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.borderSubtle,
                  width: AppDimensions.borderThin,
                ),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.search,
                color: AppColors.textPrimary,
                size: AppDimensions.iconSizeMd,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RostauHeroSection extends StatelessWidget {
  const _RostauHeroSection();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.unplannedJourneysOverline,
          style: AppTextStyles.overlineGold,
        ),
        SizedBox(height: AppDimensions.spacingSm),
        Text(
          AppStrings.rostauHeroHeadline,
          style: AppTextStyles.headingLarge,
        ),
        SizedBox(height: AppDimensions.spacingSm),
        Text(
          AppStrings.rostauHeroSubtitle,
          style: AppTextStyles.bodyLarge,
        ),
      ],
    );
  }
}

class _JourneyListHeader extends StatelessWidget {
  const _JourneyListHeader({
    required this.totalJourneysCount,
  });

  final int totalJourneysCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          AppStrings.chooseYourPathLabel,
          style: AppTextStyles.overlineMuted,
        ),
        Text(
          '$totalJourneysCount ${AppStrings.journeysCountSuffix}',
          style: AppTextStyles.overlineMuted,
        ),
      ],
    );
  }
}