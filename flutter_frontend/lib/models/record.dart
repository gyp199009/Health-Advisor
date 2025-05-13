class FileData {
  final String filename;
  final String originalName;
  final String mimetype;
  final int size;

  FileData({
    required this.filename,
    required this.originalName,
    required this.mimetype,
    required this.size,
  });

  factory FileData.fromJson(Map<String, dynamic> json) {
    return FileData(
      filename: json['filename'],
      originalName: Uri.decodeComponent(json['originalName']),
      mimetype: json['mimetype'],
      size: json['size'],
    );
  }
}

class Record {
  final String id;
  final String userId;
  final String recordType;
  final String? description;
  final FileData? file;
  final String textContent;
  final DateTime uploadDate;

  Record({
    required this.id,
    required this.userId,
    required this.recordType,
    this.description,
    this.file,
    required this.textContent,
    required this.uploadDate,
  });

  factory Record.fromJson(Map<String, dynamic> json) {
    return Record(
      id: json['_id'],
      userId: json['userId'],
      recordType: json['recordType'],
      description: json['description'],
      file: json['file'] != null ? FileData.fromJson(json['file']) : null,
      textContent: json['textContent'] ?? '', // Handle potential null
      uploadDate: DateTime.parse(json['uploadDate']).toUtc(), // 确保时间是UTC时间
    );
  }

  // Simplified version for list view (without textContent)
  factory Record.fromListJson(Map<String, dynamic> json) {
     return Record(
      id: json['_id'],
      userId: json['userId'],
      recordType: json['recordType'],
      description: json['description'],
      file: json['file'] != null ? FileData.fromJson(json['file']) : null,
      textContent: '', // Not included in list view
      uploadDate: DateTime.parse(json['uploadDate']).toUtc(), // 确保时间是UTC时间
    );
  }
}