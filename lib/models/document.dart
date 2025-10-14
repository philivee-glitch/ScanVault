class ScannedDocument {
  final String id;
  final String name;
  final List<String> imagePaths;
  final DateTime createdAt;
  String? pdfPath;

  ScannedDocument({
    required this.id,
    required this.name,
    required this.imagePaths,
    required this.createdAt,
    this.pdfPath,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imagePaths': imagePaths,
      'createdAt': createdAt.toIso8601String(),
      'pdfPath': pdfPath,
    };
  }

  factory ScannedDocument.fromJson(Map<String, dynamic> json) {
    return ScannedDocument(
      id: json['id'],
      name: json['name'],
      imagePaths: List<String>.from(json['imagePaths']),
      createdAt: DateTime.parse(json['createdAt']),
      pdfPath: json['pdfPath'],
    );
  }
}
