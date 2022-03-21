import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:yoga_house/Services/auth.dart';
import 'package:yoga_house/common_widgets/custom_button.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({Key? key, required this.auth}) : super(key: key);

  final AuthBase auth;

  static Widget create(BuildContext context) {
    final auth = Provider.of<AuthBase>(context, listen: false);
    return SignInScreen(auth: auth);
  }

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  late bool isLoading;
  late bool codeSent;
  late String verificationId;
  late TextEditingController phoneNumber;
  late TextEditingController userEnteredCode;
  final _formKey = GlobalKey<FormState>();
  @override
  void initState() {
    isLoading = false;
    codeSent = false;
    phoneNumber = TextEditingController();
    userEnteredCode = TextEditingController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    final theme = Theme.of(context);
    final deviceSize = MediaQuery.of(context).size;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  theme.colorScheme.primary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0, 1],
              ),
            ),
          ),
          SingleChildScrollView(
            // physics: const NeverScrollableScrollPhysics(),
            child: SizedBox(
              height: deviceSize.height,
              width: deviceSize.width,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Flexible(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          _numTextField(),
                          const SizedBox(height: 5),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: _detailedText(),
                          ),
                          const SizedBox(height: 10),
                          if (codeSent) _inputVerificationCodeTextField(),
                          isLoading
                              ? const CircularProgressIndicator()
                              : _verifyLoginButton()
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  _verifyLoginButton() {
    return CustomButton(
        color: null,
        msg: codeSent ? "התחבר" : "אמת",
        onTap: isLoading
            ? null
            : () {
                if ((_formKey.currentState!.validate())) {
                  if (codeSent) {
                    if (userEnteredCode.text.isEmpty) {
                      return;
                    } else {
                      _trySinginWithOTP(
                          userEnteredCode.value.text, verificationId);
                    }
                  } else {
                    verifyPhone('+972' + phoneNumber.value.text);
                  }
                }
              });
  }

  _numTextField() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: TextFormField(
        autofocus: true,
        validator: (phoneNum) =>
            phoneNum == null ? null : _phoneNumValidator(phoneNum),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: TextStyle(color: theme.colorScheme.secondaryVariant),
        maxLength: 10,
        enabled: codeSent ? false : true,
        keyboardType: TextInputType.phone,
        controller: phoneNumber,
        decoration: InputDecoration(
          icon: Icon(
            Icons.phone_iphone,
            color: theme.colorScheme.secondary,
          ),
          hintText: "050 12345 678",
          hintStyle: const TextStyle(
              color: Colors.grey, fontFamily: "Sen", fontSize: 18),
        ),
      ),
    );
  }

  _setIsLoading(bool loading) {
    setState(() {
      isLoading = loading;
    });
  }

  Future<void> verifyPhone(phoneNo) async {
    _setIsLoading(true);
    await widget.auth.verifyPhoneNumber(
        phoneNumber: phoneNo,
        duration: const Duration(seconds: 5),
        verificationCompleted: verified,
        verificationFailed: verificationfailed,
        phoneCodeSent: smsSent,
        autoTimeot: autoTimeout);
  }

  _phoneNumValidator(String? phoneNum) {
    if (phoneNum == null) return 'שדה חובה';
    if (phoneNum.isEmpty || phoneNum.length != 10) return 'מספר טלפון לא תקין';
    if (int.tryParse(phoneNum) == null) return 'שדה חובה';
    return null;
  }

  _inputVerificationCodeTextField() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: TextFormField(
        validator: _codeValidator,
        style: TextStyle(color: theme.colorScheme.secondaryVariant),
        maxLength: 6,
        keyboardType: TextInputType.phone,
        controller: userEnteredCode,
        decoration: InputDecoration(
            icon: FaIcon(FontAwesomeIcons.hashtag,
                color: theme.colorScheme.secondary),
            hintText: "קוד אימות",
            hintStyle: const TextStyle(
                color: Colors.grey, fontFamily: "Sen", fontSize: 18)),
      ),
    );
  }

  _detailedText() {
    return const Text(
      "ברוך הבא :) ההרשמה היא חד פעמית, מבטיחים לזכור אותך להבא.",
      textAlign: TextAlign.center,
      style: TextStyle(color: Colors.grey),
    );
  }

  // void _showSignInError(BuildContext context, PlatformException exception) {
  //   _setIsLoading(false);
  //   showOkAlertDialog(
  //       context: context, message: exception.message, title: 'ההתחברות נכשלה');
  // }

  verified(AuthCredential authResult) {
    _setIsLoading(false);
    widget.auth.signInWithCredential(authResult);
  }

  verificationfailed(FirebaseAuthException authException) {
    _setIsLoading(false);
    showOkAlertDialog(
        context: context,
        message: authException.message,
        okLabel: 'סגור',
        title: 'שגיאה');
  }

  smsSent(String verId, [int? forceResend]) {
    debugPrint('sent sms');
    _setIsLoading(false);
    verificationId = verId;
    setState(() {
      codeSent = true;
    });
  }

  autoTimeout(String verId) {
    verificationId = verId;
  }

  Future<void> _trySinginWithOTP(String text, String verificationId) async {
    _setIsLoading(true);
    try {
      await widget.auth
          .signInWithOtp(userEnteredCode.value.text, verificationId);
    } catch (e) {
      await showOkAlertDialog(
          context: context,
          title: 'שגיאה',
          message: 'הקוד שהוכנס שגוי. נסה שוב.',
          okLabel: 'סגור');
      _setIsLoading(false);
    }
  }

  String? _codeValidator(String? code) {
    if (code == null || code.length != 6) {
      return 'קוד חייב להכיל 6 ספרות';
    } else {
      return null;
    }
  }
}
