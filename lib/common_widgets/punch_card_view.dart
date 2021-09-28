import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:yoga_house/Services/utils_file.dart';
import 'package:yoga_house/common_widgets/punch_card.dart';

class PunchcardView extends StatelessWidget {
  final Punchcard punchcard;
  final bool isManagerView;
  final Function decrementCallback;
  final Function incrementCallback;
  const PunchcardView(
      {Key? key,
      required this.punchcard,
      required this.isManagerView,
      required this.decrementCallback,
      required this.incrementCallback})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    final total = punchcard.punchesPurchased;
    final remaining = punchcard.punchesRemaining;
    final purchasedOn =
        Utils.numericDayMonthYearFromDateTime(punchcard.purchasedOn);
    final expiresOn =
        Utils.numericDayMonthYearFromDateTime(punchcard.expiresOn);
    return SizedBox(
      width: double.infinity,
      child: Card(
        child: Column(
          children: [
            Text('הכרטיסיה שלי',
                textAlign: TextAlign.center, style: theme.textTheme.bodyText1),
            ListTile(
              leading: Icon(Icons.calendar_today_outlined, color: color),
              title: Text('נרכשה ב: $purchasedOn'),
            ),
            ListTile(
              leading: Icon(Icons.calendar_today_outlined, color: color),
              title: Text('בתוקף עד $expiresOn'),
            ),
            ListTile(
              leading: Icon(FontAwesomeIcons.hashtag, color: color),
              title: Text('ניקובים שנרכשו בכרטיסיה זו: $total'),
            ),
            ListTile(
              leading: Icon(FontAwesomeIcons.hashtag, color: color),
              title: isManagerView
                  ? _managerRow(context)
                  : Text('ניקובים שנשארו: $remaining'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _managerRow(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    final remaining = punchcard.punchesRemaining;

    return Row(
      children: [
        Text('ניקובים שנשארו: $remaining'),
        const Spacer(),
        IconButton(
          padding: const EdgeInsets.all(1),
          icon: const Icon(Icons.remove_circle_outline),
          color: color,
          onPressed: () async {
            final didApprove = await showOkCancelAlertDialog(
                isDestructiveAction: true,
                context: context,
                title: 'הפחתת ניקוב',
                message: 'האם להפחית ניקוב אחד מכרטיסיה זו?',
                okLabel: 'אשר',
                cancelLabel: 'בטל');
            if (didApprove == OkCancelResult.ok) decrementCallback();
          },
        ),
        IconButton(
          padding: const EdgeInsets.all(1),
          icon: const Icon(Icons.add_circle_outline),
          color: color,
          onPressed: () async {
            final didApprove = await showOkCancelAlertDialog(
                context: context,
                title: 'הוספת ניקוב',
                message: 'האם להוסיף ניקוב אחד לכרטיסיה זו?',
                okLabel: 'אשר',
                cancelLabel: 'בטל');
            if (didApprove == OkCancelResult.ok) incrementCallback();
          },
        ),
      ],
    );
  }
}
