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
import 'package:yoga_house/User_Info/user_info.dart';

class PracticesHistoryScreen extends StatefulWidget {
  final FirestoreDatabase database;
  final UserInfo? userToDisplay;
  final bool isManagerView;

  static Future<void> pushToTabBar(
      BuildContext context, UserInfo? userToDisplay, bool isManagerView) async {
    final database = context.read<FirestoreDatabase>();
    await pushNewScreen(
      context,
      // ignore: prefer_const_constructors
      screen: PracticesHistoryScreen(
        database: database,
        userToDisplay: userToDisplay,
        isManagerView: isManagerView,
      ),
    );
  }

  const PracticesHistoryScreen(
      {Key? key,
      required this.database,
      required this.userToDisplay,
      required this.isManagerView})
      : super(key: key);

  @override
  _PracticesHistoryScreenState createState() => _PracticesHistoryScreenState();
}

class _PracticesHistoryScreenState extends State<PracticesHistoryScreen> {
  late Future<Map<String, List<Practice>>> allPracticesFuture;
  Widget get _noPracticesWidget =>
      const Center(child: Text('אין שיעורים זמינים'));
  @override
  void initState() {
    allPracticesFuture = widget.database.practicesHistoryByMonthsFuture();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Utils.appBarTitle(context, 'היסטוריית שיעורים')),
      body: FutureBuilder<Map<String, List<Practice>>>(
          future: allPracticesFuture,
          builder: (context, snapshot) {
            if (Utils.connectionStateInvalid(snapshot)) {
              return const SplashScreen();
            }
            final practices = snapshot.data;
            if (practices == null) {
              return const SplashScreen();
            }
            final practicesList = _getPractices(practices);
            return _practiceCardsListView(practicesList);
          }),
    );
  }

  Widget _practiceCardsListView(List<Practice> allPractices) {
    if (allPractices.isEmpty) return _noPracticesWidget;
    final practicesToDisplay = _practicesToDisplay(allPractices);
    if (practicesToDisplay.isEmpty) {
      return const Center(child: Text('טרם נרשמת לשיעורים.'));
    }
    return GroupedListView<Practice, String>(
      shrinkWrap: true,
      useStickyGroupSeparators: true,
      elements: practicesToDisplay,
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
      isInWaitingList: false,
      isHistory: true,
      database: database,
      managerView: widget.isManagerView,
      data: practice,
      registerCallback: () {},
      waitingListCallback: () {},
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

  List<Practice> _practicesToDisplay(List<Practice> allPractices) {
    final userToDisplay = widget.userToDisplay;
    if (userToDisplay == null) return allPractices;
    return allPractices
        .where((practice) => practice.isUserRegistered(userToDisplay.uid))
        .toList();
  }

  List<Practice> _getPractices(Map<String, List<Practice>> monthsToPractices) {
    final result = <Practice>[];
    monthsToPractices.forEach((key, list) {
      if (list.isNotEmpty) {
        result.addAll(list);
      }
    });
    return result;
  }
}
