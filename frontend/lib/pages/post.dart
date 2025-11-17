import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:frontend/components/bottomNav.dart';

// --- ENUM FOR POST TYPE SELECTION ---
enum PostType { lost, found }

// --- CUSTOM WIDGETS ---
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

// --- MAIN PAGE IMPLEMENTATION ---
class PostPage extends StatefulWidget {
  const PostPage({super.key});

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  PostType _selectedPostType = PostType.lost;
  bool _isAnonymous = false;

  // --- IMAGE PICKER STATE ---
  final ImagePicker _picker = ImagePicker();
  List<XFile> _images = [];

  // Pick multiple from gallery
  Future<void> _pickImages() async {
    final List<XFile> pickedImages = await _picker.pickMultiImage(
      imageQuality: 85,
    );

    if (pickedImages.isNotEmpty) {
      setState(() {
        _images.addAll(pickedImages);
      });
    }
  }

  // Pick from camera
  Future<void> _pickFromCamera() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (photo != null) {
      setState(() {
        _images.add(photo);
      });
    }
  }

  // Bottom popup to choose source
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

  // Section Title Widget
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  // Input Field Widget
  Widget _buildInputField({
    required String hint,
    int maxLines = 1,
    IconData? prefixIcon,
  }) {
    return TextField(
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.grey) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Create Post',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
          ),
          centerTitle: false,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: () {
                  print('Post button tapped. Type: $_selectedPostType, Anonymous: $_isAnonymous');
                },
                child: const Text(
                  'Post',
                  style: TextStyle(color: Colors.blue, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),

        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Lost / Found Buttons
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

              // Heading
              _buildSectionTitle('Post Heading'),
              _buildInputField(hint: 'e.g., Cat Lost near Lake Street'),

              // Description
              _buildSectionTitle('Post Description'),
              _buildInputField(
                hint: 'Share details about your lost/found item...',
                maxLines: 5,
              ),

              // Upload Image Section
              _buildSectionTitle('Upload Image'),
              GestureDetector(
                onTap: _showImageSourceSheet,
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_upload_outlined, color: Colors.grey, size: 30),
                      Text('Tap to upload image', style: TextStyle(color: Colors.grey)),
                      Text('Max 5MB', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Preview of selected images
              if (_images.isNotEmpty)
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _images.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) {
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(_images[i].path),
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),

                          Positioned(
                            right: 0,
                            top: 0,
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _images.removeAt(i));
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, color: Colors.white, size: 16),
                              ),
                            ),
                          )
                        ],
                      );
                    },
                  ),
                ),

              // Location
              _buildSectionTitle('Location'),
              _buildInputField(hint: 'Central Park, New York'),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    print('Choose on Map tapped');
                  },
                  icon: const Icon(Icons.location_on_outlined, size: 20),
                  label: const Text('Choose on Map'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    side: BorderSide(color: Colors.blue.shade700),
                    foregroundColor: Colors.blue.shade700,
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Pinpoint the exact location for better visibility.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),

              // Tags
              _buildSectionTitle('Tags'),
              _buildInputField(hint: 'e.g., #petrescue, #lostcat, #dogwalker'),
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Add relevant tags to help others find your post.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),

              // Reward
              _buildSectionTitle('Reward to Finder'),
              _buildInputField(hint: 'e.g., 500', prefixIcon: Icons.currency_rupee),

              // Anonymous Switch
              _buildSectionTitle('Post Anonymously'),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Post Anonymously',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  Switch(
                    value: _isAnonymous,
                    onChanged: (value) => setState(() => _isAnonymous = value),
                    activeColor: Colors.blue,
                  ),
                ],
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),

        bottomNavigationBar: const BottomNav(currentIndex: 2),
      ),
    );
  }
}
