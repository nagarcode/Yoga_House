import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:yoga_house/Practice/practice.dart';
import 'package:yoga_house/Services/database.dart';
import 'package:yoga_house/Services/utils_file.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

class EditPracticeForm extends StatefulWidget {
  final FirestoreDatabase database;
  final Practice practice;

  const EditPracticeForm(
      {Key? key, required this.database, required this.practice})
      : super(key: key);

  static Future<void> show(BuildContext context, Practice practice,
      FirestoreDatabase database) async {
    await showCupertinoModalPopup(
      context: context,
      useRootNavigator: true,
      builder: (bCtx) {
        return EditPracticeForm(
          database: database,
          practice: practice,
        );
      },
    );
  }

  @override
  _EditPracticeFormState createState() => _EditPracticeFormState();
}

class _EditPracticeFormState extends State<EditPracticeForm> {
  late bool _isLoading;
  final _formKey = GlobalKey<FormBuilderState>();
  late String _name;
  late String _location;
  late DateTime _startTime;
  late Duration duration;
  late int _maxParticipants;

  @override
  void initState() {
    _name = widget.practice.name;
    _location = widget.practice.location;
    _startTime = widget.practice.startTime;
    _maxParticipants = widget.practice.maxParticipants;
    _isLoading = false;
    duration = widget.practice.endTime.difference(widget.practice.startTime);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.headline6;
    return Utils.bottomSheetFormBuilder(
        inputFields: _inputFields(),
        confirmText: 'אישור',
        onConfirmed: _isLoading ? () {} : _submitForm,
        innerCtx: context,
        style: style!,
        formKey: _formKey,
        title: 'פרטי שיעור',
        bottom: MediaQuery.of(context).viewInsets.bottom);
  }

  List<Widget> _inputFields() {
    final labelStyle = Theme.of(context).textTheme.subtitle2;
    return [
      _nameInput(context, labelStyle!),
      _locationInput(context, labelStyle),
      _maxParticipantsInput(context, labelStyle),
      _startTimeInput(context, labelStyle),
    ];
  }

  _nameInput(BuildContext ctx, TextStyle labelStyle) {
    const maxChars = 20;
    return FormBuilderTextField(
      initialValue: _name,
      maxLength: maxChars,
      name: 'name',
      decoration:
          InputDecoration(labelText: 'שם שיעור', labelStyle: labelStyle),
      onChanged: (newStr) {
        if (newStr != null) _name = newStr;
      },
      validator: FormBuilderValidators.compose([
        FormBuilderValidators.required(ctx),
        FormBuilderValidators.max(ctx, maxChars),
      ]),
    );
  }

  _locationInput(BuildContext ctx, TextStyle labelStyle) {
    const maxChars = 40;
    return FormBuilderTextField(
      initialValue: _location,
      maxLength: maxChars,
      name: 'location',
      decoration: InputDecoration(labelText: 'מיקום', labelStyle: labelStyle),
      onChanged: (newStr) {
        if (newStr != null) _location = newStr;
      },
      validator: FormBuilderValidators.compose([
        FormBuilderValidators.required(ctx),
        FormBuilderValidators.max(ctx, maxChars),
      ]),
    );
  }

  _startTimeInput(BuildContext ctx, TextStyle textStyle) {
    return FormBuilderField(
      name: "start time",
      validator: _dateValidator,
      builder: (FormFieldState<dynamic> field) {
        return InputDecorator(
          decoration: InputDecoration(
            labelText: "זמן התחלה",
            errorText: field.errorText,
          ),
          child: SizedBox(
            height: 200,
            child: CupertinoDatePicker(
              use24hFormat: true,
              initialDateTime: _startTime,
              onDateTimeChanged: (newTime) => _startTime = newTime,
              minimumDate: DateTime.now(),
            ),
          ),
        );
      },
    );
  }

  Widget _maxParticipantsInput(BuildContext ctx, TextStyle labelStyle) {
    const maxChars = 3;
    return FormBuilderTextField(
      initialValue: _maxParticipants.toString(),
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      maxLength: maxChars,
      name: 'max participants',
      decoration: InputDecoration(
          labelText: 'מס׳ משתתפים מקסימלי', labelStyle: labelStyle),
      onChanged: (newStr) {
        if (newStr != null) _maxParticipants = int.tryParse(newStr) ?? 0;
      },
      validator: FormBuilderValidators.compose([
        FormBuilderValidators.required(ctx),
        FormBuilderValidators.integer(ctx),
      ]),
    );
  }

  Future<void> _submitForm() async {
    _setIsLoading(true);
    _formKey.currentState?.save();
    final didValidate = _formKey.currentState?.validate();
    if (didValidate != null && didValidate) {
      final endTime = _startTime.add(duration);
      await widget.database.editPractice(widget.practice, _name, _location,
          _startTime, endTime, _maxParticipants);
      await showOkAlertDialog(
          context: context,
          title: 'הצלחה',
          message: 'עריכת השיעור הצליחה',
          okLabel: 'אישור');
      Navigator.of(context).pop();
    } else {
      debugPrint("validation failed");
      _setIsLoading(false);
    }
  }

  String? _dateValidator(dynamic v) {
    return null;
  }

  void _setIsLoading(bool value) {
    setState(() {
      _isLoading = value;
    });
  }
}
