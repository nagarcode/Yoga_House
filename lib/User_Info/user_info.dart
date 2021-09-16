import 'package:yoga_house/Canellation/cancellation.dart';
import 'package:yoga_house/Payment/payment.dart';
import 'package:yoga_house/Practice/practice.dart';

class UserInfo {
  final String uid;
  final String name;
  final String phoneNumber;
  final String email;
  final List<Practice> practicesRegistered;
  final List<Cancellation> cancelationsHistory;
  final List<Payment> payments;
  final bool isManager;
  final bool approvedTermsOfService;
  final bool submittedHealthAssurance;

  static UserInfo initEmptyUserInfo(String uid) {
    return UserInfo('', '', '', [], [], [], uid, false, false, false);
  }

  static UserInfo initNewUserInfo(
      String uid, String name, String phone, String email) {
    return UserInfo(name, phone, email, [], [], [], uid, false, false, false);
  }

  UserInfo(
      this.name,
      this.phoneNumber,
      this.email,
      this.practicesRegistered,
      this.cancelationsHistory,
      this.payments,
      this.uid,
      this.isManager,
      this.approvedTermsOfService,
      this.submittedHealthAssurance);

  factory UserInfo.fromMap(Map<String, dynamic> data) {
    return UserInfo(
      data['name'],
      data['phoneNumber'],
      data['email'],
      [], //TODO use proxy
      [],
      [],
      data['uid'],
      data['isManager'],
      data['approvedTermsOfService'],
      data['submittedHealthAssurance'],
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
    };
  }

  UserInfo copyWith({
    name,
    phoneNumber,
    email,
    practicesRegistered,
    cancelationsHistory,
    payments,
    uid,
    isManager,
    submittedHealthAssurance,
    approvedTermsOfService,
  }) {
    return UserInfo(
        name ?? this.name,
        phoneNumber ?? this.phoneNumber,
        email ?? this.email,
        practicesRegistered ?? this.practicesRegistered,
        cancelationsHistory ?? this.cancelationsHistory,
        payments ?? this.payments,
        uid ?? this.uid,
        isManager ?? this.isManager,
        submittedHealthAssurance ?? this.submittedHealthAssurance,
        approvedTermsOfService ?? this.approvedTermsOfService);
  }
}
