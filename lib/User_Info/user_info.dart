import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:yoga_house/Canellation/cancellation.dart';
import 'package:yoga_house/Practice/practice.dart';
import 'package:yoga_house/Services/database.dart';
import 'package:yoga_house/common_widgets/punch_card.dart';

class UserInfo {
  final String uid;
  final String name;
  final String phoneNumber;
  final String email;
  final List<Cancellation> cancelationsHistory;
  // final List<Payment> payments;
  final bool isManager;
  final bool approvedTermsOfService;
  final bool submittedHealthAssurance;
  final Punchcard? punchcard;

  bool get hasPunchcard => punchcard != null;
  bool get hasPunchesLeft {
    final pnchcrd = punchcard;
    if (pnchcrd == null) {
      return false;
    } else {
      return pnchcrd.hasPunchesLeft;
    }
  }

  static UserInfo initEmptyUserInfo(String uid) {
    return UserInfo(
      name: '',
      phoneNumber: '',
      email: '',
      cancelationsHistory: [],
      uid: uid,
      submittedHealthAssurance: false,
      approvedTermsOfService: false,
      isManager: false,
      punchcard: null,
    );
  }

  static UserInfo initNewUserInfo(
      String uid, String name, String phone, String email) {
    return UserInfo(
      name: name,
      phoneNumber: phone,
      email: email,
      cancelationsHistory: [],
      uid: uid,
      approvedTermsOfService: false,
      submittedHealthAssurance: false,
      isManager: false,
      punchcard: null,
    );
  }

  UserInfo({
    required this.name,
    required this.phoneNumber,
    required this.email,
    required this.cancelationsHistory,
    // this.payments,
    required this.uid,
    required this.isManager,
    required this.approvedTermsOfService,
    required this.submittedHealthAssurance,
    required this.punchcard,
  });

  factory UserInfo.fromMap(Map<String, dynamic> data) {
    final punchcardData = data['punchcard'];
    Punchcard? punchCard;
    if (punchcardData != null) {
      punchCard = Punchcard.fromMap(punchcardData);
    }
    return UserInfo(
      name: data['name'],
      phoneNumber: data['phoneNumber'],
      email: data['email'],
      cancelationsHistory: [],
      // [],
      uid: data['uid'],
      isManager: data['isManager'],
      approvedTermsOfService: data['approvedTermsOfService'],
      submittedHealthAssurance: data['submittedHealthAssurance'],
      punchcard: punchCard,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'phoneNumber': phoneNumber,
      'email': email,
      'isManager': isManager,
      'approvedTermsOfService': approvedTermsOfService,
      'submittedHealthAssurance': submittedHealthAssurance,
      'punchcard': punchcard?.toMap(),
    };
  }

  UserInfo copyWith(
      {String? name,
      String? phoneNumber,
      String? email,
      List<Cancellation>? cancelationsHistory,
      String? uid,
      bool? isManager,
      bool? submittedHealthAssurance,
      bool? approvedTermsOfService,
      Punchcard? punchCard}) {
    return UserInfo(
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      cancelationsHistory: cancelationsHistory ?? this.cancelationsHistory,
      //  payments: payments ?? this.payments,
      uid: uid ?? this.uid,
      isManager: isManager ?? this.isManager,
      submittedHealthAssurance:
          submittedHealthAssurance ?? this.submittedHealthAssurance,
      approvedTermsOfService:
          approvedTermsOfService ?? this.approvedTermsOfService,
      punchcard: punchCard ?? punchcard,
    );
  }

  List<Practice> practicesRegisteredTo(List<Practice> allPractices) {
    return allPractices
        .where((practice) => practice.isUserRegistered(uid))
        .toList();
  }

  static List<Practice> practicesUserIsRegisteredTo(
      List<Practice> allPractices, UserInfo userInfo) {
    return allPractices
        .where((practice) => practice.isUserRegistered(userInfo.uid))
        .toList();
  }

  Future<void> addPunchCard(
      Punchcard punchcardToAdd, FirestoreDatabase database) async {
    final currentPunchcard = punchcard;
    if (currentPunchcard == null) {
      await database.addNewPunchCardTransaction(uid, punchcardToAdd);
    } else {
      await database.updatePunchCardTransaction(
          uid: uid, punchcardToAdd: punchcardToAdd);
    }
  }

  Future<void> incrementPunchcard(
      FirestoreDatabase database, BuildContext context) async {
    final didSucceed = await database.incrementPunchcard(this);
    final title = didSucceed ? 'הצלחה' : 'כישלון';
    final msg = didSucceed
        ? 'ניקוב נוסף בהצלחה'
        : 'לא ניתן היה להשלים את הפעולה. אנא נסה שוב';
    showOkAlertDialog(
        context: context, title: title, message: msg, okLabel: 'אישור');
  }

  Future<void> decrementPunchcard(
      FirestoreDatabase database, BuildContext context) async {
    final didSucceed = await database.decrementPunchcard(this);
    final title = didSucceed ? 'הצלחה' : 'כישלון';
    final msg = didSucceed
        ? 'ניקוב ירד בהצלחה'
        : 'לא ניתן היה להשלים את הפעולה. אנא נסה שוב';
    showOkAlertDialog(
        context: context, title: title, message: msg, okLabel: 'אישור');
  }

  UserInfo copyWithDecrementedPunch() {
    final pnchcrd = punchcard;
    if (pnchcrd == null) {
      throw Exception('Punchcard cant be decremented if null');
    }
    return copyWith(punchCard: pnchcrd.copyWithDecrementPunches());
  }

  UserInfo copyWithIncrementedPunch() {
    final pnchcrd = punchcard;
    if (pnchcrd == null) {
      throw Exception('Punchcard cant be incremented if null');
    }
    return copyWith(punchCard: pnchcrd.copyWithIncrementPunches());
  }

  // bool isRegisteredToPractice(String practiceID) {
  //   for (var practice in practicesRegistered) {
  //     if (practice.id == practiceID) return true;
  //   }
  //   return false;
  // }
}
