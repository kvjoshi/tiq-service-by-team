import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const MaterialApp(home: InspectionFormScreen(title: "")));
}

// Mock JSON questions
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

  // Station List
  final List<String> _stations = ["Station A", "Station B", "Station C"];
  String? _selectedStation;

  // Date (fixed current date)
  final DateTime _inspectionDate = DateTime.now();

  // Questions answers
  Map<String, dynamic> _answers = {};

  // Comments
  Map<String, TextEditingController> _commentsControllers = {};

  // Image picker
  List<File> _images = [];

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Initialize comments controllers for all questions
    questionsJson.forEach((key, questions) {
      for (var q in questions) {
        _commentsControllers[q['key']] = TextEditingController();
      }
    });
  }

  @override
  void dispose() {
    _commentsControllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _images.add(File(pickedFile.path));
      });
    }
  }

  List<Step> _buildSteps() {
    return [
      // Step 1: Station Details
      Step(
        title: const Text('Station Details'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedStation,
              hint: const Text('Select Station'),
              items: _stations
                  .map(
                    (station) =>
                        DropdownMenuItem(value: station, child: Text(station)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _selectedStation = value),
              validator: (value) =>
                  value == null ? 'Please select a station' : null,
            ),
            const SizedBox(height: 16),
            Text(
              'Inspection Date: ${_inspectionDate.toLocal().toString().split(' ')[0]}',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        isActive: _currentStep >= 0,
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      ),

      // Step 2: Dispenser Checklist
      Step(
        title: const Text('Dispenser Checklist'),
        content: _buildChecklist('dispenserChecklist'),
        isActive: _currentStep >= 1,
        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      ),

      // Step 3: Tank Checklist
      Step(
        title: const Text('Tank Checklist'),
        content: _buildChecklist('tankChecklist'),
        isActive: _currentStep >= 2,
        state: _currentStep > 2 ? StepState.complete : StepState.indexed,
      ),

      // Step 4: TCEQ Checklist
      Step(
        title: const Text('TCEQ Checklist'),
        content: _buildChecklist('tceqChecklist'),
        isActive: _currentStep >= 3,
        state: _currentStep > 3 ? StepState.complete : StepState.indexed,
      ),

      // Step 5: Image Checklist
      Step(
        title: const Text('Image Checklist'),
        content: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image),
              label: const Text('Pick Image'),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _images
                  .map((img) => Image.file(img, width: 80, height: 80))
                  .toList(),
            ),
          ],
        ),
        isActive: _currentStep >= 4,
        state: _currentStep > 4 ? StepState.complete : StepState.indexed,
      ),
    ];
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
    // Collect final data
    Map<String, dynamic> finalData = {
      'station': _selectedStation,
      'inspectionDate': _inspectionDate.toIso8601String(),
      'answers': _answers,
      'comments': _commentsControllers.map(
        (key, controller) => MapEntry(key, controller.text),
      ),
      'images': _images.map((f) => f.path).toList(),
    };

    // Print to console
    print('---- Inspection Data ----');
    print(finalData);

    // Show confirmation snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Form submitted successfully! Check console.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Form(
        key: _formKey,
        child: Stepper(
          type: StepperType.vertical,
          currentStep: _currentStep,
          steps: _buildSteps(),
          onStepContinue: _onStepContinue,
          onStepCancel: _onStepCancel,
          controlsBuilder: (context, details) {
            final isLastStep = _currentStep == _buildSteps().length - 1;
            return Row(
              children: [
                ElevatedButton(
                  onPressed: details.onStepContinue,
                  child: Text(isLastStep ? 'Submit' : 'Next'),
                ),
                const SizedBox(width: 8),
                if (_currentStep > 0)
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: const Text('Back'),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
