import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/pages/mapSelectPage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:frontend/components/bottomNav.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:frontend/config/api_constants.dart';
import 'package:frontend/services/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image/image.dart' as img;

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

class EditPostPage extends StatefulWidget {
  final String postId;

  const EditPostPage({super.key, required this.postId});

  @override
  State<EditPostPage> createState() => _EditPostPageState();
}

class _EditPostPageState extends State<EditPostPage> {
  PostType _selectedPostType = PostType.lost;
  bool _isAnonymous = false;
  bool _isLoading = false;
  bool _isLoadingData = true;

  // Controllers for text fields
  final TextEditingController _headingController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final TextEditingController _rewardController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  // Images
  final ImagePicker _picker = ImagePicker();
  List<XFile> _newImages = [];
  List<String> _existingImageUrls = [];

  // Selected location
  LatLng? _selectedLatLng;

  @override
  void initState() {
    super.initState();
    _fetchPostData();
  }

  Future<void> _fetchPostData() async {
    try {
      final client = ApiClient(
        baseUrl: ApiConstants.baseUrl,
        onSessionExpired: (ctx) {
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(ctx, '/login', (route) => false);
          }
        },
      );

      final url = Uri.parse('${ApiConstants.baseUrl}/posts/${widget.postId}');
      final response = await client.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final postData = data['data'] ?? data;

        setState(() {
          _headingController.text = postData['itemName'] ?? '';
          _descriptionController.text = postData['description'] ?? '';
          _categoryController.text = postData['category'] ?? '';
          _tagsController.text = (postData['tags'] as List?)?.join(', ') ?? '';
          _rewardController.text = (postData['rewardAmount'] ?? 0).toString();
          _locationController.text = postData['location'] is Map
              ? (postData['location']['name'] ?? '')
              : (postData['location'] ?? '');

          _selectedPostType = (postData['type'] == 'lost') ? PostType.lost : PostType.found;
          _isAnonymous = postData['isAnonymous'] ?? false;

          if (postData['images'] != null && postData['images'] is List) {
            _existingImageUrls = List<String>.from(postData['images']);
          }

          if (postData['location'] is Map && postData['location']['coordinates'] != null) {
            final coords = postData['location']['coordinates'];
            if (coords is List && coords.length >= 2) {
              _selectedLatLng = LatLng(coords[1], coords[0]);
            }
          }

          _isLoadingData = false;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to load post'), backgroundColor: Colors.red),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
        Navigator.pop(context);
      }
    }
  }

  // Pick multiple images from gallery
  Future<void> _pickImages() async {
    final List<XFile>? pickedImages = await _picker.pickMultiImage(imageQuality: 85);
    if (pickedImages != null && pickedImages.isNotEmpty) {
      setState(() => _newImages.addAll(pickedImages));
    }
  }

  // Pick single image from camera
  Future<void> _pickFromCamera() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (photo != null) setState(() => _newImages.add(photo));
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
        _locationController.text = result["placeName"];
      });
    }
  }

  // Helper: Force convert any image file to REAL JPEG bytes
  Future<File> _forceConvertToJpg(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final decoded = img.decodeImage(bytes);

      if (decoded == null) {
        debugPrint("Image decode failed for ${file.path}, using original file.");
        return file;
      }

      final jpgBytes = img.encodeJpg(decoded, quality: 85);
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

  // Update post
  Future<void> _updatePost() async {
    setState(() => _isLoading = true);

    try {
      final client = ApiClient(
        baseUrl: ApiConstants.baseUrl,
        onSessionExpired: (ctx) {
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(ctx, '/login', (route) => false);
          }
        },
      );

      final uri = Uri.parse('${ApiConstants.baseUrl}/posts/${widget.postId}');
      final request = http.MultipartRequest('PATCH', uri);

      // Add text fields
      request.fields['type'] = _selectedPostType == PostType.lost ? 'lost' : 'found';
      request.fields['itemName'] = _headingController.text.trim();
      request.fields['category'] = _categoryController.text.trim().isNotEmpty
          ? _categoryController.text.trim()
          : 'others';
      request.fields['rewardAmount'] = _rewardController.text.trim();
      request.fields['description'] = _descriptionController.text.trim();
      request.fields['tags'] = _tagsController.text.trim();
      request.fields['location'] = _locationController.text.trim();

      if (_isAnonymous) {
        request.fields['isAnonymous'] = 'true';
      }

      // Add new images only
      for (var xfile in _newImages) {
        try {
          final originalFile = File(xfile.path);
          final convertedFile = await _forceConvertToJpg(originalFile);

          final multipartFile = await http.MultipartFile.fromPath(
            'images',
            convertedFile.path,
            contentType: MediaType('image', 'jpeg'),
          );

          request.files.add(multipartFile);
        } catch (e) {
          debugPrint("Failed to add image ${xfile.path}: $e");
        }
      }

      final streamedResponse = await client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      setState(() => _isLoading = false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 10),
                  Text('Post updated successfully'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        String errorMessage = 'Failed to update post';
        try {
          final errorJson = jsonDecode(response.body);
          errorMessage = errorJson['message'] ?? errorMessage;
        } catch (_) {}
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Edit Post', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isLost = _selectedPostType == PostType.lost;

    return Stack(
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
            title: const Text('Edit Post', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 18)),
            centerTitle: true,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: TextButton(
                  onPressed: _updatePost,
                  child: const Text('Update', style: TextStyle(color: Color(0xFF6366F1), fontSize: 16, fontWeight: FontWeight.w600)),
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

              _buildSectionTitle('Existing Images'),
              if (_existingImageUrls.isNotEmpty)
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _existingImageUrls.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) => ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _existingImageUrls[i],
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.image_not_supported),
                        ),
                      ),
                    ),
                  ),
                )
              else
                const Text('No existing images', style: TextStyle(color: Colors.grey)),

              _buildSectionTitle('Upload New Images'),
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
                      Text('Tap to upload new images 📸', style: TextStyle(color: Colors.grey, fontSize: 15)),
                      Text('Max 5MB', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_newImages.isNotEmpty)
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _newImages.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) => Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(File(_newImages[i].path), width: 100, height: 100, fit: BoxFit.cover),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: GestureDetector(
                            onTap: () => setState(() => _newImages.removeAt(i)),
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
    );
  }

  @override
  void dispose() {
    _headingController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _tagsController.dispose();
    _rewardController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}