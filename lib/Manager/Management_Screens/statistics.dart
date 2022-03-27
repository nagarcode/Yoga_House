import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent-tab-view.dart';
import 'package:provider/provider.dart';
import 'package:yoga_house/Services/database.dart';
import 'package:yoga_house/Services/splash_screen.dart';
import 'package:yoga_house/Services/utils_file.dart';
import 'package:yoga_house/User_Info/user_info.dart';
import 'package:yoga_house/common_widgets/punch_card.dart';

class StatisticsScreen extends StatefulWidget {
  final FirestoreDatabase database;

  static Future<void> pushToTabBar(BuildContext context) async {
    final database = context.read<FirestoreDatabase>();
    await pushNewScreen(
      context,
      // ignore: prefer_const_constructors
      screen: StatisticsScreen(
        database: database,
      ),
    );
  }

  const StatisticsScreen({Key? key, required this.database}) : super(key: key);

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  late Stream<List<UserInfo>> allUsersInfoStream;
  late Map<String, List<UserInfo>> monthsToUsers;
  Map<String, bool> expand = {};

  @override
  void initState() {
    allUsersInfoStream = widget.database.allUsersInfoStream();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserInfo>>(
        stream: allUsersInfoStream,
        builder: (context, allUsersInfoSnapshot) {
          var allUsers = <UserInfo>[];
          if (Utils.connectionStateInvalid(allUsersInfoSnapshot)) {
            return const SplashScreen();
          }
          final data = allUsersInfoSnapshot.data;
          if (data == null) return const SplashScreen();
          allUsers = data;
          final punchcards = _extractPunchcards(allUsers);
          _initPunchcardMap(allUsers);
          return Scaffold(
            appBar: AppBar(title: Utils.appBarTitle(context, 'סטטיסטיקה')),
            body: SingleChildScrollView(
              child: Column(
                children: [
                  _activePunchcards(allUsers),
                  ..._generateMonthTiles(),
                ],
              ),
            ),
          );
        });
  }

  _generateMonthTiles() {
    final tiles = <Widget>[];
    for (var month in monthsToUsers.keys) {
      final usersThisMonth = monthsToUsers[month];
      final tilesThisMonth = <Widget>[];
      for (var user in usersThisMonth!) {
        tilesThisMonth.add(_generateUserTile(user));
      }
      tiles.add(_generateMonthTile(tilesThisMonth, month));
    }
    return tiles;
  }

  _activePunchcards(List<UserInfo> punchcards) {
    final theme = Theme.of(context);
    final punchcardsWithPunches = punchcards
        .where((element) =>
            element.hasPunchesLeft &&
            element.punchcard!.expiresOn.isAfter(DateTime.now()))
        .toList();
    return ListTile(
      title: const Text('כרטיסיות פעילות: '),
      subtitle: const Text('כרטיסיות שהן בתוקף ונותרו בהן ניקובים'),
      trailing: Text(
        punchcardsWithPunches.length.toString(),
        style: TextStyle(color: theme.textTheme.subtitle1?.color),
      ),
    );
  }

  _initPunchcardMap(List<UserInfo> users) {
    final map = <String, List<UserInfo>>{};
    for (var user in users) {
      if (!user.hasPunchesLeft ||
          !user.punchcard!.expiresOn.isAfter(DateTime.now())) continue;
      final addedOn = Utils.hebrewMonthYear(user.punchcard!.purchasedOn);
      if (map[addedOn] == null) {
        map[addedOn] = [];
      }
      map[addedOn]!.add(user);
    }
    monthsToUsers = map;
  }

  List<Punchcard> _extractPunchcards(List<UserInfo> users) {
    final punchcards = <Punchcard>[];
    for (var user in users) {
      if (user.hasPunchesLeft &&
          user.punchcard!.expiresOn.isAfter(DateTime.now())) {
        punchcards.add(user.punchcard!);
      }
    }
    return punchcards;
  }

  _generateUserTile(UserInfo user) {
    if (user.punchcard == null) {
      return const ListTile(title: Text(''));
    }
    final punchcard = user.punchcard!;
    final boughtText =
        'כרטיסיה נקנתה בתאריך: ${Utils.numericDayMonthYearFromDateTime(punchcard.purchasedOn)}';
    final expires =
        'כרטיסיה בתוקף עד: ${Utils.numericDayMonthYearFromDateTime(punchcard.expiresOn)}';
    final remaining = 'ניקובים שנשארו: ${punchcard.punchesRemaining}';
    final sub = '$boughtText\n$expires\n$remaining';
    return ListTile(title: Text(user.name), subtitle: Text(sub));
  }

  _generateMonthTile(List<Widget> tilesThisMonth, String month) {
    return ListTile(
      leading: IconButton(
        icon: Icon(expand[month] ?? false
            ? Icons.keyboard_arrow_down_outlined
            : Icons.arrow_forward_ios_sharp),
        onPressed: () {
          setState(() {
            expand[month] = expand[month] == null ? true : !expand[month]!;
          });
        },
      ),
      title: Text(month),
      subtitle: expand[month] ?? false
          ? Column(
              children: tilesThisMonth,
            )
          : null,
    );
  }
}
