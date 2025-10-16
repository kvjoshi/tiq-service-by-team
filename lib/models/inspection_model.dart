class InspectionModel {
  InspectionModel();

  // Station Details
  String stationName = '';
  String stationAddress = '';
  String inspectorName = '';
  DateTime inspectionDate = DateTime.now();
  String stationId = '';

  // Checklists
  List<ChecklistItem> dispenserChecklist = [
    ChecklistItem(question: 'Dispensers are clean and properly maintained'),
    ChecklistItem(question: 'No visible leaks or damage'),
    ChecklistItem(question: 'Price displays are functioning'),
    ChecklistItem(question: 'Emergency shut-off is accessible'),
    ChecklistItem(question: 'Fire extinguisher is present and charged'),
  ];

  List<ChecklistItem> tankChecklist = [
    ChecklistItem(question: 'Tank vents are unobstructed'),
    ChecklistItem(question: 'No signs of corrosion or damage'),
    ChecklistItem(question: 'Spill containment is intact'),
    ChecklistItem(question: 'Tank gauges are functioning properly'),
    ChecklistItem(question: 'Fill caps are secure and sealed'),
  ];

  List<ChecklistItem> tceqChecklist = [
    ChecklistItem(question: 'UST registration is current and posted'),
    ChecklistItem(question: 'Leak detection system is operational'),
    ChecklistItem(question: 'Records are up to date and accessible'),
    ChecklistItem(question: 'Overfill protection is functioning'),
    ChecklistItem(question: 'Corrosion protection is in place'),
  ];

  // Image Checklist
  List<ImageItem> images = [];

  // --- 🧮 Computed Helpers ---

  // Count total checklist items
  int get totalItems =>
      dispenserChecklist.length + tankChecklist.length + tceqChecklist.length;

  // Count answered items
  int get answeredItems {
    return [
      ...dispenserChecklist,
      ...tankChecklist,
      ...tceqChecklist,
    ].where((e) => e.answer != null).length;
  }

  // Completion percentage (0-100)
  double get completionRate {
    if (totalItems == 0) return 0;
    return (answeredItems / totalItems) * 100;
  }

  // Total image count
  int get imageCount => images.length;

  // --- JSON Serialization ---

  Map<String, dynamic> toJson() {
    return {
      'stationName': stationName,
      'stationAddress': stationAddress,
      'inspectorName': inspectorName,
      'inspectionDate': inspectionDate.toIso8601String(),
      'stationId': stationId,
      'dispenserChecklist': dispenserChecklist.map((e) => e.toJson()).toList(),
      'tankChecklist': tankChecklist.map((e) => e.toJson()).toList(),
      'tceqChecklist': tceqChecklist.map((e) => e.toJson()).toList(),
      'images': images.map((e) => e.toJson()).toList(),
    };
  }

  factory InspectionModel.fromJson(Map<String, dynamic> json) {
    final model = InspectionModel();

    model.stationName = json['stationName'] ?? '';
    model.stationAddress = json['stationAddress'] ?? '';
    model.inspectorName = json['inspectorName'] ?? '';

    try {
      model.inspectionDate =
          json['inspectionDate'] != null &&
              json['inspectionDate'].toString().isNotEmpty
          ? DateTime.parse(json['inspectionDate'])
          : DateTime.now();
    } catch (_) {
      model.inspectionDate = DateTime.now();
    }

    model.stationId = json['stationId'] ?? '';

    if (json['dispenserChecklist'] != null) {
      model.dispenserChecklist = (json['dispenserChecklist'] as List)
          .map((e) => ChecklistItem.fromJson(e))
          .toList();
    }

    if (json['tankChecklist'] != null) {
      model.tankChecklist = (json['tankChecklist'] as List)
          .map((e) => ChecklistItem.fromJson(e))
          .toList();
    }

    if (json['tceqChecklist'] != null) {
      model.tceqChecklist = (json['tceqChecklist'] as List)
          .map((e) => ChecklistItem.fromJson(e))
          .toList();
    }

    if (json['images'] != null) {
      model.images = (json['images'] as List)
          .map((e) => ImageItem.fromJson(e))
          .toList();
    }

    return model;
  }
}

class ChecklistItem {
  String question;
  bool? answer;
  String comment;

  ChecklistItem({required this.question, this.answer, this.comment = ''});

  bool get isValid {
    if (answer == false && comment.trim().isEmpty) return false;
    return answer != null;
  }

  Map<String, dynamic> toJson() => {
    'question': question,
    'answer': answer,
    'comment': comment,
  };

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      question: json['question'] ?? '',
      answer: json['answer'],
      comment: json['comment'] ?? '',
    );
  }
}

class ImageItem {
  String imagePath;
  String imageBase64;
  String caption;
  DateTime timestamp;

  ImageItem({
    required this.imagePath,
    required this.imageBase64,
    this.caption = '',
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'imagePath': imagePath,
      'imageBase64': imageBase64,
      'caption': caption,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ImageItem.fromJson(Map<String, dynamic> json) {
    return ImageItem(
      imagePath: json['imagePath'] ?? '',
      imageBase64: json['imageBase64'] ?? '',
      caption: json['caption'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    );
  }
}
