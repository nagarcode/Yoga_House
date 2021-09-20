import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:yoga_house/Practice/practice.dart';
import 'package:yoga_house/Practice/practice_template.dart';
import 'package:yoga_house/Practice/practice_template_card.dart';
import 'package:yoga_house/Services/database.dart';
import 'package:yoga_house/Services/shared_prefs.dart';
import 'package:yoga_house/Services/utils_file.dart';
import 'package:yoga_house/User_Info/user_info.dart';
import 'package:yoga_house/common_widgets/card_selection_tile.dart';
import 'package:intl/intl.dart';

class ManagerCalendar extends StatefulWidget {
  final SharedPrefs prefs;
  final GlobalKey<ScaffoldState> parentScaffoldKey;
  final FirestoreDatabase database;
  const ManagerCalendar(this.prefs,
      {Key? key, required this.parentScaffoldKey, required this.database})
      : super(key: key);

  @override
  _ManagerCalendarState createState() => _ManagerCalendarState();
}

class _ManagerCalendarState extends State<ManagerCalendar> {
  late GlobalKey<FormBuilderState> _formKey, _durationFormKey, _dateFormKey;
  late String _name, _description, _lvl, _location, _managerName, _managerUID;
  DateTime? _startTime;
  late int _maxParticipants, _durationMinutes;
  late bool _isLoading,
      _didChooseDate,
      _shouldPromtDuration,
      _shouldPromtDetails;

  late ManagerAction _selectedAction;

  @override
  void initState() {
    _selectedAction = ManagerAction.insertWorkoutFromTemplate;
    _formKey = GlobalKey<FormBuilderState>();
    _dateFormKey = GlobalKey<FormBuilderState>();
    _durationFormKey = GlobalKey<FormBuilderState>();
    _isLoading = false;
    _didChooseDate = false;
    _shouldPromtDuration = false;
    _shouldPromtDetails = false;
    _durationMinutes = 0;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SfCalendar(
      onTap: (tapDetails) => _tapped(tapDetails),
      headerStyle: CalendarHeaderStyle(textStyle: theme.textTheme.bodyText2),
      todayHighlightColor: theme.colorScheme.primary,
      minDate: DateTime.now(),
      view: CalendarView.week,
      selectionDecoration: const BoxDecoration(),
      timeSlotViewSettings: const TimeSlotViewSettings(
        timeFormat: 'H:mm',
        startHour: 4,
        // timeInterval: Duration(minutes: 30),
        timeIntervalHeight: 60,
      ),
    );
  }

  _tapped(CalendarTapDetails tapDetails) {
    final appointments = tapDetails.appointments;
    if (appointments != null && appointments.isNotEmpty) {
      _tappedAnAppointment(tapDetails);
    } else {
      _tappedEmptySlot(tapDetails);
    }
  }

  void _tappedAnAppointment(CalendarTapDetails tapDetails) {}

  void _tappedEmptySlot(CalendarTapDetails tapDetails) async {
    _startTime = tapDetails.date;
    final choice = await showDialog<ManagerAction>(
        context: context, builder: (context) => _emptySlotTapDialog(context));
  }

  Widget _emptySlotTapDialog(BuildContext context) {
    return Utils.cardSelectionDialog(context, _emptyTapChoiceTiles(context));
  }

  List<CardSelectionTile> _emptyTapChoiceTiles(BuildContext context) {
    final templates = widget.prefs.practiceTemplates();

    final theme = Theme.of(context);
    return [
      if (PracticeTemplate.numOfNotEmptyTemplates(templates) != 0)
        CardSelectionTile(
          context,
          'הכנס אימון מתבנית מוכנה',
          Icon(Icons.run_circle_outlined, color: theme.colorScheme.primary),
          (context) => _choseInsertWorkoutFromTemplate(context),
        ),
      CardSelectionTile(
        context,
        'הכנס אימון חדש',
        Icon(Icons.run_circle_outlined, color: theme.colorScheme.primary),
        (context) => _choseInsertNewWorkout(context),
      ),
    ];
  }

  _choseInsertNewWorkout(BuildContext context) async {
    Navigator.of(context).pop(ManagerAction.insertNewWorkout);
  }

  _choseInsertWorkoutFromTemplate(BuildContext context) async {
    Navigator.of(context).pop(ManagerAction.insertWorkoutFromTemplate);
    await showDialog<PracticeTemplate>(
        context: context,
        builder: (context) =>
            _templateSelectionDialog(context, _templatesChoiceTiles(context)));
  }

  _templateSelectionDialog(
      BuildContext context, List<Widget> templatesChoiceTiles) {
    return Center(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ListView(
          shrinkWrap: true,
          children: templatesChoiceTiles,
        ),
      ),
    );
  }

  List<Widget> _templatesChoiceTiles(BuildContext context) {
    final templates = widget.prefs.practiceTemplates();
    final toReturn = <PracticeTemplateCard>[];
    for (PracticeTemplate template in templates) {
      if (!template.isEmpty()) {
        toReturn.add(PracticeTemplateCard(template, () => {},
            selectionScreen: true,
            onClicked: (PracticeTemplate temp) =>
                _addWorkoutFromTemplate(context, temp)));
      }
    }
    return toReturn;
  }

  _addWorkoutFromTemplate(BuildContext context, PracticeTemplate template) {
    final style = Theme.of(context).textTheme.headline6;
    final labelStyle = Theme.of(context).textTheme.subtitle2;
    Navigator.of(context).pop();
    _initPracticeDetails(template);
    _initTraineDetails(); // single trainer for now
    _promtDetails(context, style!, labelStyle!);
  }

  void _initPracticeDetails(PracticeTemplate template) {
    _name = template.name;
    _description = template.description;
    _lvl = template.level;
    _location = template.location;
    _maxParticipants = template.maxParticipants;
    _durationMinutes = template.durationMinutes;
  }

  void _initTraineDetails() {
    final userInfo = context.read<UserInfo>();
    _managerName = userInfo.name;
    _managerUID = userInfo.uid;
  }

  void _promtDetails(
      BuildContext context, TextStyle style, TextStyle labelStyle) async {
    await _promtDate(style, labelStyle);
    if (!_shouldPromtDuration) {
      _shouldPromtDetails = false;
      return;
    }
    await _promtDuration(style, labelStyle);
    if (!_shouldPromtDetails) {
      _shouldPromtDuration = false;
      return;
    }
    await showCupertinoModalPopup(
        useRootNavigator: true,
        context: widget.parentScaffoldKey.currentContext!,
        builder: (ctx) {
          return Utils.bottomSheetFormBuilder(
              context,
              [
                _nameInput(ctx, labelStyle),
                _descriptionInput(ctx, labelStyle),
                _lvlInput(ctx, labelStyle),
                _locationInput(ctx, labelStyle),
                _maxParticipantsInput(ctx, labelStyle),
              ],
              'הוסף אימון',
              () => _submitForm(ctx),
              ctx,
              style,
              _formKey,
              'הכנס אימון');
        });
  }

  Future<void> _submitForm(BuildContext ctx) async {
    _setIsLoading(true);
    _formKey.currentState?.save();
    final didValidate = _formKey.currentState?.validate();
    if (didValidate != null && didValidate) {
      _shouldPromtDetails = false;
      _shouldPromtDuration = false;
      await _createAndPersistPractice();
      Navigator.of(ctx).pop();
      showOkAlertDialog(
          context: widget.parentScaffoldKey.currentContext!,
          message: 'השיעור נוסף בהצלחה',
          title: 'הצלחה',
          okLabel: 'אוקי');
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

  _nameInput(BuildContext ctx, TextStyle labelStyle) {
    const maxChars = 20;
    return FormBuilderTextField(
      initialValue: _name,
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

  _descriptionInput(BuildContext ctx, TextStyle labelStyle) {
    const maxChars = 60;
    return FormBuilderTextField(
      initialValue: _description,
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

  _lvlInput(BuildContext ctx, TextStyle labelStyle) {
    const maxChars = 20;
    return FormBuilderTextField(
      initialValue: _lvl,
      maxLength: maxChars,
      onChanged: (newStr) {
        if (newStr != null) _lvl = newStr;
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

  _maxParticipantsInput(BuildContext ctx, TextStyle labelStyle) {
    const maxChars = 3;
    return FormBuilderTextField(
      initialValue: _maxParticipants.toString(),
      maxLength: maxChars,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      name: 'maxParticipants',
      decoration: InputDecoration(
          labelText: 'מס׳ מתאמנים מקסימלי', labelStyle: labelStyle),
      onChanged: (newStr) {
        if (newStr != null) _maxParticipants = int.parse(newStr);
      },
      validator: FormBuilderValidators.compose([
        FormBuilderValidators.required(ctx),
        FormBuilderValidators.integer(ctx),
      ]),
    );
  }

  _promtDate(TextStyle style, TextStyle labelStyle) async {
    _didChooseDate = true;
    await showCupertinoModalPopup(
        useRootNavigator: true,
        context: context,
        builder: (ctx) {
          return Utils.bottomSheetFormBuilder(
              context,
              [
                _dateInput(ctx, labelStyle),
              ],
              'אישור',
              () => _submitDateForm(ctx),
              ctx,
              style,
              _dateFormKey,
              'זמן התחלה');
        });
  }

  String? _dateValidator(dynamic v) {
    if (_didChooseDate == false) {
      return 'חובה לבחור זמן התחלה';
    } else {
      return null;
    }
  }

  _dateInput(BuildContext ctx, TextStyle textStyle) {
    return FormBuilderField(
      name: "start time",
      validator: _dateValidator,
      builder: (FormFieldState<dynamic> field) {
        return InputDecorator(
          decoration: InputDecoration(
            labelText: "זמן התחלה",
            errorText: field.errorText,
          ),
          child: Container(
            height: 200,
            child: CupertinoDatePicker(
              use24hFormat: true,
              initialDateTime: _startTime ?? DateTime.now(),
              onDateTimeChanged: (newTime) => _startTime = newTime,
              minimumDate: DateTime.now(),
            ),
          ),
        );
      },
    );
  }

  _durationInput(BuildContext ctx, TextStyle textStyle) {
    return FormBuilderField(
      name: "duration",
      validator: _durationValidator,
      builder: (FormFieldState<dynamic> field) {
        return InputDecorator(
          decoration: InputDecoration(
            labelText: "משך שיעור",
            errorText: field.errorText,
          ),
          child: Container(
            height: 200,
            child: CupertinoTimerPicker(
              initialTimerDuration: Duration(minutes: _durationMinutes),
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

  void _submitDateForm(BuildContext ctx) {
    _setIsLoading(true);
    _durationFormKey.currentState?.save();
    final didValidate = _dateFormKey.currentState?.validate();
    if (didValidate != null && didValidate) {
      _shouldPromtDuration = true;
      Navigator.of(ctx).pop();
    } else {
      debugPrint("validation failed");
    }
    _setIsLoading(false);
  }

  _promtDuration(TextStyle style, TextStyle labelStyle) async {
    await showCupertinoModalPopup(
        useRootNavigator: true,
        context: context,
        builder: (ctx) {
          return Utils.bottomSheetFormBuilder(
              context,
              [
                _durationInput(ctx, labelStyle),
              ],
              'אישור',
              () => _submitDurationForm(ctx),
              ctx,
              style,
              _durationFormKey,
              'משך שיעור');
        });
  }

  void _submitDurationForm(BuildContext ctx) {
    _setIsLoading(true);
    _durationFormKey.currentState?.save();
    final didValidate = _durationFormKey.currentState?.validate();
    if (didValidate != null && didValidate) {
      _shouldPromtDetails = true;
      _shouldPromtDuration = false;
      Navigator.of(ctx).pop();
    } else {
      debugPrint("validation failed");
    }
    _setIsLoading(false);
  }

  _createAndPersistPractice() async {
    final userInfo = context.read<UserInfo>();
    final endTime = _startTime!.add(Duration(minutes: _durationMinutes));
    final practice = Practice(
        Utils.idFromTime(),
        _name,
        _lvl,
        userInfo.name,
        userInfo.uid,
        _description,
        _location,
        _startTime!,
        endTime,
        _maxParticipants,
        [],
        0);
    await widget.database.addPractice(practice);
  }
}

enum ManagerAction {
  insertWorkoutFromTemplate,
  insertNewWorkout,
}
