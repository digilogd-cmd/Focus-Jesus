// Opens every Bible reference in the season content on 대한성서공회
// 성경플랫폼 and checks that the page shows the intended passage.
//
// The platform silently falls back to 창세기 1 for codes or chapters it does
// not know, so a 200 response alone proves nothing: the page title is
// compared with the passage the link asks for.
//
// Usage: dart run tool/check_bible_links.dart [content dir]
// Needs network access. Exits with code 1 when any link opens the wrong page.

import 'dart:convert';
import 'dart:io';

import 'package:focus_jesus/core/bible/bible_reference.dart';

const String seasonDir = 'assets/content/season1';

// The platform blocks requests that do not look like a browser.
const String _userAgent =
    'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 '
    '(KHTML, like Gecko) Chrome/128.0 Mobile Safari/537.36';

// Book names the platform spells differently from the app.
const Map<String, String> _platformNames = {
  '1JN': '요한1서',
  '2JN': '요한2서',
  '3JN': '요한3서',
};

Future<void> main(List<String> args) async {
  final dir = Directory(args.isNotEmpty ? args.first : seasonDir);
  final refs = <String>{};
  for (final file in dir.listSync().whereType<File>()) {
    if (!file.path.endsWith('.json')) continue;
    _collectRefs(jsonDecode(file.readAsStringSync()), refs);
  }
  final sorted = refs.toList()..sort();

  final client = HttpClient()..userAgent = _userAgent;
  var failures = 0;
  for (final source in sorted) {
    final reference = BibleReference.parse(source);
    final uri = reference.externalUri;
    final expected = _expectedTitle(reference, uri);
    String title;
    try {
      final request = await client.getUrl(uri);
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      title = response.statusCode == 200
          ? (RegExp(r'<title>([^<]*)').firstMatch(body)?.group(1) ?? '(none)')
          : 'HTTP ${response.statusCode}';
    } on Object catch (e) {
      title = 'error: $e';
    }
    final ok = title.startsWith('$expected - ');
    if (!ok) failures++;
    stdout.writeln(
      '${ok ? 'ok  ' : 'FAIL'} $source -> $uri'
      '${ok ? '' : '\n     expected "$expected", page "$title"'}',
    );
  }
  client.close();
  stdout.writeln('${sorted.length} references, $failures failed.');
  if (failures > 0) exitCode = 1;
}

void _collectRefs(Object? node, Set<String> out) {
  if (node is Map) {
    for (final MapEntry(:key, :value) in node.entries) {
      if (key == 'ref' && value is String) {
        out.add(value);
      } else {
        _collectRefs(value, out);
      }
    }
  } else if (node is List) {
    for (final item in node) {
      _collectRefs(item, out);
    }
  }
}

/// Title the platform shows for [uri], e.g. `갈라디아서 3:6-16`.
String _expectedTitle(BibleReference reference, Uri uri) {
  final name = _platformNames[reference.book.code] ?? reference.book.koreanName;
  final parts = uri.pathSegments.last.split('-');
  String location(String part) {
    final pieces = part.split('.'); // BOOK.C or BOOK.C.V
    return pieces.length == 2 ? pieces[1] : '${pieces[1]}:${pieces[2]}';
  }

  final start = location(parts.first);
  if (parts.length == 1) return '$name $start';
  return '$name $start-${parts.last.split('.').last}';
}
