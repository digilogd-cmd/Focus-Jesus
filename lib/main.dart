import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';
import 'core/design/startup_error.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _registerFontLicenses();
  try {
    final deps = await loadAppDependencies();
    final container = await createAppContainer(deps);
    runApp(
      UncontrolledProviderScope(
        container: container,
        child: const FocusJesusApp(),
      ),
    );
  } on Object catch (error, stack) {
    // Never show a blank screen: explain that bundled content failed to load.
    FlutterError.reportError(
      FlutterErrorDetails(exception: error, stack: stack),
    );
    runApp(StartupErrorApp(error: error));
  }
}

void _registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(const [
      'Noto Serif KR',
    ], await rootBundle.loadString('assets/licenses/NotoSerifKR-OFL.txt'));
    yield LicenseEntryWithLineBreaks(const [
      'Pretendard',
    ], await rootBundle.loadString('assets/licenses/Pretendard-OFL.txt'));
    yield LicenseEntryWithLineBreaks(
      const ['Cormorant Garamond'],
      await rootBundle.loadString('assets/licenses/CormorantGaramond-OFL.txt'),
    );
  });
}
