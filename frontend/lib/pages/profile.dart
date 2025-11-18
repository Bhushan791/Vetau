import 'package:flutter/material.dart';
import 'package:frontend/config/api_constants.dart';
import 'package:frontend/services/api_client.dart';
import 'package:frontend/services/token_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

const String apiBaseUrl = ApiConstants.baseUrl;

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late String _userName = '';
  late String _userEmail = '';
  late String _userId = '';
  late String _userAddress = '';
  late String _profileImage = '';
  bool _isLoading = false;
  bool _isLogoutLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// Load user data from SharedPreferences first, then fetch from API
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Try to load from SharedPreferences first (cached data)
      setState(() {
        _userName = prefs.getString('userName') ?? 'User';
        _userEmail = prefs.getString('userEmail') ?? 'user@example.com';
        _userId = prefs.getString('userId') ?? '';
      });

      // Now fetch fresh data from API using the access token
      await _fetchUserDataFromAPI();
    } catch (e) {
      print('❌ Error loading user data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Fetch user data from API using access token
  Future<void> _fetchUserDataFromAPI() async {
    try {
      print('📡 Fetching user data from API...');

      final client = ApiClient(
        baseUrl: apiBaseUrl,
        onSessionExpired: (ctx) {
          print('🔐 Session expired - redirecting to login');
          Navigator.pushNamedAndRemoveUntil(ctx, '/login', (route) => false);
        },
      );

      // Call the current-user endpoint
      final response = await client.get(
        Uri.parse('$apiBaseUrl/users/current-user'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = data['data'];

        print('✅ User data fetched successfully');

        // Update UI with fresh data
        setState(() {
          _userName = user['fullName'] ?? 'User';
          _userEmail = user['email'] ?? 'user@example.com';
          _userId = user['_id'] ?? '';
          _userAddress = user['address'] ?? 'No address provided';
          _profileImage = user['profileImage'] ?? '';
        });

        // Update SharedPreferences with fresh data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userName', _userName);
        await prefs.setString('userEmail', _userEmail);
        await prefs.setString('userId', _userId);
        
        print('📝 SharedPreferences updated with fresh data');
      } else if (response.statusCode == 401) {
        print('⚠️ 401 Unauthorized - Token might be expired');
        throw UnauthorizedException('Session expired. Please login again.');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to fetch user data');
      }
    } catch (e) {
      print('❌ Error fetching user data: $e');
      // If API call fails, keep using cached data
      // User can still see their cached information and logout
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not refresh profile: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    setState(() {
      _isLogoutLoading = true;
    });

    try {
      print('🚪 Attempting logout...');

      final tokenService = TokenService();
      final accessToken = await tokenService.getAccessToken();

      if (accessToken == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No token found. Please login again.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLogoutLoading = false;
        });
        return;
      }

      // Call logout API with authorization header
      final response = await http.post(
        Uri.parse('$apiBaseUrl/users/logout/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      setState(() {
        _isLogoutLoading = false;
      });

      if (response.statusCode == 200) {
        print('✅ Logout successful from API');

        // Clear access token using TokenService
        await tokenService.clearAccessToken();

        // Clear all stored data from SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('userId');
        await prefs.remove('userName');
        await prefs.remove('userEmail');

        print('🧹 All tokens and user data cleared');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged out successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to login page
        if (mounted) {
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/login', (route) => false);
        }
      } else {
        final errorData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorData['message'] ?? 'Logout failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLogoutLoading = false;
      });

      print('❌ Logout error: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Page'),
        backgroundColor: const Color(0xFF4285F4),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Profile Image or Avatar
                  if (_profileImage.isNotEmpty)
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: NetworkImage(_profileImage),
                    )
                  else
                    const Icon(
                      Icons.account_circle,
                      size: 80,
                      color: Color(0xFF4285F4),
                    ),
                  const SizedBox(height: 20),
                  
                  // User Name
                  Text(
                    _userName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // User Email
                  Text(
                    _userEmail,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // User Address
                  if (_userAddress.isNotEmpty)
                    Text(
                      _userAddress,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 40),
                  
                  // Logout Button
                  ElevatedButton(
                    onPressed: _isLogoutLoading ? null : _logout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      disabledBackgroundColor: Colors.grey[300],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isLogoutLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Logout',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}