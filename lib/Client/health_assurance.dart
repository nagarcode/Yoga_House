class HealthAssurance {
  final bool bloodPressure;
  final bool diabetes;
  final bool headachesDizzinessWeakness;
  final bool astma;
  final bool balance;
  final bool neck;
  final bool wrist;
  final bool spine;
  final bool digestion;
  final bool ears;
  final bool eyes;
  final bool chronicStuff;
  final bool surgery;
  final bool smoking;
  final bool calcium;
  final bool pregnant;
  final bool pregnantStuff;
  final int numOfBirths;
  final bool periodProblems;
  final String notes;
  final String name;
  final String phone;
  final String address;
  final int age;
  final String email;
  final DateTime date;

  HealthAssurance({
    required this.bloodPressure,
    required this.diabetes,
    required this.headachesDizzinessWeakness,
    required this.astma,
    required this.balance,
    required this.neck,
    required this.wrist,
    required this.spine,
    required this.digestion,
    required this.ears,
    required this.eyes,
    required this.chronicStuff,
    required this.surgery,
    required this.smoking,
    required this.calcium,
    required this.pregnant,
    required this.pregnantStuff,
    required this.numOfBirths,
    required this.periodProblems,
    required this.notes,
    required this.name,
    required this.phone,
    required this.address,
    required this.age,
    required this.email,
    required this.date,
  });
  factory HealthAssurance.fromMap(Map<String, dynamic> data) {
    return HealthAssurance(
      bloodPressure: data['bloodPressure'],
      diabetes: data['diabetes'],
      headachesDizzinessWeakness: data['headachesDizzinessWeakness'],
      astma: data['astma'],
      balance: data['balance'],
      neck: data['neck'],
      wrist: data['wrist'],
      spine: data['spine'],
      digestion: data['digestion'],
      ears: data['ears'],
      eyes: data['eyes'],
      chronicStuff: data['chronicStuff'],
      surgery: data['surgery'],
      smoking: data['smoking'],
      calcium: data['calcium'],
      pregnant: data['pregnant'],
      pregnantStuff: data['pregnantStuff'],
      numOfBirths: data['numOfBirths'],
      periodProblems: data['periodProblems'],
      notes: data['notes'],
      name: data['name'],
      phone: data['phone'],
      address: data['address'],
      age: data['age'],
      email: data['email'],
      date: data['date'].toDate(),
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'bloodPressure': bloodPressure,
      'diabetes': diabetes,
      'headachesDizzinessWeakness': headachesDizzinessWeakness,
      'astma': astma,
      'balance': balance,
      'neck': neck,
      'wrist': wrist,
      'spine': spine,
      'digestion': digestion,
      'ears': ears,
      'eyes': eyes,
      'chronicStuff': chronicStuff,
      'surgery': surgery,
      'smoking': smoking,
      'calcium': calcium,
      'pregnant': pregnant,
      'pregnantStuff': pregnantStuff,
      'numOfBirths': numOfBirths,
      'periodProblems': periodProblems,
      'notes': notes,
      'name': name,
      'phone': phone,
      'address': address,
      'age': age,
      'email': email,
      'date': date,
    };
  }
}
