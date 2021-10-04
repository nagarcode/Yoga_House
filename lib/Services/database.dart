import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
      practicePre.registeredParticipants.add(userToAdd);
      final practicePost = practicePre;
      transaction.update(practiceRef, practicePost.toMap());
      transaction.update(
          userInfoRef, userToAdd.copyWithDecrementedPunch().toMap());
      return true;
    });
  }

  Future<bool> unregisterFromPracticeTransaction(UserInfo userToRemoveObj,
      String practiceID, bool shouldRestorePunch) async {
    final userInfoRef = _instance.doc(APIPath.userInfo(userToRemoveObj.uid));
    final practiceRef = _instance.doc(APIPath.futurePractice(practiceID));
    final adminNotificationRef = _instance.doc(APIPath.newAdminNotification());
    return await _instance.runTransaction<bool>((transaction) async {
      final userInfoSnapshot = await transaction.get(userInfoRef);
      final practiceSnapshot = await transaction.get(practiceRef);
      final userInfoData = userInfoSnapshot.data();
      final data = practiceSnapshot.data();
      if (data == null || userInfoData == null) return false;
      final userToRemove = UserInfo.fromMap(userInfoData);
      final practicePre = Practice.fromMap(data);
      if (practicePre.isEmpty() ||
          !practicePre.isUserRegistered(userToRemove.uid)) {
        return false;
      }
      practicePre.removeParticipant(userToRemove);
      final practicePost = practicePre;
      transaction.update(practiceRef, practicePost.toMap());
      if (shouldRestorePunch) {
        transaction.update(
            userInfoRef, userToRemove.copyWithIncrementedPunch().toMap());
      }
      _sendClientCancelledAdminNotificationTransaction(
          userToRemove, practicePre, transaction);
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

  Future<bool> organizePracticesTransaction(List<Practice> allPractices) async {
    final preMoveRefs = pastPracticesRefs(allPractices);
    if (preMoveRefs.isEmpty) return true;
    final postMovePracticesToRefs = _postMovePracticesToRefs(allPractices);
    return await _instance.runTransaction<bool>((transaction) async {
      for (var practice in postMovePracticesToRefs.keys) {
        // transaction.set(postMovePracticesToRefs[practice]!, practice.toMap());
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
    final isFuturePractice = practice.startTime.isAfter(DateTime.now());
    final path = isFuturePractice
        ? APIPath.futurePractice(practice.id)
        : APIPath.pastPracticeSingleDoc(practice.startTime);
    if (!isFuturePractice) {
      await deleteDocument(path);
    } else {
      final registered = practice.registeredParticipants;
      //TODO notify all registered users of deletion.
      await deleteDocument(path); // TODO change to transaction
    }
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

  Future<void> addNotificationToUser(NotificationData notification) async {
    final reference =
        _instance.doc(APIPath.newUserNotification(notification.targetUID));
    await reference.set(notification.toMap());
  }

  addAdminNotification(String title, String msg) async {
    final reference = _instance.doc(APIPath.newAdminNotification());
    final notification = {'title': title, 'msg': msg};
    await reference.set(notification);
  }

  _addAdminNotificationTransaction(
      String title, String msg, Transaction transaction) async {
    final reference = _instance.doc(APIPath.newAdminNotification());
    final notification = {'title': title, 'msg': msg};
    transaction.set(reference, notification);
  }

  _sendClientCancelledAdminNotificationTransaction(
      UserInfo userInfo, Practice practice, Transaction transaction) {
    final ref = _instance.doc(APIPath.newUserCancelledAdminNotification());
    final username = userInfo.name;
    final practiceName = practice.name;
    final practiceDate =
        Utils.numericDayMonthYearFromDateTime(practice.startTime);
    const title = 'ביטול רישום לתרגול';
    final msg =
        '$username ביטל רישום ל$practiceName שיתקיים בתאריך $practiceDate';
    transaction.set(ref, {'title': title, 'msg': msg});
  }

  _sendClientRegisteredAdminNotificationTransaction(
      UserInfo userInfo, Practice practice, Transaction transaction) {
    final ref = _instance.doc(APIPath.newUserRegisteredAdminNotification());
    final username = userInfo.name;
    final practiceName = practice.name;
    final practiceDate =
        Utils.numericDayMonthYearFromDateTime(practice.startTime);
    const title = 'רישום לתרגול';
    final msg = '$username נרשם ל$practiceName בתאריך $practiceDate';
    transaction.set(ref, {'title': title, 'msg': msg});
  }

  Future<void> setHomepageText(String text, AppInfo oldAppInfo) async {
    final path = APIPath.appInfo();
    return await _instance.doc(path).update({'homepageText': text});
  }

  Future<void> addHomepageMessage(String msg) async {
    final path = APIPath.newHomepageMessage();
    return _instance.doc(path).set({'msg': msg});
  }

  sendNotificationToUsers(List<UserInfo> sendTo, String title, String msg) {
    _instance.runTransaction<bool>((transaction) async {
      for (var user in sendTo) {
        final ref = _instance.doc(APIPath.newUserNotification(user.uid));
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

  _sendNotificationToUserTransaction(DocumentReference ref,
      NotificationData notification, Transaction transaction) {
    transaction.set(ref, notification.toMap());
  }

  Future<void> editPractice(Practice practice, String name, String location,
      DateTime startTime) async {
    final path = APIPath.futurePractice(practice.id);
    final doc = _instance.doc(path);
    return await doc
        .update({'name': name, 'location': location, 'startTime': startTime});
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
}
