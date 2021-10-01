import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent-tab-view.dart';
import 'package:provider/provider.dart';
import 'package:yoga_house/Client/client_settings_screen.dart';
import 'package:yoga_house/Client_Profile/client_profile_screen.dart';
import 'package:yoga_house/Practice/practice.dart';
import 'package:yoga_house/Services/app_info.dart';
import 'package:yoga_house/Services/database.dart';
import 'package:yoga_house/Services/notifications.dart';
import 'package:yoga_house/User_Info/user_info.dart';
import 'client_main_screen.dart';

class ClientHome extends StatefulWidget {
  const ClientHome({Key? key}) : super(key: key);

  @override
  _ClientHomeState createState() => _ClientHomeState();
}

class _ClientHomeState extends State<ClientHome> {
  final _controller = PersistentTabController(initialIndex: 1);
  @override
  void initState() {
    _listenForNotifications();
    //TODO All inits go here: move practices to past, punchcard expiration date check, etc.
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return _tabBar(context);
  }

  List<Widget> _buildScreens() {
    final futurePractices = context.read<List<Practice>>();
    final database = context.read<FirestoreDatabase>();
    final appInfo = context.read<AppInfo>();
    final userInfo = context.read<UserInfo>();
    final practicesRegisteredTo =
        UserInfo.practicesUserIsRegisteredTo(futurePractices, userInfo);
    return [
      ClientProfileScreen(
          userInfo: userInfo, database: database, isManagerView: false),
      ClientMainScreen(
          database: database,
          appInfo: appInfo,
          practicesRegisteredTo: practicesRegisteredTo),
      ClientSettingsScreen(),
    ];
  }

  List<PersistentBottomNavBarItem> _navBarItems() {
    final colors = Theme.of(context).colorScheme;
    return [
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.card_membership_outlined),
        title: ("כרטיסיה"),
        activeColorPrimary: colors.primary,
        inactiveColorPrimary: CupertinoColors.systemGrey,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(CupertinoIcons.home),
        title: ("ראשי"),
        activeColorPrimary: colors.primary,
        inactiveColorPrimary: CupertinoColors.systemGrey,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(CupertinoIcons.settings),
        title: ("הגדרות"),
        activeColorPrimary: colors.primary,
        inactiveColorPrimary: CupertinoColors.systemGrey,
      ),
    ];
  }

  Widget _tabBar(BuildContext context) {
    return PersistentTabView(
      context,
      controller: _controller,
      screens: _buildScreens(),
      items: _navBarItems(),
      resizeToAvoidBottomInset: true,
      decoration: NavBarDecoration(
        borderRadius: BorderRadius.circular(10.0),
        colorBehindNavBar: Colors.white,
      ),
      itemAnimationProperties: const ItemAnimationProperties(
        duration: Duration(milliseconds: 200),
        curve: Curves.ease,
      ),
      screenTransitionAnimation: const ScreenTransitionAnimation(
        animateTabTransition: true,
        curve: Curves.ease,
        duration: Duration(milliseconds: 200),
      ),
      navBarStyle: NavBarStyle.style6,
    );
  }

  void _listenForNotifications() {
    final userInfo = context.read<UserInfo>();
    final notificationService =
        Provider.of<NotificationService>(context, listen: false);
    notificationService.listenForMessages(context);
    notificationService.subscribeToHomepageTextTopic();
    notificationService.subscribeToUserNotifications(userInfo.uid);
  }
}
