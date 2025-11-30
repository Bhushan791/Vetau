import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/components/bottomNav.dart';
import 'package:frontend/components/searchAppBar.dart';
import 'package:frontend/stores/filter_store.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  
  final List<String> recentSearches = [
    'lost dog in central park',
    'kirtipur',
    'Baneshwor',
    'bike lost near Kirtipur',
    'Rajneesh Shakya'
  ];

  void _performSearch(String query) {
    if (query.trim().isNotEmpty) {
      Navigator.pushNamed(
        context,
        '/search_results',
        arguments: query.trim(),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        appBar: SearchAppBar(
          controller: _searchController,
          onSubmitted: (value) {
            _performSearch(value);
          },
        ),
        body: Consumer(
          builder: (context, ref, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                Chip(
                                  label: const Text('Pro Tip: Color + Item + Location = Best results',
                                      style: TextStyle(fontSize: 12)),
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
                  const Text(
                    "Recent",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Column(
                    children: recentSearches.map((search) {
                      return GestureDetector(
                        onTap: () {
                          _performSearch(search);
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.access_time,
                                      color: Colors.grey, size: 18),
                                  const SizedBox(width: 12),
                                  Text(
                                    search,
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    recentSearches.remove(search);
                                  });
                                },
                                child: const Icon(Icons.close,
                                    color: Colors.grey, size: 18),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          },
        ),
        bottomNavigationBar: const BottomNav(currentIndex: 0),
      ),
    );
  }
}
