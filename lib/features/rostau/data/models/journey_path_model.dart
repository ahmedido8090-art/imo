// File: lib/features/rostau/data/models/journey_path_model.dart
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';

class JourneyPathModel {
  const JourneyPathModel({
    required this.id,
    required this.displayIndex,
    required this.title,
    required this.description,
    required this.estimatedDurationMinutes,
    required this.distanceInKilometers,
    required this.stopsCount,
    required this.imageUrl,
    required this.routeSteps,
  });

  final String id;
  final String displayIndex;
  final String title;
  final String description;
  final int estimatedDurationMinutes;
  final double distanceInKilometers;
  final int stopsCount;
  final String imageUrl;
  final List<String> routeSteps;

  static const List<JourneyPathModel> defaultJourneys = [
    JourneyPathModel(
      id: 'pharaohs_legacy',
      displayIndex: AppStrings.journeyOneNumber,
      title: AppStrings.journeyOneTitle,
      description: AppStrings.journeyOneDescription,
      estimatedDurationMinutes: 75,
      distanceInKilometers: 1.8,
      stopsCount: 6,
      imageUrl: AppAssets.pharaohsLegacyNetworkUrl,
      routeSteps: [
        AppStrings.stopGrandStaircase,
        AppStrings.stopRamsesII,
        AppStrings.stopRoyalRegalia,
        AppStrings.stopTutankhamunGallery,
      ],
    ),
    JourneyPathModel(
      id: 'gods_of_the_nile',
      displayIndex: AppStrings.journeyTwoNumber,
      title: AppStrings.journeyTwoTitle,
      description: AppStrings.journeyTwoDescription,
      estimatedDurationMinutes: 50,
      distanceInKilometers: 1.2,
      stopsCount: 5,
      imageUrl: AppAssets.godsOfTheNileNetworkUrl,
      routeSteps: [
        AppStrings.stopGrandStaircase,
        AppStrings.stopHallsOfOsiris,
        AppStrings.stopSekhmetSanctuary,
        AppStrings.stopAnubisShrine,
      ],
    ),
    JourneyPathModel(
      id: 'treasures_in_an_hour',
      displayIndex: AppStrings.journeyThreeNumber,
      title: AppStrings.journeyThreeTitle,
      description: AppStrings.journeyThreeDescription,
      estimatedDurationMinutes: 60,
      distanceInKilometers: 1.5,
      stopsCount: 7,
      imageUrl: AppAssets.treasuresInAnHourNetworkUrl,
      routeSteps: [
        AppStrings.stopRamsesII,
        AppStrings.stopGoldenMask,
        AppStrings.stopKhufuSolarBoat,
        AppStrings.stopTutankhamunGallery,
      ],
    ),
  ];
}