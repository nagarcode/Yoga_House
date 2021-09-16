import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'database.dart';

const tomersPhone = '+972502060269';

class AppUser {
  final String uid;
  final String displayName;
  final String phoneNumber;
  AppUser({
    required this.uid,
    required this.displayName,
    required this.phoneNumber,
  });

  Map<String, dynamic> dataMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> data) {
    final String uid = data['uid'];
    final String displayName = data['displayName'];
    final String phoneNumber = data['phoneNumber'];
    return AppUser(
      uid: uid,
      displayName: displayName,
      phoneNumber: phoneNumber,
    );
  }
}

abstract class AuthBase {
  Stream<AppUser?> get onAuthStateChanged;
  Future<AppUser?> signInWithCredential(AuthCredential authCredential);
  Future<AppUser?> currentUser();
  Future<void> saveDeviceToken();
  Future<void> signOut();
  signInWithOtp(String smsCode, String verId);
  bool isTomer();

  verifyPhoneNumber(
      {required String phoneNumber,
      required Duration duration,
      verificationCompleted,
      verificationFailed,
      phoneCodeSent,
      autoTimeot});

  setName(String firstName, String lastName);
}

class Auth implements AuthBase {
  final _firebaseAuth = FirebaseAuth.instance;

  AppUser? _userFromFirebase(User? user) {
    if (user == null) return null;
    return AppUser(
        uid: user.uid,
        displayName: user.displayName ?? '',
        phoneNumber: user.phoneNumber ?? '');
  }

  @override
  Stream<AppUser?> get onAuthStateChanged {
    return _firebaseAuth.authStateChanges().map(_userFromFirebase);
  }

  @override
  Future<AppUser?> currentUser() async {
    final user = _firebaseAuth.currentUser;
    return _userFromFirebase(user);
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  @override
  Future<AppUser?> signInWithCredential(AuthCredential authCredential) async {
    await _firebaseAuth.signInWithCredential(authCredential);
    await saveDeviceToken();
    return _userFromFirebase(_firebaseAuth.currentUser);
  }

  @override
  verifyPhoneNumber(
      {required String phoneNumber,
      required Duration duration,
      verificationCompleted,
      verificationFailed,
      phoneCodeSent,
      autoTimeot}) async {
    await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: verificationCompleted,
        verificationFailed: verificationFailed,
        codeSent: phoneCodeSent,
        codeAutoRetrievalTimeout: autoTimeot);
  }

  @override
  signInWithOtp(String smsCode, String verId) async {
    AuthCredential authCred =
        PhoneAuthProvider.credential(verificationId: verId, smsCode: smsCode);
    await signInWithCredential(authCred);
  }

  @override
  setName(String firstName, String lastName) {
    final user = _firebaseAuth.currentUser;
    user?.updateDisplayName(firstName + ' ' + lastName);
  }

  @override
  bool isTomer() {
    return _firebaseAuth.currentUser?.phoneNumber == tomersPhone;
  }

  @override
  Future<void> saveDeviceToken() async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) return;
    final uid = currentUser.uid;
    final database = FirestoreDatabase(uid: uid);
    final fcm = FirebaseMessaging.instance;
    final fcmToken = await fcm.getToken();
    if (fcmToken != null) database.saveDeviceToken(fcmToken);
  }
}
