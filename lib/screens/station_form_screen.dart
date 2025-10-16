import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

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
  final List<String> _stations = ["Station A", "Station B", "Station C"];
  String? _selectedStation;
  final DateTime _inspectionDate = DateTime.now();
  Map<String, dynamic> _answers = {};
  Map<String, TextEditingController> _commentsControllers = {};
  List<File> _images = [];
  final ImagePicker _picker = ImagePicker();

  // controller for inspection date
  late final TextEditingController _inspectionDateController;

  @override
  void initState() {
    super.initState();
    _inspectionDateController = TextEditingController(
      text: DateFormat('dd MMM yyyy').format(_inspectionDate),
    );
    questionsJson.forEach((key, questions) {
      for (var q in questions) {
        _commentsControllers[q['key']] = TextEditingController();
      }
    });
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
        title: const Text('Dispenser'),
        content: _buildChecklist('dispenserChecklist'),
        isActive: _currentStep >= 1,
        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Tank'),
        content: _buildChecklist('tankChecklist'),
        isActive: _currentStep >= 2,
        state: _currentStep > 2 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('TCEQ'),
        content: _buildChecklist('tceqChecklist'),
        isActive: _currentStep >= 3,
        state: _currentStep > 3 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Images'),
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
        DropdownButtonFormField<String>(
          value: _selectedStation,
          hint: const Text('Select Station'),
          items: _stations
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (val) => setState(() => _selectedStation = val),
          validator: (val) => val == null ? 'Please select a station' : null,
        ),
        const SizedBox(height: 16),
        // 👇 Disabled inspection date field (shows current date)
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              q['question'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Radio<String>(
                  value: 'Yes',
                  groupValue: _answers[questionKey],
                  onChanged: (val) =>
                      setState(() => _answers[questionKey] = val),
                ),
                const Text('Yes'),
                Radio<String>(
                  value: 'No',
                  groupValue: _answers[questionKey],
                  onChanged: (val) =>
                      setState(() => _answers[questionKey] = val),
                ),
                const Text('No'),
              ],
            ),
            TextFormField(
              controller: _commentsControllers[questionKey],
              decoration: const InputDecoration(
                hintText: 'Comments',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity, // full-width button
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
              crossAxisCount: 2, // 2 columns
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1, // square images
            ),
            itemBuilder: (context, index) {
              final img = _images[index];
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(img, fit: BoxFit.cover),
                ),
              );
            },
          ),
      ],
    );
  }

  void _onStepContinue() {
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

  @override
  Widget build(BuildContext context) {
    final steps = _buildSteps();
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Custom horizontal step header
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(steps.length, (index) {
                  final isActive = index == _currentStep;
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: isActive
                                ? const Color(0xFF37A8C0)
                                : Colors.grey.shade300,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // 👇 Break title words vertically
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: (steps[index].title as Text).data!
                              .split(' ')
                              .map(
                                (word) => Text(
                                  word,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: isActive
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isActive
                                        ? const Color(0xFF37A8C0)
                                        : Colors.black54,
                                    fontSize: 12,
                                    height: 1.2,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),

            const Divider(),

            // Fixed-width form area
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

            // Navigation buttons
            Container(
              margin: const EdgeInsets.only(bottom: 30, top: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Back button: only show if not first step
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
                  // Next / Submit button
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
