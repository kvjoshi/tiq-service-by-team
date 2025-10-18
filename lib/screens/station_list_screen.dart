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
  List<Map<String, dynamic>> _filteredStations = [];
  String? _error;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStations();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredStations = _stations
          .where(
            (s) => (s['stationName'] ?? '').toString().toLowerCase().contains(
              query,
            ),
          )
          .toList();
    });
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
        _filteredStations = res.data!;
        _loading = false;
      });
    } else {
      setState(() {
        _error = res.message;
        _stations = [];
        _filteredStations = [];
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res.statusCode == 401
                ? 'Session expired. Please login again.'
                : 'Failed to load stations: ${res.message}',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FC),
      appBar: AppBar(
        title: const Text('Station List'),
        backgroundColor: const Color(0xFF37A8C0),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadStations,
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Text(
          'Error loading stations: $_error',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search stations...',
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
          ),
        ),

        // Station List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: _filteredStations.length,
            itemBuilder: (ctx, i) {
              final s = _filteredStations[i];
              final name = s['stationName'] ?? 'Unknown';
              final addressMap = s['address'];
              final brandingLogoUrl = s['brandingLogoUrl'] as String?;
              String fullAddress = '';

              if (addressMap is Map && addressMap.isNotEmpty) {
                final street = addressMap['street'] ?? '';
                final city = addressMap['city'] ?? '';
                final state = addressMap['state'] ?? '';
                final country = addressMap['country'] ?? '';
                fullAddress = [street, city, state, country]
                    .where((e) => e != null && e.toString().trim().isNotEmpty)
                    .join(', ');
              }

              return _buildStationCard(
                name.toString(),
                fullAddress,
                brandingLogoUrl,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStationCard(String name, String address, String? imageUrl) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: (imageUrl != null && imageUrl.isNotEmpty)
                ? Image.network(
                    imageUrl,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _noImagePlaceholder();
                    },
                  )
                : _noImagePlaceholder(),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF37A8C0),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  address.isNotEmpty ? address : 'No address available',
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF37A8C0),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      // TODO: navigate to inspection creation
                    },
                    icon: const Icon(Icons.assignment_add, size: 18),
                    label: const Text(
                      'Create Inspection',
                      style: TextStyle(fontSize: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _noImagePlaceholder() {
    return Container(
      height: 140,
      width: double.infinity,
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
      ),
    );
  }
}
