import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:persistent_bottom_nav_bar/persistent-tab-view.dart';
import 'package:provider/provider.dart';
import 'package:yoga_house/Practice/practice_template.dart';
import 'package:yoga_house/Practice/practice_template_card.dart';
import 'package:yoga_house/Services/database.dart';
import 'package:yoga_house/Services/shared_prefs.dart';
import 'package:yoga_house/Services/utils_file.dart';

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
  late GlobalKey<FormBuilderState> _formKey, _durationFormKey;
  late String _name, _description, _selectedLvl, _location;
  late int _maxParticipants, _durationMinutes;
  late List<PracticeTemplate> _templates;
  late bool _isLoading;

  @override
  void initState() {
    _formKey = GlobalKey<FormBuilderState>();
    _durationFormKey = GlobalKey<FormBuilderState>();
    _templates = widget.sharedPrefs.practiceTemplates();
    _isLoading = false;
    _durationMinutes = 0;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Utils.appBarTitle(context, 'תבניות אימון'),
      ),
      body: Column(
        children: [
          _existingTemplatesCards(),
          if (_notEmptyCards().isEmpty) _noTemplatesText(),
          if (PracticeTemplate.numOfNotEmptyTemplates(_templates) <
              PracticeTemplate.maxTemplates)
            _addTemplateIcon(),
        ],
      ),
    );
  }

  ListView _existingTemplatesCards() {
    return ListView(
      children: _notEmptyCards(),
      shrinkWrap: true,
    );
  }

  IconButton _addTemplateIcon() {
    final iconColor = Theme.of(context).colorScheme.primary;

    return IconButton(
        onPressed: () async {
          await _selectDuration();
          if (_durationMinutes != 0) await _addPracticeTemplate();
        },
        icon: Icon(Icons.add_circle_outline_sharp, color: iconColor));
  }

  Future<void> _addPracticeTemplate() async {
    final style = Theme.of(context).textTheme.headline6;
    final labelStyle = Theme.of(context).textTheme.subtitle2;
    await showCupertinoModalPopup(
        context: context,
        builder: (ctx) {
          return Utils.bottomSheetFormBuilder(
              inputFields: [
                _practiceNameInput(ctx, labelStyle!),
                _descriptionInput(ctx, labelStyle),
                _lvlInput(ctx, labelStyle),
                _locationInput(ctx, labelStyle),
                _maxParticipantsInput(ctx, labelStyle),
              ],
              confirmText: 'הוסף אימון',
              onConfirmed: () => _submitForm(ctx),
              innerCtx: ctx,
              style: style!,
              formKey: _formKey,
              title: 'אימון קבוע חדש');
        });
  }

  Future<void> _selectDuration() async {
    final style = Theme.of(context).textTheme.headline6;
    final labelStyle = Theme.of(context).textTheme.subtitle2;
    await showCupertinoModalPopup(
        context: context,
        builder: (ctx) {
          return Utils.bottomSheetFormBuilder(
              inputFields: [
                _durationInput(ctx, labelStyle!),
              ],
              confirmText: 'אישור',
              onConfirmed: () => _submitDurationForm(ctx),
              innerCtx: ctx,
              style: style!,
              formKey: _durationFormKey,
              title: 'משך האימון');
        });
  }

  void deleteTemplateCallback(PracticeTemplate template) async {
    final didRequest = await _didRequestDelete();
    if (!didRequest) return;
    _setIsLoading(true);
    widget.sharedPrefs.deleteTemplate(template);
    setState(() {
      _templates = widget.sharedPrefs.practiceTemplates();
    });
    _setIsLoading(false);
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

  Widget _maxParticipantsInput(BuildContext ctx, TextStyle labelStyle) {
    const maxChars = 3;
    return FormBuilderTextField(
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

  Widget _locationInput(BuildContext ctx, TextStyle labelStyle) {
    const maxChars = 20;
    return FormBuilderTextField(
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

  Widget _lvlInput(BuildContext ctx, TextStyle labelStyle) {
    const maxChars = 20;
    return FormBuilderTextField(
      onChanged: (newStr) {
        if (newStr != null) _selectedLvl = newStr;
      },
      name: 'lvl',
      decoration: InputDecoration(
          label: const Text('רמת קושי'), labelStyle: labelStyle),
      validator: FormBuilderValidators.compose([
        FormBuilderValidators.required(ctx),
        FormBuilderValidators.max(ctx, maxChars),
      ]),
    );
  }

  void _submitForm(BuildContext ctx) {
    _setIsLoading(true);
    _formKey.currentState?.save();
    final didValidate = _formKey.currentState?.validate();
    if (didValidate != null && didValidate) {
      final template = PracticeTemplate(
        Utils.idFromTime(),
        _name,
        _description,
        _selectedLvl,
        _location,
        _maxParticipants,
        _durationMinutes,
      );
      widget.database
          .persistPracticeTemplateLocally(template, widget.sharedPrefs);
      setState(() {
        _templates = widget.sharedPrefs.practiceTemplates();
      });
      Navigator.of(ctx).pop();
    } else {
      debugPrint("validation failed");
    }
    _setIsLoading(false);
  }

  void _submitDurationForm(BuildContext ctx) {
    _setIsLoading(true);
    _durationFormKey.currentState?.save();
    final didValidate = _durationFormKey.currentState?.validate();
    if (didValidate != null && didValidate) {
      Navigator.of(ctx).pop();
    } else {
      debugPrint("validation failed");
    }
    _setIsLoading(false);
  }

  void _setIsLoading(bool value) {
    setState(() {
      _isLoading = value;
    });
  }

  List<PracticeTemplateCard> _notEmptyCards() {
    final toReturn = <PracticeTemplateCard>[];
    for (PracticeTemplate template in _templates) {
      if (!template.isEmpty()) {
        toReturn.add(PracticeTemplateCard(
            template, () => deleteTemplateCallback(template)));
      }
    }
    return toReturn;
  }

  Future<bool> _didRequestDelete() async {
    return await showOkCancelAlertDialog(
            context: context,
            message: 'האם למחוק תבנית אימון זו?',
            okLabel: 'מחק',
            isDestructiveAction: true,
            cancelLabel: 'ביטול') ==
        OkCancelResult.ok;
  }

  Widget _noTemplatesText() {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Center(
            child: Text(
          'לחצי על הפלוס על מנת להוסיף תבניות אימון',
          style: theme.textTheme.bodyText1,
        )),
      ],
    );
  }

  _durationInput(BuildContext ctx, TextStyle textStyle) {
    return FormBuilderField(
      name: "duration",
      validator: _durationValidator,
      builder: (FormFieldState<dynamic> field) {
        return InputDecorator(
          decoration: InputDecoration(
            labelText: "משך האימון",
            errorText: field.errorText,
          ),
          child: SizedBox(
            height: 200,
            child: CupertinoTimerPicker(
              mode: CupertinoTimerPickerMode.hm,
              onTimerDurationChanged: (duration) =>
                  _durationMinutes = duration.inMinutes,
            ),
          ),
        );
      },
    );
  }

  String? _durationValidator(dynamic v) {
    if (_durationMinutes == 0) {
      return 'חובה לבחור משך אימון';
    } else {
      return null;
    }
  }
}
