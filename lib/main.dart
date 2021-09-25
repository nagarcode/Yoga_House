import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';
import 'package:syncfusion_localizations/syncfusion_localizations.dart';
import 'package:yoga_house/Services/shared_prefs.dart';
import 'package:yoga_house/landing.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'Services/auth.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  final preferences = await StreamingSharedPreferences.instance;
  final sharedPrefs = SharedPrefs(preferences);
  runApp(MyApp(sharedPrefs));
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // await NotificationService.showNotification(message);
}

class MyApp extends StatelessWidget {
  final SharedPrefs sharedPrefs;
  const MyApp(this.sharedPrefs, {Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final FirebaseAnalytics analytics = FirebaseAnalytics();
    return Provider<AuthBase>(
      create: (_) => Auth(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Yoga_Base',
        theme: _theme(context),
        home: LandingPage(sharedPrefs, skipNameCheck: false),
        navigatorObservers: [
          FirebaseAnalyticsObserver(analytics: analytics),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          DefaultCupertinoLocalizations.delegate,
          SfGlobalLocalizations.delegate
        ],
        supportedLocales: const [
          Locale('he', 'IL'),
          Locale('en', 'US'),
        ],
        locale: const Locale('he'),
      ),
    );
  }

  ThemeData _theme(BuildContext context) {
    return ThemeData(
      // textButtonTheme: _textButtonTheme(),
      colorScheme: _colorScheme(),
      textTheme: _textTheme(),
      appBarTheme: _appBarTheme(),
      iconTheme: _iconTheme(),
    );
  }

  TextTheme _textTheme() {
    final defaultTheme = ThemeData.light().textTheme;
    final colorScheme = _colorScheme();
    return TextTheme(
        button:
            defaultTheme.button?.copyWith(color: colorScheme.secondaryVariant),
        bodyText1: defaultTheme.bodyText1
            ?.copyWith(color: colorScheme.secondaryVariant),
        bodyText2: defaultTheme.bodyText2?.copyWith(color: colorScheme.primary),
        subtitle1: defaultTheme.subtitle1
            ?.copyWith(color: colorScheme.secondaryVariant),
        subtitle2:
            defaultTheme.subtitle2?.copyWith(color: colorScheme.primaryVariant),
        headline6: defaultTheme.headline6
            ?.copyWith(color: colorScheme.secondaryVariant),
        headline5: defaultTheme.headline5
            ?.copyWith(color: colorScheme.secondaryVariant),
        headline4: defaultTheme.headline4
            ?.copyWith(color: colorScheme.secondaryVariant),
        headline3: defaultTheme.headline3
            ?.copyWith(color: colorScheme.secondaryVariant),
        headline2: defaultTheme.headline2
            ?.copyWith(color: colorScheme.secondaryVariant),
        headline1: defaultTheme.headline2
            ?.copyWith(color: colorScheme.secondaryVariant),
        caption: defaultTheme.caption,
        overline: defaultTheme.overline);
  }

  ColorScheme _colorScheme() {
    final def = ThemeData.light().colorScheme;
    final primary = Colors.deepOrange.shade100;
    final primaryVariant = Colors.deepOrange.shade300;
    final secondary = Colors.lightBlue.shade50;
    final secondaryVariant = Colors.lightBlue.shade300;
    // final primaryVariant = Colors.deepOrange.shade300;
    // final secondaryVariant = Colors.purple.shade300;
    return ColorScheme(
        background: primary,
        brightness: Brightness.light,
        error: Colors.red,
        onBackground: def.onBackground,
        onError: def.onError,
        primary: primary,
        onPrimary: def.onPrimary,
        secondary: secondary,
        onSecondary: def.onSecondary,
        onSurface: def.onSurface,
        primaryVariant: primaryVariant,
        secondaryVariant: secondaryVariant,
        surface: Colors.deepOrangeAccent.shade100);
  }

  AppBarTheme _appBarTheme() {
    return AppBarTheme(
      backgroundColor: _colorScheme().primary,
      foregroundColor: _colorScheme().primary,
      iconTheme: const IconThemeData(color: Colors.white),
      shadowColor: Colors.white,
    );
  }

  IconThemeData _iconTheme() {
    return ThemeData.light()
        .iconTheme
        .copyWith(color: _colorScheme().secondaryVariant);
  }

  // _textButtonTheme() {return TextButtonThemeData(style: ButtonStyle())}

}
