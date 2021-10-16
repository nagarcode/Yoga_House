import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yoga_house/Practice/edit_practice_form.dart';
import 'package:yoga_house/Services/app_info.dart';
import 'package:yoga_house/Services/database.dart';
import 'package:yoga_house/Services/notifications.dart';
import 'package:yoga_house/Services/utils_file.dart';
import 'package:yoga_house/User_Info/user_info.dart';
import 'package:yoga_house/common_widgets/card_selection_tile.dart';

class Practice {
  final String id;
  final String name;
  final String level;
  final String managerName;
  final String managerUID;
  final String description;
  final String location;
  final DateTime startTime;
  final DateTime endTime;
  final int maxParticipants;
  final List<UserInfo> registeredParticipants;
  final int numOfUsersInWaitingList;
  final List<UserInfo> waitingList;

  int get numOfRegisteredParticipants => registeredParticipants.length;

  Practice(
    this.id,
    this.name,
    this.level,
    this.managerName,
    this.managerUID,
    this.description,
    this.location,
    this.startTime,
    this.endTime,
    this.maxParticipants,
    this.registeredParticipants,
    this.numOfUsersInWaitingList,
    this.waitingList,
  );
  factory Practice.fromMap(Map<String, dynamic> data) {
    List<UserInfo> registered = _extractRegisteredUsers(data);
    List<UserInfo> waitingList = _extractWaitingListUsers(data);

    return Practice(
      data['id'],
      data['name'],
      data['level'],
      data['managerName'],
      data['managerUID'],
      data['description'],
      data['location'],
      data['startTime'].toDate(),
      data['endTime'].toDate(),
      data['maxParticipants'],
      registered,
      data['numOfUsersInWaitingList'],
      waitingList,
    );
  }

  static List<UserInfo> _extractRegisteredUsers(Map<String, dynamic> data) {
    final List<UserInfo> registered = [];
    final usersMap = data['registeredParticipants'];
    if (usersMap.isNotEmpty) {
      for (var key in usersMap.keys) {
        final data = usersMap[key];
        if (data == null) break;
        registered.add(UserInfo.fromMap(data));
      }
    }
    return registered;
  }

  static List<UserInfo> _extractWaitingListUsers(Map<String, dynamic> data) {
    final List<UserInfo> waiting = [];
    final usersMap = data['waitingList'];
    if (usersMap.isNotEmpty) {
      for (var key in usersMap.keys) {
        final data = usersMap[key];
        if (data == null) break;
        waiting.add(UserInfo.fromMap(data));
      }
    }
    return waiting;
  }

  Map<String, dynamic> toMap() {
    final Map<String, Map<String, dynamic>> registeredParticipants =
        _mapRegisteredUsers();
    final Map<String, dynamic> waitingList = _mapWaitingList();
    return {
      'id': id,
      'name': name,
      'level': level,
      'managerName': managerName,
      'managerUID': managerUID,
      'description': description,
      'location': location,
      'startTime': startTime,
      'endTime': endTime,
      'maxParticipants': maxParticipants,
      'numOfUsersInWaitingList': numOfUsersInWaitingList,
      'numOfRegisteredParticipants': numOfRegisteredParticipants,
      'registeredParticipants': registeredParticipants,
      'waitingList': waitingList,
    };
  }

  Map<String, Map<String, dynamic>> _mapRegisteredUsers() {
    final Map<String, Map<String, dynamic>> toReturn = {};
    if (registeredParticipants.isEmpty) return toReturn;
    for (var userInfo in registeredParticipants) {
      toReturn[userInfo.uid] = userInfo.toMap();
    }
    return toReturn;
  }

  Map<String, Map<String, dynamic>> _mapWaitingList() {
    final Map<String, Map<String, dynamic>> toReturn = {};
    if (waitingList.isEmpty) return toReturn;
    for (var userInfo in waitingList) {
      toReturn[userInfo.uid] = userInfo.toMap();
    }
    return toReturn;
  }

  Practice copyWith({
    String? id,
    String? name,
    String? level,
    String? managerName,
    String? managerUID,
    String? description,
    String? location,
    DateTime? startTime,
    DateTime? endTime,
    int? maxParticipants,
    List<UserInfo>? registeredParticipants,
    int? numOfUsersInWaitingList,
    int? numOfRegisteredParticipants,
    List<UserInfo>? waitingList,
  }) {
    return Practice(
      id ?? this.id,
      name ?? this.name,
      level ?? this.level,
      managerName ?? this.managerName,
      managerUID ?? this.managerUID,
      description ?? this.description,
      location ?? this.location,
      startTime ?? this.startTime,
      endTime ?? this.endTime,
      maxParticipants ?? this.maxParticipants,
      registeredParticipants ?? this.registeredParticipants,
      numOfUsersInWaitingList ?? this.numOfUsersInWaitingList,
      waitingList ?? this.waitingList,
    );
  }

  Function registerToPracticeCallback(
      UserInfo userInfo,
      FirestoreDatabase database,
      BuildContext screenContext,
      bool isManagerView) {
    final notifications = screenContext.read<NotificationService>();
    // final appInfo = screenContext.read<AppInfo>();
    return () async {
      try {
        if (!userInfo.hasPunchcard) {
          await _showNoPunchcardDialog(screenContext);
          return;
        }
        if (!userInfo.hasPunchesLeft) {
          await _showNoPunchesLeftDialog(screenContext);
          return;
        }
        final didRequestRegister =
            await _promtRegistrationConfirmation(screenContext);
        if (didRequestRegister) {
          database.registerUserToPracticeTransaction(userInfo, id);
          if (!isManagerView) {
            notifications.setPracticeLocalNotification(this, 24);
          }
          if (isManagerView) {
            notifications.sendManagerRegisteredYouNotification(userInfo, this);
          }
        }
      } on Exception catch (_) {
        await showOkAlertDialog(
            context: screenContext,
            message: 'בעיית חיבור לאינטרט. אנא נסה שוב.',
            okLabel: 'אישור');
      }
    };
  }

  Function unregisterFromPracticeCallback(
      UserInfo userInfo,
      FirestoreDatabase database,
      BuildContext screenContext,
      AppInfo appInfo,
      bool isManagerView) {
    return () async {
      final notifications = screenContext.read<NotificationService>();

      try {
        final didRequestUnregister =
            await _promtUnregisterConfirmation(screenContext);
        if (didRequestUnregister) {
          bool shouldRestorePunch = isEnoughTimeLeftToCancel(appInfo);
          database.unregisterFromPracticeTransaction(
              userInfo, this, shouldRestorePunch, appInfo);
          if (isManagerView) {
            notifications.sendManagerUnregisteredYouNotification(
                userInfo, this);
          }
          if (!isManagerView) {
            notifications.cancelPracticeLocalNotification(this);
          }
        }
      } on Exception catch (_) {
        await showOkAlertDialog(
            context: screenContext,
            message: 'בעיית חיבור לאינטרט. אנא נסה שוב.',
            okLabel: 'אישור');
      }
    };
  }

  bool isFull() {
    return numOfRegisteredParticipants >= maxParticipants;
  }

  Future<bool> _promtRegistrationConfirmation(
      BuildContext screenContext) async {
    final appInfo = screenContext.read<AppInfo>();
    final minHours = appInfo.minHoursToCancel;
    final numericDate = Utils.numericDayMonthYearFromDateTime(startTime);
    final hour = Utils.hourFromDateTime(startTime);
    const firstLine = 'נותר רק לאשר את הפרטים הבאים והרישום יושלם :)';
    final secondLine =
        '-ברצוני להירשם לשיעור $name בתאריך $numericDate בשעה $hour.';
    final thirdLine =
        '-חשוב! ביטול ללא ניקוב יתאפשר לכל היותר $minHours שעות לפני מועד השיעור.';
    const fourthLine = '- אנא להגיע 5 דקות לפני תחילת השיעור על מנת להתמקם.';
    final registerText = '$firstLine\n$secondLine\n$thirdLine\n$fourthLine';
    final ans = await showOkCancelAlertDialog(
      context: screenContext,
      title: 'אישור רישום',
      message: registerText,
    );
    return ans == OkCancelResult.ok;
  }

  Future<bool> _promtUnregisterConfirmation(BuildContext screenContext) async {
    final appInfo = screenContext.read<AppInfo>();
    final minHours = appInfo.minHoursToCancel;
    final notEnoughTimeText =
        'חשוב לשים לב! שיעור זה יתקיים בעוד פחות מ$minHours שעות ולכן במידה ותבטל את רישומך לא יוחזר לך הניקוב לכרטיסיה. האם לבטל בכל זאת?';
    const enoughTimeText =
        'איזה כיף שביטלת את הרישום בזמן! ביטול זה הוא ללא חיוב. האם לבטל את הרישום?';
    final ans = await showOkCancelAlertDialog(
      isDestructiveAction: true,
      context: screenContext,
      title: 'ביטול רישום',
      message: isEnoughTimeLeftToCancel(appInfo)
          ? enoughTimeText
          : notEnoughTimeText,
    );
    return ans == OkCancelResult.ok;
  }

  bool isUserRegistered(String uid) {
    return registeredParticipants
        .any((registeredUser) => registeredUser.uid == uid);
  }

  bool isEnoughTimeLeftToCancel(AppInfo appInfo) {
    return startTime.difference(DateTime.now()).inHours >=
        appInfo.minHoursToCancel;
  }

  bool isEmpty() {
    return registeredParticipants.isEmpty;
  }

  void removeParticipant(UserInfo userToRemove) {
    registeredParticipants.removeWhere(
        (registeredUser) => registeredUser.uid == userToRemove.uid);
  }

  _showNoPunchcardDialog(BuildContext screenContext) async {
    await showOkAlertDialog(
        context: screenContext,
        title: 'אין כרטיסיה',
        message: 'יש לרכוש כרטיסיה על מנת להירשם לשיעורים. לרכישה אנא צור קשר.',
        okLabel: 'אישור');
  }

  _showNoPunchesLeftDialog(BuildContext screenContext) async {
    await showOkAlertDialog(
        context: screenContext,
        title: 'אין ניקובים',
        message: 'לא נותרו ניקובים בכרטיסיה שלך. לרכישה אנא צור קשר.',
        okLabel: 'אישור');
  }

  Future<void> onTap(BuildContext context, FirestoreDatabase database) async {
    await showDialog(
        context: context,
        builder: (context) => Utils.cardSelectionDialog(
            context, _tapChoiceTiles(context, database)));
  }

  List<CardSelectionTile> _tapChoiceTiles(
      BuildContext context, FirestoreDatabase database) {
    final theme = Theme.of(context);
    return [
      CardSelectionTile(
        context,
        'שלח הודעה לרשומים',
        Icon(Icons.message_outlined, color: theme.colorScheme.primary),
        (context) => _sendNotificationToRegisteredClients(context, database),
      ),
      CardSelectionTile(
        context,
        'ערוך פרטי שיעור',
        Icon(Icons.mode_edit_outline_outlined,
            color: theme.colorScheme.primary),
        (context) => _editPractice(context, database),
      ),
      CardSelectionTile(
        context,
        'בטל שיעור',
        Icon(Icons.delete_outline_outlined, color: theme.colorScheme.primary),
        (context) => _delete(context, database),
      ),
    ];
  }

  _delete(BuildContext context, FirestoreDatabase database) async {
    final shouldDelete = await _didRequestDelete(context);
    if (shouldDelete) {
      Navigator.of(context).pop();
      await database.deletePractice(this);
    }
  }

  Future<bool> _didRequestDelete(BuildContext context) async {
    final didRequestDelete = await showOkCancelAlertDialog(
        context: context,
        isDestructiveAction: true,
        title: 'ביטול שיעור',
        message:
            'האם לבטל שיעור זה? במידה ויש מתאמנים רשומים, מומלץ לשלוח להם תחילה הודעה על ביטול.');
    return didRequestDelete == OkCancelResult.ok;
  }

  _editPractice(BuildContext context, FirestoreDatabase database) async {
    // final title = _getPromtTitle(editOption);
    Navigator.of(context).pop();
    await EditPracticeForm.show(context, this, database);
  }

  // _getPromtTitle(PracticeEditOption editOption) {
  //   switch (editOption) {
  //     case PracticeEditOption.name:
  //       return 'שם אימון';
  //     case PracticeEditOption.location:
  //       return 'מיקום אימון';
  //     case PracticeEditOption.time:
  //       return 'זמן תחילת אימון';
  //     default:
  //       return 'שם אימון';
  //   }
  // }

  _sendNotificationToRegisteredClients(
      BuildContext context, FirestoreDatabase database) async {
    final date = Utils.numericDayMonthYearFromDateTime(startTime);
    // final hour = Utils.hourFromDateTime(startTime);
    final field = DialogTextField(
        validator: _notificationTextValidator,
        maxLines: 6,
        hintText: 'הודעה לרשומים');
    final textList =
        await showTextInputDialog(context: context, textFields: [field]);
    if (textList == null || textList.isEmpty) return;
    final notificationText = textList.first;
    final title = '$name בתאריך $date';
    final sendTo = registeredParticipants;
    database.sendNotificationToUsers(sendTo, title, notificationText);
    await showOkAlertDialog(
        context: context,
        message: 'ההודעה נשלחה בהצלחה לכל הרשומים',
        title: 'הצלחה');
    Navigator.of(context).pop();
  }

  String? _notificationTextValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'חובה להזין טקסט';
    } else {
      return null;
    }
  }

  Future<void> joinWaitingList(
      FirestoreDatabase database, UserInfo user, BuildContext context) async {
    if (startTime.isBefore(DateTime.now())) return;
    database.addUserToWaitingList(this, user);
    await showOkAlertDialog(
        context: context,
        message:
            'נרשמת בהצלחה לרשימת ההמתנה של שיעור זה. במידה ויתפנה מקום תקבל התראה מיידית.',
        title: 'הצלחה');
  }

  Future<void> leaveWaitingList(
      FirestoreDatabase database, UserInfo user, BuildContext context) async {
    if (startTime.isBefore(DateTime.now())) return;
    await database.removeUserFromWaitingList(this, user);
    await showOkAlertDialog(
        context: context,
        message: 'בוטל רישומך לרשימת ההמתנה של שיעור זה.',
        title: 'הצלחה');
  }

  Practice withUserAddedToWaitingList(UserInfo userInfo) {
    final newWaitingList = <UserInfo>[];
    newWaitingList.addAll(waitingList);
    newWaitingList.add(userInfo);
    return copyWith(waitingList: newWaitingList);
  }

  Practice withUserRemovedFromWaitingList(UserInfo userInfo) {
    final newWaitingList = <UserInfo>[];
    newWaitingList.addAll(waitingList);
    newWaitingList.removeWhere((element) => element.uid == userInfo.uid);
    return copyWith(waitingList: newWaitingList);
  }

  bool isInWaitingList(UserInfo user) {
    return waitingList.any((element) => element.uid == user.uid);
  }
}

enum PracticeEditOption { name, time, location }
