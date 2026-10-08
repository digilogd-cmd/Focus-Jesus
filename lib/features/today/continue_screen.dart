import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';

/// Target of a reminder tap: opens the next chapter to read, or home when the
/// season is finished. Shows only the background while it redirects.
class ContinueScreen extends ConsumerStatefulWidget {
  const ContinueScreen({super.key});

  @override
  ConsumerState<ContinueScreen> createState() => _ContinueScreenState();
}

class _ContinueScreenState extends ConsumerState<ContinueScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(journeyProvider.future);
      if (!mounted) return;
      final next = ref.read(todayPlanProvider).nextChapterId;
      context.go(Routes.today);
      if (next != null) context.push(Routes.read(next));
    });
  }

  @override
  Widget build(BuildContext context) => const Scaffold(body: SizedBox.expand());
}
