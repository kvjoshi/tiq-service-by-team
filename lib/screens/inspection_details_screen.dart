import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../controllers/inspection_api_controller.dart';
import '../models/inspection_model.dart';

class InspectionDetailsPage extends StatefulWidget {
  final String inspectionId;
  const InspectionDetailsPage({super.key, required this.inspectionId});

  @override
  State<InspectionDetailsPage> createState() => _InspectionDetailsPageState();
}

class _InspectionDetailsPageState extends State<InspectionDetailsPage> {
  bool _loading = true;
  InspectionModel? inspection;

  @override
  void initState() {
    super.initState();
    _fetchInspection();
  }

  Future<void> _fetchInspection() async {
    final res = await InspectionApiController().getInspectionData(
      widget.inspectionId,
    );

    if (!mounted) return;

    if (res.success && res.data != null) {
      setState(() {
        inspection = res.data!;
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message ?? "Failed to load inspection")),
      );
    }
  }

  List<Map<String, String>> mapChecklist(Map<String, dynamic>? data) {
    if (data == null) return [];
    return data.entries
        .map(
          (e) => {
            "question": e.value['label']?.toString() ?? "",
            "status": e.value['status']?.toString() ?? "",
          },
        )
        .toList();
  }

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

  Widget buildChecklist(List<Map<String, String>> checklist) {
    return Column(
      children: checklist.map((item) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(item['question'] ?? "")),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: item['status'] == 'Pass' ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item['status'] ?? "",
                  style: const TextStyle(color: Colors.white),
                ),
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
                    child: Image.network(
                      images[index],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.broken_image),
                    ),
                  );
                },
              ),
            ],
          );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (inspection == null) {
      return const Scaffold(
        body: Center(child: Text("No inspection data found")),
      );
    }

    final station = {
      "name": inspection!.stationName,
      "address": inspection!.stationAddress,
      "engineer": inspection!.engineerName,
      "date": inspection!.inspectionDate.toLocal().toString().split(' ').first,
      "status": inspection!.status,
    };

    final dispenserChecklist = mapChecklist(inspection!.dispenserInspection);
    final tankChecklist = mapChecklist(inspection!.tankInspection);
    final tceqChecklist = mapChecklist(inspection!.tceqInspection);
    final images = inspection!.urls; // List<String>

    return Scaffold(
      appBar: AppBar(title: const Text("Inspection Details")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Print Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final pdf = pw.Document();

                  // Load images as bytes from network
                  List<Uint8List> imageBytes = [];
                  for (var url in images) {
                    try {
                      final data = await NetworkAssetBundle(
                        Uri.parse(url),
                      ).load(url);
                      imageBytes.add(data.buffer.asUint8List());
                    } catch (_) {}
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
                        pw.Text(
                          "Station Details",
                          style: pw.TextStyle(fontSize: 18),
                        ),
                        pw.Text("Name: ${station['name']}"),
                        pw.Text("Address: ${station['address']}"),
                        pw.Text("Engineer: ${station['engineer']}"),
                        pw.Text("Date: ${station['date']}"),
                        pw.Text("Status: ${station['status']}"),

                        pw.SizedBox(height: 16),
                        pw.Text(
                          "Dispenser Checklist",
                          style: pw.TextStyle(fontSize: 18),
                        ),
                        ...dispenserChecklist.map(
                          (q) => pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Expanded(child: pw.Text(q['question'] ?? "")),
                              pw.Text(q['status'] ?? ""),
                            ],
                          ),
                        ),
                        pw.SizedBox(height: 16),
                        pw.Text(
                          "Tank Checklist",
                          style: pw.TextStyle(fontSize: 18),
                        ),
                        ...tankChecklist.map(
                          (q) => pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Expanded(child: pw.Text(q['question'] ?? "")),
                              pw.Text(q['status'] ?? ""),
                            ],
                          ),
                        ),
                        pw.SizedBox(height: 16),
                        pw.Text(
                          "TCEQ Checklist",
                          style: pw.TextStyle(fontSize: 18),
                        ),
                        ...tceqChecklist.map(
                          (q) => pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Expanded(child: pw.Text(q['question'] ?? "")),
                              pw.Text(q['status'] ?? ""),
                            ],
                          ),
                        ),
                        pw.SizedBox(height: 16),
                        if (imageBytes.isNotEmpty)
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                "Images",
                                style: pw.TextStyle(fontSize: 18),
                              ),
                              pw.Divider(),
                              pw.Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: imageBytes
                                    .map(
                                      (bytes) => pw.Container(
                                        width:
                                            (PdfPageFormat.a4.width / 3) - 16,
                                        height: 120,
                                        child: pw.Image(
                                          pw.MemoryImage(bytes),
                                          fit: pw.BoxFit.cover,
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                          ),
                      ],
                    ),
                  );

                  await Printing.layoutPdf(
                    onLayout: (PdfPageFormat format) async => pdf.save(),
                  );
                },
                icon: const Icon(Icons.print),
                label: const Text("Print Inspection"),
              ),
            ),

            buildCard(
              title: "Station Details",
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Name: ${station['name']}"),
                  Text("Address: ${station['address']}"),
                  Text("Engineer: ${station['engineer']}"),
                  Text("Date: ${station['date']}"),
                  Text("Status: ${station['status']}"),
                ],
              ),
            ),

            buildCard(
              title: "Dispenser Checklist",
              child: buildChecklist(dispenserChecklist),
            ),
            buildCard(
              title: "Tank Checklist",
              child: buildChecklist(tankChecklist),
            ),
            buildCard(
              title: "TCEQ Checklist",
              child: buildChecklist(tceqChecklist),
            ),
            buildImages(images),
          ],
        ),
      ),
    );
  }
}
