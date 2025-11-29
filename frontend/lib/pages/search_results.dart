import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/config/api_constants.dart';
import 'package:frontend/pages/detail_home.dart';
import 'package:frontend/pages/home.dart';
import 'package:frontend/components/searchAppBar.dart';
import 'package:http/http.dart' as http;

class SearchResults extends StatefulWidget {
  final String searchQuery;
  const SearchResults({super.key, required this.searchQuery});

  @override
  State<SearchResults> createState() => _SearchResultsState();
}

class _SearchResultsState extends State<SearchResults> {
  List posts = [];
  bool isLoading = true;
  late TextEditingController _searchController;
  late String currentQuery;

  @override
  void initState() {
    super.initState();
    currentQuery = widget.searchQuery;
    _searchController = TextEditingController(text: currentQuery);
    fetchSearchResults();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchSearchResults() async {
    setState(() => isLoading = true);
    final url = Uri.parse("${ApiConstants.baseUrl}/posts/?search=$currentQuery");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        setState(() {
          posts = parsed["data"]["posts"] ?? [];
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load posts");
      }
    } catch (e) {
      print("Error: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: SearchAppBar(
        controller: _searchController,
        onSubmitted: (value) {
          if (value.trim().isNotEmpty) {
            setState(() {
              currentQuery = value.trim();
            });
            fetchSearchResults();
          }
        },
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Chip(
                          label: const Text('Pro Tip: Color + Item + Location = Best results',
                              style: TextStyle(fontSize: 14)),
                          backgroundColor: Colors.grey.shade100,
                          side: BorderSide.none,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : posts.isEmpty
              ? const Center(child: Text("No results found", style: TextStyle(fontSize: 16)))
              : RefreshIndicator(
                  onRefresh: fetchSearchResults,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      return PostCard(
                        post: posts[index],
                        onTap: () {
                          final postId = posts[index]["postId"] ?? posts[index]["_id"];
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetailHome(postId: postId.toString()),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
          ),
        ],
      ),
    );
  }
}
