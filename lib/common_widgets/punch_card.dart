class Punchcard {
  final DateTime purchasedOn;
  final DateTime expiresOn;
  final int punchesPurchased;
  final int punchesRemaining;
  int get punchesUsed => punchesPurchased - punchesRemaining;
  bool get hasPunchesLeft => punchesRemaining > 0;

  Punchcard({
    required this.purchasedOn,
    required this.punchesPurchased,
    required this.expiresOn,
    required this.punchesRemaining,
  });

  Punchcard copyWith(
      {DateTime? purchasedOn,
      DateTime? expiresOn,
      int? punchesPurchased,
      int? punchesRemaining}) {
    return Punchcard(
        purchasedOn: purchasedOn ?? this.purchasedOn,
        punchesPurchased: punchesPurchased ?? this.punchesPurchased,
        expiresOn: expiresOn ?? this.expiresOn,
        punchesRemaining: punchesRemaining ?? this.punchesRemaining);
  }

  factory Punchcard.fromMap(Map<String, dynamic> data) {
    return Punchcard(
      purchasedOn: data['purchasedOn'].toDate(),
      expiresOn: data['expiresOn'].toDate(),
      punchesRemaining: data['punchesRemaining'],
      punchesPurchased: data['punchesPurchased'],
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'purchasedOn': purchasedOn,
      'expiresOn': expiresOn,
      'punchesPurchased': punchesPurchased,
      'punchesRemaining': punchesRemaining,
    };
  }

  Punchcard aggregate(Punchcard newPunchCard) {
    return newPunchCard.copyWith(
        punchesRemaining: punchesRemaining + newPunchCard.punchesRemaining);
  }

  Punchcard copyWithDecrementPunches() {
    if (punchesRemaining <= 0) throw Exception('punches already 0');
    return copyWith(punchesRemaining: punchesRemaining - 1);
  }

  Punchcard copyWithIncrementPunches() {
    return copyWith(punchesRemaining: punchesRemaining + 1);
  }
}
