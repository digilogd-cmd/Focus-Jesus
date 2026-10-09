import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/design/motion.dart';
import '../../core/design/tokens.dart';
import '../../core/design/widgets.dart';
import '../../core/time/clock.dart';
import '../../data/content/chapter.dart';
import '../../data/repositories/reflection_repository.dart';
import '../../core/design/korean_text.dart';

/// Three reflection questions, each with an optional private note that saves
/// itself while typing.
class ReflectionSection extends ConsumerStatefulWidget {
  const ReflectionSection({super.key, required this.chapter});

  final Chapter chapter;

  @override
  ConsumerState<ReflectionSection> createState() => ReflectionSectionState();
}

class ReflectionSectionState extends ConsumerState<ReflectionSection> {
  static const Duration _debounce = Duration(milliseconds: 600);

  late final ReflectionRepository _repo;
  late final Clock _clock;
  late final List<TextEditingController> _controllers;
  final Map<int, Timer> _timers = {};
  final Set<int> _dirty = {};
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _repo = ref.read(reflectionRepositoryProvider);
    _clock = ref.read(clockProvider);
    _controllers = [
      for (var i = 0; i < widget.chapter.reflectionQuestions.length; i++)
        TextEditingController(),
    ];
    _load();
  }

  Future<void> _load() async {
    final notes = await _repo.loadNotes(widget.chapter.id);
    if (!mounted) return;
    setState(() {
      for (final e in notes.entries) {
        if (e.key < _controllers.length) _controllers[e.key].text = e.value;
      }
      _loaded = true;
    });
  }

  void _onChanged(int index) {
    _dirty.add(index);
    _timers[index]?.cancel();
    _timers[index] = Timer(_debounce, () => _save(index));
  }

  Future<void> _save(int index) async {
    if (!_dirty.remove(index)) return;
    await _repo.saveNote(
      chapterId: widget.chapter.id,
      questionIndex: index,
      body: _controllers[index].text,
      now: _clock.now(),
    );
  }

  /// Writes any pending note immediately (before completing or leaving).
  Future<void> flush() async {
    for (final t in _timers.values) {
      t.cancel();
    }
    _timers.clear();
    await Future.wait([for (final i in _dirty.toList()) _save(i)]);
  }

  @override
  void dispose() {
    // Repository was captured in initState, so saving after dispose is safe.
    flush();
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = FjText.of(context);
    final questions = widget.chapter.reflectionQuestions;
    return Padding(
      padding: const EdgeInsets.only(top: FjSpace.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DrawnRule(onScreen: true),
          const SizedBox(height: FjSpace.xl),
          const Reveal(onScreen: true, child: FjDualLabel('REFLECT', '묵상')),
          const SizedBox(height: FjSpace.s),
          Reveal(
            onScreen: true,
            child: Text(
              keepAll('답을 적지 않아도 괜찮습니다. 적은 메모는 이 기기에만 저장됩니다.'),
              style: t.meta,
            ),
          ),
          for (var i = 0; i < questions.length; i++)
            Padding(
              padding: const EdgeInsets.only(top: FjSpace.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MaskRise(
                    onScreen: true,
                    child: ExcludeSemantics(
                      child: Text(
                        '${i + 1}'.padLeft(2, '0'),
                        style: t.numeral.copyWith(
                          fontSize: 34,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: FjSpace.s),
                  Reveal(
                    onScreen: true,
                    child: Text(
                      keepAll(questions[i]),
                      style: t.body.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  TextField(
                    key: ValueKey('reflection-note-$i'),
                    controller: _controllers[i],
                    enabled: _loaded,
                    onChanged: (_) => _onChanged(i),
                    minLines: 2,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    scrollPadding: const EdgeInsets.only(bottom: 160),
                    style: t.ui.copyWith(height: 1.65),
                    decoration: const InputDecoration(
                      hintText: '떠오르는 생각을 적어 보세요',
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
