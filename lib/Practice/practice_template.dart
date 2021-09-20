class PracticeTemplate {
  final String id;
  final String name;
  final String description;
  final String level;
  final String location;
  final int maxParticipants;
  final int durationMinutes;

  PracticeTemplate(
    this.id,
    this.name,
    this.description,
    this.level,
    this.location,
    this.maxParticipants,
    this.durationMinutes,
  );

  static int get maxTemplates => 4;

  PracticeTemplate.fromJson(dynamic json)
      : id = json['id'],
        name = json['name'],
        description = json['description'],
        level = json['level'],
        location = json['location'],
        maxParticipants = json['maxParticipants'],
        durationMinutes = json['durationMinutes'];
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'level': level,
        'location': location,
        'maxParticipants': maxParticipants,
        'durationMinutes': durationMinutes,
      };

  static PracticeTemplate empty() {
    return PracticeTemplate('', '', '', '', '', 0, 0);
  }

  bool isEmpty() {
    return id == '' && name == '' && description == '' && level == '';
  }

  static int numOfNotEmptyTemplates(List<PracticeTemplate> templates) {
    int i = 0;
    for (var template in templates) {
      if (!template.isEmpty()) i++;
    }
    return i;
  }
}
