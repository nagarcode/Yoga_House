import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:yoga_house/Practice/practice_template.dart';
import 'package:yoga_house/Services/shared_prefs.dart';
import 'package:yoga_house/User_Info/user_info.dart';

import 'api_path.dart';
import 'app_info.dart';

class FirestoreDatabase {
  final String uid;

  final _instance = FirebaseFirestore.instance;

  FirestoreDatabase({required this.uid});

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

  Future<void> saveDeviceToken(String fcmToken) {
    final path = APIPath.fcmToken(uid, fcmToken);
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
      //TODO check which one is empty and replace it.
      PracticeTemplate template,
      SharedPrefs sharedPrefs) async {
    return await sharedPrefs.practiceTemplate1.setValue(template);
  }
}
