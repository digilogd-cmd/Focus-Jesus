import 'dart:convert';

import 'package:flutter/services.dart';

import 'chapter.dart';
import 'curriculum.dart';

/// A season as the app uses it: the outline plus every readable chapter.
class Season {
  Season({required this.curriculum, required List<Chapter> chapters})
    : chapters = List.unmodifiable(
        [...chapters]..sort((a, b) => a.order.compareTo(b.order)),
      );

  final Curriculum curriculum;

  /// Readable chapters only, in reading order.
  final List<Chapter> chapters;

  late final Map<String, Chapter> _byId = {for (final c in chapters) c.id: c};

  Chapter? chapterById(String id) => _byId[id];

  List<String> get orderedIds => [for (final c in chapters) c.id];

  /// Number of outline days whose manuscripts are still in preparation.
  int get plannedDayCount =>
      curriculum.days.where((d) => !d.isAvailable).length;
}

/// Loads bundled, versioned JSON content. Works fully offline.
class ContentRepository {
  ContentRepository(this._bundle, {this.seasonPath = 'assets/content/season1'});

  final AssetBundle _bundle;
  final String seasonPath;

  Future<Season> loadSeason() async {
    final curriculumJson = await _bundle.loadString(
      '$seasonPath/curriculum.json',
    );
    final curriculum = Curriculum.fromJson(
      jsonDecode(curriculumJson) as Map<String, Object?>,
    );
    final chapters = <Chapter>[];
    for (final day in curriculum.availableDays) {
      final path = '$seasonPath/${day.file}';
      final raw = await _bundle.loadString(path);
      chapters.add(
        Chapter.fromJson(jsonDecode(raw) as Map<String, Object?>, path: path),
      );
    }
    return Season(curriculum: curriculum, chapters: chapters);
  }
}
