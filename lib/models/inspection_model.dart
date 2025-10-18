class InspectionModel {
  InspectionModel();

  // --- IDs & Station ---
  String id = '';
  String stationName = '';
  String stationAddress = '';
  String stationId = '';

  // --- People ---
  String inspectorName = ''; // internal
  String engineerName = ''; // UI compatibility (some responses use this)

  // --- Dates & meta ---
  String status = '';
  String result = '';
  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();
  DateTime inspectionDate = DateTime.now();

  // --- Raw inspection sections (match API) ---
  // These map keys like "D1", "T1", etc. to their objects:
  // { "D1": {"status":"Fail","comment":"...","label":"..."} }
  Map<String, dynamic>? dispenserInspection;
  Map<String, dynamic>? tankInspection;
  Map<String, dynamic>? tceqInspection;

  // --- Checklists for UI/edit mode (optional defaults) ---
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

  // --- Images ---
  List<ImageItem> images = [];

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

  int get imageCount => images.length;

  /// Derive inspection result from raw inspection maps.
  /// Returns "Fail" if any contained item has status == 'Fail' (case-insensitive).
  String get inspectionResult {
    bool hasFailInMap(Map<String, dynamic>? section) {
      if (section == null) return false;
      try {
        return section.values.any((v) {
          if (v is Map) {
            final s = (v['status'] ?? '').toString().toLowerCase();
            return s == 'fail';
          }
          return false;
        });
      } catch (_) {
        return false;
      }
    }

    if (hasFailInMap(dispenserInspection) ||
        hasFailInMap(tankInspection) ||
        hasFailInMap(tceqInspection)) {
      return 'Fail';
    }
    // fallback: if model.result provided prefer that, else Pass
    if (result.isNotEmpty) return result;
    return 'Pass';
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
      'images': images.map((e) => e.toJson()).toList(),
    };
  }

  factory InspectionModel.fromJson(Map<String, dynamic> json) {
    final model = InspectionModel();

    model.id = json['_id'] ?? '';
    model.stationName = json['stationName'] ?? '';
    // stationAddress could be at top-level or nested inside stationId->address etc.
    model.stationAddress =
        json['stationAddress'] ??
        (json['stationId'] is Map
            ? (json['stationId']['address']?['street'] ?? '')
            : '');

    // names — tolerate both field names
    model.inspectorName =
        json['inspectorName'] ??
        json['engineerName'] ??
        json['engineerAssigned'] ??
        '';

    model.engineerName = model.inspectorName;

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

    // Raw inspection sections: accept multiple casings/keys
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

    // If API returns structured checklists as arrays for these sections, convert them.
    // but keep original lists if present
    if (json['dispenserChecklist'] != null) {
      model.dispenserChecklist = (json['dispenserChecklist'] as List)
          .map((e) => ChecklistItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    if (json['tankChecklist'] != null) {
      model.tankChecklist = (json['tankChecklist'] as List)
          .map((e) => ChecklistItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    if (json['tceqChecklist'] != null) {
      model.tceqChecklist = (json['tceqChecklist'] as List)
          .map((e) => ChecklistItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    if (json['images'] != null && json['images'] is List) {
      // API may send list of strings (paths) or object entries
      model.images = (json['images'] as List).map((e) {
        if (e is String) {
          return ImageItem(imagePath: e, imageBase64: '');
        } else if (e is Map) {
          return ImageItem.fromJson(Map<String, dynamic>.from(e));
        } else {
          return ImageItem(imagePath: '', imageBase64: '');
        }
      }).toList();
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
