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
  final bool isLocked;

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
    this.isLocked,
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
      data['isLocked'] ?? false,
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
      'isLocked': isLocked,
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
    bool? isLocked,
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
      isLocked ?? this.isLocked,
    );
  }

  Function registerToPracticeCallback(
      UserInfo userInfo,
      FirestoreDatabase database,
      BuildContext screenContext,
      bool isManagerView) {
    final notifications = screenContext.read<NotificationService>();
    final allPractices = screenContext.read<List<Practice>>();
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
        if (isLocked && !isManagerView) {
          await _showLockedDialog(screenContext);
          return;
        }
        if (!isManagerView) {
          if (_isRegisteredToThatDay(userInfo, allPractices)) {
            await _alertRegisteredToday(screenContext);
            return;
          }
        }
        final didRequestRegister =
            await _promtRegistrationConfirmation(screenContext);
        if (didRequestRegister) {
          await _showRegisteredDialog(screenContext);
          await _showLastPunchDialog(screenContext, userInfo);
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
            await _promtUnregisterConfirmation(screenContext, isManagerView);
        if (didRequestUnregister) {
          bool shouldRestorePunch = isEnoughTimeLeftToCancel(appInfo);
          database.unregisterFromPracticeTransaction(
              userInfo, this, shouldRestorePunch, appInfo, !isManagerView);
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

  Future<bool> _promtUnregisterConfirmation(
      BuildContext screenContext, bool isManagerView) async {
    final appInfo = screenContext.read<AppInfo>();
    final minHours = appInfo.minHoursToCancel;
    final notEnoughTimeText = isManagerView
        ? 'שימי לב, לא יוחזר ללקוח ניקוב משום שהביטול לא מספיק זמן מראש. במידה והלקוח צריך לקבל ניקוב בחזרה אנא הזיני לו אחד מעמוד הלקוחות. האם לבטל את רישום הלקוח?'
        : 'חשוב לשים לב! שיעור זה יתקיים בעוד פחות מ$minHours שעות ולכן במידה ותבטל את רישומך לא יוחזר לך הניקוב לכרטיסיה. האם לבטל בכל זאת?';
    final enoughTimeText = isManagerView
        ? 'הלקוח  יקבל החזר ניקוב. האם לבטל את רישומו?'
        : 'איזה כיף שביטלת את הרישום בזמן ♡ ביטול זה הוא ללא חיוב. האם לבטל את הרישום?';
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

  Future<void> onTap(BuildContext context, FirestoreDatabase database,
      AppInfo appInfo, NotificationService notifications) async {
    await showDialog(
        context: context,
        builder: (context) => Utils.cardSelectionDialog(context,
            _tapChoiceTiles(context, database, appInfo, notifications)));
  }

  List<CardSelectionTile> _tapChoiceTiles(
      BuildContext context,
      FirestoreDatabase database,
      AppInfo appInfo,
      NotificationService notifications) {
    final theme = Theme.of(context);
    return [
      if (!isLocked)
        CardSelectionTile(
          context,
          'נעל שיעור',
          Icon(Icons.lock_outline, color: theme.colorScheme.primary),
          (context) => _lock(context, database),
        ),
      if (isLocked)
        CardSelectionTile(
          context,
          'פתח שיעור להרשמה',
          Icon(Icons.lock_open_outlined, color: theme.colorScheme.primary),
          (context) => unlock(context, database),
        ),
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
        (context) => _delete(context, database, appInfo, notifications),
      ),
    ];
  }

  _delete(BuildContext context, FirestoreDatabase database, AppInfo appInfo,
      NotificationService notifications) async {
    final shouldDelete = await _didRequestDelete(context);
    if (shouldDelete) {
      for (var user in registeredParticipants) {
        await database.unregisterFromPracticeTransaction(
            user, this, true, appInfo, false);
        notifications.sendManagerUnregisteredYouNotification(user, this);
      }
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
            'האם לבטל שיעור זה? ניקובים יוחזרו לרשומים. מומלץ גם לשלוח להם הודעה על ביטול.');
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
    if (!user.hasPunchesLeft) {
      await _alertNoPunches(context);
      return;
    }
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

  _showRegisteredDialog(BuildContext context) async {
    await showOkAlertDialog(
        context: context,
        title: 'רישום מאושר',
        message: 'הרישום התבצע בהצלחה.');
  }

  _lock(BuildContext context, FirestoreDatabase database) async {
    final bool shouldLock = await _promtShouldLock(context);
    if (shouldLock) await database.lockPractice(this);
    Navigator.of(context).pop();
  }

  Future<void> lockWithoutPromt(FirestoreDatabase database) async {
    await database.lockPractice(this);
  }

  Future<void> unlockWithoutPromt(FirestoreDatabase database) async {
    await database.unlockPractice(this);
  }

  unlock(BuildContext context, FirestoreDatabase database) async {
    final bool shouldUnlock = await _promtShouldUnlock(context);
    if (shouldUnlock) await database.unlockPractice(this);
    Navigator.of(context).pop();
  }

  Future<bool> _promtShouldUnlock(BuildContext context) async {
    final ans = await showOkCancelAlertDialog(
        context: context,
        title: 'פתח להרשמה',
        message:
            'האם לפתוח שיעור זה להרשמה? לקוחות יוכלו להירשם מרגע זה והלאה.');
    return ans == OkCancelResult.ok;
  }

  Future<bool> _promtShouldLock(BuildContext context) async {
    final ans = await showOkCancelAlertDialog(
        context: context,
        title: 'נעל שיעור',
        message: 'האם לנעול שיעור זה? לקוחות לא יוכלו להירשם מרגע זה והלאה.',
        isDestructiveAction: true);
    return ans == OkCancelResult.ok;
  }

  _showLockedDialog(BuildContext screenContext) async {
    await showOkAlertDialog(
        context: screenContext,
        title: 'שיעור נעול',
        message: 'שיעור זה נעול ולא ניתן להירשם אליו.');
  }

  bool _isRegisteredToThatDay(UserInfo userInfo, List<Practice> allPractices) {
    for (var practice in allPractices) {
      if (Utils.isSameDate(startTime, practice.startTime)) {
        if (practice.isUserRegistered(userInfo.uid)) {
          return true;
        }
      }
    }
    return false;
  }

  _alertRegisteredToday(BuildContext context) async {
    await showOkAlertDialog(
        context: context,
        title: 'לא ניתן לבצע רישום כפול',
        message: 'הינך כבר רשום לשיעור אחד ביום זה.');
  }

  _alertNoPunches(BuildContext context) async {
    await showOkAlertDialog(
        context: context,
        title: 'אין לך ניקובים',
        message:
            'לא ניתן להירשם לרשימת המתנה ללא ניקובים. לרכישה אנא צרו קשר ♡');
  }

  _showLastPunchDialog(BuildContext context, UserInfo user) async {
    if (user.punchcard != null && user.punchcard!.punchesRemaining == 1) {
      await showOkAlertDialog(
          context: context,
          title: 'סיום כרטיסיה',
          message:
              'ברגע זה ניצלת את הניקוב האחרון בכרטיסיה. לרכישת כרטיסיה נוספת אנא צרו קשר ${Utils.heartEmoji()}');
    }
  }
}

enum PracticeEditOption { name, time, location }
