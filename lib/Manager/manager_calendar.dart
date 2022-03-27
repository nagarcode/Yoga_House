// ignore_for_file: unused_field

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
import 'package:yoga_house/Practice/repeateng_practice.dart';
import 'package:yoga_house/Practice/repeating_practice_card.dart';
import 'package:yoga_house/Services/app_info.dart';
import 'package:yoga_house/Services/database.dart';
import 'package:yoga_house/Services/notifications.dart';
import 'package:yoga_house/Services/shared_prefs.dart';
import 'package:yoga_house/Services/utils_file.dart';
import 'package:yoga_house/User_Info/user_info.dart';
import 'package:yoga_house/common_widgets/card_selection_tile.dart';

class ManagerCalendar extends StatefulWidget {
  final SharedPrefs prefs;
  final GlobalKey<ScaffoldState> parentScaffoldKey;
  final FirestoreDatabase database;
  final NotificationService notifications;
  const ManagerCalendar(this.prefs, this.notifications,
      {Key? key, required this.parentScaffoldKey, required this.database})
      : super(key: key);

  @override
  _ManagerCalendarState createState() => _ManagerCalendarState();
}

class _ManagerCalendarState extends State<ManagerCalendar> {
  late GlobalKey<FormBuilderState> _formKey, _durationFormKey, _dateFormKey;
  String? _name, _description, _lvl, _location, _managerName, _managerUID;
  DateTime? _startTime;
  int? _maxParticipants;
  late int _durationMinutes;
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
    // _name = null;
    // _description = null;
    // _lvl = ;
    // _location = '';
    // _managerName = '';
    // _managerUID = '';
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SfCalendar(
      onTap: (tapDetails) => _tapped(tapDetails),
      dataSource: _dataSource(),
      headerStyle: CalendarHeaderStyle(textStyle: theme.textTheme.bodyText2),
      todayHighlightColor: theme.colorScheme.primary,
      minDate: DateTime.now(),
      view: CalendarView.week,
      selectionDecoration: const BoxDecoration(),
      timeSlotViewSettings: const TimeSlotViewSettings(
        timeFormat: 'H:mm',
        startHour: 5,
        endHour: 23,
        timeIntervalHeight: 32,
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

  void _tappedAnAppointment(CalendarTapDetails tapDetails) async {
    final appInfo = context.read<AppInfo>();
    final notifications = context.read<NotificationService>();
    final apts = tapDetails.appointments;
    if (apts == null || apts.isEmpty) return;
    final appointment = apts.first;
    final practice = _getPracticeWithId(appointment.id);
    await practice.onTap(context, widget.database, appInfo, notifications);
  }

  void _tappedEmptySlot(CalendarTapDetails tapDetails) async {
    _startTime = tapDetails.date;
    await showDialog<ManagerAction>(
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
          'הכנס שיעור מתבנית מוכנה',
          Icon(Icons.run_circle_outlined, color: theme.colorScheme.primary),
          (context) => _choseInsertWorkoutFromTemplate(context),
        ),
      CardSelectionTile(
        context,
        'הכנס שיעור חדש',
        Icon(Icons.run_circle_outlined, color: theme.colorScheme.primary),
        (context) => _choseInsertNewWorkout(context),
      ),
      CardSelectionTile(
        context,
        'הכנס שיעור עם רשומים קבועים',
        Icon(Icons.loop_outlined, color: theme.colorScheme.primary),
        (context) => _choseInsertRepeating(context),
      ),
    ];
  }

  _choseInsertNewWorkout(BuildContext context) async {
    final style = Theme.of(context).textTheme.headline6;
    final labelStyle = Theme.of(context).textTheme.subtitle2;
    Navigator.of(context).pop(ManagerAction.insertNewWorkout);
    _initTraineDetails(); // single trainer for now
    _promtDetails(context, style!, labelStyle!, []);
  }

  _choseInsertWorkoutFromTemplate(BuildContext context) async {
    Navigator.of(context).pop(ManagerAction.insertWorkoutFromTemplate);
    await showDialog<PracticeTemplate>(
        context: context,
        builder: (context) =>
            _templateSelectionDialog(context, _templatesChoiceTiles(context)));
  }

  _choseInsertRepeating(BuildContext context) async {
    Navigator.of(context).pop(ManagerAction.insertRepeatingPractice);
    await showDialog<RepeatingPractice>(
        context: context,
        builder: (context) => _repeatingPracticeSelectionDialog(
            context, _repeatingPracticeChoiceTiles(context)));
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

  _repeatingPracticeSelectionDialog(
      BuildContext context, List<Widget> _repeatingPracticeChoiceTiles) {
    return Center(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ListView(
          shrinkWrap: true,
          children: _repeatingPracticeChoiceTiles,
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

  List<Widget> _repeatingPracticeChoiceTiles(BuildContext ctxt) {
    final practices = context.read<List<RepeatingPractice>>();
    final toReturn = <RepeatingPracticeCard>[];
    for (RepeatingPractice repeatingPractice in practices) {
      toReturn.add(RepeatingPracticeCard(repeatingPractice, () => {},
          selectionScreen: true,
          ctxt: context,
          onClicked: (RepeatingPractice pract) =>
              _addWorkoutFromRepeatingPractice(ctxt, pract)));
    }
    return toReturn;
  }

  _addWorkoutFromTemplate(BuildContext context, PracticeTemplate template) {
    final style = Theme.of(context).textTheme.headline6;
    final labelStyle = Theme.of(context).textTheme.subtitle2;
    Navigator.of(context).pop();
    _initPracticeDetails(template);
    _initTraineDetails(); // single trainer for now
    _promtDetails(context, style!, labelStyle!, []);
  }

  _addWorkoutFromRepeatingPractice(
      BuildContext context, RepeatingPractice practice) async {
    final style = Theme.of(context).textTheme.headline6;
    final labelStyle = Theme.of(context).textTheme.subtitle2;
    Navigator.of(context).pop();
    if (!await _promtAddRepeatingPractice(practice)) return;
    if (!await _notifyIfNotEnoughPunches(practice.registeredParticipants)) {
      return;
    }
    _initRepeatingPracticeDetails(practice);
    _initTraineDetails();
    _promtDetails(
        context, style!, labelStyle!, practice.registeredParticipants);
  }

  void _initPracticeDetails(PracticeTemplate template) {
    _name = template.name;
    _description = template.description;
    _lvl = template.level;
    _location = template.location;
    _maxParticipants = template.maxParticipants;
    _durationMinutes = template.durationMinutes;
  }

  void _initRepeatingPracticeDetails(RepeatingPractice template) {
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

  void _promtDetails(BuildContext context, TextStyle style,
      TextStyle labelStyle, List<UserInfo> usersToRegister) async {
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
              inputFields: [
                _nameInput(ctx, labelStyle),
                _descriptionInput(ctx, labelStyle),
                _lvlInput(ctx, labelStyle),
                _locationInput(ctx, labelStyle),
                _maxParticipantsInput(ctx, labelStyle),
              ],
              confirmText: 'הוסף שיעור',
              onConfirmed: () => _submitForm(ctx, usersToRegister),
              innerCtx: ctx,
              style: style,
              formKey: _formKey,
              title: 'הכנס שיעור');
        });
  }

  Future<void> _submitForm(
      BuildContext ctx, List<UserInfo> usersToRegister) async {
    _setIsLoading(true);
    _formKey.currentState?.save();
    final didValidate = _formKey.currentState?.validate();
    if (didValidate != null && didValidate) {
      _shouldPromtDetails = false;
      _shouldPromtDuration = false;
      final practice = await _createAndPersistPractice();
      if (usersToRegister.isNotEmpty) {
        await _registerAllParticipants(usersToRegister, practice, ctx);
      }
      final context = widget.parentScaffoldKey.currentContext ?? ctx;
      await showOkAlertDialog(
          context: context,
          message: 'השיעור נוסף בהצלחה',
          title: 'הצלחה',
          okLabel: 'אוקי');
      Navigator.of(ctx).pop();
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

  _descriptionInput(BuildContext ctx, TextStyle labelStyle) {
    const maxChars = 80;
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
      initialValue: _maxParticipants?.toString(),
      maxLength: maxChars,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      name: 'maxParticipants',
      decoration: InputDecoration(
          labelText: 'מס׳ מתאמנים מקסימלי', labelStyle: labelStyle),
      onChanged: (newStr) {
        if (newStr != null) _maxParticipants = int.tryParse(newStr) ?? 0;
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
              inputFields: [
                _dateInput(ctx, labelStyle),
              ],
              confirmText: 'אישור',
              onConfirmed: () => _submitDateForm(ctx),
              innerCtx: ctx,
              style: style,
              formKey: _dateFormKey,
              title: 'זמן התחלה');
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
          child: SizedBox(
            height: 200,
            child: CupertinoDatePicker(
              use24hFormat: true,
              initialDateTime: _getStartTime(),
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
          child: SizedBox(
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
              inputFields: [
                _durationInput(ctx, labelStyle),
              ],
              confirmText: 'אישור',
              onConfirmed: () => _submitDurationForm(ctx),
              innerCtx: ctx,
              style: style,
              formKey: _durationFormKey,
              title: 'משך שיעור');
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
    final name = _name;
    final lvl = _lvl;
    final description = _description;
    final location = _location;
    final maxParticipants = _maxParticipants;
    if (name == null ||
        lvl == null ||
        description == null ||
        location == null ||
        maxParticipants == null) return;
    final practice = Practice(
      Utils.idFromTime(),
      name,
      lvl,
      userInfo.name,
      userInfo.uid,
      description,
      location,
      _startTime!,
      endTime,
      maxParticipants,
      [],
      0,
      [],
      true,
    );
    await widget.database.addPractice(practice);
    _resetFields();
    return practice;
  }

  DateTime _getStartTime() {
    final startTime = _startTime;
    if (startTime != null) {
      if (DateTime.now().isAfter(startTime)) {
        return DateTime.now().add(const Duration(seconds: 60));
      } else {
        return startTime;
      }
    } else {
      return DateTime.now().add(const Duration(seconds: 60));
    }
  }

  _dataSource() {
    final practices = context.read<List<Practice>>();
    final theme = Theme.of(context);
    final appointments = <Appointment>[];
    for (var practice in practices) {
      final registered = practice.numOfRegisteredParticipants;
      final max = practice.maxParticipants;
      final sub = '$registered/$max';
      final apt = Appointment(
        id: practice.id,
        startTime: practice.startTime,
        endTime: practice.endTime,
        subject: '${practice.name} $sub',
        color: practice.isLocked ? Colors.grey : theme.colorScheme.primary,
      );
      appointments.add(apt);
    }
    return DataSource(appointments);
  }

  Practice _getPracticeWithId(id) {
    final practices = context.read<List<Practice>>();
    final practice = practices.firstWhere((element) => element.id == id);
    return practice;
  }

  void _resetFields() {
    _name = null;
    _description = null;
    _lvl = null;
    _location = null;
    _startTime = null;
    _maxParticipants = null;
    _durationMinutes = 0;
    _isLoading = false;
    _didChooseDate = false;
    _shouldPromtDuration = false;
    _shouldPromtDetails = false;
  }

  Future<bool> _notifyIfNotEnoughPunches(
      List<UserInfo> registeredParticipants) async {
    final noPunchesLeft = _getUsersWithNoPunches(registeredParticipants);
    return await _displayNoPunchesAlert(noPunchesLeft);
  }

  List<UserInfo> _getUsersWithNoPunches(List<UserInfo> registeredParticipants) {
    return registeredParticipants.where((element) {
      final punchcard = element.punchcard;
      if (punchcard == null) {
        return true;
      }
      if (punchcard.hasPunchesLeft) {
        return false;
      } else {
        return true;
      }
    }).toList();
  }

  Future<bool> _displayNoPunchesAlert(List<UserInfo> noPunchesLeft) async {
    if (noPunchesLeft.isEmpty) {
      return true;
    }
    var usersText = '';
    for (var user in noPunchesLeft) {
      usersText += (user.name + ', ');
    }
    usersText = usersText.replaceRange(usersText.length - 2, null, '.');

    final txt =
        "לרשומים הבאים נגמרו הניקובים: $usersText \n האם ברצונך להמשיך ולרשום את כל השאר או לבטל את הוספת השיעור?";
    return await showOkCancelAlertDialog(
            context: context,
            title: 'לא מספיק ניקובים',
            message: txt,
            okLabel: 'המשך') ==
        OkCancelResult.ok;
  }

  _registerAllParticipants(List<UserInfo> usersToRegister, Practice practice,
      BuildContext ctx) async {
    for (var user in usersToRegister) {
      await widget.database
          .registerUserToPracticeTransaction(user, practice.id);
      widget.notifications.sendManagerRegisteredYouNotification(user, practice);
    }
  }

  Future<bool> _promtAddRepeatingPractice(RepeatingPractice practice) async {
    if (practice.registeredParticipants.isEmpty) return true;
    var usersText = '';
    for (var user in practice.registeredParticipants) {
      usersText += (user.name + ', ');
    }
    usersText = usersText.replaceRange(usersText.length - 2, null, '.');
    final txt =
        "הוספת שיעור קבוע זה תרשום אוטומטית את כל המתאמנים הבאים: $usersText \n האם להמשיך?";
    return await showOkCancelAlertDialog(
            context: context, title: 'רישום אוטומטי', message: txt) ==
        OkCancelResult.ok;
  }
}

class DataSource extends CalendarDataSource {
  DataSource(List<Appointment> apts) {
    appointments = apts;
  }
}

enum ManagerAction {
  insertWorkoutFromTemplate,
  insertNewWorkout,
  insertRepeatingPractice,
}
