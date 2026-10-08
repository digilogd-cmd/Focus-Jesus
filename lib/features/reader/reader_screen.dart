import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/bible/bible_reference.dart';
import '../../core/design/tokens.dart';
import '../../core/design/widgets.dart';
import '../../core/time/clock.dart';
import '../../data/content/chapter.dart';
import '../../data/content/chapter_composer.dart';
import '../../data/models/progress.dart';
import '../../data/models/user_settings.dart';
import '../../data/repositories/progress_repository.dart';
import '../reflection/reflection_section.dart';
import 'chapter_body.dart';
import 'reading_settings_sheet.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({super.key, required this.chapterId});

  final String chapterId;

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  static const double _barHeight = 56;
  static const Duration _saveDebounce = Duration(milliseconds: 500);

  final ScrollController _scroll = ScrollController();
  final GlobalKey<ReflectionSectionState> _reflectionKey = GlobalKey();
  final ValueNotifier<double> _progress = ValueNotifier(0);
  late final ProgressRepository _progressRepo;
  late final Clock _clock;
  late final ProviderContainer _container;
  late final AppLifecycleListener _lifecycle;

  ReadingPosition? _savedPosition;
  bool _positionLoaded = false;
  bool _restored = false;
  bool _barVisible = true;
  bool _completing = false;
  bool _savePending = false;
  Timer? _saveTimer;
  String _layoutKey = '';

  /// Fraction to restore after a reading-mode/level change re-lays the text.
  double? _pendingFraction;

  @override
  void initState() {
    super.initState();
    _progressRepo = ref.read(progressRepositoryProvider);
    _clock = ref.read(clockProvider);
    _container = ProviderScope.containerOf(context, listen: false);
    _lifecycle = AppLifecycleListener(
      onInactive: _flushPosition,
      onHide: _flushPosition,
      onPause: _flushPosition,
    );
    _progressRepo.loadPosition(widget.chapterId).then((p) {
      if (!mounted) return;
      setState(() {
        _savedPosition = p;
        _positionLoaded = true;
      });
    });
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _saveTimer?.cancel();
    final save = _savePending ? _writePosition() : Future<void>.value();
    // Let the home screen pick up "이어서 읽기" once the write lands.
    save.whenComplete(
      () => _container.invalidate(readingPositionProvider(widget.chapterId)),
    );
    _scroll.dispose();
    _progress.dispose();
    super.dispose();
  }

  // Position persistence ------------------------------------------------------

  double get _fraction {
    if (!_scroll.hasClients) return 0;
    final max = _scroll.position.maxScrollExtent;
    return max <= 0 ? 0 : (_scroll.offset / max).clamp(0.0, 1.0);
  }

  void _schedulePositionSave() {
    if (!_restored) return;
    _savePending = true;
    _saveTimer?.cancel();
    _saveTimer = Timer(_saveDebounce, _writePosition);
  }

  void _flushPosition() {
    _saveTimer?.cancel();
    if (_savePending) _writePosition();
  }

  Future<void> _writePosition() async {
    if (!_scroll.hasClients) return;
    _savePending = false;
    await _progressRepo.savePosition(
      ReadingPosition(
        chapterId: widget.chapterId,
        offset: _scroll.offset,
        fraction: _fraction,
        layoutKey: _layoutKey,
        updatedAt: _clock.now(),
      ),
    );
  }

  void _restoreAfterLayout() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final max = _scroll.position.maxScrollExtent;
      final pending = _pendingFraction;
      if (pending != null) {
        _pendingFraction = null;
        _scroll.jumpTo((pending * max).clamp(0.0, max));
      } else if (!_restored) {
        final saved = _savedPosition;
        if (saved != null && saved.isMeaningful) {
          final target = saved.layoutKey == _layoutKey
              ? saved.offset
              : saved.fraction * max;
          _scroll.jumpTo(target.clamp(0.0, max));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('지난번 읽던 곳에서 이어집니다.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        _restored = true;
      }
      _progress.value = _fraction;
    });
  }

  // Scrolling chrome ---------------------------------------------------------

  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0) return false;
    _progress.value = _fraction;
    if (n is UserScrollNotification) {
      final dir = n.direction;
      final atTop = n.metrics.pixels < 80;
      final nearEnd = n.metrics.extentAfter < 120;
      final show = atTop || nearEnd || dir == ScrollDirection.forward;
      final hide = dir == ScrollDirection.reverse && !atTop && !nearEnd;
      if (show && !_barVisible) setState(() => _barVisible = true);
      if (hide && _barVisible) setState(() => _barVisible = false);
    }
    if (n is ScrollUpdateNotification || n is ScrollEndNotification) {
      _schedulePositionSave();
    }
    return false;
  }

  // Actions ------------------------------------------------------------------

  Future<void> _openReference(BibleReference reference) async {
    final ok = await ref.read(linkOpenerProvider).open(reference.externalUri);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${reference.label} 본문을 열 수 없습니다. 인터넷 연결이나 브라우저를 확인해 주세요.',
          ),
        ),
      );
    }
  }

  Future<void> _complete(Chapter chapter) async {
    if (_completing) return;
    setState(() => _completing = true);
    try {
      await _reflectionKey.currentState?.flush();
      _saveTimer?.cancel();
      _savePending = false;
      await ref.read(journeyProvider.notifier).complete(chapter.id);
      await ref.read(reminderCoordinatorProvider).sync();
      if (mounted) context.pushReplacement(Routes.done(chapter.id));
    } on Object {
      if (mounted) {
        setState(() => _completing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('완료 기록을 저장하지 못했습니다. 다시 한 번 눌러 주세요.')),
        );
      }
    }
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.today);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chapter = ref.watch(seasonProvider).chapterById(widget.chapterId);
    if (chapter == null) return _MissingChapter(onClose: _close);

    final settings = ref.watch(settingsProvider);
    ref.listen<UserSettings>(settingsProvider, (prev, next) {
      if (prev?.minutes != next.minutes || prev?.level != next.level) {
        _pendingFraction = _fraction;
      }
    });

    final composed = composeChapter(
      chapter,
      minutes: settings.minutes,
      level: settings.level,
    );
    final media = MediaQuery.of(context);
    final width = media.size.width;
    _layoutKey =
        '${settings.minutes.minutes}|${settings.level.id}|'
        '${media.textScaler.scale(100).round()}|${width.round()}';

    final c = FjColors.of(context);
    final topInset = media.padding.top;
    final journey = ref.watch(journeyProvider).value;
    final firstDone = journey?.firstCompletion(chapter.id);

    if (_positionLoaded) _restoreAfterLayout();

    return PopScope(
      onPopInvokedWithResult: (_, _) => _flushPosition(),
      child: Scaffold(
        body: Stack(
          children: [
            if (_positionLoaded)
              NotificationListener<ScrollNotification>(
                onNotification: _onScroll,
                child: SingleChildScrollView(
                  key: const ValueKey('reader-scroll'),
                  controller: _scroll,
                  padding: EdgeInsets.only(
                    top: topInset + _barHeight + FjSpace.l,
                    bottom: FjSpace.xxl,
                  ),
                  child: ReadingColumn(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ChapterHeader(composed: composed),
                        for (final section in composed.sections)
                          SectionView(
                            section: section,
                            onOpenReference: _openReference,
                          ),
                        KeyMessageView(chapter: chapter),
                        ScriptureLinksView(
                          chapter: chapter,
                          onOpen: _openReference,
                        ),
                        ReflectionSection(
                          key: _reflectionKey,
                          chapter: chapter,
                        ),
                        const SizedBox(height: FjSpace.xxl),
                        if (firstDone != null) ...[
                          Text(
                            '처음 읽은 날 · ${DateFormat('yyyy년 M월 d일', 'ko_KR').format(firstDone.localDate.asDateTime)}',
                            style: FjText.of(context).meta,
                          ),
                          const SizedBox(height: FjSpace.m),
                        ],
                        FjPrimaryButton(
                          key: const ValueKey('reader-complete'),
                          label: firstDone == null
                              ? '오늘의 이야기 완료하기'
                              : '다시 읽기 마치기',
                          onPressed: _completing
                              ? null
                              : () => _complete(chapter),
                        ),
                        const SizedBox(height: FjSpace.xl),
                        ManuscriptStatusView(chapter: chapter),
                      ],
                    ),
                  ),
                ),
              ),
            // Top chrome: hides while reading forward, returns on scroll up.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AnimatedSlide(
                offset: _barVisible ? Offset.zero : const Offset(0, -1),
                duration: FjMotion.of(context, FjMotion.medium),
                curve: FjMotion.curve,
                child: ValueListenableBuilder<double>(
                  valueListenable: _progress,
                  builder: (context, progress, child) => Container(
                    decoration: BoxDecoration(
                      color: c.background,
                      border: Border(
                        bottom: BorderSide(
                          color: progress > 0 ? c.divider : Colors.transparent,
                        ),
                      ),
                    ),
                    padding: EdgeInsets.only(top: topInset),
                    height: topInset + _barHeight,
                    child: child,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        key: const ValueKey('reader-back'),
                        tooltip: '뒤로',
                        onPressed: _close,
                        icon: const Icon(Icons.arrow_back),
                      ),
                      Expanded(child: Center(child: FjLabel(chapter.dayLabel))),
                      TextButton(
                        key: const ValueKey('reader-settings'),
                        onPressed: () => showReadingSettingsSheet(context),
                        style: TextButton.styleFrom(
                          foregroundColor: c.textSecondary,
                          minimumSize: const Size(
                            FjSpace.minTouchTarget,
                            FjSpace.minTouchTarget,
                          ),
                        ),
                        child: Text(
                          readingSettingsLabel(
                            settings.minutes,
                            settings.level,
                          ),
                          style: FjText.of(context).meta,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                  ),
                ),
              ),
            ),
            // Thin reading progress line, always visible under the status bar.
            Positioned(
              top: topInset,
              left: 0,
              right: 0,
              child: ValueListenableBuilder<double>(
                valueListenable: _progress,
                builder: (context, value, _) => Semantics(
                  label: '읽은 정도 ${(value * 100).round()}%',
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: value,
                      child: Container(
                        height: 2,
                        color: c.accent.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissingChapter extends StatelessWidget {
  const _MissingChapter({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final t = FjText.of(context);
    return Scaffold(
      body: SafeArea(
        child: ReadingColumn(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('이 이야기는 아직 준비 중입니다.', style: t.heading),
              const SizedBox(height: FjSpace.l),
              FjPrimaryButton(label: '오늘로 돌아가기', onPressed: onClose),
            ],
          ),
        ),
      ),
    );
  }
}
