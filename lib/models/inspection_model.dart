class InspectionModel {
  InspectionModel();

  // --- IDs & Station ---
  String id = '';
  String stationName = '';
  String stationAddress = '';
  String stationId = '';

  // --- People ---
  String inspectorName = ''; // internal
  String engineerName = ''; // UI compatibility
  String serviceCompany = ''; // UI compatibility

  // --- Dates & meta ---
  String status = '';
  String result = '';
  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();
  DateTime inspectionDate = DateTime.now();

  // --- Raw inspection sections from API ---
  Map<String, dynamic>? dispenserInspection;
  Map<String, dynamic>? tankInspection;
  Map<String, dynamic>? tceqInspection;

  // --- Checklists derived from API ---
  List<ChecklistItem> dispenserChecklist = [];
  List<ChecklistItem> tankChecklist = [];
  List<ChecklistItem> tceqChecklist = [];

  // --- Images ---
  List<String> urls = [];

  // --- Computed helpers ---
  int get totalItems =>
      dispenserChecklist.length + tankChecklist.length + tceqChecklist.length;

  int get answeredItems {
    return [
      ...dispenserChecklist,
      ...tankChecklist,
      ...tceqChecklist,
    ].where((e) => e.answer != null).length;
  }

  double get completionRate {
    if (totalItems == 0) return 0;
    return (answeredItems / totalItems) * 100;
  }

  int get imageCount => urls.length;

  String get inspectionResult {
    bool hasFailInMap(Map<String, dynamic>? section) {
      if (section == null) return false;
      return section.values.any((v) {
        if (v is Map) {
          final s = (v['status'] ?? '').toString().toLowerCase();
          return s == 'fail';
        }
        return false;
      });
    }

    if (hasFailInMap(dispenserInspection) ||
        hasFailInMap(tankInspection) ||
        hasFailInMap(tceqInspection)) {
      return 'Fail';
    }
    return result.isNotEmpty ? result : 'Pass';
  }

  // --- Serialization ---
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'stationName': stationName,
      'stationAddress': stationAddress,
      'stationId': stationId,
      'inspectorName': inspectorName,
      'engineerName': engineerName,
      'status': status,
      'result': result,
      'inspectionDate': inspectionDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'Dispenser_inspection': dispenserInspection,
      'Tank_inspection': tankInspection,
      'TCEQ_inspection': tceqInspection,
      'dispenserChecklist': dispenserChecklist.map((e) => e.toJson()).toList(),
      'tankChecklist': tankChecklist.map((e) => e.toJson()).toList(),
      'tceqChecklist': tceqChecklist.map((e) => e.toJson()).toList(),
      'urls': urls,
    };
  }

  factory InspectionModel.fromJson(Map<String, dynamic> json) {
    final model = InspectionModel();

    model.id = json['_id'] ?? '';
    model.stationName = json['stationName'] ?? '';
    model.stationAddress =
        json['stationAddress'] ??
        (json['stationId'] is Map
            ? (json['stationId']['address']?['street'] ?? '')
            : '');

    model.inspectorName =
        json['inspectorName'] ??
        json['engineerName'] ??
        json['engineerAssigned'] ??
        '';
    model.engineerName = model.inspectorName;
    model.serviceCompany = json['serviceCompany'] ?? '';

    model.stationId = json['stationId'] is String
        ? json['stationId']
        : (json['stationId'] is Map ? (json['stationId']['_id'] ?? '') : '');

    model.status = json['status'] ?? '';
    model.result = json['result'] ?? '';

    try {
      model.createdAt = json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now();
    } catch (_) {
      model.createdAt = DateTime.now();
    }

    try {
      model.updatedAt = json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now();
    } catch (_) {
      model.updatedAt = DateTime.now();
    }

    try {
      model.inspectionDate = json['inspectionDate'] != null
          ? DateTime.parse(json['inspectionDate'])
          : model.createdAt;
    } catch (_) {
      model.inspectionDate = model.createdAt;
    }

    // --- Raw inspection sections ---
    model.dispenserInspection =
        (json['Dispenser_inspection'] ??
                json['dispenserInspection'] ??
                json['DispenserInspection'])
            is Map
        ? Map<String, dynamic>.from(
            json['Dispenser_inspection'] ??
                json['dispenserInspection'] ??
                json['DispenserInspection'],
          )
        : null;

    model.tankInspection =
        (json['Tank_inspection'] ??
                json['tankInspection'] ??
                json['TankInspection'])
            is Map
        ? Map<String, dynamic>.from(
            json['Tank_inspection'] ??
                json['tankInspection'] ??
                json['TankInspection'],
          )
        : null;

    model.tceqInspection =
        (json['TCEQ_inspection'] ??
                json['tceqInspection'] ??
                json['Tceq_inspection'])
            is Map
        ? Map<String, dynamic>.from(
            json['TCEQ_inspection'] ??
                json['tceqInspection'] ??
                json['Tceq_inspection'],
          )
        : null;

    // --- Generate dynamic checklists from API maps ---
    model.dispenserChecklist = mapInspectionToChecklist(
      model.dispenserInspection,
    );
    model.tankChecklist = mapInspectionToChecklist(model.tankInspection);
    model.tceqChecklist = mapInspectionToChecklist(model.tceqInspection);

    // --- Images ---
    if (json['urls'] != null && json['urls'] is List) {
      model.urls = (json['urls'] as List).map((e) => e.toString()).toList();
    }

    return model;
  }

  // helper to map raw API inspection maps to ChecklistItem
  static List<ChecklistItem> mapInspectionToChecklist(
    Map<String, dynamic>? section,
  ) {
    if (section == null) return [];
    return section.entries.map((e) {
      return ChecklistItem(
        question: e.value['label'] ?? '',
        answer: e.value['status']?.toString().toLowerCase() == 'pass'
            ? true
            : false,
        comment: e.value['comment'] ?? '',
      );
    }).toList();
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
      question: json['question'] ?? json['label'] ?? '',
      answer: json['status'] == null
          ? json['answer']
          : (json['status'].toString().toLowerCase() == 'pass'
                ? true
                : (json['status'].toString().toLowerCase() == 'fail'
                      ? false
                      : null)),
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
      imagePath: json['imagePath'] ?? json['path'] ?? '',
      imageBase64: json['imageBase64'] ?? '',
      caption: json['caption'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    );
  }
}
