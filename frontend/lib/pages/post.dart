import 'package:flutter/material.dart';
import 'package:frontend/components/bottomNav.dart';

// --- PLACEHOLDER COMPONENTS (Replace with your actual files) ---

// // Placeholder for your BottomNav component
// class BottomNav extends StatelessWidget {
//   final int currentIndex;
//   const BottomNav({super.key, required this.currentIndex});

//   @override
//   Widget build(BuildContext context) {
//     return BottomNavigationBar(
//       currentIndex: currentIndex,
//       items: const [
//         BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
//         BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
//         BottomNavigationBarItem(icon: Icon(Icons.add_box), label: 'Post'),
//         BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
//       ],
//     );
//   }
// }

// --- ENUM FOR POST TYPE SELECTION ---
enum PostType { lost, found }

// --- CUSTOM WIDGETS ---

// A reusable widget for the Lost/Found selection buttons
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
          borderRadius: BorderRadius.circular(8.0),
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

  // Helper to create the titled sections (e.g., "Post Heading")
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
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

  // Helper for input fields
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
          borderRadius: BorderRadius.circular(8.0),
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
        // Custom AppBar implementation
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          // Back arrow
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          // Title
          title: const Text(
            'Create Post',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
          ),
          centerTitle: false,
          // Post button
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton(
                onPressed: () {
                  // Handle post submission logic
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

        // Body containing the form
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Lost/Found Buttons
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

              // 2. Post Heading
              _buildSectionTitle('Post Heading'),
              _buildInputField(hint: 'e.g., Cat Lost near Lake Street'),

              // 3. Post Description
              _buildSectionTitle('Post Description'),
              _buildInputField(
                  hint: 'Share details about your lost/found item...', maxLines: 5),

              // 4. Upload Image
              _buildSectionTitle('Upload Image'),
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: Colors.grey.shade300,
                    // Fix: BorderStyle only has 'solid' and 'none'.
                    // Using BorderStyle.solid as 'dashed' is not a standard option in Box Border.
                    // For a true dashed border, a package (like dotted_border) or CustomPainter is needed.
                    style: BorderStyle.solid, 
                    width: 2.0,
                  ),
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

              // 5. Location
              _buildSectionTitle('Location'),
              _buildInputField(hint: 'Central Park, New York'),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Handle map selection
                    print('Choose on Map tapped');
                  },
                  icon: const Icon(Icons.location_on_outlined, size: 20),
                  label: const Text('Choose on Map'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    side: BorderSide(color: Colors.blue.shade700),
                    foregroundColor: Colors.blue.shade700,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  'Pinpoint the exact location for better visibility.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),

              // 6. Tags
              _buildSectionTitle('Tags'),
              _buildInputField(hint: 'e.g., #petrescue, #lostcat, #dogwalker'),
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  'Add relevant tags to help others find your post.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),

              // 7. Reward to Finder
              _buildSectionTitle('Reward to Finder'),
              _buildInputField(
                  hint: 'e.g., 500', prefixIcon: Icons.currency_rupee),

              // 8. Post Anonymously Switch
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
                    onChanged: (value) {
                      setState(() {
                        _isAnonymous = value;
                      });
                    },
                    activeColor: Colors.blue,
                  ),
                ],
              ),
              const SizedBox(height: 30), // Extra space at the bottom
            ],
          ),
        ),

        // Bottom Navigation Bar (using your existing component)
        bottomNavigationBar: const BottomNav(currentIndex: 2),
      ),
    );
  }
}
