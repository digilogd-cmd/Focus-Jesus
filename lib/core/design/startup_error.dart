import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'tokens.dart';
import 'widgets.dart';

/// Shown only if bundled content or storage cannot be opened at launch.
class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      home: Builder(
        builder: (context) {
          final t = FjText.of(context);
          return Scaffold(
            body: SafeArea(
              child: ReadingColumn(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Wordmark(size: 18),
                    const SizedBox(height: FjSpace.xl),
                    Text('앱을 여는 중 문제가 생겼습니다', style: t.heading),
                    const SizedBox(height: FjSpace.m),
                    Text(
                      '앱에 포함된 이야기나 저장 공간을 불러오지 못했습니다. 앱을 완전히 종료한 뒤 다시 열어 주세요. '
                      '같은 문제가 계속되면 앱을 최신 버전으로 업데이트해 주세요.',
                      style: t.body.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: FjSpace.l),
                    Text(
                      '$error',
                      style: t.meta,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
