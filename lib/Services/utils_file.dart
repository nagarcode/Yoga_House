import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';
import 'package:yoga_house/common_widgets/card_selection_tile.dart';

import 'auth.dart';

class Utils {
  static bool connectionStateInvalid(AsyncSnapshot snapshot) {
    return (snapshot.connectionState != ConnectionState.active &&
        snapshot.connectionState != ConnectionState.done);
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

  static Widget bottomSheetFormBuilder(
      BuildContext outerContext,
      List<Widget> inputFields,
      String confirmText,
      void Function() onConfirmed,
      BuildContext innerCtx,
      TextStyle style,
      formKey,
      String title) {
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

  static String idFromTime() => DateTime.now().toIso8601String();
}
