import 'package:flutter/material.dart';
import 'package:frontend/config/api_constants.dart';
import 'package:frontend/services/api_client.dart';
import 'package:frontend/services/token_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

const Color kPrimaryColor = Color(0xFF4285F4);
const Color kOrangeColor = Color(0xFFFB9A47);
const Color kLightBlueBackground = Color(0xFFE8F0FE);
const Color kCardBackground = Color(0xFFFFFFFF);
const Color kScaffoldBackground = Color(0xFFF5F6F8);

const String apiBaseUrl = ApiConstants.baseUrl;

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);
  @override
  String toString() => 'UnauthorizedException: $message';
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _userName = 'Luniva Maharjan';
  String _userEmail = 'mhrznluniva22@gmail.com';
  String _userPhone = '+977 - 9823456789';
  String _userId = '';
  String _profileImage = '';
  
  final double _karmaPoints = 3355.06;
  final int _totalPost = 10;
  final int _foundItems = 6;
  final int _itemsReturned = 3;

  bool _isLoading = false;
  bool _isLogoutLoading = false;
  final double _headerHeight = 280.0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _userName = prefs.getString('userName') ?? 'Luniva Maharjan';
        _userEmail = prefs.getString('userEmail') ?? 'mhrznluniva22@gmail.com';
        _userId = prefs.getString('userId') ?? '';
      });
      await _fetchUserDataFromAPI();
    } catch (e) {
      print('❌ Error loading user data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchUserDataFromAPI() async {
    try {
      final client = ApiClient(
        baseUrl: apiBaseUrl,
        onSessionExpired: (ctx) {
          if (mounted) Navigator.pushNamedAndRemoveUntil(ctx, '/login', (route) => false);
        },
      );
      final response = await client.get(Uri.parse('$apiBaseUrl/users/current-user'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = data['data'];
        setState(() {
          _userName = user['fullName'] ?? 'User';
          _userEmail = user['email'] ?? 'user@example.com';
          _userId = user['_id'] ?? '';
          _profileImage = user['profileImage'] ?? '';
        });
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userName', _userName);
        await prefs.setString('userEmail', _userEmail);
        await prefs.setString('userId', _userId);
      }
    } catch (e) {
      print('❌ Error fetching user data: $e');
    }
  }

  Future<void> _logout() async {
    setState(() => _isLogoutLoading = true);
    try {
      final tokenService = TokenService();
      final accessToken = await tokenService.getAccessToken();

      if (accessToken == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No token found. Please login again.'), backgroundColor: Colors.red),
        );
        setState(() => _isLogoutLoading = false);
        return;
      }

      final response = await http.post(
        Uri.parse('$apiBaseUrl/users/logout/'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $accessToken'},
      );

      setState(() => _isLogoutLoading = false);

      if (response.statusCode == 200) {
        await tokenService.clearAccessToken();
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('userId');
        await prefs.remove('userName');
        await prefs.remove('userEmail');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logged out successfully'), backgroundColor: Colors.green),
        );

        if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      } else {
        final errorData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorData['message'] ?? 'Logout failed'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      setState(() => _isLogoutLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScaffoldBackground,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildActivityOverview(),
                  const SizedBox(height: 20),
                  _buildUserActionsList(),
                  const SizedBox(height: 20),
                  _buildAccountActionsList(),
                  const SizedBox(height: 50),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Container(
          height: _headerHeight,
          decoration: BoxDecoration(
            color: kLightBlueBackground,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(50),
              bottomRight: Radius.circular(50),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: Column(
              children: [
                _buildTopBar(),
                const SizedBox(height: 30),
                _buildProfileSection(),
                const SizedBox(height: 15),
                _buildKarmaPointsBadge(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
            ),
          ),
          const Text(
            'Vetau\nProfile',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              height: 1.2,
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[300],
                backgroundImage: _profileImage.isNotEmpty ? NetworkImage(_profileImage) : null,
                child: _profileImage.isEmpty ? const Icon(Icons.person, size: 60, color: Colors.grey) : null,
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: () => showModalBottomSheet(
                  context: context,
                  builder: (context) => Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.visibility),
                          title: const Text('View Profile Picture'),
                          onTap: () {
                            Navigator.pop(context);
                            print('View Profile Picture clicked');
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.edit),
                          title: const Text('Edit Profile'),
                          onTap: () {
                            Navigator.pop(context);
                            print('Edit Profile clicked');
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey[300]!, width: 2),
                  ),
                  child: const Icon(Icons.edit, size: 16, color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Text(
          _userName,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          '$_userEmail | $_userPhone',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildKarmaPointsBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: kOrangeColor,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: kOrangeColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        '${_karmaPoints.toStringAsFixed(2)} Karma Points',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kCardBackground,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildActivityOverview() {
    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Activity Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildActivityItem(Icons.description_outlined, _totalPost, 'Total Post', kPrimaryColor),
              _buildActivityItem(Icons.search, _foundItems, 'Found Items', const Color(0xFF139A43)),
              _buildActivityItem(Icons.keyboard_return, _itemsReturned, 'Items Returned', const Color(0xFF9C27B0)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(IconData icon, int count, String label, Color color) {
    return Column(
      children: [
        Icon(icon, size: 30, color: color),
        const SizedBox(height: 8),
        Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildUserActionsList() {
    return _buildSectionCard(
      child: Column(
        children: [
          _buildActionRow('Saved Posts', () => print('Saved Posts clicked')),
          const Divider(height: 1, thickness: 0.5),
          _buildActionRow('Your Posts', () => print('Your Posts clicked')),
          const Divider(height: 1, thickness: 0.5),
          _buildActionRow('Your Contribution', () => print('Your Contribution clicked')),
          const Divider(height: 1, thickness: 0.5),
          _buildActionRow('Achievements', () => print('Achievements clicked')),
        ],
      ),
    );
  }

  Widget _buildAccountActionsList() {
    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Account Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 15),
          _buildActionRowWithIcon('Settings', Icons.settings_outlined, Colors.black, () => print('Settings clicked')),
          const Divider(height: 1, thickness: 0.5),
          _buildActionRowWithIcon('Log out', Icons.logout, Colors.red, _isLogoutLoading ? null : _logout, isLogout: true, isLoading: _isLogoutLoading),
        ],
      ),
    );
  }

  Widget _buildActionRow(String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, color: Colors.black87)),
            const Text('View All >', style: TextStyle(fontSize: 14, color: kPrimaryColor, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionRowWithIcon(String title, IconData icon, Color color, VoidCallback? onTap, {bool isLogout = false, bool isLoading = false}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15.0),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 15),
            Text(title, style: TextStyle(fontSize: 16, color: color, fontWeight: isLogout ? FontWeight.bold : FontWeight.normal)),
            if (isLogout && isLoading)
              const Padding(
                padding: EdgeInsets.only(left: 10.0),
                child: SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.red)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}