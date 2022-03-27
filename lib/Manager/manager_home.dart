import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent-tab-view.dart';
import 'package:provider/provider.dart';
import 'package:yoga_house/Manager/clients_screen.dart';
import 'package:yoga_house/Manager/management_screen.dart';
import 'package:yoga_house/Manager/manager_main_screen.dart';
import 'package:yoga_house/Practice/practice.dart';
import 'package:yoga_house/Services/database.dart';
import 'package:yoga_house/Services/notifications.dart';

class ManagerHome extends StatefulWidget {
  const ManagerHome({Key? key}) : super(key: key);

  @override
  _ManagerHomeState createState() => _ManagerHomeState();
}

class _ManagerHomeState extends State<ManagerHome> {
  PersistentTabController? _controller;
  @override
  void initState() {
    _listenForNotifications();
    _organizePracticesCollection();
    _controller = PersistentTabController(initialIndex: 1);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return _tabBar(context);
  }

  List<Widget> _buildScreens() {
    final database = context.read<FirestoreDatabase>();
    return [
      ClientsScreen(database: database),
      // ignore: prefer_const_constructors
      ManagerMainScreen(),
      // ignore: prefer_const_constructors
      ManagementScreen(),
    ];
  }

  List<PersistentBottomNavBarItem> _navBarItems() {
    final colors = Theme.of(context).colorScheme;
    return [
      PersistentBottomNavBarItem(
        icon: const Icon(CupertinoIcons.person_circle),
        title: ("מתאמנים"),
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
        title: ("ניהול"),
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

  void _organizePracticesCollection() {
    final database = context.read<FirestoreDatabase>();
    final allPractices = context.read<List<Practice>>();
    database.organizePracticesTransaction(allPractices);
  }

  void _listenForNotifications() {
    final notificationService =
        Provider.of<NotificationService>(context, listen: false);
    notificationService.listenForMessages(context);
    notificationService.subscribeToAdminNotificationsTopic();
    notificationService.subscribeToHomepageTextTopic();
  }
}
