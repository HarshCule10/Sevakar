import 'package:flutter/material.dart';
import 'package:fchecker/screens/profilescreen.dart';

class GovtSchemeScreen extends StatefulWidget {
  const GovtSchemeScreen({Key? key}) : super(key: key);

  @override
  _GovtSchemeScreenState createState() => _GovtSchemeScreenState();
}

class _GovtSchemeScreenState extends State<GovtSchemeScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Sample list of government schemes
  final List<Map<String, dynamic>> _schemes = [
    {
      'title': 'PM Kisan Samman Nidhi',
      'description': 'Income support of ₹6,000 per year for farmer families',
      'eligibility': 'All small and marginal farmers with cultivable land',
      'icon': Icons.agriculture,
      'category': 'Agriculture',
    },
    {
      'title': 'Ayushman Bharat',
      'description': 'Health insurance coverage of ₹5 lakh per family per year',
      'eligibility': 'Poor and vulnerable families as per SECC database',
      'icon': Icons.health_and_safety,
      'category': 'Healthcare',
    },
    {
      'title': 'PM Awas Yojana',
      'description': 'Financial assistance for construction of houses',
      'eligibility':
          'Houseless people and those living in kutcha/dilapidated houses',
      'icon': Icons.home,
      'category': 'Housing',
    },
    {
      'title': 'Sukanya Samriddhi Yojana',
      'description': 'Small savings scheme for girl child with tax benefits',
      'eligibility': 'Parents of girl child below 10 years',
      'icon': Icons.girl,
      'category': 'Education',
    },
    {
      'title': 'PM Ujjwala Yojana',
      'description': 'Free LPG connections to women from BPL households',
      'eligibility': 'Women from BPL households without LPG connection',
      'icon': Icons.local_fire_department,
      'category': 'Energy',
    },
  ];

  List<Map<String, dynamic>> _filteredSchemes = [];

  @override
  void initState() {
    super.initState();
    _filteredSchemes = List.from(_schemes);
  }

  void _filterSchemes(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSchemes = List.from(_schemes);
      } else {
        _filteredSchemes =
            _schemes
                .where(
                  (scheme) =>
                      scheme['title'].toLowerCase().contains(
                        query.toLowerCase(),
                      ) ||
                      scheme['description'].toLowerCase().contains(
                        query.toLowerCase(),
                      ) ||
                      scheme['category'].toLowerCase().contains(
                        query.toLowerCase(),
                      ),
                )
                .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Government Schemes',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
              },
              child: const CircleAvatar(
                backgroundColor: Colors.black,
                radius: 18,
                child: Icon(Icons.person, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            _buildCategoryFilters(),
            Expanded(
              child:
                  _filteredSchemes.isEmpty
                      ? _buildEmptyState()
                      : _buildSchemesList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        onChanged: _filterSchemes,
        decoration: InputDecoration(
          hintText: 'Search for schemes...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 0.0,
            horizontal: 20.0,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    final categories = [
      'All',
      'Agriculture',
      'Healthcare',
      'Education',
      'Housing',
      'Energy',
    ];

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: FilterChip(
              label: Text(categories[index]),
              selected: false,
              onSelected: (selected) {
                setState(() {
                  if (categories[index] == 'All') {
                    _filteredSchemes = List.from(_schemes);
                  } else {
                    _filteredSchemes =
                        _schemes
                            .where(
                              (scheme) =>
                                  scheme['category'] == categories[index],
                            )
                            .toList();
                  }
                });
              },
              backgroundColor: Colors.grey[100],
              selectedColor: Colors.black,
              checkmarkColor: Colors.white,
              labelStyle: const TextStyle(color: Colors.black),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No schemes found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search term',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildSchemesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _filteredSchemes.length,
      itemBuilder: (context, index) {
        final scheme = _filteredSchemes[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: InkWell(
            onTap: () {
              // Navigate to scheme details
              _showSchemeDetails(scheme);
            },
            borderRadius: BorderRadius.circular(12.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Icon(
                          scheme['icon'],
                          color: Colors.black,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              scheme['title'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4.0),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                                vertical: 2.0,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                              child: Text(
                                scheme['category'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    scheme['description'],
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      const Icon(Icons.people, size: 16, color: Colors.grey),
                      const SizedBox(width: 4.0),
                      Expanded(
                        child: Text(
                          'Eligibility: ${scheme['eligibility']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSchemeDetails(Map<String, dynamic> scheme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, controller) {
            return Container(
              padding: const EdgeInsets.all(24.0),
              child: ListView(
                controller: controller,
                children: [
                  Center(
                    child: Container(
                      width: 60,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        child: Icon(
                          scheme['icon'],
                          color: Colors.black,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              scheme['title'],
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                                vertical: 2.0,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                              child: Text(
                                scheme['category'],
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    scheme['description'],
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Eligibility',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    scheme['eligibility'],
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'How to Apply',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Visit the nearest Common Service Center (CSC) or apply online through the official website. You will need to provide identity proof, address proof, and other relevant documents.',
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Benefits',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Financial assistance, subsidies, and other benefits as per the scheme guidelines.',
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      // Action to check eligibility or apply
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Check Eligibility'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
