import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:yoga_house/Practice/repeateng_practice.dart';
import 'package:yoga_house/Services/database.dart';
import 'package:yoga_house/User_Info/user_info.dart';
import 'package:provider/provider.dart';
import 'package:yoga_house/common_widgets/punch_card.dart';

class RepeatingPracticeCard extends StatefulWidget {
  final RepeatingPractice data;
  final Function deleteTemplateCallback;
  final UserInfo? userToAdd;
  final bool selectionScreen;
  final Function(RepeatingPractice)? onClicked;
  final BuildContext? ctxt;

  const RepeatingPracticeCard(
    this.data,
    this.deleteTemplateCallback, {
    Key? key,
    this.userToAdd,
    this.selectionScreen = false,
    this.onClicked,
    this.ctxt,
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

    return ListTile(
      title: Column(
        children: [
          Text(
            widget.data.nickname,
            style: const TextStyle(color: Color.fromARGB(255, 193, 110, 207)),
          ),
          Text(widget.data.name),
        ],
      ),
      onTap: expandCard,
      subtitle: Column(
        children: [
          Text(text),
          if (expand) _usersList(),
        ],
      ),
      trailing: _deleteOrChooseButton(),
    );
  }

  Widget _deleteOrChooseButton() {
    if (widget.selectionScreen || widget.userToAdd != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(onPressed: _selectOnClick, child: const Text('בחר')),
        ],
      );
    } else {
      return IconButton(
        icon: const Icon(Icons.delete_forever_outlined),
        onPressed: () => widget.deleteTemplateCallback(widget.data),
      );
    }
  }

  _selectOnClick() {
    widget.userToAdd != null
        ? addUserToPractice()
        : widget.onClicked!(widget.data);
  }

  // void tileOnclick() {
  //   widget.userToAdd == null ? expandCard() : verifyAndAddUser();
  // }

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
    if (!expand) expandCard();
    return true;
  }

  _usersList() {
    final useContext = widget.ctxt ?? context;
    final database = useContext.read<FirestoreDatabase>();
    final theme = Theme.of(useContext);
    final users = widget.data.registeredParticipants;
    const registeredText = Text('רשומים:');
    if (users.isEmpty) {
      return const Text('טרם רשמת מתאמנים לשיעור קבוע זה');
    }
    final rows = <Widget>[registeredText];
    _generateUserTiles(users, theme, database, rows);
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      children: rows,
    );
  }

  List<Widget> _generateUserTiles(List<UserInfo> users, ThemeData theme,
      FirestoreDatabase database, List<Widget> rows) {
    for (var user in users) {
      final tile = ListTile(
        dense: true,
        title: Text('- ' + user.name,
            style: theme.textTheme.subtitle1!.copyWith(fontSize: 13)),
        subtitle: _punchesLeft(user.punchcard),
        trailing: TextButton(
            onPressed: () => _removeUSerOnClick(user, database),
            child: const Text('הסר')),
      );
      rows.add(tile);
    }
    return rows;
  }

  _removeUSerOnClick(UserInfo user, FirestoreDatabase database) async {
    if (await promtRemoveUser(user.name)) {
      database.removeUserFromRepeatingPractice(user, widget.data);
      await showConfirmation('הצלחה', 'ההסרה התבצעה בהצלחה');
    }
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

  _punchesLeft(Punchcard? punchcard) {
    final remaining = punchcard != null ? punchcard.punchesRemaining : 0;
    return Text('ניקובים שנותרו: ${remaining}');
  }
}
