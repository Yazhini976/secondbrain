import 'package:flutter/material.dart';

/// Document categories supported by Second Brain.
enum DocumentCategory {
  identity,
  financial,
  medical,
  insurance,
  education,
  property,
  vehicle,
  other,
}

extension DocumentCategoryExtension on DocumentCategory {
  String get displayName {
    switch (this) {
      case DocumentCategory.identity:
        return 'Identity';
      case DocumentCategory.financial:
        return 'Financial';
      case DocumentCategory.medical:
        return 'Medical';
      case DocumentCategory.insurance:
        return 'Insurance';
      case DocumentCategory.education:
        return 'Education';
      case DocumentCategory.property:
        return 'Property';
      case DocumentCategory.vehicle:
        return 'Vehicle';
      case DocumentCategory.other:
        return 'Other';
    }
  }

  static DocumentCategory fromString(String value) {
    final lower = value.toLowerCase().trim();
    switch (lower) {
      case 'identity':
        return DocumentCategory.identity;
      case 'financial':
        return DocumentCategory.financial;
      case 'medical':
        return DocumentCategory.medical;
      case 'insurance':
        return DocumentCategory.insurance;
      case 'education':
        return DocumentCategory.education;
      case 'property':
        return DocumentCategory.property;
      case 'vehicle':
        return DocumentCategory.vehicle;
      default:
        return DocumentCategory.other;
    }
  }

  IconData get icon {
    switch (this) {
      case DocumentCategory.identity:
        return Icons.badge_outlined;
      case DocumentCategory.financial:
        return Icons.account_balance_outlined;
      case DocumentCategory.medical:
        return Icons.local_hospital_outlined;
      case DocumentCategory.insurance:
        return Icons.shield_outlined;
      case DocumentCategory.education:
        return Icons.school_outlined;
      case DocumentCategory.property:
        return Icons.home_outlined;
      case DocumentCategory.vehicle:
        return Icons.directions_car_outlined;
      case DocumentCategory.other:
        return Icons.folder_outlined;
    }
  }
}

/// Immutable document model.
class Document {
  final String id;
  final String title;
  final DocumentCategory category;
  final String? description;
  final DateTime? issueDate;
  final DateTime? expiryDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? fileName;
  final String? fileType;
  final int? fileSize;
  final String? notes;

  Document({
    String? id,
    required this.title,
    required this.category,
    this.description,
    this.issueDate,
    this.expiryDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.fileName,
    this.fileType,
    this.fileSize,
    this.notes,
  })  : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'] as String?,
      title: (json['title'] ?? json['name'] ?? 'Untitled') as String,
      category: DocumentCategoryExtension.fromString((json['category'] ?? 'Other') as String),
      description: json['description'] as String?,
      issueDate: json['issue_date'] != null ? DateTime.parse(json['issue_date'] as String) : null,
      expiryDate: json['expiry_date'] != null ? DateTime.parse(json['expiry_date'] as String) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : DateTime.now(),
      fileName: json['file_name'] as String?,
      fileType: json['file_type'] as String?,
      fileSize: json['file_size'] as int?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'name': title,
      'category': category.displayName,
      if (description != null) 'description': description,
      if (issueDate != null) 'issue_date': issueDate!.toIso8601String().split('T')[0],
      if (expiryDate != null) 'expiry_date': expiryDate!.toIso8601String().split('T')[0],
      if (fileName != null) 'file_name': fileName,
      if (fileType != null) 'file_type': fileType,
      if (fileSize != null) 'file_size': fileSize,
      if (notes != null) 'notes': notes,
    };
  }

  Document copyWith({
    String? title,
    DocumentCategory? category,
    String? description,
    DateTime? issueDate,
    DateTime? expiryDate,
    String? fileName,
    String? fileType,
    int? fileSize,
    String? notes,
  }) {
    return Document(
      id: id,
      title: title ?? this.title,
      category: category ?? this.category,
      description: description ?? this.description,
      issueDate: issueDate ?? this.issueDate,
      expiryDate: expiryDate ?? this.expiryDate,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      fileName: fileName ?? this.fileName,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize ?? this.fileSize,
      notes: notes ?? this.notes,
    );
  }
}
