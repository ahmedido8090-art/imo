import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/themes.dart';
import '../../data/models/journey_path_model.dart';

class JourneyPathCard extends StatelessWidget {
  const JourneyPathCard({
    super.key,
    required this.journeyPath,
    required this.onJourneySelected,
  });

  final JourneyPathModel journeyPath;
  final ValueChanged<JourneyPathModel> onJourneySelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppDimensions.cardHeight,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: AppColors.borderSubtle,
          width: AppDimensions.borderThin,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onJourneySelected(journeyPath),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _JourneyCardThumbnail(
                imageUrl: journeyPath.imageUrl,
                displayIndex: journeyPath.displayIndex,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.spacingMd),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        journeyPath.title,
                        style: AppTextStyles.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppDimensions.spacingXs),
                      Expanded(
                        child: Text(
                          journeyPath.description,
                          style: AppTextStyles.bodyMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _JourneyCardMetadataFooter(
                        estimatedDurationMinutes:
                            journeyPath.estimatedDurationMinutes,
                        stopsCount: journeyPath.stopsCount,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JourneyCardThumbnail extends StatelessWidget {
  const _JourneyCardThumbnail({
    required this.imageUrl,
    required this.displayIndex,
  });

  final String imageUrl;
  final String displayIndex;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppDimensions.cardImageWidth,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: AppColors.primary,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.account_balance_outlined,
                  color: AppColors.secondary,
                  size: AppDimensions.spacingLg,
                ),
              );
            },
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Color(0x99000000),
                ],
                stops: [0.5, 1.0],
              ),
            ),
          ),
          Positioned(
            left: AppDimensions.spacingSm + AppDimensions.spacingXs,
            bottom: AppDimensions.spacingSm + AppDimensions.spacingXs,
            child: Text(
              displayIndex,
              style: AppTextStyles.cardIndexNumber,
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneyCardMetadataFooter extends StatelessWidget {
  const _JourneyCardMetadataFooter({
    required this.estimatedDurationMinutes,
    required this.stopsCount,
  });

  final int estimatedDurationMinutes;
  final int stopsCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.access_time,
          size: AppDimensions.iconSizeSm,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: AppDimensions.spacingXs),
        Text(
          '$estimatedDurationMinutes ${AppStrings.minutesUnit}',
          style: AppTextStyles.caption,
        ),
        const SizedBox(width: AppDimensions.spacingSm + AppDimensions.spacingXs),
        Text(
          '$stopsCount ${AppStrings.stopsUnit}',
          style: AppTextStyles.caption,
        ),
        const Spacer(),
        const Icon(
          Icons.chevron_right,
          size: AppDimensions.iconSizeMd,
          color: AppColors.secondary,
        ),
      ],
    );
  }
}