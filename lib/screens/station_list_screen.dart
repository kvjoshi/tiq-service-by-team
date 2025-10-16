import 'package:flutter/material.dart';
import '../controllers/inspection_api_controller.dart';

class StationListScreen extends StatefulWidget {
  const StationListScreen({super.key});

  @override
  State<StationListScreen> createState() => _StationListScreenState();
}

class _StationListScreenState extends State<StationListScreen> {
  final _api = InspectionApiController();
  bool _loading = true;
  List<Map<String, dynamic>> _stations = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStations();
  }

  Future<void> _loadStations() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final res = await _api.getStations();

    if (!mounted) return;
    if (res.success && res.data != null) {
      setState(() {
        _stations = res.data!;
        _loading = false;
      });
    } else {
      setState(() {
        _error = res.message;
        _stations = [];
        _loading = false;
      });
      // optional: show a snack so user sees the error immediately
      if (res.statusCode == 401) {
        // unauthorized — optional: navigate to login
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Session expired. Please login again.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load stations: ${res.message}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // RefreshIndicator requires a scrollable widget as child (usually ListView).
    return Scaffold(
      appBar: AppBar(title: const Text('Stations')),
      body: RefreshIndicator(
        onRefresh: _loadStations,
        child: _buildListViewContent(context),
      ),
    );
  }

  Widget _buildListViewContent(BuildContext context) {
    // Always return a ListView so RefreshIndicator works consistently.
    if (_loading) {
      // show a large centered loader inside a scrollable
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: const Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }

    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Error loading stations:\n$_error',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            onPressed: _loadStations,
          ),
        ],
      );
    }

    if (_stations.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: const Center(
              child: Text('No stations found', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _stations.length,
      itemBuilder: (ctx, i) {
        final s = _stations[i];
        final name = s['name'] ?? s['stationName'] ?? s['title'] ?? 'Unknown';
        final code = s['id'] ?? s['stationId'] ?? '';
        final address = s['address'] ?? s['location'] ?? s['addressLine'] ?? '';
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: const Icon(
              Icons.local_gas_station,
              color: Color(0xFF37A8C0),
            ),
            title: Text(name.toString()),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (code != null && code.toString().isNotEmpty)
                  Text('Code: ${code.toString()}'),
                if (address != null && address.toString().isNotEmpty)
                  Text(address.toString()),
              ],
            ),
            onTap: () {
              // optionally navigate to station details
            },
          ),
        );
      },
    );
  }
}
