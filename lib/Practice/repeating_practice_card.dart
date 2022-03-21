import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:yoga_house/Practice/repeateng_practice.dart';
import 'package:yoga_house/Services/database.dart';
import 'package:yoga_house/User_Info/user_info.dart';
import 'package:provider/provider.dart';

class RepeatingPracticeCard extends StatefulWidget {
  final RepeatingPractice data;
  final Function deleteTemplateCallback;
  final UserInfo? userToAdd;

  const RepeatingPracticeCard(
    this.data,
    this.deleteTemplateCallback, {
    Key? key,
    this.userToAdd,
  }) : super(key: key);

  @override
  State<RepeatingPracticeCard> createState() => _RepeatingPracticeCardState();
}

class _RepeatingPracticeCardState extends State<RepeatingPracticeCard> {
  bool expand = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: _buildCard(context),
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    final text =
        'רמה: ${widget.data.level}\nמיקום: ${widget.data.location}\nמשך: ${widget.data.durationMinutes} דקות\nמספר משתתפים מקסימלי: ${widget.data.maxParticipants}\nתאור: ${widget.data.description}';
    if (widget.userToAdd == null) {
      return ListTile(
        title: Text(widget.data.name),
        onTap: () => tileOnclick(),
        subtitle: Column(
          children: [
            Text(text),
            if (expand) _usersList(),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_forever_outlined),
          onPressed: () => widget.deleteTemplateCallback(widget.data),
        ),
      );
    } else {
      return ListTile(
        title: Text(widget.data.name),
        onTap: () => tileOnclick(),
        subtitle: Column(
          children: [
            Text(text),
            if (expand) _usersList(),
          ],
        ),
      );
    }
  }

  void tileOnclick() {
    widget.userToAdd == null ? expandCard() : verifyAndAddUser();
  }

  expandCard() {
    setState(() {
      expand = !expand;
    });
  }

  addUserToPractice() async {
    if (widget.data.registeredParticipants.length >=
        widget.data.maxParticipants) {
      await displayTooManyRegisteredError();
      return false;
    }
    final database = context.read<FirestoreDatabase>();
    await database.addUserToRepeatingPractice(widget.userToAdd, widget.data);
    return true;
  }

  _usersList() {
    final database = context.read<FirestoreDatabase>();
    final theme = Theme.of(context);
    final users = widget.data.registeredParticipants;
    const registeredText = Text('רשומים:');
    final rows = <Widget>[registeredText];
    if (users.isEmpty) {
      return const Text('טרם רשמת מתאמנים לשיעור קבוע זה');
    }
    for (var user in users) {
      final tile = ListTile(
        dense: true,
        title: Text('- ' + user.name,
            style: theme.textTheme.subtitle1!.copyWith(fontSize: 13)),
        onTap: () async {
          if (await promtRemoveUser(user.name)) {
            database.removeUserFromRepeatingPractice(user, widget.data);
            await showConfirmation('הצלחה', 'ההסרה התבצעה בהצלחה');
          }
        },
      );
      rows.add(tile);
    }
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      children: rows,
    );
  }

  promtAddUserToPractice() async {
    final name = widget.userToAdd?.name ?? 'שגיאה';
    final text = 'האם להוסיף את $name לשיעור קבוע זה?';
    final ans = await showOkCancelAlertDialog(
      context: context,
      title: 'הוסף לשיעור קבוע',
      message: text,
    );
    return ans == OkCancelResult.ok;
  }

  promtRemoveUser(String name) async {
    final text = 'האם להסיר את $name משיעור קבוע זה?';
    final ans = await showOkCancelAlertDialog(
        context: context,
        title: 'הסר משיעור קבוע',
        message: text,
        isDestructiveAction: true,
        okLabel: 'הסר');
    return ans == OkCancelResult.ok;
  }

  verifyAndAddUser() async {
    if (userAlreadyRegistered()) {
      displayAlreadyRegistered();
      return;
    }
    if (await promtAddUserToPractice()) {
      if (await addUserToPractice()) {
        await showConfirmation('הצלחה', 'ההוספה התבצעה בהצלחה');
      }
      Navigator.of(context).pop();
    }
  }

  showConfirmation(String title, String txt) async {
    await showOkAlertDialog(
      context: context,
      title: title,
      message: txt,
    );
  }

  displayTooManyRegisteredError() async {
    await showOkAlertDialog(
      context: context,
      title: 'שגיאה',
      message:
          'מספר המתאמנים שרשמת לשיעור קבוע זה עולה על מספר המתאמנים המקסימלי שהגדרת לאימון.',
    );
  }

  bool userAlreadyRegistered() {
    return widget.data.registeredParticipants
        .any((element) => element.uid == widget.userToAdd!.uid);
  }

  void displayAlreadyRegistered() async {
    await showOkAlertDialog(
      context: context,
      title: 'שגיאה',
      message: 'מתאמן זה כבר שייך לרשימת המתאמנים באימון קבוע זה.',
    );
  }
}
