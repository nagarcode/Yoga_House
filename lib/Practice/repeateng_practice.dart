import 'package:yoga_house/User_Info/user_info.dart';

class RepeatingPractice {
  final String id;
  final String name;
  final String description;
  final String level;
  final String location;
  final int maxParticipants;
  final int durationMinutes;
  final List<UserInfo> registeredParticipants;

  RepeatingPractice({
    required this.id,
    required this.name,
    required this.description,
    required this.level,
    required this.location,
    required this.maxParticipants,
    required this.durationMinutes,
    required this.registeredParticipants,
  });

  factory RepeatingPractice.fromMap(Map<String, dynamic> data) {
    // print(data['id']);
    // print(data['name']);
    // print(data['description']);
    // print(data['level']);
    // print(data['location']);
    // print(data['maxParticipants']);
    // print(data['durationMinutes']);
    // print(data['uids']);
    final registeredParticipants = _extractRegisteredUsers(data);
    final practice = RepeatingPractice(
      id: data['id'],
      name: data['name'],
      description: data['description'],
      level: data['level'],
      location: data['location'],
      maxParticipants: data['maxParticipants'],
      durationMinutes: data['durationMinutes'],
      registeredParticipants: registeredParticipants,
    );
    return practice;
  }

  static List<UserInfo> _extractRegisteredUsers(Map<String, dynamic> data) {
    final List<UserInfo> registered = [];
    final usersMap = data['registeredParticipants'];
    if (usersMap.isNotEmpty) {
      for (var key in usersMap.keys) {
        final data = usersMap[key];
        if (data == null) break;
        registered.add(UserInfo.fromMap(data));
      }
    }
    return registered;
  }

  Map<String, Map<String, dynamic>> _mapRegisteredUsers() {
    final Map<String, Map<String, dynamic>> toReturn = {};
    if (registeredParticipants.isEmpty) return toReturn;
    for (var userInfo in registeredParticipants) {
      toReturn[userInfo.uid] = userInfo.toMap();
    }
    return toReturn;
  }

  static List<String> extractUids(List uids) {
    final result = <String>[];
    for (var uid in uids) {
      result.add(uid);
    }
    return result;
  }

  Map<String, dynamic> toMap() {
    final Map<String, Map<String, dynamic>> registeredParticipants =
        _mapRegisteredUsers();
    return {
      'id': id,
      'name': name,
      'description': description,
      'level': level,
      'location': location,
      'maxParticipants': maxParticipants,
      'durationMinutes': durationMinutes,
      'registeredParticipants': registeredParticipants,
    };
  }

  void removeParticipant(UserInfo userToRemove) {
    registeredParticipants.removeWhere(
        (registeredUser) => registeredUser.uid == userToRemove.uid);
  }
}
