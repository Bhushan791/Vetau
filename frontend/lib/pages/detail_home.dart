import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/stores/like_store.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class DetailHome extends ConsumerStatefulWidget {
  const DetailHome({super.key});

  @override
  ConsumerState<DetailHome> createState() => _DetailHomeState();
}

class _DetailHomeState extends ConsumerState<DetailHome> {
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
    final likeState = ref.watch(likesProvider);

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
                      // -------- POST SECTION --------
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
                                  color: const Color(0xFFFD8B02),
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
                              label: const Text("LOST",
                                  style: TextStyle(color: Colors.white)),
                              backgroundColor:
                                  const Color.fromARGB(255, 225, 61, 61),
                            ),
                            const SizedBox(width: 8),
                            Chip(label: Text(postData!['location'] ?? '')),
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

                        // -------- POST ACTION BUTTONS (comment, share, save) --------
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.mode_comment_outlined),
                              onPressed: () {},
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.share_outlined),
                              onPressed: () {},
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.bookmark_border),
                              onPressed: () {},
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () {
                            // Your action here
                          },
                          icon: const Icon(
                            Icons.chat_outlined,
                            color: Colors.white,
                            size: 24,
                          ),
                          label: const Text(
                            'Claim as found',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                        ),

                        const SizedBox(height: 24),
                        const Divider(),
                      ],

                      // -------- COMMENTS SECTION --------
                      if (commentData != null) ...[
                        Text(
                          "Comments (${commentData!['comments'].length})",
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        for (int index = 0;
                            index < commentData!['comments'].length;
                            index++) ...[
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
                                          commentData!['comments'][index]
                                                  ['author']['avatar'] ??
                                              ''),
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          commentData!['comments'][index]
                                              ['author']['name'],
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          commentData!['comments'][index]
                                              ['postedAgo'],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  commentData!['comments'][index]['text'],
                                ),
                                const SizedBox(height: 8),

                                // -------- LIKE & REPLY for comments --------
                                Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        likeState.likedComments
                                                .contains(index.toString())
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        size: 20,
                                        color: likeState.likedComments
                                                .contains(index.toString())
                                            ? Colors.red
                                            : Colors.grey,
                                      ),
                                      onPressed: () {
                                        ref
                                            .read(likesProvider.notifier)
                                            .toggleLike(
                                              index.toString(),
                                              commentData!['comments'][index]
                                                  ['likes'],
                                            );
                                      },
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "${likeState.likeCounts[index.toString()] ?? commentData!['comments'][index]['likes']}",
                                    ),
                                    const SizedBox(width: 16),
                                    TextButton(
                                      onPressed: () {},
                                      child: const Text(
                                        "Reply",
                                        style: TextStyle(color: Colors.blue),
                                      ),
                                    ),
                                  ],
                                ),

                                // -------- REPLIES --------
                                if (commentData!['comments'][index]['replies'] !=
                                        null &&
                                    commentData!['comments'][index]['replies']
                                        .isNotEmpty)
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
                                        for (var r in commentData!['comments']
                                            [index]['replies']) ...[
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