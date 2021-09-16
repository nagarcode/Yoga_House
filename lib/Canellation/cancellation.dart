class Cancellation {
  final DateTime requestedOn;
  final DateTime practiceID;
  final DateTime practiceWasOn;
  final bool isEnoughTimeInAdvance;

  Cancellation(this.requestedOn, this.practiceID, this.practiceWasOn,
      this.isEnoughTimeInAdvance);
}
