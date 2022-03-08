import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:yoga_house/Canellation/cancellation.dart';
import 'package:yoga_house/Client/health_assurance.dart';
import 'package:yoga_house/Practice/practice.dart';
import 'package:yoga_house/Practice/practice_template.dart';
import 'package:yoga_house/Services/shared_prefs.dart';
import 'package:yoga_house/Services/utils_file.dart';
import 'package:yoga_house/User_Info/user_info.dart';
import 'package:yoga_house/common_widgets/punch_card.dart';

import 'api_path.dart';
import 'app_info.dart';
import 'notifications.dart';

class FirestoreDatabase {
  final String currentUserUID;

  final _instance = FirebaseFirestore.instance;

  FirestoreDatabase({required this.currentUserUID});

  Future<void> setDocument(String path, Map<String, dynamic> data) async {
    return await _instance.doc(path).set(data);
  }

  Future<void> deleteDocument(String path) async {
    return await _instance.doc(path).delete();
  }

  Stream<List<T>> _collectionStream<T>(
      {required String path,
      required T Function(Map<String, dynamic> data) builder}) {
    debugPrint('FIREBASE QUERY: getting stream: $path');
    final reference = _instance.collection(path);
    final snapshots = reference.snapshots();
    return snapshots.map((snapshot) => snapshot.docs
        .map(
          (snapshot) => builder(snapshot.data()),
        )
        .toList());
  }

  Stream<T> _streamFromDoc<T>(
      String docPath, T Function(Map<String, dynamic> data) builder) {
    debugPrint('Stream from doc: getting stream: ' + docPath);
    final reference = _instance.doc(docPath);
    final snapshots = reference.snapshots();
    return snapshots.map((snapshot) {
      final data = snapshot.data();
      if (data == null) {
        throw Exception('streamfrom doc got NULL');
      } else {
        return builder(data);
      }
    });
  }

  Stream<List<Practice>> futurePracticesStream() {
    final path = APIPath.futurePractices();
    return _collectionStream(
        path: path, builder: (data) => Practice.fromMap(data));
  }

  Stream<List<Practice>> userFuturePracticesStream(String uid) {
    final path = APIPath.userFuturePractices(uid);
    return _collectionStream(
        path: path, builder: (data) => Practice.fromMap(data));
  }

  Future<void> saveDeviceToken(String fcmToken) {
    final path = APIPath.fcmToken(currentUserUID, fcmToken);
    debugPrint('Writing fcm token: $path');
    final doc = _instance.doc(path);
    return doc.set({
      'token': fcmToken,
      'createdAt': DateTime.now().toIso8601String(), // optional
      'platform': Platform.operatingSystem
    });
  }

  Future<void> initEmptyUserInfo(String uid) async {
    debugPrint('FIREBASE QUERY: Creating empty user doc');
    final docPath = APIPath.userInfo(uid);
    final reference = _instance.doc(docPath);
    final userInfo = UserInfo.initEmptyUserInfo(uid);
    return await reference.set(userInfo.toMap());
  }

  Future<void> initNewUserInfo(
      String uid, String name, String phone, String email) async {
    debugPrint('FIREBASE QUERY: Creating new user doc');
    final docPath = APIPath.userInfo(uid);
    final reference = _instance.doc(docPath);
    final userInfo = UserInfo.initNewUserInfo(uid, name, phone, email);
    return await reference.set(userInfo.toMap());
  }

  // setNamePhoneEmail(UserInfo currentInfo, String uid, String name,
  //     String phoneNumber, String email) {}

  Future<AppInfo> appInfoFuture() async {
    final docPath = APIPath.appInfo();
    final reference = _instance.doc(docPath);
    final doc = await reference.get();
    final data = doc.data();
    if (data == null) {
      throw Exception('app info is null! in database');
    } else {
      final appInfo = AppInfo.fromMap(data);
      return appInfo;
    }
  }

  Stream<UserInfo> userInfoStream(String uid) {
    final docPath = APIPath.userInfo(uid);
    return _streamFromDoc(docPath, (data) => UserInfo.fromMap(data));
  }

  Future<UserInfo> userInfoFuture(String uid) async {
    final docPath = APIPath.userInfo(uid);
    final ref = await _instance.doc(docPath).get();
    final data = ref.data();
    if (data == null) return UserInfo.initEmptyUserInfo(uid);
    return UserInfo.fromMap(data);
  }

  Stream<AppInfo> appInfoStream() {
    final path = APIPath.appInfo();
    return _streamFromDoc(path, (data) {
      return AppInfo.fromMap(data);
    });
  }

  Future<bool> persistPracticeTemplateLocally(
      PracticeTemplate template, SharedPrefs sharedPrefs) async {
    final emptyTemplateIndex = sharedPrefs.emptyTemplateIndex();
    if (emptyTemplateIndex == 0) {
      throw Exception('No empty templates available!');
    }
    switch (emptyTemplateIndex) {
      case 1:
        return await sharedPrefs.practiceTemplate1.setValue(template);
      case 2:
        return await sharedPrefs.practiceTemplate2.setValue(template);
      case 3:
        return await sharedPrefs.practiceTemplate3.setValue(template);
      case 4:
        return await sharedPrefs.practiceTemplate4.setValue(template);
      default:
        return false;
    }
  }

  Future<void> addPractice(Practice practice) async {
    final path = APIPath.futurePractice(practice.id);
    return await setDocument(path, practice.toMap());
  }

  Future<bool> registerUserToPracticeTransaction(
      UserInfo userToAddObj, String practiceID) async {
    final userInfoRef = _instance.doc(APIPath.userInfo(userToAddObj.uid));
    final practiceRef = _instance.doc(APIPath.futurePractice(practiceID));
    return await _instance.runTransaction<bool>((transaction) async {
      final practiceSnapshot = await transaction.get(practiceRef);
      final userToAddRaw = await transaction.get(userInfoRef);
      final userToAddData = userToAddRaw.data();
      if (userToAddData == null) return false;
      final userToAdd = UserInfo.fromMap(userToAddData);
      final currentPunchcard = userToAdd.punchcard;
      if (currentPunchcard == null || !currentPunchcard.hasPunchesLeft) {
        return false;
      }
      final data = practiceSnapshot.data();
      if (data == null) return false;
      final practicePre = Practice.fromMap(data);
      if (practicePre.isFull() || practicePre.isUserRegistered(userToAdd.uid)) {
        return false;
      }
      if (practicePre.isFull()) return false;
      practicePre.registeredParticipants.add(userToAdd);
      final practicePost = practicePre;
      transaction.update(practiceRef, practicePost.toMap());
      transaction.update(
          userInfoRef, userToAdd.copyWithDecrementedPunch().toMap());
      if (practicePost.isInWaitingList(userToAdd)) {
        await _removeUserFromWaitingListTransaction(
            practicePost, userToAdd, transaction);
      }
      await _sendClientRegisteredAdminNotificationTransaction(
          userToAddObj, practicePost, transaction);
      return true;
    });
  }

  Future<bool> unregisterFromPracticeTransaction(
      UserInfo userToRemoveObj,
      Practice practice,
      bool shouldRestorePunch,
      AppInfo appInfo,
      bool shouldSendAdminNotification) async {
    final userInfoRef = _instance.doc(APIPath.userInfo(userToRemoveObj.uid));
    final practicePath = APIPath.futurePractice(practice.id);
    final practiceRef = _instance.doc(practicePath);
    return await _instance.runTransaction<bool>((transaction) async {
      final userInfoSnapshot = await transaction.get(userInfoRef);
      final practiceSnapshot = await transaction.get(practiceRef);
      final userInfoData = userInfoSnapshot.data();
      final practiceData = practiceSnapshot.data();
      if (userInfoData == null) {
        debugPrint('no user info data');
        return false;
      }
      if (practiceData == null) {
        debugPrint('no practice data');
        return false;
      }
      final userToRemove = UserInfo.fromMap(userInfoData);
      final practicePre = Practice.fromMap(practiceData);
      if (practicePre.isEmpty() ||
          !practicePre.isUserRegistered(userToRemove.uid)) {
        debugPrint('no practice');
        return false;
      }
      practicePre.removeParticipant(userToRemove);
      final practicePost = practicePre;
      transaction.update(practiceRef, practicePost.toMap());
      if (shouldRestorePunch) {
        final newUserInfo = userToRemove.copyWithIncrementedPunch();
        transaction.update(userInfoRef, newUserInfo.toMap());
      }
      if (shouldSendAdminNotification) {
        _sendClientCancelledAdminNotificationTransaction(
            userToRemove, practicePre, transaction);
      }
      _addCancellationTransaction(
          practice, userToRemoveObj, appInfo, transaction);
      _notifyWaitingListTransaction(practice, transaction);
      return true;
    });
  }

  Future<bool> incrementPunchcard(UserInfo userInfoObj) async {
    final userInfoRef = _instance.doc(APIPath.userInfo(userInfoObj.uid));
    return await _instance.runTransaction((transaction) async {
      final userInfoSnapshot = await transaction.get(userInfoRef);
      final userInfoData = userInfoSnapshot.data();
      if (userInfoData == null) return false;
      final userInfo = UserInfo.fromMap(userInfoData);
      if (!userInfo.hasPunchcard) return false;
      transaction.update(
          userInfoRef, userInfo.copyWithIncrementedPunch().toMap());
      return true;
    });
  }

  Future<bool> decrementPunchcard(UserInfo userInfoObj) async {
    final userInfoRef = _instance.doc(APIPath.userInfo(userInfoObj.uid));
    return await _instance.runTransaction((transaction) async {
      final userInfoSnapshot = await transaction.get(userInfoRef);
      final userInfoData = userInfoSnapshot.data();
      if (userInfoData == null) return false;
      final userInfo = UserInfo.fromMap(userInfoData);
      if (!userInfo.hasPunchcard || !userInfo.hasPunchesLeft) return false;
      transaction.update(
          userInfoRef, userInfo.copyWithDecrementedPunch().toMap());
      return true;
    });
  }

  Stream<List<UserInfo>> allUsersInfoStream() {
    final path = APIPath.userInfoCollection();
    return _collectionStream(
        path: path, builder: (data) => UserInfo.fromMap(data));
  }

  Future<void> addNewPunchCardTransaction(
      String uid, Punchcard punchCardToAdd) async {
    final userInfoRef = _instance.doc(APIPath.userInfo(uid));
    // final punchCardInHistoryRef = _instance
    //     .doc(APIPath.userPunchCardFromHistory(uid, punchCardToAdd.purchasedOn));
    return await _instance.runTransaction((transaction) async {
      transaction.update(userInfoRef, {'punchcard': punchCardToAdd.toMap()});
      // transaction.set(punchCardInHistoryRef, punchCardToAdd.toMap());
    });
  }

  // Future<void> addNewPunchCardTransacrion( WITH COPYWITH
  //     String uid, Punchcard punchcardToAdd) async {
  //   final userInfoRef = _instance.doc(APIPath.userInfo(uid));
  //   final punchCardInHistoryRef = _instance
  //       .doc(APIPath.userPunchCardFromHistory(uid, punchcardToAdd.purchasedOn));
  //   return await _instance.runTransaction((transaction) async {
  //     final userInfoSnapshot = await transaction.get(userInfoRef);
  //     final data = userInfoSnapshot.data();
  //     if (data == null) return;
  //     final userInfoPre = UserInfo.fromMap(data);
  //     final userInfoPost = userInfoPre.copyWith(punchCard: punchcardToAdd);
  //     transaction.set(userInfoRef, userInfoPost.toMap());
  //     transaction.set(punchCardInHistoryRef, punchcardToAdd.toMap());
  //   });
  // }

  Future<void> updatePunchCardTransaction({
    required String uid,
    required Punchcard punchcardToAdd,
  }) async {
    final userInfoRef = _instance.doc(APIPath.userInfo(uid));

    return await _instance.runTransaction((transaction) async {
      final userInfoSnapshot = await transaction.get(userInfoRef);
      final userInfoData = userInfoSnapshot.data();
      if (userInfoData == null) return;
      final userInfo = UserInfo.fromMap(userInfoData);
      final currentPunchcard = userInfo.punchcard;
      if (currentPunchcard == null) return;
      final aggregatedPunchcard = currentPunchcard
          .aggregate(punchcardToAdd); //first aggregate then make punchesLeft 0.
      final currentPunchcardRefInHistory = _instance.doc(
          APIPath.userPunchCardFromHistory(uid, currentPunchcard.purchasedOn));
      transaction.set(currentPunchcardRefInHistory,
          currentPunchcard.copyWith(punchesRemaining: 0).toMap());
      transaction
          .update(userInfoRef, {'punchcard': aggregatedPunchcard.toMap()});
    });
  }

  Future<void> movePunchcardToHistory(UserInfo userInfo) async {
    final punchcard = userInfo.punchcard;
    if (punchcard == null) return;
    final userInfoRef = _instance.doc(APIPath.userInfo(userInfo.uid));
    final punchcardInHistoryPath =
        APIPath.userPunchCardFromHistory(userInfo.uid, punchcard.purchasedOn);
    final punchcardInHistoryRef = _instance.doc(punchcardInHistoryPath);
    return await _instance.runTransaction((transaction) async {
      transaction.update(userInfoRef, {'punchcard': null});
      transaction.set(punchcardInHistoryRef, punchcard.toMap());
    });
  }

  // Future<bool> organizePracticesTransaction(List<Practice> allPractices) async {
  //   final preMoveRefs = pastPracticesRefs(allPractices);
  //   if (preMoveRefs.isEmpty) return true;
  //   final postMovePracticesToRefs = _postMovePracticesToRefs(allPractices);
  //   return await _instance.runTransaction<bool>((transaction) async {
  //     for (var practice in postMovePracticesToRefs.keys) {
  //       _transactionAddFieldToSingleDoc(
  //           reference: postMovePracticesToRefs[practice]!,
  //           fieldId: practice.id,
  //           field: practice.toMap(),
  //           transaction: transaction);
  //     }
  //     for (var ref in preMoveRefs) {
  //       transaction.delete(ref);
  //     }
  //     return true;
  //   });
  // }
  Future<bool> organizePracticesTransaction(List<Practice> allPractices) async {
    final preMoveRefs = pastPracticesRefs(allPractices);
    if (preMoveRefs.isEmpty) return true;
    final postMovePracticesToRefs = _postMovePracticesToRefs(allPractices);
    return await _instance.runTransaction<bool>((transaction) async {
      for (var practice in postMovePracticesToRefs.keys) {
        _transactionAddFieldToSingleDoc(
            reference: postMovePracticesToRefs[practice]!,
            fieldId: practice.id,
            field: practice.toMap(),
            transaction: transaction);
      }
      for (var ref in preMoveRefs) {
        transaction.delete(ref);
      }
      return true;
    });
  }

  List<DocumentReference> pastPracticesRefs(List<Practice> allPractices) {
    final pastPractices = _pastPractices(allPractices);
    final preMoveRefs = <DocumentReference>[];
    for (var pastPractice in pastPractices) {
      final ref = _instance.doc(APIPath.futurePractice(pastPractice.id));
      preMoveRefs.add(ref);
    }
    return preMoveRefs;
  }

  Map<Practice, DocumentReference> _postMovePracticesToRefs(
      List<Practice> allPractices) {
    final pastPractices = _pastPractices(allPractices);
    final map = <Practice, DocumentReference>{};
    for (var pastPractice in pastPractices) {
      final path = APIPath.pastPracticeSingleDoc(pastPractice.startTime);
      final ref = _instance.doc(path);
      map[pastPractice] = ref;
    }
    return map;
  }

  List<Practice> _pastPractices(List<Practice> allPractices) {
    final now = DateTime.now();
    final pastPractices = allPractices
        .where((practice) => practice.startTime.isBefore(now))
        .toList();
    return pastPractices;
  }

  deletePractice(Practice practice) async {
    //Assumes future practice
    final path = APIPath.futurePractice(practice.id);

    await deleteDocument(path);
  }

  Future<List<Practice>> practicesHistoryFuture() async {
    final collectionPath = APIPath.pastPracticesCollection();
    final monthsRef = _instance.collection(collectionPath);
    final monthsData = await monthsRef.get();
    final docsSnapshot = monthsData.docs;
    final allPractices = <Practice>[];
    for (var snapshot in docsSnapshot) {
      final data = snapshot.data();
      for (var practice in data.values) {
        allPractices.add(Practice.fromMap(practice));
      }
    }
    return allPractices;
  }

  Future<void> addFieldToSingleDoc({
    required String docPath,
    required String fieldId,
    required Map<String, dynamic> field,
  }) async {
    debugPrint('Adding field $fieldId to doc $docPath');
    final reference = _instance.doc(docPath);
    final SetOptions setOptions = SetOptions(merge: true);
    return await reference.set({fieldId: field}, setOptions);
  }

  Future<void> _transactionAddFieldToSingleDoc(
      {required DocumentReference reference,
      required String fieldId,
      required Map<String, dynamic> field,
      required Transaction transaction}) async {
    debugPrint('Adding field $fieldId to a singleDoc');
    final SetOptions setOptions = SetOptions(merge: true);
    transaction.set(reference, {fieldId: field}, setOptions);
  }

  Future<void> _transactionAddDoc({
    required DocumentReference reference,
    required Map<String, dynamic> doc,
    required Transaction transaction,
  }) async {
    debugPrint('Adding doc');
    transaction.set(reference, doc);
  }

  Future<void> addNotificationToUser(NotificationData notification) async {
    final reference = _instance.doc(APIPath.newUserNotification());
    await reference.set(notification.toMap());
  }

  addAdminNotification(String title, String msg) async {
    final reference = _instance.doc(APIPath.newAdminNotification());
    final notification = {'title': title, 'msg': msg};
    await reference.set(notification);
  }

  // _addAdminNotificationTransaction(
  //     String title, String msg, Transaction transaction) async {
  //   final reference = _instance.doc(APIPath.newAdminNotification());
  //   final notification = {'title': title, 'msg': msg};
  //   transaction.set(reference, notification);
  // }

  _sendClientCancelledAdminNotificationTransaction(
      UserInfo userInfo, Practice practice, Transaction transaction) {
    final ref = _instance.doc(APIPath.newAdminNotification());
    final username = userInfo.name;
    final practiceName = practice.name;
    final practiceDate =
        Utils.numericDayMonthYearFromDateTime(practice.startTime);
    const title = 'ביטול רישום לשיעור';
    final msg =
        '$username ביטל/ה רישום לשיעור $practiceName שיתקיים בתאריך $practiceDate';
    transaction.set(ref, {'title': title, 'msg': msg});
  }

  _sendClientRegisteredAdminNotificationTransaction(
      UserInfo userInfo, Practice practice, Transaction transaction) {
    final ref = _instance.doc(APIPath.newAdminNotification());
    final username = userInfo.name;
    final practiceName = practice.name;
    final practiceDate =
        Utils.numericDayMonthYearFromDateTime(practice.startTime);
    const title = 'רישום לשיעור';
    final msg = '$username נרשם/ה לשיעור $practiceName בתאריך $practiceDate';
    transaction.set(ref, {'title': title, 'msg': msg});
  }

  Future<void> setHomepageText(String text, AppInfo oldAppInfo) async {
    final path = APIPath.appInfo();
    return await _instance.doc(path).update({'homepageText': text});
  }

  Future<void> addHomepageMessage(String msg) async {
    final path = APIPath.newHomepageMessage();
    return _instance.doc(path).set({'title': 'Yoga House', 'msg': msg});
  }

  sendNotificationToUsers(List<UserInfo> sendTo, String title, String msg) {
    _instance.runTransaction<bool>((transaction) async {
      for (var user in sendTo) {
        final ref = _instance.doc(APIPath.newUserNotification());
        final notification = NotificationData(
            title: title,
            msg: msg,
            targetUID: user.uid,
            targetUserNotificationTopic:
                APIPath.clientNotificationsTopic(user.uid));
        transaction.set(ref, notification.toMap());
      }

      return true;
    });
  }

  // _sendNotificationToUserTransaction(DocumentReference ref,
  //     NotificationData notification, Transaction transaction) {
  //   transaction.set(ref, notification.toMap());
  // }

  Future<void> editPractice(Practice practice, String name, String location,
      DateTime startTime, DateTime endTime, int maxParticipants) async {
    final path = APIPath.futurePractice(practice.id);
    final doc = _instance.doc(path);
    return await doc.update({
      'name': name,
      'location': location,
      'startTime': startTime,
      'endTime': endTime,
      'maxParticipants': maxParticipants,
    });
  }

  Future<List<Punchcard>> userPunchcardsFuture(UserInfo user) async {
    final path = APIPath.userPunchCardHistoryCollection(user.uid);
    final reference = _instance.collection(path);
    final docs = await reference.get();
    final queries = docs.docs;
    final punchcards = <Punchcard>[];
    for (var query in queries) {
      final data = query.data();
      punchcards.add(Punchcard.fromMap(data));
    }
    return punchcards;
  }

  Future<void> toggleTerminateClient(bool newValue) async {
    final path = APIPath.appInfo();
    return await _instance.doc(path).update({'isClientTerminated': newValue});
  }

  Future<void> toggleTerminateManager(bool newValue) async {
    final path = APIPath.appInfo();
    return await _instance.doc(path).update({'isManagerTerminated': newValue});
  }

  Future<void> setHealthAssurance(
      UserInfo userInfo, HealthAssurance healthAssurance) async {
    final path = APIPath.userInfo(userInfo.uid);
    final haInHistoryPath = APIPath.newHealthAssuranceInHistory(userInfo.uid);
    await _instance.doc(haInHistoryPath).set(healthAssurance.toMap());
    return await _instance
        .doc(path)
        .update({'healthAssurance': healthAssurance.toMap()});
  }

  Future<void> addUserToWaitingList(
      Practice practiceToJoin, UserInfo user) async {
    final practicePath = APIPath.futurePractice(practiceToJoin.id);
    final practiceRef = _instance.doc(practicePath);
    return await _instance.runTransaction((transaction) async {
      final practiceData =
          await transaction.get(practiceRef).then((value) => value.data());
      if (practiceData == null) return;
      final practicePre = Practice.fromMap(practiceData);
      final practicePost = practicePre.withUserAddedToWaitingList(user);
      transaction.update(practiceRef, practicePost.toMap());
    });
  }

  removeUserFromWaitingList(Practice practiceToLeave, UserInfo user) async {
    final practicePath = APIPath.futurePractice(practiceToLeave.id);
    final practiceRef = _instance.doc(practicePath);
    return await _instance.runTransaction((transaction) async {
      final practiceData =
          await transaction.get(practiceRef).then((value) => value.data());
      if (practiceData == null) return;
      final practicePre = Practice.fromMap(practiceData);
      final practicePost = practicePre.withUserRemovedFromWaitingList(user);
      transaction.update(practiceRef, practicePost.toMap());
    });
  }

  void _notifyWaitingListTransaction(
      Practice practice, Transaction transaction) {
    final name = practice.name;
    final title = 'רשימת המתנה: $name';
    final date = Utils.numericDayMonthYearFromDateTime(practice.startTime);
    final hour = Utils.hourFromDateTime(practice.startTime);
    final msg =
        'התפנה מקום לשיעור $name בתאריך $date בשעה $hour. היכנס/י על מנת להירשם.';
    for (var user in practice.waitingList) {
      final path = APIPath.newUserNotification();
      final ref = _instance.doc(path);
      final notification = NotificationData(
          targetUID: user.uid,
          targetUserNotificationTopic: APIPath.userNotificationsTopic(user.uid),
          title: title,
          msg: msg);
      transaction.set(ref, notification.toMap());
    }
  }

  _removeUserFromWaitingListTransaction(
      Practice practice, UserInfo user, Transaction transaction) async {
    final practicePath = APIPath.futurePractice(practice.id);
    final practiceRef = _instance.doc(practicePath);
    final practicePost = practice.withUserRemovedFromWaitingList(user);
    transaction.update(practiceRef, practicePost.toMap());
  }

  void _addCancellationTransaction(Practice practice, UserInfo user,
      AppInfo appInfo, Transaction transaction) {
    final cancellationRef =
        _instance.doc(APIPath.newUserCancellation(user.uid));
    final cancellation = Cancellation(DateTime.now(), practice,
        practice.startTime, practice.isEnoughTimeLeftToCancel(appInfo));
    transaction.set(cancellationRef, cancellation.toMap());
  }

  Future<List<Cancellation>> cancellationsFuture(String uid) async {
    final collectionPath = APIPath.userCancellationsCollection(uid);
    final ref = _instance.collection(collectionPath);
    final data = await ref.get();
    final docsSnapshot = data.docs;
    final allCancellations = <Cancellation>[];
    for (var snapshot in docsSnapshot) {
      final cancellation = snapshot.data();
      final canc = Cancellation.fromMap(cancellation);
      allCancellations.add(canc);
    }

    return allCancellations;
  }

  Future<void> unlockPractice(Practice practice) {
    final practicePath = APIPath.futurePractice(practice.id);
    final practiceRef = _instance.doc(practicePath);
    return practiceRef.update({'isLocked': false});
  }

  Future<void> lockPractice(Practice practice) {
    final practicePath = APIPath.futurePractice(practice.id);
    final practiceRef = _instance.doc(practicePath);
    return practiceRef.update({'isLocked': true});
  }
}
