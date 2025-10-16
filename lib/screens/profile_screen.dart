import 'package:flutter/material.dart';
import '../controllers/inspection_api_controller.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _api = InspectionApiController();
  bool _loading = true;
  Map<String, dynamic>? _profile;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    final res = await _api.getUserProfile();
    if (res.success && res.data != null) {
      setState(() {
        // directly use user_withOrgs
        _profile = res.data?['user_withOrgs'];
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(res.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userData = _profile ?? {};
    final avatarUrl = userData['brandingLogoUrl'] as String?;
    final firstName = _profile?['fName'] as String? ?? '';
    final lastName = _profile?['lName'] as String? ?? '';
    final email = _profile?['email'] as String? ?? '';
    final phone = _profile?['phone'] as String? ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: const Color(0xFF37A8C0),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              color: Colors.white,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 55,
                      backgroundColor: const Color(0xFF37A8C0),
                      backgroundImage:
                          (avatarUrl != null && avatarUrl.isNotEmpty)
                          ? NetworkImage(avatarUrl)
                          : null,
                      child: (avatarUrl == null || avatarUrl.isEmpty)
                          ? const Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$firstName $lastName',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),

                    const SizedBox(height: 20),

                    // Tabs
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF7FA),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      padding: const EdgeInsets.all(6),
                      child: Row(
                        children: [
                          _tabPill('Personal Info', 0),
                          _tabPill('Change Password', 1),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _selectedTab == 0
                          ? _personalInfoCard(firstName, lastName, email, phone)
                          : _passwordCard(),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _tabPill(String label, int index) {
    final active = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF37A8C0) : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _personalInfoCard(
    String firstName,
    String lastName,
    String email,
    String phone,
  ) {
    final deco = _inputDecoration();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Personal Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              readOnly: true,
              decoration: deco.copyWith(labelText: 'First Name'),
              initialValue: firstName,
            ),
            const SizedBox(height: 12),
            TextFormField(
              readOnly: true,
              decoration: deco.copyWith(labelText: 'Last Name'),
              initialValue: lastName,
            ),
            const SizedBox(height: 12),
            TextFormField(
              readOnly: true,
              decoration: deco.copyWith(labelText: 'Email'),
              initialValue: email,
            ),
            const SizedBox(height: 12),
            TextFormField(
              readOnly: true,
              decoration: deco.copyWith(labelText: 'Phone'),
              initialValue: phone,
            ),
          ],
        ),
      ),
    );
  }

  Widget _passwordCard() {
    return const Center(
      child: Text(
        'Password change is not available in read-only mode.',
        style: TextStyle(color: Colors.grey),
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFEFF7FA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }
}
