import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class DetailHome extends StatefulWidget {
  const DetailHome({super.key});

  @override
  State<DetailHome> createState() => _DetailHomeState();
}

class _DetailHomeState extends State<DetailHome> {
  Map<String, dynamic>? postData;
  Map<String, dynamic>? commentData;
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final postResponse = await http.get(
        Uri.parse('https://dummyjson.com/c/5fbb-eeeb-499a-bdcb'),        
      );
      final commentResponse = await http.get(
        Uri.parse('https://dummyjson.com/c/2e0b-a391-4bae-971a'),
      );

      if (postResponse.statusCode == 200 && commentResponse.statusCode == 200) {
        print('Post Response: ${postResponse.body}');
        print('Comment Response: ${commentResponse.body}');
        
        setState(() {
          postData = json.decode(postResponse.body);
          commentData = json.decode(commentResponse.body);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post Details')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Something went wrong'),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: fetchData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// --- POST DETAILS ---
                      if (postData != null) ...[
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundImage: NetworkImage(
                                  postData!['author']['avatar'] ?? ''),
                              radius: 24,
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  postData!['author']['name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(postData!['postedAgo']),
                              ],
                            ),
                            const Spacer(),
                            if (postData!['reward'] != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Color(0xFFFD8B02),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  "₹${postData!['reward']}",
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Chip(
                              label: Text(postData!['status'], style: TextStyle(color: Colors.white),), 
                              backgroundColor: Color.fromARGB(255, 225, 61, 61),

                            ),
                            const SizedBox(width: 8),
                            Chip(label: Text(postData!['location'])),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          postData!['title'],
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(postData!['description']),
                        const SizedBox(height: 12),
                        if (postData!['images'] != null &&
                            postData!['images'].isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(postData!['images'][0]),
                          ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("❤️ ${postData!['stats']['likes']}"),
                            Text("💬 ${postData!['stats']['comments']}"),
                            Text("🔗 ${postData!['stats']['shares']}"),
                          ],
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.pets),
                          label: const Text('Claim as found'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            backgroundColor: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                      ],

                      /// --- COMMENTS SECTION ---
                      if (commentData != null) ...[
                        Text(
                          "Comments (${commentData!['comments'].length})",
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        for (var c in commentData!['comments']) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundImage: NetworkImage(
                                          c['author']['avatar'] ?? ''),
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          c['author']['name'],
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text(c['postedAgo']),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(c['text']),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text("❤️ ${c['likes']}"),
                                    const SizedBox(width: 16),
                                    const Text("Reply",
                                        style: TextStyle(color: Colors.blue)),
                                  ],
                                ),
                                if (c['replies'] != null &&
                                    c['replies'].isNotEmpty)
                                  Container(
                                    margin: const EdgeInsets.only(
                                        left: 40, top: 8),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        for (var r in c['replies']) ...[
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                backgroundImage: NetworkImage(
                                                    r['author']['avatar'] ?? ''),
                                                radius: 14,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                r['author']['name'],
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(r['postedAgo']),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(r['text']),
                                          const SizedBox(height: 6),
                                        ]
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ]
                    ],
                  ),
                ),
    );
  }
}
