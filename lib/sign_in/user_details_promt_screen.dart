import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:yoga_house/Services/auth.dart';
import 'package:yoga_house/Services/database.dart';
import 'package:yoga_house/Services/shared_prefs.dart';

import 'package:yoga_house/common_widgets/custom_button.dart';
import 'package:yoga_house/landing.dart';

class UserDetailsPromtScreen extends StatefulWidget {
  final AuthBase auth;
  final FirestoreDatabase database;

  const UserDetailsPromtScreen({
    Key? key,
    required this.auth,
    required this.database,
  }) : super(key: key);

  @override
  _UserDetailsPromtScreenState createState() => _UserDetailsPromtScreenState();
}

class _UserDetailsPromtScreenState extends State<UserDetailsPromtScreen> {
  bool isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController firstName = TextEditingController();
  final TextEditingController lastName = TextEditingController();
  final TextEditingController email = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    final theme = Theme.of(context);
    final deviceSize = MediaQuery.of(context).size;
    return Stack(
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
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: _oneLastThing(),
                        ),
                        const SizedBox(height: 5),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: _details(),
                        ),
                        const SizedBox(height: 10),
                        _nameTextField(),
                        const SizedBox(height: 5),
                        _lastNameTextField(),
                        const SizedBox(height: 5),
                        _emailTextField(),
                        isLoading
                            ? const CircularProgressIndicator()
                            : _setNameButton()
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  _setNameButton() {
    final sharedPrefs = context.read<SharedPrefs>();
    return CustomButton(
        msg: "המשך",
        onTap: isLoading
            ? null
            : () async {
                if (!_formKey.currentState!.validate()) return;
                final user = await widget.auth.currentUser();
                final uid = user!.uid;
                _setIsLoading(true);
                await widget.auth.setName(firstName.text, lastName.text);

                await widget.database.initNewUserInfo(
                    uid,
                    '${firstName.text} ${lastName.text}',
                    user.phoneNumber,
                    email.text);
                // _setIsLoading(false);
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                  builder: (context) => LandingPage(
                    sharedPrefs,
                    skipNameCheck: true,
                  ),
                ));
              });
  }

  _nameTextField() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: TextFormField(
        autofocus: true,
        validator: (first) => _firstNameValidator(first),
        style: TextStyle(color: theme.colorScheme.secondaryVariant),
        maxLength: 15,
        controller: firstName,
        decoration: const InputDecoration(
          hintText: "שם פרטי",
          hintStyle:
              TextStyle(color: Colors.grey, fontFamily: "Sen", fontSize: 18),
        ),
      ),
    );
  }

  _emailTextField() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: TextFormField(
        validator: (email) => _emailValidator(email),
        style: TextStyle(color: theme.colorScheme.secondaryVariant),
        maxLength: 30,
        controller: email,
        decoration: const InputDecoration(
          hintText: "אימייל",
          hintStyle:
              TextStyle(color: Colors.grey, fontFamily: "Sen", fontSize: 18),
        ),
      ),
    );
  }

  _setIsLoading(bool loading) {
    setState(() {
      isLoading = loading;
    });
  }

  _firstNameValidator(String? first) {
    if (first == null || first.isEmpty) return 'שדה חובה';
    return null;
  }

  _emailValidator(String? email) {
    if (email == null || email.isEmpty) return 'שדה חובה';
    if (!email.contains('@') || !email.contains('.')) return 'אימייל לא תקין';
    return null;
  }

  _lastNameTextField() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: TextFormField(
        validator: (lastName) => _lastNameValidator(lastName),
        style: TextStyle(color: theme.colorScheme.secondaryVariant),
        maxLength: 15,
        controller: lastName,
        decoration: const InputDecoration(
            hintText: "שם משפחה",
            hintStyle:
                TextStyle(color: Colors.grey, fontFamily: "Sen", fontSize: 18)),
      ),
    );
  }

  _oneLastThing() {
    final textTheme = Theme.of(context).textTheme;
    // final theme = Theme.of(context);
    return Center(
      child: Text(
        'נעים להכיר :)',
        style: textTheme.headline6,
        textAlign: TextAlign.center,
      ),
    );
  }

  _details() {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Text(
        'דבר אחרון לפני שממשיכים, כדי להירשם לאימונים בקלות נותר רק להזין פרטים אחרונים',
        style: textTheme.subtitle1,
        textAlign: TextAlign.center,
      ),
    );
  }

  _lastNameValidator(String? lastName) {
    if (lastName == null || lastName.isEmpty) return 'שדה חובה';
    return null;
  }
}
