import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

const Map<String, dynamic> inspectionData = {
  "stationDetails": {
    "name": "Station A",
    "address": "123 Main St, City",
    "engineer": "John Doe",
    "date": "16 Oct 2025",
    "status": "Completed",
    "facilityId": "FAC123",
    "ownerId": "OWN456",
  },

  "dispenserChecklist": [
    {"question": "Is the dispenser clean?", "status": "Pass"},
    {"question": "Are the hoses in good condition?", "status": "Fail"},
    {"question": "Are the hoses in good condition?", "status": "Pass"},
  ],
  "tankChecklist": [
    {"question": "Is the tank leak-free?", "status": "Pass"},
    {"question": "Is the tank properly labeled?", "status": "Pass"},
    {"question": "Is the tank properly labeled?", "status": "Fail"},
  ],
  "tceqChecklist": [
    {"question": "Are records up-to-date?", "status": "Fail"},
    {"question": "Are gauges functioning?", "status": "Pass"},
    {"question": "Are gauges functioning?", "status": "Pass"},
  ],
  "images": [
    "assets/images/pump1.jpg",
    "assets/images/pump2.jpg",
    "assets/images/pump3.jpg",
  ],
};

class InspectionDetailsPage extends StatelessWidget {
  const InspectionDetailsPage({super.key});

  Widget buildCard({required String title, required Widget child}) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(top: 20),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            child,
          ],
        ),
      ),
    );
  }

  Widget buildChecklist(List<dynamic> checklist) {
    return Column(
      children: checklist.map((item) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(item['question'])),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: item['status'] == 'Pass'
                          ? Colors.green
                          : Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      item['status'],
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget buildImages(List<dynamic> images) {
    return images.isEmpty
        ? const SizedBox()
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text(
                "Images",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: images.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(images[index], fit: BoxFit.cover),
                  );
                },
              ),
            ],
          );
  }

  @override
  Widget build(BuildContext context) {
    final station = inspectionData['stationDetails'];
    final dispenserChecklist =
        inspectionData['dispenserChecklist'] as List<dynamic>;
    final tankChecklist = inspectionData['tankChecklist'] as List<dynamic>;
    final tceqChecklist = inspectionData['tceqChecklist'] as List<dynamic>;
    final images = inspectionData['images'] as List<dynamic>;

    return Scaffold(
      appBar: AppBar(title: const Text("Inspection Details")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Print Button at Top
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final pdf = pw.Document();

                  final station = inspectionData['stationDetails'];
                  final dispenserChecklist =
                      inspectionData['dispenserChecklist'] as List<dynamic>;
                  final tankChecklist =
                      inspectionData['tankChecklist'] as List<dynamic>;
                  final tceqChecklist =
                      inspectionData['tceqChecklist'] as List<dynamic>;
                  final images = inspectionData['images'] as List<dynamic>;

                  // Load images as bytes from assets
                  List<Uint8List> imageBytes = [];
                  for (var path in images) {
                    final bytes = await rootBundle.load(path);
                    imageBytes.add(bytes.buffer.asUint8List());
                  }

                  pdf.addPage(
                    pw.MultiPage(
                      build: (context) => [
                        pw.Text(
                          "Inspection Report",
                          style: pw.TextStyle(
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 16),

                        // Station Details
                        pw.Text(
                          "Station Details",
                          style: pw.TextStyle(fontSize: 18),
                        ),
                        pw.Text("Name: ${station['name']}"),
                        pw.Text("Address: ${station['address']}"),
                        pw.Text("Engineer: ${station['engineer']}"),
                        pw.Text("Date: ${station['date']}"),
                        pw.Text("Status: ${station['status']}"),
                        pw.Text("Facility ID: ${station['facilityId']}"),
                        pw.Text("Owner ID: ${station['ownerId']}"),
                        pw.SizedBox(height: 16),

                        // Dispenser Checklist
                        pw.Text(
                          "Dispenser Checklist",
                          style: pw.TextStyle(fontSize: 18),
                        ),
                        ...dispenserChecklist.map(
                          (q) => pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Expanded(child: pw.Text(q['question'])),
                              pw.Text(q['status']),
                            ],
                          ),
                        ),
                        pw.SizedBox(height: 16),

                        // Tank Checklist
                        pw.Text(
                          "Tank Checklist",
                          style: pw.TextStyle(fontSize: 18),
                        ),
                        ...tankChecklist.map(
                          (q) => pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Expanded(child: pw.Text(q['question'])),
                              pw.Text(q['status']),
                            ],
                          ),
                        ),
                        pw.SizedBox(height: 16),

                        // TCEQ Checklist
                        pw.Text(
                          "TCEQ Checklist",
                          style: pw.TextStyle(fontSize: 18),
                        ),
                        ...tceqChecklist.map(
                          (q) => pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Expanded(child: pw.Text(q['question'])),
                              pw.Text(q['status']),
                            ],
                          ),
                        ),
                        pw.SizedBox(height: 16),

                        // Images at Bottom
                        if (imageBytes.isNotEmpty)
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                "Images",
                                style: pw.TextStyle(fontSize: 18),
                              ),
                              pw.SizedBox(height: 8),
                              ...imageBytes.map(
                                (bytes) => pw.Container(
                                  margin: const pw.EdgeInsets.only(bottom: 8),
                                  height: 150,
                                  child: pw.Image(
                                    pw.MemoryImage(bytes),
                                    fit: pw.BoxFit.cover,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  );

                  // Open print preview
                  await Printing.layoutPdf(
                    onLayout: (PdfPageFormat format) async => pdf.save(),
                  );
                },
                icon: const Icon(Icons.print),
                label: const Text("Print Inspection"),
              ),
            ),

            // Station Details
            buildCard(
              title: 'Station Details',

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Name: ${station['name']}"),
                  Text("Address: ${station['address']}"),
                  Text("Engineer: ${station['engineer']}"),
                  Text("Date: ${station['date']}"),
                  Text("Status: ${station['status']}"),
                  Text("Facility ID: ${station['facilityId']}"),
                  Text("Owner ID: ${station['ownerId']}"),
                ],
              ),
            ),

            // Dispenser Checklist
            buildCard(
              title: 'Dispenser Checklist',
              child: buildChecklist(dispenserChecklist),
            ),

            // Tank Checklist
            buildCard(
              title: 'Tank Checklist',
              child: buildChecklist(tankChecklist),
            ),

            // TCEQ Checklist
            buildCard(
              title: 'TCEQ Checklist',
              child: buildChecklist(tceqChecklist),
            ),

            // Images at Bottom
            buildImages(images),
          ],
        ),
      ),
    );
  }
}
