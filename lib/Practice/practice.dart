import 'package:yoga_house/User_Info/user_info.dart';

class Practice {
  final String id;
  final String name;
  final String level;
  final String managerName;
  final String managerUID;
  final String description;
  final String location;
  final DateTime startTime;
  final DateTime endTime;
  final int maxParticipants;
  final List<UserInfo> registeredParticipants;
  final int numOfUsersInWaitingList;

  Practice(
    this.id,
    this.name,
    this.level,
    this.managerName,
    this.managerUID,
    this.description,
    this.location,
    this.startTime,
    this.endTime,
    this.maxParticipants,
    this.registeredParticipants,
    this.numOfUsersInWaitingList,
  );
  factory Practice.fromMap(Map<String, dynamic> data) {
    return Practice(
        data['id'],
        data['name'],
        data['level'],
        data['managerName'],
        data['managerUID'],
        data['description'],
        data['location'],
        data['startTime'].toDate(),
        data['endTime'].toDate(),
        data['maxParticipants'],
        [], //TODO get registered participants - proxy?
        data['numOfUsersInWaitingList']);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'level': level,
      'managerName': managerName,
      'managerUID': managerUID,
      'description': description,
      'location': location,
      'startTime': startTime,
      'endTime': endTime,
      'maxParticipants': maxParticipants,
      'numOfUsersInWaitingList': numOfUsersInWaitingList,
    };
  }
}
