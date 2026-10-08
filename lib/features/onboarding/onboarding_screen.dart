import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/design/tokens.dart';
import '../../core/design/widgets.dart';
import '../../data/models/reading_preferences.dart';
import '../../data/models/user_settings.dart';
import '../../core/design/korean_text.dart';
import '../settings/reminder_time_picker.dart';

/// First launch: welcome → level → daily minutes → reminder.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const int _stepCount = 4;
  int _step = 0;
  ReadingLevel _level = ReadingLevel.beginner;
  ReadingMinutes _minutes = ReadingMinutes.ten;
  int _hour = ReminderPreference.defaults.hour;
  int _minute = ReminderPreference.defaults.minute;
  bool _finishing = false;

  void _next() => setState(() => _step = (_step + 1).clamp(0, _stepCount - 1));

  void _back() => setState(() => _step = (_step - 1).clamp(0, _stepCount - 1));

  Future<void> _finish({required bool withReminder}) async {
    if (_finishing) return;
    setState(() => _finishing = true);
    var enabled = withReminder;
    final coordinator = ref.read(reminderCoordinatorProvider);
    if (withReminder) {
      final granted = await coordinator.requestPermission();
      if (!granted) {
        enabled = false;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('알림 권한이 없어 알림 없이 시작합니다. 설정에서 언제든 다시 켤 수 있습니다.'),
            ),
          );
        }
      }
    }
    await ref
        .read(settingsProvider.notifier)
        .update(
          (s) => s.copyWith(
            level: _level,
            minutes: _minutes,
            reminder: ReminderPreference(
              enabled: enabled,
              hour: _hour,
              minute: _minute,
            ),
            onboardingComplete: true,
          ),
        );
    await coordinator.sync();
    // The router redirects to the home screen once onboarding is complete.
  }

  @override
  Widget build(BuildContext context) {
    final c = FjColors.of(context);
    final t = FjText.of(context);
    final duration = FjMotion.of(context, FjMotion.medium);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: FjSpace.minTouchTarget + 8,
              child: ReadingColumn(
                child: Row(
                  children: [
                    if (_step > 0)
                      TextButton(
                        key: const ValueKey('onboarding-back'),
                        onPressed: _back,
                        style: TextButton.styleFrom(
                          foregroundColor: c.textSecondary,
                          minimumSize: const Size(
                            FjSpace.minTouchTarget,
                            FjSpace.minTouchTarget,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: Text(
                          '이전',
                          style: t.ui.copyWith(color: c.textSecondary),
                        ),
                      ),
                    const Spacer(),
                    Semantics(
                      label: '${_step + 1}/$_stepCount 단계',
                      excludeSemantics: true,
                      child: Row(
                        children: [
                          for (var i = 0; i < _stepCount; i++)
                            AnimatedContainer(
                              duration: duration,
                              margin: const EdgeInsets.only(left: 6),
                              width: i == _step ? 18 : 6,
                              height: 2,
                              color: i <= _step ? c.accent : c.divider,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: duration,
                switchInCurve: FjMotion.curve,
                child: KeyedSubtree(
                  key: ValueKey(_step),
                  child: _buildStep(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context) => switch (_step) {
    0 => _StepLayout(
      footer: FjPrimaryButton(label: '시작하기', onPressed: _next),
      children: [
        const SizedBox(height: FjSpace.xl),
        const Wordmark(),
        const SizedBox(height: FjSpace.m),
        Text('모든 이야기는 그리스도께로', style: FjText.of(context).subtitle),
        const SizedBox(height: FjSpace.xxl),
        Text(
          keepAll('성경은 흩어진 이야기의 모음이 아니라, 하나의 큰 이야기입니다.'),
          style: FjText.of(context).heading,
        ),
        const SizedBox(height: FjSpace.l),
        Text(
          keepAll(
            '하루에 한 편, 이해하기 쉬운 해설로 성경의 흐름을 따라갑니다. '
            '이야기를 읽은 뒤에는 실제 성경 본문을 직접 펼쳐 보도록 안내해 드립니다. '
            '서두르지 않아도 괜찮습니다. 놓친 날이 있으면 그다음 날 이어서 읽으면 됩니다.',
          ),
          style: FjText.of(context).body,
        ),
      ],
    ),
    1 => _StepLayout(
      footer: FjPrimaryButton(label: '다음', onPressed: _next),
      children: [
        const _StepTitle(
          title: '성경을 얼마나 읽어 보셨나요?',
          lead: '같은 이야기를 읽되, 곁 설명의 깊이가 달라집니다.',
        ),
        for (final level in ReadingLevel.values)
          FjOptionTile(
            key: ValueKey('level-${level.id}'),
            title: level.label,
            description: level.description,
            selected: _level == level,
            onTap: () => setState(() => _level = level),
          ),
      ],
    ),
    2 => _StepLayout(
      footer: FjPrimaryButton(label: '다음', onPressed: _next),
      children: [
        const _StepTitle(
          title: '하루에 얼마나 읽고 싶으세요?',
          lead: '시간이 길수록 이야기의 맥락과 배경을 더 넓게 다룹니다. 언제든 바꿀 수 있습니다.',
        ),
        for (final m in ReadingMinutes.values)
          FjOptionTile(
            key: ValueKey('minutes-${m.minutes}'),
            title: '${m.minutes}분',
            description: _minutesDescription(m),
            selected: _minutes == m,
            onTap: () => setState(() => _minutes = m),
          ),
      ],
    ),
    _ => _StepLayout(
      footer: Column(
        children: [
          FjPrimaryButton(
            key: const ValueKey('onboarding-enable-reminder'),
            label: '이 시간에 알림 받기',
            onPressed: _finishing ? null : () => _finish(withReminder: true),
          ),
          const SizedBox(height: FjSpace.s),
          FjQuietButton(
            key: const ValueKey('onboarding-skip-reminder'),
            label: '알림 없이 시작하기',
            onPressed: _finishing ? null : () => _finish(withReminder: false),
          ),
        ],
      ),
      children: [
        const _StepTitle(
          title: '매일 읽을 시간을 알려 드릴까요?',
          lead: '정해 둔 시간에 조용히 한 번 알려 드립니다. 그날 이야기를 이미 읽었다면 알리지 않습니다.',
        ),
        FjListRow(
          key: const ValueKey('onboarding-reminder-time'),
          title: '알림 시간',
          value: ReminderPreference(
            enabled: true,
            hour: _hour,
            minute: _minute,
          ).timeLabel,
          onTap: () async {
            final picked = await pickReminderTime(
              context,
              hour: _hour,
              minute: _minute,
            );
            if (picked != null) {
              setState(() {
                _hour = picked.$1;
                _minute = picked.$2;
              });
            }
          },
        ),
        const SizedBox(height: FjSpace.m),
        Text(
          '휴대전화의 배터리 관리 정책에 따라 알림이 몇 분 늦게 도착할 수 있습니다.',
          style: FjText.of(context).meta,
        ),
      ],
    ),
  };

  static String _minutesDescription(ReadingMinutes m) => switch (m) {
    ReadingMinutes.five => '핵심 이야기와 그리스도와의 연결',
    ReadingMinutes.ten => '이야기의 흐름과 맥락까지',
    ReadingMinutes.fifteen => '역사와 문학적 배경까지',
    ReadingMinutes.twenty => '관련 본문 비교와 심화 해설까지',
  };
}

class _StepTitle extends StatelessWidget {
  const _StepTitle({required this.title, required this.lead});

  final String title;
  final String lead;

  @override
  Widget build(BuildContext context) {
    final t = FjText.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: FjSpace.xl, bottom: FjSpace.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(keepAll(title), style: t.chapterTitle),
          const SizedBox(height: FjSpace.m),
          Text(keepAll(lead), style: t.subtitle),
        ],
      ),
    );
  }
}

/// Scrollable content with the action pinned below, safe at large text sizes.
class _StepLayout extends StatelessWidget {
  const _StepLayout({required this.children, required this.footer});

  final List<Widget> children;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: ReadingColumn(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ),
        ),
        ReadingColumn(
          child: Padding(
            padding: const EdgeInsets.only(top: FjSpace.m, bottom: FjSpace.l),
            child: footer,
          ),
        ),
      ],
    );
  }
}
