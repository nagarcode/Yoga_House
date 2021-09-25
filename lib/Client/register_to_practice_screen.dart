import 'package:flutter/material.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:persistent_bottom_nav_bar/persistent-tab-view.dart';
import 'package:provider/provider.dart';
import 'package:yoga_house/Practice/practice.dart';
import 'package:yoga_house/Practice/practice_card.dart';
import 'package:yoga_house/Services/database.dart';
import 'package:yoga_house/Services/utils_file.dart';
import 'package:intl/intl.dart';
import 'package:yoga_house/User_Info/user_info.dart';

class RegisterToPracticeScreen extends StatefulWidget {
  final List<Practice> futurePractices;
  final FirestoreDatabase database;
  const RegisterToPracticeScreen(
      {Key? key, required this.futurePractices, required this.database})
      : super(key: key);

  static Future<void> pushToTabBar(BuildContext context) async {
    final futurePractices = context.read<List<Practice>>();
    final database = context.read<FirestoreDatabase>();
    // final sharedPrefs = context.read<SharedPrefs>();
    await pushNewScreen(
      context,
      screen: RegisterToPracticeScreen(
        futurePractices: futurePractices,
        database: database,
      ),
    );
  }

  @override
  _RegisterToPracticeScreenState createState() =>
      _RegisterToPracticeScreenState();
}

class _RegisterToPracticeScreenState extends State<RegisterToPracticeScreen> {
  Widget get _noPracticesWidget =>
      const Center(child: Text('אין אימונים זמינים'));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Utils.appBarTitle(context, 'רישום לתרגול')),
      body: _practiceCardsListView(),
    );
  }

  // List<PracticeCard> _practiceCards() {
  //   final userInfo = context.read<UserInfo>();
  //   final cards = <PracticeCard>[];
  //   for (var practice in widget.futurePractices) {
  //     cards.add(PracticeCard(
  //       data: practice,
  //       registerCallback: practice.registerToPracticeCallback(
  //           userInfo, widget.database, context),
  //       waitingListCallback: () {}, //TODO change
  //     ));
  //   }
  //   return cards;
  // }

  Widget _practiceCardsListView() {
    if (widget.futurePractices.isEmpty) return _noPracticesWidget;
    return GroupedListView<Practice, String>(
      // padding: const EdgeInsets.only(top: 4),
      shrinkWrap: true,
      useStickyGroupSeparators: true,
      elements: widget.futurePractices,
      groupBy: _groupBy,
      groupSeparatorBuilder: _groupSeparatorBuilder,
      itemBuilder: _itemBuilder,
      itemComparator: _utemComparator,
      groupComparator: _groupComparator,
    );
  }

  Widget _itemBuilder(BuildContext listContext, Practice practice) {
    final userInfo = context.read<UserInfo>();
    return PracticeCard(
      data: practice,
      registerCallback: practice.registerToPracticeCallback(
          userInfo, widget.database, context),
      waitingListCallback: () {}, //TODO change
      isRegistered: practice.isUserRegistered(userInfo.uid),
      unregisterCallback: practice.unregisterFromPracticeCallback(
          userInfo, widget.database, context),
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
}
