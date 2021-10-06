import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:provider/provider.dart';
import 'package:yoga_house/Client/health_assurance_screen.dart';
import 'package:yoga_house/Client/register_to_practice_screen.dart';
import 'package:yoga_house/Practice/practice.dart';
import 'package:yoga_house/Practice/practice_card.dart';
import 'package:yoga_house/Services/api_path.dart';
import 'package:yoga_house/Services/app_info.dart';
import 'package:yoga_house/Services/auth.dart';
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
              if (widget.practicesRegisteredTo.isNotEmpty) _practicesText,
              if (widget.practicesRegisteredTo.isNotEmpty)
                _practiceCardsListView(),
              userInfo.didSubmitHealthAssurance
                  ? SizedBox(height: 60, child: _registerToPracticeButton)
                  : _haColumn(userInfo, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget get _registerToPracticeButton => Container(
        padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 8),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
          ),
          child: const Text(
            'רישום לשיעור',
            style: TextStyle(fontSize: 20),
          ),
          onPressed: () async {
            await RegisterToPracticeScreen.pushToTabBar(context, false);
          },
        ),
      );

  Widget _logo() {
    return SizedBox(
        height: 140,
        width: 50,
        child: Image.asset(
          APIPath.logo(),
          fit: BoxFit.cover,
        ));
  }

  void _signOut() async {
    final auth = context.read<AuthBase>();
    final didRequestLeave = await showOkCancelAlertDialog(
        context: context,
        isDestructiveAction: true,
        okLabel: 'התנתק',
        cancelLabel: 'ביטול',
        title: 'התנתקות',
        message: 'האם להתנתק מהמערכת?');
    if (didRequestLeave == OkCancelResult.ok) auth.signOut();
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

  // ListView _registeredPracticesListView() {
  //   return ListView(
  //     shrinkWrap: true,
  //     children: _practiceCards(),
  //   );
  // }

  // List<PracticeCard> _practiceCards() {
  //   final userInfo = context.read<UserInfo>();
  //   final cards = <PracticeCard>[];
  //   for (var practice in widget.practicesRegisteredTo) {
  //     cards.add(
  //       PracticeCard(
  //           data: practice,
  //           registerCallback: practice.registerToPracticeCallback(
  //               userInfo, widget.database, context),
  //           waitingListCallback: () {},
  //           isRegistered: true,
  //           unregisterCallback: practice.unregisterFromPracticeCallback(
  //               userInfo, widget.database, context)), //TODO change
  //     );
  //   }
  //   return cards;
  // }

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
          userInfo, widget.database, context),
      waitingListCallback: () => {},
      isRegistered: practice.isUserRegistered(userInfo.uid),
      unregisterCallback: practice.unregisterFromPracticeCallback(
          userInfo, widget.database, context, widget.appInfo),
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

  Widget _haColumn(UserInfo userInfo, ThemeData theme) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      children: [
        Center(
            child: Text('על מנת להירשם לשיעורים חובה למלא תחילה הצהרת בריאות.',
                style: theme.textTheme.bodyText1)),
        SizedBox(height: 60, child: _haButton(userInfo, theme)),
      ],
    );
  }

  _haButton(UserInfo userInfo, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 8),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
        ),
        child: const Text(
          'מלא הצהרת בריאות',
          style: TextStyle(fontSize: 20),
        ),
        onPressed: () async {
          await HealthAssuranceScreen.pushToTabBar(context, userInfo);
        },
      ),
    );
  }
}
