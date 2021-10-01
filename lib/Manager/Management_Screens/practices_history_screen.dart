import 'package:flutter/material.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:persistent_bottom_nav_bar/persistent-tab-view.dart';
import 'package:provider/provider.dart';
import 'package:yoga_house/Practice/practice.dart';
import 'package:yoga_house/Practice/practice_card.dart';
import 'package:yoga_house/Services/database.dart';
import 'package:intl/intl.dart';
import 'package:yoga_house/Services/splash_screen.dart';
import 'package:yoga_house/Services/utils_file.dart';

class PracticesHistoryScreen extends StatefulWidget {
  final FirestoreDatabase database;

  static Future<void> pushToTabBar(BuildContext context) async {
    final database = context.read<FirestoreDatabase>();
    await pushNewScreen(
      context,
      // ignore: prefer_const_constructors
      screen: PracticesHistoryScreen(database: database),
    );
  }

  const PracticesHistoryScreen({Key? key, required this.database})
      : super(key: key);

  @override
  _PracticesHistoryScreenState createState() => _PracticesHistoryScreenState();
}

class _PracticesHistoryScreenState extends State<PracticesHistoryScreen> {
  late Future<List<Practice>> allPracticesFuture;
  Widget get _noPracticesWidget =>
      const Center(child: Text('אין תרגולים זמינים'));
  @override
  void initState() {
    allPracticesFuture = widget.database.practicesHistoryFuture();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Utils.appBarTitle(context, 'היסטוריית תרגולים')),
      body: FutureBuilder<List<Practice>>(
          future: allPracticesFuture,
          builder: (context, snapshot) {
            if (Utils.connectionStateInvalid(snapshot)) {
              return const SplashScreen();
            }
            final practices = snapshot.data;
            if (practices == null) {
              return const SplashScreen();
            }
            return _practiceCardsListView(practices);
          }),
    );
  }

  Widget _practiceCardsListView(List<Practice> allPractices) {
    if (allPractices.isEmpty) return _noPracticesWidget;
    return GroupedListView<Practice, String>(
      shrinkWrap: true,
      useStickyGroupSeparators: true,
      elements: allPractices,
      groupBy: _groupBy,
      groupSeparatorBuilder: _groupSeparatorBuilder,
      itemBuilder: _itemBuilder,
      itemComparator: _itemComparator,
      groupComparator: _groupComparator,
    );
  }

  Widget _itemBuilder(BuildContext listContext, Practice practice) {
    final database = context.read<FirestoreDatabase>();
    return PracticeCard(
      isHistory: true,
      database: database,
      managerView: true,
      data: practice,
      registerCallback: () {},
      waitingListCallback: () {}, //TODO change
      isRegistered: false,
      unregisterCallback: () {},
    );
  }

  int _itemComparator(first, second) =>
      second.startTime.compareTo(first.startTime);

  String _groupBy(practice) =>
      Utils.numericDayMonthYearFromDateTime(practice.startTime);

  int _groupComparator(str1, str2) => DateFormat.yMd('he_IL')
      .parse(str2)
      .compareTo(DateFormat.yMd('he_IL').parse(str1));

  Widget _groupSeparatorBuilder(String groupByValue) {
    final theme = Theme.of(context);
    final dateTime = DateFormat.yMd('he_IL').parse(groupByValue);
    final verbouseDay = Utils.vebouseDayFromDateTime(dateTime);
    return Text('$verbouseDay, $groupByValue',
        style: theme.textTheme.bodyText1!.copyWith(fontSize: 18),
        textAlign: TextAlign.center);
  }
}
