import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:whatsapp_unilink/whatsapp_unilink.dart';
import 'package:yoga_house/common_widgets/card_selection_tile.dart';
import 'package:intl/intl.dart';
import 'auth.dart';

class Utils {
  static bool connectionStateInvalid(AsyncSnapshot snapshot) {
    return (snapshot.connectionState != ConnectionState.active &&
        snapshot.connectionState != ConnectionState.done);
  }

  static String heartEmoji() => '♡';

  static bool isSameDate(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  static void signOut(BuildContext context) async {
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

  static Text appBarTitle(BuildContext context, String title) {
    // final theme = Theme.of(context);
    return Text(
      title,
      style: const TextStyle(fontSize: 20, color: Colors.white),
    );
  }

  static Widget cardSelectionDialog(
      BuildContext context, List<CardSelectionTile> tiles) {
    return Center(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          children: tiles,
        ),
      ),
    );
  }

  static Card bottomModalSheetCard(Widget child) {
    return Card(
        color: Colors.grey[200],
        margin: const EdgeInsets.all(8),
        elevation: 0,
        child: child);
  }

  static String stripPhonePrefix(String str) {
    if (str.length > 4) {
      return '0${str.substring(4)}';
    } else {
      return str;
    }
  }

  static Widget bottomSheetFormBuilder(
      {required List<Widget> inputFields,
      required String confirmText,
      required void Function() onConfirmed,
      required BuildContext innerCtx,
      required TextStyle style,
      required Key formKey,
      required String title}) {
    return CupertinoActionSheet(
      title: Text(title),
      actions: [
        Utils.bottomModalSheetCard(
          FormBuilder(
            key: formKey,
            child: Column(
              children: inputFields,
            ),
          ),
        )
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: onConfirmed,
        child: Text(
          confirmText,
          style: style,
        ),
      ),
    );
  }

  static launchWhatsapp(String phoneWithPrefix) async {
    final link = WhatsAppUnilink(phoneNumber: phoneWithPrefix);
    await launch('$link');
  }

  static void call(String phoneNoPrefix, BuildContext context) async {
    final url = 'tel://' + phoneNoPrefix;
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      _showCantLaunchDialog('לא ניתן לבצע את הפעולה', context);
    }
  }

  static _showCantLaunchDialog(String msg, BuildContext context) async {
    await showOkAlertDialog(
      context: context,
      title: 'שגיאה',
      message: msg,
      okLabel: 'אישור',
    );
  }

  static void launchInstagram(String url, BuildContext context) async {
    await canLaunch(url)
        ? await launch(url)
        : _showCantLaunchDialog('לא ניתן לבצע את הפעולה', context);
  }

  static String yuvishPhoneNoPrefix() => '0526424442';

  static String adminInstagramUrl() => 'https://instagram.com/yuval.giat';

  static String idFromTime() => DateTime.now().toIso8601String();

  static String idFromPastTime(DateTime time) => time.toIso8601String();

  //DateTime
  static String numericDayMonthYearFromDateTime(DateTime dateTime) =>
      DateFormat.yMd('he_IL').format(dateTime);

  static String vebouseDayFromDateTime(DateTime dateTime) =>
      DateFormat.E('he_IL').format(dateTime);

  static String hourFromDateTime(DateTime dateTime) =>
      DateFormat.Hm().format(dateTime);

  static String hebrewMonthYear(DateTime date) =>
      DateFormat.yMMMM('he_IL').format(date);

  static String numericMonthYear(DateTime date) =>
      DateFormat.yMMM().format(date);

  static String hebNumericMonthYear(DateTime date) =>
      DateFormat.yMMM('he_IL').format(date);

  static String appOneLink() => 'http://onelink.to/yoga_house';
}
