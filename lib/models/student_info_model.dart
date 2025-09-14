class StudentInfoModel {
  final String? schoolName;
  final String? faculty;
  final String? department;

  StudentInfoModel({
    this.schoolName,
    this.faculty,
    this.department,
  });

  factory StudentInfoModel.fromJson(Map<String, dynamic> json) {
    return StudentInfoModel(
      schoolName: json['schoolName'] as String? ?? '',
      faculty: json['faculty'] as String? ?? '',
      department: json['department'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schoolName': schoolName,
      'faculty': faculty,
      'department': department,
    };
  }
}
