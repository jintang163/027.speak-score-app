import 'package:flutter/material.dart';

class MaterialTag {
  final int? id;
  final String? tagName;
  final String? tagType;
  const MaterialTag({this.id, this.tagName, this.tagType});
  factory MaterialTag.fromJson(Map<String, dynamic> json) {
    return MaterialTag(
      id: json['id'] as int?,
      tagName: json['tagName'] as String?,
      tagType: json['tagType'] as String?,
    );
  }
  Map<String, dynamic> toJson() => {'id': id, 'tagName': tagName, 'tagType': tagType};
}

class MaterialInfo {
  final int? id;
  final String? title;
  final String? description;
  final String? materialType;
  final String? fileUrl;
  final int? fileSize;
  final String? fileName;
  final String? mimeType;
  final String? coverUrl;
  final int? duration;
  final String? hlsUrl;
  final String? transcodeStatus;
  final String? reviewStatus;
  final String? reviewComment;
  final String? scope;
  final int? uploaderId;
  final String? uploaderName;
  final int? schoolId;
  final String? schoolName;
  final int? classId;
  final String? className;
  final int? gradeLevel;
  final int? viewCount;
  final int? downloadCount;
  final List<MaterialTag>? tags;
  final String? createdAt;

  const MaterialInfo({
    this.id,
    this.title,
    this.description,
    this.materialType,
    this.fileUrl,
    this.fileSize,
    this.fileName,
    this.mimeType,
    this.coverUrl,
    this.duration,
    this.hlsUrl,
    this.transcodeStatus,
    this.reviewStatus,
    this.reviewComment,
    this.scope,
    this.uploaderId,
    this.uploaderName,
    this.schoolId,
    this.schoolName,
    this.classId,
    this.className,
    this.gradeLevel,
    this.viewCount,
    this.downloadCount,
    this.tags,
    this.createdAt,
  });

  factory MaterialInfo.fromJson(Map<String, dynamic> json) {
    return MaterialInfo(
      id: json['id'] as int?,
      title: json['title'] as String?,
      description: json['description'] as String?,
      materialType: json['materialType'] as String?,
      fileUrl: json['fileUrl'] as String?,
      fileSize: json['fileSize'] as int?,
      fileName: json['fileName'] as String?,
      mimeType: json['mimeType'] as String?,
      coverUrl: json['coverUrl'] as String?,
      duration: json['duration'] as int?,
      hlsUrl: json['hlsUrl'] as String?,
      transcodeStatus: json['transcodeStatus'] as String?,
      reviewStatus: json['reviewStatus'] as String?,
      reviewComment: json['reviewComment'] as String?,
      scope: json['scope'] as String?,
      uploaderId: json['uploaderId'] as int?,
      uploaderName: json['uploaderName'] as String?,
      schoolId: json['schoolId'] as int?,
      schoolName: json['schoolName'] as String?,
      classId: json['classId'] as int?,
      className: json['className'] as String?,
      gradeLevel: json['gradeLevel'] as int?,
      viewCount: json['viewCount'] as int?,
      downloadCount: json['downloadCount'] as int?,
      tags: (json['tags'] as List<dynamic>?)
          ?.map((e) => MaterialTag.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: json['createdAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'materialType': materialType,
        'fileUrl': fileUrl,
        'fileSize': fileSize,
        'fileName': fileName,
        'mimeType': mimeType,
        'coverUrl': coverUrl,
        'duration': duration,
        'hlsUrl': hlsUrl,
        'transcodeStatus': transcodeStatus,
        'reviewStatus': reviewStatus,
        'reviewComment': reviewComment,
        'scope': scope,
        'uploaderId': uploaderId,
        'uploaderName': uploaderName,
        'schoolId': schoolId,
        'schoolName': schoolName,
        'classId': classId,
        'className': className,
        'gradeLevel': gradeLevel,
        'viewCount': viewCount,
        'downloadCount': downloadCount,
        'tags': tags?.map((e) => e.toJson()).toList(),
        'createdAt': createdAt,
      };

  String get typeLabel {
    switch (materialType) {
      case 'VIDEO':
        return '视频';
      case 'PDF':
        return 'PDF';
      case 'IMAGE':
        return '图片';
      default:
        return '资料';
    }
  }

  IconData get typeIcon {
    switch (materialType) {
      case 'VIDEO':
        return Icons.play_circle_filled;
      case 'PDF':
        return Icons.picture_as_pdf;
      case 'IMAGE':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  String get fileSizeLabel {
    if (fileSize == null) return '';
    if (fileSize! < 1024) return '$fileSize B';
    if (fileSize! < 1024 * 1024) return '${(fileSize! / 1024).toStringAsFixed(1)} KB';
    if (fileSize! < 1024 * 1024 * 1024) return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(fileSize! / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
