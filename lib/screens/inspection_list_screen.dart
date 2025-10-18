import 'package:flutter/material.dart';
import 'package:tiq_service_mob/screens/inspection_details_screen.dart';
import 'package:tiq_service_mob/screens/station_form_screen.dart';

const List<Map<String, dynamic>> inspectionList = [
  {
    "stationName": "Fuel Point A",
    "stationCode": "STN-001",
    "stationAddress": "123 Green Avenue, City Center",
    "createdAt": "2025-10-10",
    "updatedAt": "2025-10-15",
    "engineerAssigned": "John Doe",
    "status": "Pending Approval",
    "result": "Fail",
  },
  {
    "stationName": "PetroMax Station",
    "stationCode": "STN-002",
    "stationAddress": "45 Highway Road, West Zone",
    "createdAt": "2025-09-25",
    "updatedAt": "2025-10-05",
    "engineerAssigned": "Alice Smith",
    "status": "Completed",
    "result": "Pass",
  },
  {
    "stationName": "Energy Fuel Depot",
    "stationCode": "STN-003",
    "stationAddress": "678 Industrial Lane, East Block",
    "createdAt": "2025-09-20",
    "updatedAt": "2025-10-02",
    "engineerAssigned": "Robert White",
    "status": "Completed",
    "result": "Fail",
  },
];

class InspectionListScreen extends StatelessWidget {
  const InspectionListScreen({super.key});

  // Status badge background colors
  Color _getStatusColor(String status) {
    switch (status) {
      case "Completed":
        return Colors.green.shade100;
      case "Pending Approval":
        return const Color(0xFFFFFBC2);
      default:
        return Colors.grey.shade300;
    }
  }

  // Result badge background colors
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

  // Text color for both status & result
  Color _getTextColor(String value) {
    switch (value) {
      case "Completed":
      case "Pass":
        return Colors.green.shade900;
      case "Pending Approval":
        return const Color(0xFFB38F00);
      case "Fail":
        return Colors.red.shade900;
      default:
        return Colors.black87;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FC),
      appBar: AppBar(
        title: const Text("Inspection List"),
        backgroundColor: const Color(0xFF37A8C0),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: inspectionList.length,
          itemBuilder: (context, index) {
            final item = inspectionList[index];

            return Container(
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200, width: 1),
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
                    // Station Name
                    Text(
                      item['stationName'],
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF37A8C0),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text("Code: ${item['stationCode']}"),
                    Text("Address: ${item['stationAddress']}"),
                    const Divider(height: 20),

                    // Details
                    Text("Engineer Assigned: ${item['engineerAssigned']}"),
                    Text("Created At: ${item['createdAt']}"),
                    Text("Updated At: ${item['updatedAt']}"),
                    const SizedBox(height: 12),

                    // Status and Result with labels
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text(
                              "Status: ",
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(item['status']),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                item['status'],
                                style: TextStyle(
                                  color: _getTextColor(item['status']),
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
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getResultColor(item['result']),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                item['result'],
                                style: TextStyle(
                                  color: _getTextColor(item['result']),
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

                    // Action Buttons
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
                              backgroundColor: const Color(0xFF2C9BB7),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
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
                              // Edit action
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
                              backgroundColor: const Color(0xFFFD8233),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
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
    );
  }
}
