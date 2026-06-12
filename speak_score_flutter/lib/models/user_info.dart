class UserInfo {
  final int? id;
  final String? username;
  final String? nickname;
  final String? realName;
  final String? avatar;
  final String? phone;
  final int? gender;
  final List<String>? roles;
  final int? schoolId;
  final String? schoolName;
  final int? classId;
  final String? className;
  final int? gradeId;
  final String? gradeName;

  const UserInfo({
    this.id,
    this.username,
    this.nickname,
    this.realName,
    this.avatar,
    this.phone,
    this.gender,
    this.roles,
    this.schoolId,
    this.schoolName,
    this.classId,
    this.className,
    this.gradeId,
    this.gradeName,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'] as int?,
      username: json['username'] as String?,
      nickname: json['nickname'] as String?,
      realName: json['realName'] as String?,
      avatar: json['avatar'] as String?,
      phone: json['phone'] as String?,
      gender: json['gender'] as int?,
      roles: (json['roles'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      schoolId: json['schoolId'] as int?,
      schoolName: json['schoolName'] as String?,
      classId: json['classId'] as int?,
      className: json['className'] as String?,
      gradeId: json['gradeId'] as int?,
      gradeName: json['gradeName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'nickname': nickname,
      'realName': realName,
      'avatar': avatar,
      'phone': phone,
      'gender': gender,
      'roles': roles,
      'schoolId': schoolId,
      'schoolName': schoolName,
      'classId': classId,
      'className': className,
      'gradeId': gradeId,
      'gradeName': gradeName,
    };
  }
}

class TokenResponse {
  final String? accessToken;
  final String? refreshToken;
  final int? expiresIn;
  final UserInfo? userInfo;
  final bool? isNewUser;

  const TokenResponse({
    this.accessToken,
    this.refreshToken,
    this.expiresIn,
    this.userInfo,
    this.isNewUser,
  });

  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    return TokenResponse(
      accessToken: json['accessToken'] as String?,
      refreshToken: json['refreshToken'] as String?,
      expiresIn: json['expiresIn'] as int?,
      userInfo: json['userInfo'] != null
          ? UserInfo.fromJson(json['userInfo'] as Map<String, dynamic>)
          : null,
      isNewUser: json['isNewUser'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiresIn': expiresIn,
      'userInfo': userInfo?.toJson(),
      'isNewUser': isNewUser,
    };
  }
}

class School {
  final int? id;
  final String? schoolName;
  final String? schoolCode;
  final String? province;
  final String? city;
  final String? district;

  const School({
    this.id,
    this.schoolName,
    this.schoolCode,
    this.province,
    this.city,
    this.district,
  });

  factory School.fromJson(Map<String, dynamic> json) {
    return School(
      id: json['id'] as int?,
      schoolName: json['schoolName'] as String?,
      schoolCode: json['schoolCode'] as String?,
      province: json['province'] as String?,
      city: json['city'] as String?,
      district: json['district'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'schoolName': schoolName,
      'schoolCode': schoolCode,
      'province': province,
      'city': city,
      'district': district,
    };
  }
}

class Grade {
  final int? id;
  final String? gradeName;
  final String? gradeCode;
  final int? gradeLevel;
  final int? schoolId;

  const Grade({
    this.id,
    this.gradeName,
    this.gradeCode,
    this.gradeLevel,
    this.schoolId,
  });

  factory Grade.fromJson(Map<String, dynamic> json) {
    return Grade(
      id: json['id'] as int?,
      gradeName: json['gradeName'] as String?,
      gradeCode: json['gradeCode'] as String?,
      gradeLevel: json['gradeLevel'] as int?,
      schoolId: json['schoolId'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gradeName': gradeName,
      'gradeCode': gradeCode,
      'gradeLevel': gradeLevel,
      'schoolId': schoolId,
    };
  }
}

class ClassInfo {
  final int? id;
  final String? className;
  final String? classCode;
  final int? gradeId;
  final String? gradeName;
  final int? schoolId;
  final String? schoolName;
  final int? teacherId;
  final String? teacherName;
  final String? academicYear;
  final String? status;
  final int? studentCount;

  const ClassInfo({
    this.id,
    this.className,
    this.classCode,
    this.gradeId,
    this.gradeName,
    this.schoolId,
    this.schoolName,
    this.teacherId,
    this.teacherName,
    this.academicYear,
    this.status,
    this.studentCount,
  });

  factory ClassInfo.fromJson(Map<String, dynamic> json) {
    return ClassInfo(
      id: json['id'] as int?,
      className: json['className'] as String?,
      classCode: json['classCode'] as String?,
      gradeId: json['gradeId'] as int?,
      gradeName: json['gradeName'] as String?,
      schoolId: json['schoolId'] as int?,
      schoolName: json['schoolName'] as String?,
      teacherId: json['teacherId'] as int?,
      teacherName: json['teacherName'] as String?,
      academicYear: json['academicYear'] as String?,
      status: json['status'] as String?,
      studentCount: json['studentCount'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'className': className,
      'classCode': classCode,
      'gradeId': gradeId,
      'gradeName': gradeName,
      'schoolId': schoolId,
      'schoolName': schoolName,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'academicYear': academicYear,
      'status': status,
      'studentCount': studentCount,
    };
  }
}

class MenuItem {
  final String? key;
  final String? title;
  final String? icon;
  final String? route;

  const MenuItem({
    this.key,
    this.title,
    this.icon,
    this.route,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      key: json['key'] as String?,
      title: json['title'] as String?,
      icon: json['icon'] as String?,
      route: json['route'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'title': title,
      'icon': icon,
      'route': route,
    };
  }
}

class HomeMenu {
  final String? role;
  final List<MenuItem>? menus;

  const HomeMenu({
    this.role,
    this.menus,
  });

  factory HomeMenu.fromJson(Map<String, dynamic> json) {
    return HomeMenu(
      role: json['role'] as String?,
      menus: (json['menus'] as List<dynamic>?)
          ?.map((e) => MenuItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'menus': menus?.map((e) => e.toJson()).toList(),
    };
  }
}

class ParentStudent {
  final int? id;
  final int? parentId;
  final int? studentId;
  final String? studentName;
  final String? studentAvatar;
  final String? schoolName;
  final String? className;
  final String? relation;
  final bool? isPrimary;
  final DateTime? createdAt;

  const ParentStudent({
    this.id,
    this.parentId,
    this.studentId,
    this.studentName,
    this.studentAvatar,
    this.schoolName,
    this.className,
    this.relation,
    this.isPrimary,
    this.createdAt,
  });

  factory ParentStudent.fromJson(Map<String, dynamic> json) {
    return ParentStudent(
      id: json['id'] as int?,
      parentId: json['parentId'] as int?,
      studentId: json['studentId'] as int?,
      studentName: json['studentName'] as String?,
      studentAvatar: json['studentAvatar'] as String?,
      schoolName: json['schoolName'] as String?,
      className: json['className'] as String?,
      relation: json['relation'] as String?,
      isPrimary: json['isPrimary'] as bool?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parentId': parentId,
      'studentId': studentId,
      'studentName': studentName,
      'studentAvatar': studentAvatar,
      'schoolName': schoolName,
      'className': className,
      'relation': relation,
      'isPrimary': isPrimary,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}

class ApiResponse<T> {
  final int? code;
  final String? message;
  final T? data;

  const ApiResponse({
    this.code,
    this.message,
    this.data,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>)? fromJsonT,
  ) {
    return ApiResponse(
      code: json['code'] as int?,
      message: json['message'] as String?,
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  factory ApiResponse.fromJsonList(
    Map<String, dynamic> json,
    T Function(List<dynamic>)? fromJsonListT,
  ) {
    return ApiResponse(
      code: json['code'] as int?,
      message: json['message'] as String?,
      data: json['data'] != null && fromJsonListT != null
          ? fromJsonListT(json['data'] as List<dynamic>)
          : null,
    );
  }

  bool get isSuccess => code == 200 || code == 0;

  Map<String, dynamic> toJson(Map<String, dynamic>? Function(T?)? toJsonT) {
    return {
      'code': code,
      'message': message,
      'data': toJsonT != null ? toJsonT(data) : data,
    };
  }
}
