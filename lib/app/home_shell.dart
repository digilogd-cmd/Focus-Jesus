import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/design/tokens.dart';

/// Home scaffold with a text-only bottom navigation. A thin ink bar slides
/// along the top rule to the current tab.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const List<String> _labels = ['오늘', '여정', '설정'];

  @override
  Widget build(BuildContext context) {
    final c = FjColors.of(context);
    final t = FjText.of(context);
    final index = shell.currentIndex;
    final d = FjMotion.of(context, const Duration(milliseconds: 420));
    return Scaffold(
      body: shell,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: c.background,
          border: Border(top: BorderSide(color: c.divider, width: 0.8)),
        ),
        child: SafeArea(
          top: false,
          child: Stack(
            children: [
              Row(
                children: [
                  for (var i = 0; i < _labels.length; i++)
                    Expanded(
                      child: Semantics(
                        selected: index == i,
                        button: true,
                        label: _labels[i],
                        excludeSemantics: true,
                        child: InkWell(
                          key: ValueKey('nav-$i'),
                          onTap: () =>
                              shell.goBranch(i, initialLocation: i == index),
                          child: SizedBox(
                            height: 60,
                            child: Center(
                              child: AnimatedDefaultTextStyle(
                                duration: d,
                                curve: FjMotion.curve,
                                style: (index == i ? t.uiStrong : t.ui)
                                    .copyWith(
                                      fontSize: 14.5,
                                      color: index == i
                                          ? c.textPrimary
                                          : c.textSecondary,
                                    ),
                                child: Text(_labels[i]),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedAlign(
                    duration: d,
                    curve: FjMotion.emphasized,
                    alignment: Alignment(
                      -1 + 2 * index / (_labels.length - 1),
                      -1,
                    ),
                    child: SizedBox(
                      height: 1.5,
                      child: FractionallySizedBox(
                        widthFactor: 1 / _labels.length,
                        child: Center(
                          child: Container(
                            width: 28,
                            height: 1.5,
                            color: c.textPrimary,
                          ),
                        ),
                      ),
                    ),
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
