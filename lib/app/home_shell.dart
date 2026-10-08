import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/design/tokens.dart';

/// Home scaffold with a quiet, text-only bottom navigation.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const List<String> _labels = ['오늘', '여정', '설정'];

  @override
  Widget build(BuildContext context) {
    final c = FjColors.of(context);
    final t = FjText.of(context);
    return Scaffold(
      body: shell,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: c.background,
          border: Border(top: BorderSide(color: c.divider)),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              for (var i = 0; i < _labels.length; i++)
                Expanded(
                  child: Semantics(
                    selected: shell.currentIndex == i,
                    button: true,
                    label: _labels[i],
                    excludeSemantics: true,
                    child: InkWell(
                      key: ValueKey('nav-$i'),
                      onTap: () => shell.goBranch(
                        i,
                        initialLocation: i == shell.currentIndex,
                      ),
                      child: SizedBox(
                        height: 58,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _labels[i],
                              style:
                                  (shell.currentIndex == i ? t.uiStrong : t.ui)
                                      .copyWith(
                                        fontSize: 14.5,
                                        color: shell.currentIndex == i
                                            ? c.textPrimary
                                            : c.textSecondary,
                                      ),
                            ),
                            const SizedBox(height: 6),
                            AnimatedContainer(
                              duration: FjMotion.of(context, FjMotion.short),
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: shell.currentIndex == i
                                    ? c.accent
                                    : Colors.transparent,
                              ),
                            ),
                          ],
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
