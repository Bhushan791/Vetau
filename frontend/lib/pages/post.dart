import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/pages/mapSelectPage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:frontend/components/bottomNav.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// NEW imports required for conversion
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:http_parser/http_parser.dart';

enum PostType { lost, found }

class PostTypeButton extends StatelessWidget {
  final String text;
  final PostType type;
  final PostType selectedType;
  final VoidCallback onTap;

  const PostTypeButton({
    super.key,
    required this.text,
    required this.type,
    required this.selectedType,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = selectedType == type;
    final Color buttonColor = isSelected
        ? (type == PostType.lost ? Colors.red.shade700 : Colors.blue.shade700)
        : (type == PostType.lost ? Colors.red.shade100 : Colors.blue.shade100);
    final Color textColor = isSelected ? Colors.white : Colors.black;

    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        elevation: isSelected ? 4 : 0,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          fontSize: 16,
        ),
      ),
    );
  }
}

class PostPage extends StatefulWidget {
  const PostPage({super.key});

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  PostType _selectedPostType = PostType.lost;
  bool _isAnonymous = false;
  bool _isLoading = false;

  // Controllers for text fields
  final TextEditingController _headingController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final TextEditingController _rewardController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  // Images
  final ImagePicker _picker = ImagePicker();
  List<XFile> _images = [];

  // Selected location
  LatLng? _selectedLatLng;

  // Pick multiple images from gallery
  Future<void> _pickImages() async {
    final List<XFile>? pickedImages = await _picker.pickMultiImage(imageQuality: 85);
    if (pickedImages != null && pickedImages.isNotEmpty) {
      setState(() => _images.addAll(pickedImages));
    }
  }

  // Pick single image from camera
  Future<void> _pickFromCamera() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (photo != null) setState(() => _images.add(photo));
  }

  // Bottom sheet to choose image source
  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo),
                title: const Text("Pick from Gallery"),
                onTap: () {
                  Navigator.pop(context);
                  _pickImages();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text("Take a Photo"),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromCamera();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Section title helper
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Text(title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
    );
  }

  // Input field helper
  Widget _buildInputField({required TextEditingController controller, required String hint, int maxLines = 1, IconData? prefixIcon}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.grey.shade600, size: 20) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
        ),
      ),
    );
  }

  // Open MapSelectPage to pick location
  Future<void> _chooseLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MapSelectPage()),
    );

    if (result != null) {
      setState(() {
        _selectedLatLng = LatLng(result["lat"], result["lng"]);
        _locationController.text = result["placeName"]; // Show readable name
      });
    }
  }

  // Build payload for backend
  Map<String, dynamic> _buildPayload() {
    return {
      "type": _selectedPostType == PostType.lost ? "lost" : "found",
      "heading": _headingController.text.trim(),
      "description": _descriptionController.text.trim(),
      "tags": _tagsController.text.trim(),
      "reward": _rewardController.text.trim(),
      "anonymous": _isAnonymous,
      "location": _selectedLatLng != null
          ? {
              "lat": _selectedLatLng!.latitude,
              "lng": _selectedLatLng!.longitude,
              "text": _locationController.text.trim(), // <-- for backend display/search
            }
          : null,
      "images": _images.map((e) => e.path).toList(),
    };
  }

  // -------------------------
  // Helper: Force convert any image file to REAL JPEG bytes and save as .jpg
  // -------------------------
  Future<File> _forceConvertToJpg(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final decoded = img.decodeImage(bytes);

      // If decode fails, return the original file (backend may still reject, but we tried)
      if (decoded == null) {
        debugPrint("Image decode failed for ${file.path}, using original file.");
        return file;
      }

      final jpgBytes = img.encodeJpg(decoded, quality: 85);

      // create new file path with .jpg extension
      final newPath = file.path.replaceAll(RegExp(r'\.\w+$'), '.jpg');

      final jpgFile = File(newPath);
      await jpgFile.writeAsBytes(jpgBytes, flush: true);
      debugPrint("Converted ${file.path} -> $newPath");
      return jpgFile;
    } catch (e) {
      debugPrint("Error converting image to JPG: $e");
      return file;
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade400,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade400,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Submit post
  void _submitPost() async {
    setState(() => _isLoading = true);

    // Future payload (KEEP THIS) ---------------------------
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');
    final futurePayload = _buildPayload();
    print("Full payload (for future backend): $futurePayload");
    // -------------------------------------------------------

    final uri = Uri.parse("https://vetau.onrender.com/api/v1/posts");

    final request = http.MultipartRequest("POST", uri);

    // Add text fields
    request.fields['type'] =
        _selectedPostType == PostType.lost ? "lost" : "found";

    request.fields['itemName'] = _headingController.text.trim();
    request.fields['category'] = _categoryController.text.trim().isNotEmpty 
        ? _categoryController.text.trim() 
        : "others";
    request.fields['rewardAmount'] = _rewardController.text.trim();
    request.fields['description'] = _descriptionController.text.trim();
    request.fields['tags'] = _tagsController.text.trim();
    
    // Debug: Check the actual value
    debugPrint("_isAnonymous value: $_isAnonymous");
    debugPrint("Sending isAnonymous as: ${_isAnonymous.toString()}");
    
    // Don't send isAnonymous field at all if false (backend will default to false)
    if (_isAnonymous) {
      request.fields['isAnonymous'] = 'true';
    }

    // Location text only
    request.fields['location'] = _locationController.text.trim();

    // Add images
    for (var xfile in _images) {
      try {
        final originalFile = File(xfile.path);
        debugPrint("Original image path: ${originalFile.path}");

        // Convert to a true JPEG file (this re-encodes bytes and ensures valid JPEG signature)
        final convertedFile = await _forceConvertToJpg(originalFile);

        // Use contentType to explicitly set MIME
        final multipartFile = await http.MultipartFile.fromPath(
          'images',
          convertedFile.path,
          contentType: MediaType('image', 'jpeg'),
        );

        request.files.add(multipartFile);
        debugPrint("Added multipart file: ${convertedFile.path}");
      } catch (e) {
        debugPrint("Failed to add image ${xfile.path}: $e");
      }
    }

    // ---------------------------------------
    // ADD HEADERS (Authorization + Accept)
    // ---------------------------------------
    request.headers.addAll({
      'Authorization': 'Bearer $accessToken',
      'Accept': 'application/json',
    });

    debugPrint("Request fields: ${request.fields}");
    debugPrint("Sending API request...");

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print("Response Status: ${response.statusCode}");
      print("Response Body: ${response.body}");

      setState(() => _isLoading = false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSuccessSnackBar("Post created successfully");
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        });
      } else {
        String errorMessage = "Failed to create post";
        try {
          final errorJson = jsonDecode(response.body);
          errorMessage = errorJson["message"] ?? errorMessage;
        } catch (_) {}
        _showErrorSnackBar(errorMessage);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Request error: $e");
      _showErrorSnackBar("Server error. Please try again later.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLost = _selectedPostType == PostType.lost;
    
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return false;
      },
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text('Create Post', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 18)),
              centerTitle: true,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: TextButton(
                    onPressed: _submitPost,
                    child: const Text('Post', style: TextStyle(color: Color(0xFF6366F1), fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(
                  children: [
                    Expanded(
                      child: PostTypeButton(
                        text: 'Lost',
                        type: PostType.lost,
                        selectedType: _selectedPostType,
                        onTap: () => setState(() => _selectedPostType = PostType.lost),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PostTypeButton(
                        text: 'Found',
                        type: PostType.found,
                        selectedType: _selectedPostType,
                        onTap: () => setState(() => _selectedPostType = PostType.found),
                      ),
                    ),
                  ],
                ),

                _buildSectionTitle(isLost ? 'Post Heading / What did you lose?' : 'Post Heading / What did you find?'),
                _buildInputField(controller: _headingController, hint: isLost ? 'e.g., My black leather wallet with cards' : 'e.g., Black leather wallet with cards'),

                _buildSectionTitle(isLost ? 'Post Description / Tell us more about it' : 'Post Description / Tell us more about it'),
                _buildInputField(controller: _descriptionController, hint: isLost ? 'Where did you last see it? Any special features?\nHelp others identify it...' : 'Where did you find it? Any special features?\nHelp the owner identify it...', maxLines: 4),

                _buildSectionTitle('Category / What type of item?'),
                _buildInputField(controller: _categoryController, hint: 'e.g., Electronics, Accessories, Documents...'),
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text('Makes your post easier to find',
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                ),

                _buildSectionTitle('Upload Image'),
                GestureDetector(
                  onTap: _showImageSourceSheet,
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_upload_outlined, color: Colors.grey, size: 32),
                        SizedBox(height: 8),
                        Text('Tap to upload image 📸', style: TextStyle(color: Colors.grey, fontSize: 15)),
                        Text('Max 5MB', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (_images.isNotEmpty)
                  SizedBox(
                    height: 100,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _images.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (_, i) => Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(File(_images[i].path), width: 100, height: 100, fit: BoxFit.cover),
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: GestureDetector(
                              onTap: () => setState(() => _images.removeAt(i)),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                child: const Icon(Icons.close, color: Colors.white, size: 16),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),

                _buildSectionTitle(isLost ? 'Location / Where did you lose it ?' : 'Location / Where did you find it ?'),
                _buildInputField(controller: _locationController, hint: isLost ? 'e.g., lost near sainikhand park' : 'e.g., found near sainikhand park'),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _chooseLocation,
                    icon: const Icon(Icons.location_on_outlined, size: 20),
                    label: const Text('Choose on map'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: const BorderSide(color: Color(0xFF6366F1)),
                      foregroundColor: const Color(0xFF6366F1),
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('Pinpoint location will recommend post to nearby users',
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                ),

                _buildSectionTitle('Tags / Add hashtags to describe it'),
                _buildInputField(controller: _tagsController, hint: 'e.g., #wallet #black #leather #cards'),
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text('Add keywords like color, brand, size...',
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                ),

                _buildSectionTitle(isLost ? 'Reward to Finder / Amount' : 'Ask to Owner / Amount'),
                _buildInputField(controller: _rewardController, hint: 'e.g., 1200', prefixIcon: Icons.currency_rupee),

                _buildSectionTitle('Post Anonymously'),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text('"Post Anonymously" Your name won\'t be shown', style: TextStyle(fontSize: 15, color: Colors.grey.shade700)),
                    ),
                    Switch(
                      value: _isAnonymous,
                      onChanged: (value) => setState(() => _isAnonymous = value),
                      activeColor: const Color(0xFF6366F1),
                    ),
                  ],
                ),

                const SizedBox(height: 30),
              ]),
            ),
            bottomNavigationBar: const BottomNav(currentIndex: 2),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF6366F1)),
              ),
            ),
        ],
      ),
    );
  }
}
