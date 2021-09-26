import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:yoga_house/Practice/practice.dart';
import 'package:yoga_house/Practice/practice_template.dart';
import 'package:yoga_house/Services/shared_prefs.dart';
import 'package:yoga_house/User_Info/user_info.dart';
import 'package:yoga_house/common_widgets/punch_card.dart';

import 'api_path.dart';
import 'app_info.dart';

class FirestoreDatabase {
  final String currentUserUID;

  final _instance = FirebaseFirestore.instance;

  FirestoreDatabase({required this.currentUserUID});

  Future<void> setDocument(String path, Map<String, dynamic> data) async {
    return await _instance.doc(path).set(data);
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
      UserInfo userToAdd, String practiceID) async {
    return await _instance.runTransaction<bool>((transaction) async {
      final practiceRef = _instance.doc(APIPath.futurePractice(practiceID));
      final practiceSnapshot = await transaction.get(practiceRef);
      final data = practiceSnapshot.data();
      if (data == null) return false;
      final practicePre = Practice.fromMap(data);
      if (practicePre.isFull() || practicePre.isUserRegistered(userToAdd.uid)) {
        return false;
      }
      // final newNumOfRegistered = practicePre.numOfRegisteredParticipants + 1;
      practicePre.registeredParticipants.add(userToAdd);
      final practicePost = practicePre;
      transaction.update(practiceRef, practicePost.toMap());
      return true;
    });
  }

  Future<bool> unregisterFromPracticeTransaction(
      UserInfo userToRemove, String practiceID) async {
    return await _instance.runTransaction<bool>((transaction) async {
      final practiceRef = _instance.doc(APIPath.futurePractice(practiceID));
      final practiceSnapshot = await transaction.get(practiceRef);
      final data = practiceSnapshot.data();
      if (data == null) return false;
      final practicePre = Practice.fromMap(data);
      if (practicePre.isEmpty() ||
          !practicePre.isUserRegistered(userToRemove.uid)) {
        return false;
      }
      // final newNumOfRegistered = practicePre.numOfRegisteredParticipants - 1;
      practicePre.removeParticipant(userToRemove);

      final practicePost = practicePre;
      transaction.update(practiceRef, practicePost.toMap());
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
    final punchCardInHistoryRef = _instance
        .doc(APIPath.userPunchCardFromHistory(uid, punchCardToAdd.purchasedOn));
    return await _instance.runTransaction((transaction) async {
      transaction.update(userInfoRef, {'punchcard': punchCardToAdd.toMap()});
      transaction.set(punchCardInHistoryRef, punchCardToAdd.toMap());
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

  Future<void> updatePunchCardTransaction(String uid, Punchcard punchCardToAdd,
      Punchcard aggregatedPunchcard) async {
    final userInfoRef = _instance.doc(APIPath.userInfo(uid));
    final punchCardToAddRefInHistory = _instance
        .doc(APIPath.userPunchCardFromHistory(uid, punchCardToAdd.purchasedOn));
    return await _instance.runTransaction((transaction) async {
      transaction
          .update(userInfoRef, {'punchcard': aggregatedPunchcard.toMap()});
      transaction.set(punchCardToAddRefInHistory, punchCardToAdd.toMap());
    });
  }
}
