// File: lib/features/rostau/presentation/widgets/journey_details_sheet.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/themes.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../data/models/journey_path_model.dart';

class JourneyDetailsSheet extends StatelessWidget {
  const JourneyDetailsSheet({
    super.key,
    required this.journeyPath,
    required this.onClosePressed,
    required this.onViewFullRoutePressed,
  });

  final JourneyPathModel journeyPath;
  final VoidCallback onClosePressed;
  final ValueChanged<JourneyPathModel> onViewFullRoutePressed;

  static Future<void> show({
    required BuildContext context,
    required JourneyPathModel journeyPath,
    required ValueChanged<JourneyPathModel> onViewFullRoutePressed,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.scrimOverlay,
      builder: (sheetContext) {
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: AppDimensions.blurSigma,
            sigmaY: AppDimensions.blurSigma,
          ),
          child: JourneyDetailsSheet(
            journeyPath: journeyPath,
            onClosePressed: () => Navigator.of(sheetContext).pop(),
            onViewFullRoutePressed: (selectedPath) {
              Navigator.of(sheetContext).pop();
              onViewFullRoutePressed(selectedPath);
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXl),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.spacingLg,
            AppDimensions.spacingSm + AppDimensions.spacingXs,
            AppDimensions.spacingLg,
            AppDimensions.spacingMd,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: _SheetDragHandle()),
              const SizedBox(height: AppDimensions.spacingMd),
              _SheetHeaderSection(
                title: journeyPath.title,
                onClosePressed: onClosePressed,
              ),
              const SizedBox(height: AppDimensions.spacingMd),
              _JourneyMetricsRow(
                estimatedDurationMinutes: journeyPath.estimatedDurationMinutes,
                distanceInKilometers: journeyPath.distanceInKilometers,
                stopsCount: journeyPath.stopsCount,
              ),
              const SizedBox(height: AppDimensions.spacingLg),
              const Text(
                AppStrings.placesAlongThePathLabel,
                style: AppTextStyles.overlineMuted,
              ),
              const SizedBox(height: AppDimensions.spacingMd),
              _JourneyTimelineList(
                routeSteps: journeyPath.routeSteps,
              ),
              const SizedBox(height: AppDimensions.spacingLg),
              PrimaryButton(
                label: AppStrings.viewFullRouteButton,
                leadingIcon: Icons.map_outlined,
                onPressed: () => onViewFullRoutePressed(journeyPath),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetDragHandle extends StatelessWidget {
  const _SheetDragHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppDimensions.sheetHandleWidth,
      height: AppDimensions.sheetHandleHeight,
      decoration: BoxDecoration(
        color: AppColors.sheetHandle,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
    );
  }
}

class _SheetHeaderSection extends StatelessWidget {
  const _SheetHeaderSection({
    required this.title,
    required this.onClosePressed,
  });

  final String title;
  final VoidCallback onClosePressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                AppStrings.yourJourneyOverline,
                style: AppTextStyles.overlineGold,
              ),
              const SizedBox(height: AppDimensions.spacingXs),
              Text(
                title,
                style: AppTextStyles.sheetTitle,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppDimensions.spacingMd),
        GestureDetector(
          onTap: onClosePressed,
          child: Container(
            width: AppDimensions.closeButtonSize,
            height: AppDimensions.closeButtonSize,
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
              Icons.close,
              size: AppDimensions.iconSizeSm + 2.0,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _JourneyMetricsRow extends StatelessWidget {
  const _JourneyMetricsRow({
    required this.estimatedDurationMinutes,
    required this.distanceInKilometers,
    required this.stopsCount,
  });

  final int estimatedDurationMinutes;
  final double distanceInKilometers;
  final int stopsCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _JourneyMetricPill(
            icon: Icons.access_time,
            valueText: '$estimatedDurationMinutes ${AppStrings.minutesUnit}',
            sublabelText: AppStrings.estimatedSublabel,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingSm),
        Expanded(
          child: _JourneyMetricPill(
            icon: Icons.directions_walk,
            valueText: '$distanceInKilometers ${AppStrings.kilometersUnit}',
            sublabelText: AppStrings.walkingSublabel,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingSm),
        Expanded(
          child: _JourneyMetricPill(
            icon: Icons.location_on_outlined,
            valueText: '$stopsCount',
            sublabelText: AppStrings.stopsUnit,
          ),
        ),
      ],
    );
  }
}

class _JourneyMetricPill extends StatelessWidget {
  const _JourneyMetricPill({
    required this.icon,
    required this.valueText,
    required this.sublabelText,
  });

  final IconData icon;
  final String valueText;
  final String sublabelText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingSm + AppDimensions.spacingXs,
        vertical: AppDimensions.spacingSm + 2.0,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: AppDimensions.iconSizeMd,
            color: AppColors.secondary,
          ),
          const SizedBox(width: AppDimensions.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  valueText,
                  style: AppTextStyles.metricValue,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  sublabelText,
                  style: AppTextStyles.metricSublabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneyTimelineList extends StatelessWidget {
  const _JourneyTimelineList({
    required this.routeSteps,
  });

  final List<String> routeSteps;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(routeSteps.length, (index) {
        final bool isLastStep = index == routeSteps.length - 1;
        return _TimelineStepTile(
          stepNumber: index + 1,
          stepTitle: routeSteps[index],
          isLastStep: isLastStep,
        );
      }),
    );
  }
}

class _TimelineStepTile extends StatelessWidget {
  const _TimelineStepTile({
    required this.stepNumber,
    required this.stepTitle,
    required this.isLastStep,
  });

  final int stepNumber;
  final String stepTitle;
  final bool isLastStep;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: AppDimensions.stepBadgeSize,
              height: AppDimensions.stepBadgeSize,
              decoration: const BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '$stepNumber',
                style: AppTextStyles.stepBadgeNumber,
              ),
            ),
            if (!isLastStep)
              Container(
                width: AppDimensions.stepConnectorWidth,
                height: AppDimensions.stepConnectorHeight,
                color: AppColors.timelineConnector,
              ),
          ],
        ),
        const SizedBox(width: AppDimensions.spacingMd),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 3.0),
            child: Text(
              stepTitle,
              style: AppTextStyles.stepTitle,
            ),
          ),
        ),
      ],
    );
  }
}