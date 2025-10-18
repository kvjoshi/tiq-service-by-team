import 'package:flutter/material.dart';
import '../controllers/inspection_api_controller.dart';
import '../models/inspection_model.dart';
import 'inspection_details_screen.dart';
import 'station_form_screen.dart';

class InspectionListScreen extends StatefulWidget {
  const InspectionListScreen({super.key});

  @override
  State<InspectionListScreen> createState() => _InspectionListScreenState();
}

class _InspectionListScreenState extends State<InspectionListScreen> {
  final InspectionApiController _api = InspectionApiController();
  final TextEditingController _searchController = TextEditingController();

  bool _loading = true;
  String? _error;
  List<InspectionModel> _inspections = [];
  List<InspectionModel> _filteredInspections = [];

  @override
  void initState() {
    super.initState();
    _fetchInspections();
    _searchController.addListener(_applySearchFilter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchInspections() async {
    final res = await _api.getAllInspections();

    if (!mounted) return;

    if (res.success && res.data != null) {
      setState(() {
        _inspections = res.data!;
        _filteredInspections = List.from(_inspections);
        _loading = false;
      });
    } else {
      setState(() {
        _error = res.message;
        _loading = false;
      });
    }
  }

  void _applySearchFilter() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => _filteredInspections = List.from(_inspections));
      return;
    }

    setState(() {
      _filteredInspections = _inspections.where((insp) {
        final nameMatch = insp.stationName.toLowerCase().contains(query);
        final engineerMatch =
            insp.engineerName?.toLowerCase().contains(query) ?? false;
        return nameMatch || engineerMatch;
      }).toList();
    });
  }

  // Simple helper to derive pass/fail
  String _getInspectionResult(InspectionModel insp) {
    final failInDispenser =
        insp.dispenserInspection?.values.any(
          (d) => d['status']?.toString().toLowerCase() == 'fail',
        ) ??
        false;
    final failInTank =
        insp.tankInspection?.values.any(
          (t) => t['status']?.toString().toLowerCase() == 'fail',
        ) ??
        false;
    final failInTCEQ =
        insp.tceqInspection?.values.any(
          (t) => t['status']?.toString().toLowerCase() == 'fail',
        ) ??
        false;

    return (failInDispenser || failInTank || failInTCEQ) ? "Fail" : "Pass";
  }

  // Status helpers
  String _getReadableStatus(String? status) {
    switch (status?.toLowerCase()) {
      case "approved":
      case "completed":
        return "Completed";
      case "pending approval":
      case "in progress":
        return "Pending Approval";
      default:
        return "In Progress";
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "Completed":
        return Colors.green.shade100;
      case "In Progress":
      case "Pending Approval":
        return const Color(0xFFFFFBC2);
      default:
        return Colors.grey.shade300;
    }
  }

  Color _getResultColor(String result) {
    switch (result) {
      case "Pass":
        return Colors.green.shade100;
      case "Fail":
        return Colors.red.shade100;
      default:
        return Colors.orange.shade100;
    }
  }

  Color _getTextColor(String value) {
    switch (value) {
      case "Completed":
      case "Pass":
        return Colors.green.shade900;
      case "Pending Approval":
      case "In Progress":
        return const Color(0xFFB38F00);
      case "Fail":
        return Colors.red.shade900;
      default:
        return Colors.black87;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Inspection List"),
          backgroundColor: const Color(0xFF37A8C0),
        ),
        body: Center(
          child: Text(_error!, style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FC),
      appBar: AppBar(
        title: const Text("Inspection List"),
        backgroundColor: const Color(0xFF37A8C0),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 🔍 Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search inspections...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF37A8C0)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(50),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(50),
                  borderSide: const BorderSide(
                    color: Color(0xFF37A8C0),
                    width: 1.2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 🧾 Inspection List
            Expanded(
              child: _filteredInspections.isEmpty
                  ? const Center(child: Text("No inspections found"))
                  : ListView.builder(
                      itemCount: _filteredInspections.length,
                      itemBuilder: (context, index) {
                        final insp = _filteredInspections[index];
                        final status = _getReadableStatus(insp.status);
                        final result = _getInspectionResult(insp);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  insp.stationName,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF37A8C0),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text("Address: ${insp.stationAddress}"),
                                Text("Engineer: ${insp.engineerName}"),
                                Text(
                                  "Created At: ${insp.createdAt?.toLocal().toString().split(' ').first ?? ''}",
                                ),
                                Text(
                                  "Updated At: ${insp.updatedAt?.toLocal().toString().split(' ').first ?? ''}",
                                ),
                                const Divider(height: 20),

                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Text(
                                          "Status: ",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(status),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            status,
                                            style: TextStyle(
                                              color: _getTextColor(status),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        const Text(
                                          "Result: ",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getResultColor(result),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            result,
                                            style: TextStyle(
                                              color: _getTextColor(result),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 16),

                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const InspectionDetailsPage(),
                                            ),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF2C9BB7,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              50,
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          "View",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const InspectionFormScreen(
                                                    title: "Edit Inspection",
                                                  ),
                                            ),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFFFD8233,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              50,
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          "Edit",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
