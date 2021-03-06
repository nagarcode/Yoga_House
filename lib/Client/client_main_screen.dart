import 'package:flutter/material.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:provider/provider.dart';
import 'package:yoga_house/Client/contact_button_grid.dart';
import 'package:yoga_house/Client/health_assurance_screen.dart';
import 'package:yoga_house/Client/register_to_practice_screen.dart';
import 'package:yoga_house/Practice/practice.dart';
import 'package:yoga_house/Practice/practice_card.dart';
import 'package:yoga_house/Services/api_path.dart';
import 'package:yoga_house/Services/app_info.dart';
import 'package:yoga_house/Services/database.dart';
import 'package:yoga_house/Services/utils_file.dart';
import 'package:yoga_house/User_Info/user_info.dart';
import 'package:intl/intl.dart';

class ClientMainScreen extends StatefulWidget {
  final List<Practice> practicesRegisteredTo;
  final AppInfo appInfo;
  final FirestoreDatabase database;
  const ClientMainScreen(
      {Key? key,
      required this.appInfo,
      required this.practicesRegisteredTo,
      required this.database})
      : super(key: key);

  @override
  _ClientMainScreenState createState() => _ClientMainScreenState();
}

class _ClientMainScreenState extends State<ClientMainScreen> {
  get _practicesText => const Text('השיעורים שלי', textAlign: TextAlign.center);

  @override
  Widget build(BuildContext context) {
    final userInfo = context.read<UserInfo>();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Utils.appBarTitle(context, 'יוגה  האוס'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _logo(),
              _homepageText(theme, widget.appInfo),
              const Divider(),
              if (widget.practicesRegisteredTo.isNotEmpty) _practicesText,
              if (widget.practicesRegisteredTo.isNotEmpty)
                _practiceCardsListView(),
              userInfo.didSubmitHealthAssurance
                  ? SizedBox(height: 55, child: _registerToPracticeButton)
                  : _haColumn(userInfo, theme),
              const SizedBox(
                height: 400,
                child: ContactButtonGreed(),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget get _registerToPracticeButton {
    final userInfo = context.read<UserInfo>();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 105, vertical: 8),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
        ),
        child: const Text(
          'רישום לשיעור',
          style: TextStyle(fontSize: 16),
        ),
        onPressed: () async {
          await RegisterToPracticeScreen.pushToTabBar(context, false, userInfo);
        },
      ),
    );
  }

  Widget _logo() {
    return SizedBox(
        height: 230,
        // width: 50,
        child: Image.asset(
          APIPath.logo(),
          fit: BoxFit.cover,
        ));
  }

  _homepageText(ThemeData theme, AppInfo appInfo) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8.0),
      child: Center(
        child: Text(
          appInfo.homepageText,
          textAlign: TextAlign.center,
          style: theme.textTheme.headline6,
        ),
      ),
    );
  }

  Widget _practiceCardsListView() {
    return GroupedListView<Practice, String>(
      shrinkWrap: true,
      useStickyGroupSeparators: true,
      elements: widget.practicesRegisteredTo,
      groupBy: _groupBy,
      groupSeparatorBuilder: _groupSeparatorBuilder,
      itemBuilder: _itemBuilder,
      itemComparator: _utemComparator,
      groupComparator: _groupComparator,
    );
  }

  Widget _itemBuilder(BuildContext listContext, Practice practice) {
    final userInfo = context.read<UserInfo>();
    final database = context.read<FirestoreDatabase>();
    return PracticeCard(
      isInWaitingList: practice.isInWaitingList(userInfo),
      isHistory: false,
      database: database,
      managerView: false,
      data: practice,
      registerCallback: practice.registerToPracticeCallback(
          userInfo, widget.database, context, false),
      waitingListCallback: () => {},
      isRegistered: practice.isUserRegistered(userInfo.uid),
      unregisterCallback: practice.unregisterFromPracticeCallback(
          userInfo, widget.database, context, widget.appInfo, false),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 90),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Text('$verbouseDay, $groupByValue',
            style: theme.textTheme.bodyText2!
                .copyWith(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
      ),
    );
  }

  Widget _haColumn(UserInfo userInfo, ThemeData theme) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      children: [
        Center(
            child: Text('על מנת להירשם לשיעורים חובה למלא תחילה הצהרת בריאות.',
                style: theme.textTheme.bodyText1)),
        SizedBox(height: 55, child: _haButton(userInfo, theme)),
      ],
    );
  }

  _haButton(UserInfo userInfo, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 8),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
        ),
        child: const Text(
          'מלא הצהרת בריאות',
          style: TextStyle(fontSize: 16),
        ),
        onPressed: () async {
          await HealthAssuranceScreen.pushToTabBar(context, userInfo);
        },
      ),
    );
  }
}
