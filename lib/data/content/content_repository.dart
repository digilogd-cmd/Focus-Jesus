import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'curriculum.dart';
import 'program.dart';

/// Loads bundled, versioned JSON content. Works fully offline.
class ContentRepository {
  ContentRepository(this._bundle, {this.root = 'assets/content'});

  final AssetBundle _bundle;
  final String root;

  /// Reads program.json and every bundled season outline. Seasons whose
  /// outline is not bundled yet are kept, with all days in preparation.
  Future<Program> loadProgram() async {
    final json = jsonDecode(
      await _bundle.loadString('$root/program.json'),
    ) as Map<String, Object?>;
    final outlines = <String, Curriculum?>{};
    for (final s in (json['seasons'] as List).cast<Map>()) {
      final path = s['path'] as String;
      outlines[path] = await _curriculum(path);
    }
    return Program.fromJson(json, curriculumFor: (path) => outlines[path]);
  }

  Future<Curriculum?> _curriculum(String seasonPath) async {
    final String raw;
    try {
      raw = await _bundle.loadString('$root/$seasonPath/curriculum.json');
    } on FlutterError {
      return null; // Not bundled yet.
    }
    return Curriculum.fromJson(jsonDecode(raw) as Map<String, Object?>);
  }

  ChapterStore chapterStore(Program program) =>
      ChapterStore(program, (path) => _bundle.loadString(path));
}
