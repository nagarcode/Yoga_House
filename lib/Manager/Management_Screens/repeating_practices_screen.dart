import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:persistent_bottom_nav_bar/persistent-tab-view.dart';
import 'package:provider/provider.dart';
import 'package:yoga_house/Practice/repeateng_practice.dart';
import 'package:yoga_house/Practice/repeating_practice_card.dart';
import 'package:yoga_house/Services/database.dart';
import 'package:yoga_house/Services/splash_screen.dart';
import 'package:yoga_house/Services/utils_file.dart';
import 'package:yoga_house/User_Info/user_info.dart';

class RepeatingPracticesScreen extends StatefulWidget {
  final FirestoreDatabase database;
  final UserInfo? userToAdd;

  static Future<void> pushToTabBar(
      BuildContext context, UserInfo? userToAdd) async {
    final database = context.read<FirestoreDatabase>();
    await pushNewScreen(
      context,
      screen: RepeatingPracticesScreen(database, userToAdd),
    );
  }

  const RepeatingPracticesScreen(this.database, this.userToAdd, {Key? key})
      : super(key: key);

  @override
  _RepeatingPracticesScreenState createState() =>
      _RepeatingPracticesScreenState();
}

class _RepeatingPracticesScreenState extends State<RepeatingPracticesScreen> {
  late GlobalKey<FormBuilderState> _formKey, _durationFormKey;
  late String _name, _description, _selectedLvl, _location;
  late int _maxParticipants, _durationMinutes;
  late List<RepeatingPractice>? _practices;
  late bool _isLoading;

  @override
  void initState() {
    _formKey = GlobalKey<FormBuilderState>();
    _durationFormKey = GlobalKey<FormBuilderState>();
    _isLoading = false;
    _durationMinutes = 0;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Utils.appBarTitle(context, 'שיעורים קבועים'),
      ),
      body: StreamBuilder<List<RepeatingPractice>>(
          stream: widget.database.repeatingPracticesStream(),
          builder: (context, snapshot) {
            if (Utils.connectionStateInvalid(snapshot)) {
              return const SplashScreen();
            }
            _practices = snapshot.data;
            final practices = _practices;
            // print(_practices);
            return Column(
              children: [
                _practiceCards(practices),
                if (practices == null || practices.isEmpty) _noTemplatesText(),
                _addTemplateIcon(),
              ],
            );
          }),
    );
  }

  ListView _practiceCards(List<RepeatingPractice>? practices) {
    final cards = <RepeatingPracticeCard>[];
    for (var practice in practices ?? []) {
      cards.add(RepeatingPracticeCard(practice, deleteTemplateCallback,
          userToAdd: widget.userToAdd));
    }
    return ListView(
      children: cards,
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
              confirmText: 'הוסף שיעור',
              onConfirmed: _isLoading ? () {} : () => _submitForm(ctx),
              innerCtx: ctx,
              style: style!,
              formKey: _formKey,
              title: 'שיעור קבוע חדש');
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
              title: 'משך השיעור');
        });
  }

  void deleteTemplateCallback(RepeatingPractice template) async {
    final didRequest = await _didRequestDelete();
    if (!didRequest) return;
    _setIsLoading(true);
    widget.database.deleteRepeatingPractice(template);

    _setIsLoading(false);
  }

  Widget _practiceNameInput(BuildContext ctx, TextStyle labelStyle) {
    const maxChars = 20;
    return FormBuilderTextField(
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

  Widget _descriptionInput(BuildContext ctx, TextStyle labelStyle) {
    const maxChars = 100;
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

  Future<void> _submitForm(BuildContext ctx) async {
    _setIsLoading(true);
    _formKey.currentState?.save();
    final didValidate = _formKey.currentState?.validate();
    if (didValidate != null && didValidate) {
      final template = RepeatingPractice(
          id: Utils.idFromTime(),
          name: _name,
          description: _description,
          level: _selectedLvl,
          location: _location,
          maxParticipants: _maxParticipants,
          durationMinutes: _durationMinutes,
          registeredParticipants: []);

      await widget.database.addRepeatingPractice(template);
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
    // setState(() {
    //   _isLoading = value;
    // });
  }

  // List<PracticeTemplateCard> _notEmptyCards() {
  //   final toReturn = <PracticeTemplateCard>[];
  //   for (PracticeTemplate template in _templates) {
  //     if (!template.isEmpty()) {
  //       toReturn.add(PracticeTemplateCard(
  //           template, () => deleteTemplateCallback(template)));
  //     }
  //   }
  //   return toReturn;
  // }

  Future<bool> _didRequestDelete() async {
    return await showOkCancelAlertDialog(
            context: context,
            message: 'האם למחוק שיעור קבוע זה?',
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
          'לחצי על הפלוס על מנת להוסיף שיעורים קבועים',
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
            labelText: "משך השיעור",
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
      return 'חובה לבחור משך שיעור';
    } else {
      return null;
    }
  }
}
