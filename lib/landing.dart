import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yoga_house/Client/client_home.dart';
import 'package:yoga_house/Manager/manager_home.dart';
import 'package:yoga_house/sign_in/sign_in_screen.dart';
import 'package:yoga_house/sign_in/user_details_promt_screen.dart';
import 'Practice/practice.dart';
import 'Services/app_info.dart';
import 'Services/auth.dart';
import 'Services/database.dart';
import 'Services/notifications.dart';
import 'Services/shared_prefs.dart';
import 'Services/splash_screen.dart';
import 'Services/utils_file.dart';
import 'User_Info/user_info.dart';
import 'common_widgets/info_screen.dart';

class LandingPage extends StatelessWidget {
  final bool skipNameCheck;
  final SharedPrefs sharedPrefs;
  const LandingPage(this.sharedPrefs, {Key? key, required this.skipNameCheck})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthBase>();
    return StreamBuilder<AppUser?>(
      stream: auth.onAuthStateChanged,
      builder: (authContext, authSnapshot) {
        if (Utils.connectionStateInvalid(authSnapshot)) {
          return const SplashScreen();
        } else {
          final user = authSnapshot.data;
          if (user == null) {
            return SignInScreen(auth: auth);
          } else {
            //user != null
            final database = FirestoreDatabase(currentUserUID: user.uid);
            return StreamBuilder<UserInfo>(
                stream: database.userInfoStream(user.uid),
                builder: (context, userInfoSnapshot) {
                  if (Utils.connectionStateInvalid(userInfoSnapshot)) {
                    return const SplashScreen();
                  }
                  final userInfo = userInfoSnapshot.data;
                  _checkUserInfoErrorAndInit(userInfoSnapshot, database, user);
                  if (userInfo == null) {
                    return const SplashScreen();
                  }
                  return MultiProvider(
                    providers: [
                      Provider<AppUser>.value(value: user),
                      Provider<UserInfo>.value(value: userInfo),
                      Provider<FirestoreDatabase>.value(value: database),
                      Provider<SharedPrefs>.value(value: sharedPrefs),
                      Provider<NotificationService>(
                        create: (_) {
                          return _createNotificationService(database);
                        },
                      ),
                    ],
                    child: !_hasDetails(userInfo)
                        ? UserDetailsPromtScreen(auth: auth, database: database)
                        : _isManager(userInfo)
                            ? _managerSubTree(database)
                            : clientSubTree(database, userInfo),
                  );
                });
          }
        }
      },
    );
  }

  NotificationService _createNotificationService(FirestoreDatabase database) {
    final notifications = NotificationService(database);
    notifications.init();
    return notifications;
  }

  bool _isManager(UserInfo userInfo) {
    return userInfo.isManager;
  }

  Widget _managerSubTree(FirestoreDatabase database) {
    return StreamBuilder<AppInfo>(
        stream: database.appInfoStream(),
        builder: (context, appInfoSnapshot) {
          if (Utils.connectionStateInvalid(appInfoSnapshot)) {
            return const SplashScreen();
          }
          final appInfo = appInfoSnapshot.data;
          if (appInfo == null) {
            return const SplashScreen();
          }
          return StreamBuilder<List<Practice>>(
            stream: database.futurePracticesStream(),
            builder: (context, futurePracticesSnapshot) {
              if (Utils.connectionStateInvalid(futurePracticesSnapshot)) {
                return const SplashScreen();
              }
              final futurePractices = futurePracticesSnapshot.data;
              if (futurePractices == null) {
                return const SplashScreen();
              }
              return MultiProvider(
                  providers: [
                    Provider<AppInfo>.value(value: appInfo),
                    Provider<List<Practice>>.value(value: futurePractices),
                  ],
                  child: appInfo.isManagerTerminated
                      ? const InfoScreen(PageType.managerTerminated)
                      // ignore: prefer_const_constructors
                      : ManagerHome());
            },
          );
        });
  }

  Widget clientSubTree(FirestoreDatabase database, UserInfo userInfo) {
    return FutureBuilder<AppInfo>(
        future: database.appInfoFuture(),
        builder: (context, appInfoSnapshot) {
          if (Utils.connectionStateInvalid(appInfoSnapshot)) {
            return const SplashScreen();
          }
          final appInfo = appInfoSnapshot.data;
          if (appInfo == null) {
            return const SplashScreen();
          }
          return StreamBuilder<List<Practice>>(
              stream: database.futurePracticesStream(),
              builder: (context, futurePracticesSnapshot) {
                if (Utils.connectionStateInvalid(futurePracticesSnapshot)) {
                  return const SplashScreen();
                }
                final futurePractices = futurePracticesSnapshot.data;
                if (futurePractices == null) {
                  return const SplashScreen();
                }
                return MultiProvider(
                  providers: [
                    Provider<AppInfo>.value(value: appInfo),
                    Provider<List<Practice>>.value(value: futurePractices),
                  ],
                  child: appInfo.isClientTerminated && !userInfo.isTomer()
                      ? const InfoScreen(PageType.clientTerminated)
                      // ignore: prefer_const_constructors
                      : ClientHome(),
                );
              });
        });
  }

  Future<void> _checkUserInfoErrorAndInit(
      AsyncSnapshot snapshot, FirestoreDatabase database, AppUser user) async {
    if (snapshot.hasError && !skipNameCheck) {
      debugPrint(snapshot.error.toString());
      debugPrint('User info snapshot has error! initializing empty user info');
      await database.initEmptyUserInfo(user.uid);
    }
  }

  bool _hasDetails(UserInfo userInfo) {
    return userInfo.name.isNotEmpty &&
        userInfo.phoneNumber.isNotEmpty &&
        userInfo.email.isNotEmpty;
  }
}
