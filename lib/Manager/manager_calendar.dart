import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:yoga_house/Services/utils_file.dart';
import 'package:yoga_house/common_widgets/card_selection_tile.dart';

class ManagerCalendar extends StatefulWidget {
  const ManagerCalendar({Key? key}) : super(key: key);

  @override
  _ManagerCalendarState createState() => _ManagerCalendarState();
}

class _ManagerCalendarState extends State<ManagerCalendar> {
  late ManagerAction _selectedAction;
  @override
  void initState() {
    _selectedAction = ManagerAction.insertWorkout;
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
    final choice = await showDialog<ManagerAction>(
        context: context, builder: (context) => _emptySlotTapDialog(context));
  }

  Widget _emptySlotTapDialog(BuildContext context) {
    return Utils.cardSelectionDialog(context, _emptyTapChoiceTiles(context));
  }

  List<CardSelectionTile> _emptyTapChoiceTiles(BuildContext context) {
    final theme = Theme.of(context);
    return [
      CardSelectionTile(
        context,
        'הכנס אימון',
        Icon(Icons.run_circle_outlined, color: theme.colorScheme.primary),
        (context) => Navigator.of(context).pop(ManagerAction.insertWorkout),
      ),
    ];
  }
}

enum ManagerAction {
  insertWorkout,
}
