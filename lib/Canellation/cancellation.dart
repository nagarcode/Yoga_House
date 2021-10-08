import 'package:yoga_house/Practice/practice.dart';

class Cancellation {
  final DateTime requestedOn;
  final Practice practice;
  final DateTime practiceWasOn;
  final bool isEnoughTimeInAdvance;

  Cancellation(this.requestedOn, this.practice, this.practiceWasOn,
      this.isEnoughTimeInAdvance);

  factory Cancellation.fromMap(Map<String, dynamic> data) {
    return Cancellation(
      data['requestedOn'].toDate(),
      Practice.fromMap(data['practice']),
      data['practiceWasOn'].toDate(),
      data['isEnoughTimeInAdvance'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'requestedOn': requestedOn,
      'practice': practice.toMap(),
      'practiceWasOn': practiceWasOn,
      'isEnoughTimeInAdvance': isEnoughTimeInAdvance
    };
  }
}
