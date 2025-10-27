import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../widgets/custom_dropdown.dart';
import '../controllers/inspection_api_controller.dart';

void main() {
  runApp(
    const MaterialApp(home: InspectionFormScreen(title: "Inspection Form")),
  );
}

const Map<String, dynamic> questionsJson = {
  "dispenserChecklist": [
    {"question": "Is the dispenser clean?", "key": "dispenser_clean"},
    {"question": "Are the hoses in good condition?", "key": "hoses_condition"},
  ],
  "tankChecklist": [
    {"question": "Is the tank leak-free?", "key": "tank_leak"},
    {"question": "Is the tank properly labeled?", "key": "tank_label"},
  ],
  "tceqChecklist": [
    {"question": "Are records up-to-date?", "key": "records_up_to_date"},
    {"question": "Are gauges functioning?", "key": "gauges_functioning"},
  ],
};

class InspectionFormScreen extends StatefulWidget {
  final String title;
  const InspectionFormScreen({super.key, required this.title});

  @override
  State<InspectionFormScreen> createState() => _InspectionFormScreenState();
}

class _InspectionFormScreenState extends State<InspectionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  List<String> _stations = [];
  Future<void> _loadStations() async {
    final controller = InspectionApiController();

    // Try reading from local storage first
    List<Map<String, dynamic>> stationsData = await controller.readStations();

    // If nothing is stored, fetch from API and store it
    if (stationsData.isEmpty) {
      final response = await controller.getStations();
      if (response.success && response.data != null) {
        stationsData = response.data!;
        await controller.saveStations(stationsData);
      }
    }

    if (!mounted) return;
    setState(() {
      _stations = stationsData
          .map((s) => s['stationName'] as String)
          .where((name) => name.isNotEmpty)
          .toList();
    });
  }

  String? _selectedStation;

  final DateTime _inspectionDate = DateTime.now();
  Map<String, dynamic> _answers = {};
  Map<String, TextEditingController> _commentsControllers = {};
  List<File> _images = [];
  final ImagePicker _picker = ImagePicker();
  late final TextEditingController _inspectionDateController;

  @override
  @override
  @override
  void initState() {
    super.initState();
    _inspectionDateController = TextEditingController(
      text: DateFormat('dd MMM yyyy').format(_inspectionDate),
    );
    _loadStations();
  }

  @override
  void dispose() {
    _inspectionDateController.dispose();
    _commentsControllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile != null && mounted) {
        setState(() {
          _images.add(File(pickedFile.path));
        });
      }
    } catch (e) {
      debugPrint("Image pick error: $e");
    }
  }

  List<Step> _buildSteps() {
    return [
      Step(
        title: const Text('Station Details'),
        content: _buildStationDetails(),
        isActive: _currentStep >= 0,
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Dispenser Checklist'),
        content: _buildChecklist('dispenserChecklist'),
        isActive: _currentStep >= 1,
        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Tank Checklist'),
        content: _buildChecklist('tankChecklist'),
        isActive: _currentStep >= 2,
        state: _currentStep > 2 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('TCEQ Checklist'),
        content: _buildChecklist('tceqChecklist'),
        isActive: _currentStep >= 3,
        state: _currentStep > 3 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Insepction Images'),
        content: _buildImageSection(),
        isActive: _currentStep >= 4,
        state: _currentStep > 4 ? StepState.complete : StepState.indexed,
      ),
    ];
  }

  Widget _buildStationDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: CustomDropdown(
            items: _stations, // pass directly, no .map() needed
            selectedValue: _selectedStation,
            popupWidth: MediaQuery.of(context).size.width * 0.95,
            onChanged: (val) {
              setState(() {
                _selectedStation = val;
              });
            },
          ),
        ),

        const SizedBox(height: 16),
        TextField(
          controller: _inspectionDateController,
          readOnly: true,
          decoration: InputDecoration(
            labelText: 'Inspection Date',
            prefixIcon: const Icon(Icons.calendar_today, color: Colors.grey),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            filled: true,
            fillColor: Colors.grey.shade200,
          ),
        ),
      ],
    );
  }

  Widget _buildChecklist(String key) {
    final questions = questionsJson[key] as List<dynamic>;
    return Column(
      children: questions.map((q) {
        final questionKey = q['key'];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  q['question'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Radio<String>(
                      value: 'Yes',
                      groupValue: _answers[questionKey],
                      onChanged: (val) =>
                          setState(() => _answers[questionKey] = val),
                    ),
                    const Text('Yes'),
                    const SizedBox(width: 20),
                    Radio<String>(
                      value: 'No',
                      groupValue: _answers[questionKey],
                      onChanged: (val) =>
                          setState(() => _answers[questionKey] = val),
                    ),
                    const Text('No'),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _commentsControllers[questionKey],
                  decoration: const InputDecoration(
                    hintText: 'Comments',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.image),
            label: const Text('Pick Image'),
          ),
        ),
        const SizedBox(height: 16),
        if (_images.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _images.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              final img = _images[index];
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      img,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _images.removeAt(index);
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // Station Details
        if (_selectedStation == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a station')),
          );
          return false;
        }
        return true;
      case 1: // Dispenser
        return _validateChecklist('dispenserChecklist');
      case 2: // Tank
        return _validateChecklist('tankChecklist');
      case 3: // TCEQ
        return _validateChecklist('tceqChecklist');
      default:
        return true; // Images step has no required fields
    }
  }

  bool _validateChecklist(String key) {
    final questions = questionsJson[key] as List<dynamic>;
    for (var q in questions) {
      final questionKey = q['key'];
      if (_answers[questionKey] == null || _answers[questionKey]!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please answer: ${q['question']}')),
        );
        return false;
      }
    }
    return true;
  }

  void _onStepContinue() {
    if (!_validateCurrentStep()) return;

    if (_currentStep < _buildSteps().length - 1) {
      setState(() => _currentStep += 1);
    } else {
      _submitForm();
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) setState(() => _currentStep -= 1);
  }

  void _submitForm() {
    Map<String, dynamic> finalData = {
      'station': _selectedStation,
      'inspectionDate': _inspectionDate.toIso8601String(),
      'answers': _answers,
      'comments': _commentsControllers.map((key, c) => MapEntry(key, c.text)),
      'images': _images.map((f) => f.path).toList(),
    };
    debugPrint('---- Inspection Data ----');
    debugPrint(finalData.toString());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Form submitted successfully!')),
    );
  }

  Widget _buildStepIndicator() {
    final steps = _buildSteps();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: List.generate(steps.length, (index) {
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep;
          return Expanded(
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? Colors.green
                        : isActive
                        ? const Color(0xFF37A8C0)
                        : Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  (steps[index].title as Text).data!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: isActive ? const Color(0xFF37A8C0) : Colors.black54,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final steps = _buildSteps();
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Fixed step header
            _buildStepIndicator(),
            const Divider(height: 1),
            // Form content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: steps[_currentStep].content,
                  ),
                ),
              ),
            ),
            // Buttons
            Container(
              margin: const EdgeInsets.only(bottom: 30, top: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _onStepCancel,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Back',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _onStepContinue,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        _currentStep == steps.length - 1 ? 'Submit' : 'Next',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
