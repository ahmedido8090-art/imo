import 'package:flutter_test/flutter_test.dart';
import 'package:imo/data/gem_extras.dart';
import 'package:imo/data/gem_regions.dart';
import 'package:imo/data/gem_regions_rooms.dart';

void main() {
  test('main_building regions include extracted room footprints', () {
    final regions = regionsFor('main_building');
    final roomIds = {for (final r in kRoomRegions) r.id};
    final mapIds = {for (final r in regions) r.id};
    for (final id in roomIds) {
      expect(mapIds.contains(id), isTrue, reason: '$id is missing from regionsFor(main_building)');
    }
  });

  test('room footprints stay normalized and pinned to valid places', () {
    for (final r in kRoomRegions) {
      expect(r.mapId, 'main_building');
      expect(r.placeId, isNotNull, reason: '${r.id} must stay tied to a place pin');
      final p = placeById(r.placeId!);
      expect(p, isNotNull, reason: '${r.id} place ${r.placeId} not found');
      expect(mapIdOfPlace(r.placeId!), r.mapId);
      expect(r.contains(p!.position), isTrue, reason: '${r.id} no longer contains ${r.placeId}');
      for (final pt in r.points) {
        expect(pt.dx, inInclusiveRange(0.0, 1.0), reason: '${r.id} x out of bounds');
        expect(pt.dy, inInclusiveRange(0.0, 1.0), reason: '${r.id} y out of bounds');
      }
      expect(r.area, greaterThan(0));
    }
  });
}
