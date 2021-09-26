import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';
import 'package:yoga_house/Services/database.dart';
import 'package:yoga_house/Services/splash_screen.dart';
import 'package:yoga_house/Services/utils_file.dart';
import 'package:yoga_house/User_Info/user_info.dart';
import 'package:yoga_house/common_widgets/punch_card.dart';

class NewPunchcardForm extends StatefulWidget {
  final UserInfo userToAddTo;
  final FirestoreDatabase database;

  static Future<void> show(BuildContext context, UserInfo userToAddTo) async {
    final database = context.read<FirestoreDatabase>();
    await showCupertinoModalPopup(
      context: context,
      useRootNavigator: true,
      builder: (bCtx) {
        return NewPunchcardForm(
          database: database,
          userToAddTo: userToAddTo,
        );
      },
    );
  }

  const NewPunchcardForm(
      {Key? key, required this.userToAddTo, required this.database})
      : super(key: key);

  @override
  _NewPunchcardFormState createState() => _NewPunchcardFormState();
}

class _NewPunchcardFormState extends State<NewPunchcardForm> {
  late bool _isLoading;
  late GlobalKey<FormBuilderState> _formKey;
  late int _numOfPunches, _monthsToKeepAlive;

  @override
  void initState() {
    _isLoading = false;
    _formKey = GlobalKey<FormBuilderState>();
    _numOfPunches = 0;
    _monthsToKeepAlive = 0;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.headline6;

    return Utils.bottomSheetFormBuilder(
        inputFields: _inputFields(),
        confirmText: 'הוסף כרטיסיה',
        onConfirmed: _submitForm,
        innerCtx: context,
        style: style!,
        formKey: _formKey,
        title: 'כרטיסיה חדשה');
  }

  List<Widget> _inputFields() {
    final labelStyle = Theme.of(context).textTheme.subtitle2;
    return [
      _numOfPunchesInput(context, labelStyle!),
      _shelfLifeInput(context, labelStyle),
    ];
  }

  Widget _numOfPunchesInput(BuildContext ctx, TextStyle labelStyle) {
    const maxChars = 3;
    return FormBuilderTextField(
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      maxLength: maxChars,
      name: 'num of punches',
      decoration:
          InputDecoration(labelText: 'מס׳ ניקובים', labelStyle: labelStyle),
      onChanged: (newStr) {
        if (newStr != null) _numOfPunches = int.parse(newStr);
      },
      validator: FormBuilderValidators.compose([
        FormBuilderValidators.required(ctx),
        FormBuilderValidators.integer(ctx),
      ]),
    );
  }

  _shelfLifeInput(BuildContext ctx, TextStyle labelStyle) {
    const maxChars = 2;
    return FormBuilderTextField(
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      maxLength: maxChars,
      name: 'shelf life',
      decoration: InputDecoration(
          labelText: 'תוקף כרטיסיה (בחודשים)', labelStyle: labelStyle),
      onChanged: (newStr) {
        if (newStr != null) _monthsToKeepAlive = int.parse(newStr);
      },
      validator: FormBuilderValidators.compose([
        FormBuilderValidators.required(ctx),
        FormBuilderValidators.integer(ctx),
      ]),
    );
  }

  void _submitForm() {
    _setIsLoading(true);
    _formKey.currentState?.save();
    final didValidate = _formKey.currentState?.validate();
    if (didValidate != null && didValidate) {
      final expiresOn =
          DateTime.now().add(Duration(days: 31 * _monthsToKeepAlive));
      final newPunchcard = Punchcard(
        purchasedOn: DateTime.now(),
        punchesPurchased: _numOfPunches,
        expiresOn: expiresOn,
        punchesRemaining: _numOfPunches,
      );
      widget.userToAddTo.addPunchCard(newPunchcard, widget.database);
      Navigator.of(context).pop();
    } else {
      debugPrint("validation failed");
      _setIsLoading(false);
    }
  }

  void _setIsLoading(bool value) {
    setState(() {
      _isLoading = value;
    });
  }
}
