import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ckb_localizations/ckb_localizations.dart';
import 'package:provider/provider.dart';

import 'l10n/localization_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0F0F1A),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Restore saved language BEFORE first frame so the splash is in the right
  // language on the very first build.
  final l10n = LocalizationProvider();
  await l10n.load();

  runApp(SignslatorApp(l10n: l10n));
}

class SignslatorApp extends StatelessWidget {
  final LocalizationProvider l10n;
  const SignslatorApp({super.key, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LocalizationProvider>.value(value: l10n),
        // AuthProvider depends on LocalizationProvider so they share state.
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(l10n)..bootstrap(),
        ),
      ],
      child: Consumer<LocalizationProvider>(
        builder: (context, loc, _) {
          return MaterialApp(
            title: loc.tr('app_name'),
            debugShowCheckedModeBanner: false,
            theme: AppTheme.dark,
            // ─── Localization ─────────────────────────────────
            locale: loc.locale,
            supportedLocales: const [
              Locale('en', 'US'),
              Locale('ckb', 'IQ'), // Kurdish (Sorani)
            ],
            localizationsDelegates: const [
              ...CkbLocalizations.localizationsDelegates,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            // ─── RTL/LTR direction follows the chosen language ─
            builder: (ctx, child) => Directionality(
              textDirection: loc.language.direction,
              child: child ?? const SizedBox.shrink(),
            ),
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
