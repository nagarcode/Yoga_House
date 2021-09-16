class PracticeTemplate {
  final String id;
  final String name;
  final String description;
  final String level;

  PracticeTemplate(
    this.id,
    this.name,
    this.description,
    this.level,
  );

  PracticeTemplate.fromJson(dynamic json)
      : id = json['id'],
        name = json['name'],
        description = json['id'],
        level = json['id'];
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'level': level,
      };

  static PracticeTemplate empty() {
    return PracticeTemplate('', '', '', '');
  }
}
