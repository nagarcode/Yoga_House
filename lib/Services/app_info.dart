class AppInfo {
  final String adminPhone;
  final String homepageText;
  final int minHoursToCancel;
  final bool isManagerTerminated;
  final bool isClientTerminated;

  AppInfo(this.adminPhone, this.homepageText, this.minHoursToCancel,
      this.isManagerTerminated, this.isClientTerminated);

  factory AppInfo.fromMap(Map<String, dynamic> data) {
    final adminPhone = data['adminPhone'];
    final homepageText = data['homepageText'];
    final minHoursToCancel = data['minHoursToCancel'];
    final isManagerTerminated = data['isManagerTerminated'];
    final isClientTerminated = data['isClientTerminated'];

    return AppInfo(adminPhone, homepageText, minHoursToCancel,
        isManagerTerminated, isClientTerminated);
  }

  AppInfo copyWith(
      {String? adminPhone,
      String? homepageText,
      int? minHoursToCancel,
      bool? isManagerTerminated,
      bool? isClientTerminated}) {
    return AppInfo(
        adminPhone ?? this.adminPhone,
        homepageText ?? this.homepageText,
        minHoursToCancel ?? this.minHoursToCancel,
        isManagerTerminated ?? this.isManagerTerminated,
        isClientTerminated ?? this.isClientTerminated);
  }

  Map<String, dynamic> toMap() {
    return {
      'adminPhone': adminPhone,
      'homepageText': homepageText,
      'minHoursToCancel': minHoursToCancel,
      'isManagerTerminated': isManagerTerminated,
      'isClientTerminated': isClientTerminated,
    };
  }
}
