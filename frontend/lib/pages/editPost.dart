// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:frontend/pages/mapSelectPage.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:frontend/components/bottomNav.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:image/image.dart' as img;
// import 'package:http_parser/http_parser.dart';

// enum PostType { lost, found }

// class PostTypeButton extends StatelessWidget {
//   final String text;
//   final PostType type;
//   final PostType selectedType;
//   final VoidCallback onTap;

//   const PostTypeButton({
//     super.key,
//     required this.text,
//     required this.type,
//     required this.selectedType,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final bool isSelected = selectedType == type;
//     final Color buttonColor = isSelected
//         ? (type == PostType.lost ? Colors.red.shade700 : Colors.blue.shade700)
//         : (type == PostType.lost ? Colors.red.shade100 : Colors.blue.shade100);
//     final Color textColor = isSelected ? Colors.white : Colors.black;

//     return ElevatedButton(
//       onPressed: onTap,
//       style: ElevatedButton.styleFrom(
//         backgroundColor: buttonColor,
//         elevation: isSelected ? 4 : 0,
//         padding: const EdgeInsets.symmetric(vertical: 16),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(8),
//         ),
//       ),
//       child: Text(
//         text,
//         style: TextStyle(
//           color: textColor,
//           fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
//           fontSize: 16,
//         ),
//       ),
//     );
//   }
// }

// class EditPostPage extends StatefulWidget {
//   final String postId;

//   const EditPostPage({super.key, required this.postId});

//   @override
//   State<EditPostPage> createState() => _EditPostPageState();
// }

// class _EditPostPageState extends State<EditPostPage> {
//   PostType _selectedPostType = PostType.lost;
//   bool _isAnonymous = false;
//   bool _isLoading = true;

//   // Controllers for text fields
//   final TextEditingController _headingController = TextEditingController();
//   final TextEditingController _descriptionController = TextEditingController();
//   final TextEditingController _tagsController = TextEditingController();
//   final TextEditingController _rewardController = TextEditingController();
//   final TextEditingController _locationController = TextEditingController();

//   // Images
//   final ImagePicker _picker = ImagePicker();
//   List<XFile> _newImages = [];
//   List<String> _existingImageUrls = [];

//   // Selected location
//   LatLng? _selectedLatLng;
//   String _locationText = "";

//   @override
//   void initState() {
//     super.initState();
//     _fetchPostData();
//   }

//   // Fetch post data from API
//   Future<void> _fetchPostData() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final accessToken = prefs.getString('accessToken');

//       final uri = Uri.parse("https://vetau.onrender.com/api/v1/posts/${widget.postId}");

//       final response = await http.get(
//         uri,
//         headers: {
//           'Authorization': 'Bearer $accessToken',
//           'Accept': 'application/json',
//         },
//       );

//       print("Fetch Response Status: ${response.statusCode}");
//       print("Fetch Response Body: ${response.body}");

//       if (response.statusCode == 200) {
//         final data = response.body;
//         // Parse JSON response based on your backend structure
//         // This is a template - adjust field names based on your API response
//         setState(() {
//           // Example: adjust these based on actual API response
//           _headingController.text = data['itemName'] ?? '';
//           _descriptionController.text = data['description'] ?? '';
//           _tagsController.text = data['tags'] ?? '';
//           _rewardController.text = data['rewardAmount']?.toString() ?? '';
//           _locationController.text = data['location'] ?? '';
//           _locationText = data['location'] ?? '';

//           // Set post type
//           _selectedPostType = (data['type'] == 'lost') ? PostType.lost : PostType.found;

//           // Set anonymous
//           _isAnonymous = data['anonymous'] ?? false;

//           // Store existing images
//           if (data['images'] != null && data['images'] is List) {
//             _existingImageUrls = List<String>.from(data['images']);
//           }

//           // Set location if available
//           if (data['latitude'] != null && data['longitude'] != null) {
//             _selectedLatLng = LatLng(data['latitude'], data['longitude']);
//           }

//           _isLoading = false;
//         });
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Failed to load post")),
//         );
//         setState(() => _isLoading = false);
//       }
//     } catch (e) {
//       debugPrint("Error fetching post: $e");
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Error loading post")),
//       );
//       setState(() => _isLoading = false);
//     }
//   }

//   // Pick multiple images from gallery
//   Future<void> _pickImages() async {
//     final List<XFile>? pickedImages = await _picker.pickMultiImage(imageQuality: 85);
//     if (pickedImages != null && pickedImages.isNotEmpty) {
//       setState(() => _newImages.addAll(pickedImages));
//     }
//   }

//   // Pick single image from camera
//   Future<void> _pickFromCamera() async {
//     final XFile? photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
//     if (photo != null) setState(() => _newImages.add(photo));
//   }

//   // Bottom sheet to choose image source
//   void _showImageSourceSheet() {
//     showModalBottomSheet(
//       context: context,
//       builder: (_) {
//         return SafeArea(
//           child: Wrap(
//             children: [
//               ListTile(
//                 leading: const Icon(Icons.photo),
//                 title: const Text("Pick from Gallery"),
//                 onTap: () {
//                   Navigator.pop(context);
//                   _pickImages();
//                 },
//               ),
//               ListTile(
//                 leading: const Icon(Icons.camera_alt),
//                 title: const Text("Take a Photo"),
//                 onTap: () {
//                   Navigator.pop(context);
//                   _pickFromCamera();
//                 },
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   // Section title helper
//   Widget _buildSectionTitle(String title) {
//     return Padding(
//       padding: const EdgeInsets.only(top: 24, bottom: 8),
//       child: Text(title,
//           style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
//     );
//   }

//   // Input field helper
//   Widget _buildInputField({required TextEditingController controller, required String hint, int maxLines = 1, IconData? prefixIcon}) {
//     return TextField(
//       controller: controller,
//       maxLines: maxLines,
//       decoration: InputDecoration(
//         hintText: hint,
//         hintStyle: TextStyle(color: Colors.grey.shade400),
//         filled: true,
//         fillColor: Colors.grey.shade100,
//         contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//         prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.grey) : null,
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
//       ),
//     );
//   }

//   // Open MapSelectPage to pick location
//   Future<void> _chooseLocation() async {
//     final result = await Navigator.push(
//       context,
//       MaterialPageRoute(builder: (_) => const MapSelectPage()),
//     );

//     if (result != null) {
//       setState(() {
//         _selectedLatLng = LatLng(result["lat"], result["lng"]);
//         _locationText = result["placeName"];
//         _locationController.text = result["placeName"];
//       });
//     }
//   }

//   // Helper: Force convert any image file to REAL JPEG bytes and save as .jpg
//   Future<File> _forceConvertToJpg(File file) async {
//     try {
//       final bytes = await file.readAsBytes();
//       final decoded = img.decodeImage(bytes);

//       if (decoded == null) {
//         debugPrint("Image decode failed for ${file.path}, using original file.");
//         return file;
//       }

//       final jpgBytes = img.encodeJpg(decoded, quality: 85);
//       final newPath = file.path.replaceAll(RegExp(r'\.\w+$'), '.jpg');

//       final jpgFile = File(newPath);
//       await jpgFile.writeAsBytes(jpgBytes, flush: true);
//       debugPrint("Converted ${file.path} -> $newPath");
//       return jpgFile;
//     } catch (e) {
//       debugPrint("Error converting image to JPG: $e");
//       return file;
//     }
//   }

//   // Update post
//   void _updatePost() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final accessToken = prefs.getString('accessToken');

//       final uri = Uri.parse("https://vetau.onrender.com/api/v1/posts/${widget.postId}");

//       final request = http.MultipartRequest("PATCH", uri);

//       // Add text fields
//       request.fields['type'] = _selectedPostType == PostType.lost ? "lost" : "found";
//       request.fields['itemName'] = _headingController.text.trim();
//       request.fields['category'] = "others"; // TEMP
//       request.fields['rewardAmount'] = _rewardController.text.trim();
//       request.fields['description'] = _descriptionController.text.trim();
//       request.fields['tags'] = _tagsController.text.trim();
//       request.fields['location'] = _locationController.text.trim();
//       request.fields['anonymous'] = _isAnonymous.toString();

//       // Add new images only
//       for (var xfile in _newImages) {
//         try {
//           final originalFile = File(xfile.path);
//           debugPrint("Original image path: ${originalFile.path}");

//           final convertedFile = await _forceConvertToJpg(originalFile);

//           final multipartFile = await http.MultipartFile.fromPath(
//             'images',
//             convertedFile.path,
//             contentType: MediaType('image', 'jpeg'),
//           );

//           request.files.add(multipartFile);
//           debugPrint("Added multipart file: ${convertedFile.path}");
//         } catch (e) {
//           debugPrint("Failed to add image ${xfile.path}: $e");
//         }
//       }

//       // ADD HEADERS
//       request.headers.addAll({
//         'Authorization': 'Bearer $accessToken',
//         'Accept': 'application/json',
//       });

//       print("Sending update API request...");

//       final streamedResponse = await request.send();
//       final response = await http.Response.fromStream(streamedResponse);

//       print("Response Status: ${response.statusCode}");
//       print("Response Body: ${response.body}");

//       if (response.statusCode == 200 || response.statusCode == 201) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Post updated successfully")),
//         );
//         Navigator.pop(context, true);
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Failed to update post")),
//         );
//       }
//     } catch (e) {
//       debugPrint("Request error: $e");
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Failed to update post")),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_isLoading) {
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }

//     return WillPopScope(
//       onWillPop: () async {
//         Navigator.pop(context);
//         return false;
//       },
//       child: Scaffold(
//         backgroundColor: Colors.white,
//         appBar: AppBar(
//           backgroundColor: Colors.white,
//           elevation: 0,
//           leading: IconButton(
//             icon: const Icon(Icons.arrow_back, color: Colors.black),
//             onPressed: () => Navigator.pop(context),
//           ),
//           title: const Text('Edit Post', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
//           centerTitle: false,
//           actions: [
//             Padding(
//               padding: const EdgeInsets.only(right: 8),
//               child: TextButton(
//                 onPressed: _updatePost,
//                 child: const Text('Update', style: TextStyle(color: Colors.blue, fontSize: 18, fontWeight: FontWeight.bold)),
//               ),
//             ),
//           ],
//         ),
//         body: SingleChildScrollView(
//           padding: const EdgeInsets.all(16),
//           child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//             Row(
//               children: [
//                 Expanded(
//                   child: PostTypeButton(
//                     text: 'Lost',
//                     type: PostType.lost,
//                     selectedType: _selectedPostType,
//                     onTap: () => setState(() => _selectedPostType = PostType.lost),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: PostTypeButton(
//                     text: 'Found',
//                     type: PostType.found,
//                     selectedType: _selectedPostType,
//                     onTap: () => setState(() => _selectedPostType = PostType.found),
//                   ),
//                 ),
//               ],
//             ),

//             _buildSectionTitle('Post Heading'),
//             _buildInputField(controller: _headingController, hint: 'e.g., Cat Lost near Lake Street'),

//             _buildSectionTitle('Post Description'),
//             _buildInputField(controller: _descriptionController, hint: 'Share details about your lost/found item...', maxLines: 5),

//             _buildSectionTitle('Existing Images'),
//             if (_existingImageUrls.isNotEmpty)
//               SizedBox(
//                 height: 100,
//                 child: ListView.separated(
//                   scrollDirection: Axis.horizontal,
//                   itemCount: _existingImageUrls.length,
//                   separatorBuilder: (_, __) => const SizedBox(width: 10),
//                   itemBuilder: (_, i) => Stack(
//                     children: [
//                       ClipRRect(
//                         borderRadius: BorderRadius.circular(8),
//                         child: Image.network(
//                           _existingImageUrls[i],
//                           width: 100,
//                           height: 100,
//                           fit: BoxFit.cover,
//                           errorBuilder: (_, __, ___) => Container(
//                             width: 100,
//                             height: 100,
//                             color: Colors.grey.shade300,
//                             child: const Icon(Icons.image_not_supported),
//                           ),
//                         ),
//                       ),
//                       Positioned(
//                         right: 0,
//                         top: 0,
//                         child: GestureDetector(
//                           onTap: () => setState(() => _existingImageUrls.removeAt(i)),
//                           child: Container(
//                             padding: const EdgeInsets.all(4),
//                             decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
//                             child: const Icon(Icons.close, color: Colors.white, size: 16),
//                           ),
//                         ),
//                       )
//                     ],
//                   ),
//                 ),
//               )
//             else
//               const Text('No existing images', style: TextStyle(color: Colors.grey)),

//             _buildSectionTitle('Upload New Images'),
//             GestureDetector(
//               onTap: _showImageSourceSheet,
//               child: Container(
//                 height: 120,
//                 width: double.infinity,
//                 decoration: BoxDecoration(
//                   color: Colors.grey.shade50,
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(color: Colors.grey.shade300, width: 2),
//                 ),
//                 child: const Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(Icons.cloud_upload_outlined, color: Colors.grey, size: 30),
//                     Text('Tap to upload new images', style: TextStyle(color: Colors.grey)),
//                     Text('Max 5MB', style: TextStyle(color: Colors.grey, fontSize: 12)),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 12),
//             if (_newImages.isNotEmpty)
//               SizedBox(
//                 height: 100,
//                 child: ListView.separated(
//                   scrollDirection: Axis.horizontal,
//                   itemCount: _newImages.length,
//                   separatorBuilder: (_, __) => const SizedBox(width: 10),
//                   itemBuilder: (_, i) => Stack(
//                     children: [
//                       ClipRRect(
//                         borderRadius: BorderRadius.circular(8),
//                         child: Image.file(_newImages[i].path as File, width: 100, height: 100, fit: BoxFit.cover),
//                       ),
//                       Positioned(
//                         right: 0,
//                         top: 0,
//                         child: GestureDetector(
//                           onTap: () => setState(() => _newImages.removeAt(i)),
//                           child: Container(
//                             padding: const EdgeInsets.all(4),
//                             decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
//                             child: const Icon(Icons.close, color: Colors.white, size: 16),
//                           ),
//                         ),
//                       )
//                     ],
//                   ),
//                 ),
//               ),

//             _buildSectionTitle('Location'),
//             _buildInputField(controller: _locationController, hint: 'Select location on map'),
//             const SizedBox(height: 12),
//             SizedBox(
//               width: double.infinity,
//               child: OutlinedButton.icon(
//                 onPressed: _chooseLocation,
//                 icon: const Icon(Icons.location_on_outlined, size: 20),
//                 label: const Text('Choose on Map'),
//                 style: OutlinedButton.styleFrom(
//                   padding: const EdgeInsets.symmetric(vertical: 14),
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                   side: BorderSide(color: Colors.blue.shade700),
//                   foregroundColor: Colors.blue.shade700,
//                 ),
//               ),
//             ),
//             const Padding(
//               padding: EdgeInsets.only(top: 8),
//               child: Text('Pinpoint the exact location for better visibility.',
//                   style: TextStyle(color: Colors.grey, fontSize: 12)),
//             ),

//             _buildSectionTitle('Tags'),
//             _buildInputField(controller: _tagsController, hint: 'e.g., #petrescue, #lostcat, #dogwalker'),
//             const Padding(
//               padding: EdgeInsets.only(top: 8),
//               child: Text('Add relevant tags to help others find your post.',
//                   style: TextStyle(color: Colors.grey, fontSize: 12)),
//             ),

//             _buildSectionTitle('Reward to Finder'),
//             _buildInputField(controller: _rewardController, hint: 'e.g., 500', prefixIcon: Icons.currency_rupee),

//             _buildSectionTitle('Post Anonymously'),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const Text('Post Anonymously', style: TextStyle(fontSize: 16, color: Colors.black54)),
//                 Switch(
//                   value: _isAnonymous,
//                   onChanged: (value) => setState(() => _isAnonymous = value),
//                   activeColor: Colors.blue,
//                 ),
//               ],
//             ),

//             const SizedBox(height: 30),
//           ]),
//         ),
//         bottomNavigationBar: const BottomNav(currentIndex: 2),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _headingController.dispose();
//     _descriptionController.dispose();
//     _tagsController.dispose();
//     _rewardController.dispose();
//     _locationController.dispose();
//     super.dispose();
//   }
// }

import 'package:flutter/material.dart';

class Editpost extends StatefulWidget {
  const Editpost({super.key});

  @override
  State<Editpost> createState() => _EditpostState();
}

class _EditpostState extends State<Editpost> {
  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}