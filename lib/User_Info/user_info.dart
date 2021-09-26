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
      punchcard: punchCard ?? this.punchcard,
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
      final aggregatedPunchcard = currentPunchcard.aggregate(punchcardToAdd);
      await database.updatePunchCardTransaction(
          uid, punchcardToAdd, aggregatedPunchcard);
    }
  }

  // bool isRegisteredToPractice(String practiceID) {
  //   for (var practice in practicesRegistered) {
  //     if (practice.id == practiceID) return true;
  //   }
  //   return false;
  // }
}
