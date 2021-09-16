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
}
