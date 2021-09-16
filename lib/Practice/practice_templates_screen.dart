import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:persistent_bottom_nav_bar/persistent-tab-view.dart';
import 'package:provider/provider.dart';
import 'package:yoga_house/Practice/practice.dart';
import 'package:yoga_house/Practice/practice_template.dart';
import 'package:yoga_house/Services/database.dart';
import 'package:yoga_house/Services/shared_prefs.dart';
import 'package:yoga_house/Services/utils_file.dart';
import 'package:yoga_house/common_widgets/custom_button.dart';

class PracticeTemplatesScreen extends StatefulWidget {
  final FirestoreDatabase database;
  final SharedPrefs sharedPrefs;
  static Future<void> pushToTabBar(BuildContext context) async {
    final database = context.read<FirestoreDatabase>();
    final sharedPrefs = context.read<SharedPrefs>();
    await pushNewScreen(
      context,
      screen: PracticeTemplatesScreen(
        database,
        sharedPrefs,
      ),
    );
  }

  const PracticeTemplatesScreen(this.database, this.sharedPrefs, {Key? key})
      : super(key: key);

  @override
  _PracticeTemplatesScreenState createState() =>
      _PracticeTemplatesScreenState();
}

class _PracticeTemplatesScreenState extends State<PracticeTemplatesScreen> {
  late GlobalKey<FormBuilderState> _formKey;
  late String _name, _description, _selectedLvl;

  @override
  void initState() {
    _formKey = GlobalKey<FormBuilderState>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final firstTemplate = widget.sharedPrefs.practiceTemplate1.getValue();
    print(firstTemplate.name);
    return Scaffold(
        appBar: AppBar(
          title: Utils.appBarTitle(context, 'אימונים קבועים'),
        ),
        body: Center(
          child: IconButton(
              onPressed: _addPracticeTemplate,
              icon: const Icon(Icons.add_circle_outline_sharp)),
        ));
  }

  void _addPracticeTemplate() async {
    final style = Theme.of(context).textTheme.headline6;
    final labelStyle = Theme.of(context).textTheme.subtitle2;
    await showCupertinoModalPopup(
        context: context,
        builder: (ctx) {
          return Utils.bottomSheetFormBuilder(
              context,
              [
                _practiceNameInput(ctx, labelStyle!),
                _descriptionInput(ctx, labelStyle),
                _lvlInput(ctx, labelStyle)
              ],
              'הוסף אימון',
              _submitForm,
              ctx,
              style!,
              _formKey);
        });
  }

  Widget _practiceNameInput(BuildContext ctx, TextStyle labelStyle) {
    const maxChars = 20;
    return FormBuilderTextField(
      maxLength: maxChars,
      name: 'name',
      decoration:
          InputDecoration(labelText: 'שם אימון', labelStyle: labelStyle),
      onChanged: (newStr) {
        if (newStr != null) _name = newStr;
      },
      validator: FormBuilderValidators.compose([
        FormBuilderValidators.required(ctx),
        FormBuilderValidators.max(ctx, maxChars),
      ]),
    );
  }

  Widget _descriptionInput(BuildContext ctx, TextStyle labelStyle) {
    const maxChars = 60;

    return FormBuilderTextField(
      maxLength: maxChars,
      name: 'description',
      decoration: InputDecoration(labelText: 'תאור', labelStyle: labelStyle),
      onChanged: (newStr) {
        if (newStr != null) _description = newStr;
      },
      validator: FormBuilderValidators.compose([
        FormBuilderValidators.required(ctx),
        FormBuilderValidators.max(ctx, maxChars),
      ]),
    );
  }

  Widget _lvlInput(BuildContext ctx, TextStyle labelStyle) {
    final genderOptions = ['מתחילים', 'מתקדמים', 'מתקדמים מאוד'];
    return FormBuilderDropdown<String>(
      onChanged: (newStr) {
        if (newStr != null) _selectedLvl = newStr;
      },
      name: 'lvl',
      decoration: InputDecoration(
          label: const Text('רמת קושי'), labelStyle: labelStyle),
      validator: FormBuilderValidators.required(ctx),
      items: genderOptions
          .map((level) => DropdownMenuItem(
                value: level,
                child: Text(level),
              ))
          .toList(),
    );
  }

  void _submitForm() {
    _formKey.currentState?.save();
    final didValidate = _formKey.currentState?.validate();
    if (didValidate != null && didValidate) {
      final template = PracticeTemplate(
          Utils.idFromTime(), _name, _description, _selectedLvl);
      widget.database
          .persistPracticeTemplateLocally(template, widget.sharedPrefs);
    } else {
      debugPrint("validation failed");
    }
  }
}
