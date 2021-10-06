import 'package:flutter/material.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:persistent_bottom_nav_bar/persistent-tab-view.dart';
import 'package:provider/provider.dart';
import 'package:yoga_house/Practice/practice.dart';
import 'package:yoga_house/Practice/practice_card.dart';
import 'package:yoga_house/Services/app_info.dart';
import 'package:yoga_house/Services/database.dart';
import 'package:yoga_house/Services/utils_file.dart';
import 'package:intl/intl.dart';
import 'package:yoga_house/User_Info/user_info.dart';

class RegisterToPracticeScreen extends StatefulWidget {
  final bool managerView;
  const RegisterToPracticeScreen({Key? key, required this.managerView})
      : super(key: key);

  static Future<void> pushToTabBar(
      BuildContext context, bool managerView) async {
    await pushNewScreen(
      context,
      // ignore: prefer_const_constructors
      screen: RegisterToPracticeScreen(managerView: managerView),
    );
  }

  @override
  _RegisterToPracticeScreenState createState() =>
      _RegisterToPracticeScreenState();
}

class _RegisterToPracticeScreenState extends State<RegisterToPracticeScreen> {
  Widget get _noPracticesWidget =>
      const Center(child: Text('אין שיעורים זמינים'));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Utils.appBarTitle(context,
              widget.managerView ? 'שיעורים עתידיים' : 'רישום לשיעור')),
      body: _practiceCardsListView(),
    );
  }

  Widget _practiceCardsListView() {
    final allPractices = context.watch<List<Practice>>();
    final futurePractices = allPractices
        .where((practice) => practice.startTime.isAfter(DateTime.now()))
        .toList();
    if (futurePractices.isEmpty) return _noPracticesWidget;
    return GroupedListView<Practice, String>(
      shrinkWrap: true,
      useStickyGroupSeparators: true,
      elements: futurePractices,
      groupBy: _groupBy,
      groupSeparatorBuilder: _groupSeparatorBuilder,
      itemBuilder: _itemBuilder,
      itemComparator: _utemComparator,
      groupComparator: _groupComparator,
    );
  }

  Widget _itemBuilder(BuildContext listContext, Practice practice) {
    final appInfo = context.read<AppInfo>();
    final userInfo = context.read<UserInfo>();
    final database = context.read<FirestoreDatabase>();
    return PracticeCard(
      isInWaitingList: practice.isInWaitingList(userInfo),
      isHistory: false,
      database: database,
      managerView: widget.managerView,
      data: practice,
      registerCallback:
          practice.registerToPracticeCallback(userInfo, database, context),
      waitingListCallback: () {
        _waitingListCallback(practice, userInfo, database);
      },
      isRegistered: practice.isUserRegistered(userInfo.uid),
      unregisterCallback: practice.unregisterFromPracticeCallback(
          userInfo, database, context, appInfo),
    );
  }

  int _utemComparator(first, second) =>
      first.startTime.compareTo(second.startTime);

  String _groupBy(practice) =>
      Utils.numericDayMonthYearFromDateTime(practice.startTime);

  int _groupComparator(str1, str2) => DateFormat.yMd('he_IL')
      .parse(str1)
      .compareTo(DateFormat.yMd('he_IL').parse(str2));

  Widget _groupSeparatorBuilder(String groupByValue) {
    final theme = Theme.of(context);
    final dateTime = DateFormat.yMd('he_IL').parse(groupByValue);
    final verbouseDay = Utils.vebouseDayFromDateTime(dateTime);
    return Text('$verbouseDay, $groupByValue',
        style: theme.textTheme.bodyText1!.copyWith(fontSize: 18),
        textAlign: TextAlign.center);
  }

  _waitingListCallback(
      Practice practice, UserInfo userInfo, FirestoreDatabase database) {
    if (practice.isInWaitingList(userInfo)) {
      print('in waiting list');
      practice.leaveWaitingList(database, userInfo);
    } else {
      print('not in waiting list');
      practice.joinWaitingList(database, userInfo, context);
    }
  }
}
