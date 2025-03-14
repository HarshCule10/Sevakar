import 'package:flutter/material.dart';
import 'package:fchecker/screens/profilescreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GovtSchemeScreen extends StatefulWidget {
  const GovtSchemeScreen({Key? key}) : super(key: key);

  @override
  _GovtSchemeScreenState createState() => _GovtSchemeScreenState();
}

class _GovtSchemeScreenState extends State<GovtSchemeScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  bool _hasCompletedProfile = false;
  bool _isLoadingRecommendations = false;
  Map<String, dynamic>? _userProfileData;
  List<Map<String, dynamic>> _recommendedSchemes = [];
  List<Map<String, dynamic>> _filteredSchemes = [];
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  late TabController _tabController;

  // API key for Gemini
  final String _apiKey =
      'AIzaSyBDpgJ2C4bV1DOgX3yTwixnpxv4zjizdNM'; // Use your API key

  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _filteredSchemes = List.from(_schemes);
    _checkProfileStatus();

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          if (_tabController.index == 1) {
            // Recommended tab
            _filteredSchemes = List.from(_recommendedSchemes);
          } else {
            // All schemes tab
            _filteredSchemes = List.from(_schemes);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkProfileStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(currentUser.uid).get();

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final bool hasCompletedProfile =
              userData['hasCompletedProfile'] ?? false;

          setState(() {
            _hasCompletedProfile = hasCompletedProfile;
            _userProfileData = userData;
            _isLoading = false;
          });

          if (hasCompletedProfile && _recommendedSchemes.isEmpty) {
            _fetchPersonalizedRecommendations();
          }
        }
      }
    } catch (e) {
      print('Error checking profile status: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchPersonalizedRecommendations() async {
    if (_userProfileData == null) return;

    setState(() {
      _isLoadingRecommendations = true;
    });

    try {
      // Extract relevant user data for the prompt
      final additionalDetails =
          _userProfileData!['additionalDetails'] as Map<String, dynamic>?;

      if (additionalDetails == null) {
        throw Exception('Additional details not found in profile');
      }

      // Create a structured profile summary for the prompt
      final profileSummary = {
        'age': additionalDetails['age'],
        'gender': additionalDetails['gender'],
        'caste': additionalDetails['caste'],
        'maritalStatus': additionalDetails['maritalStatus'],
        'state': additionalDetails['state'],
        'residenceArea': additionalDetails['residenceArea'],
        'occupation': additionalDetails['occupation'],
        'education': additionalDetails['education'],
        'annualIncome': additionalDetails['annualIncome'],
        'familyMembers': additionalDetails['familyMembers'],
        'employmentStatus': additionalDetails['employmentStatus'],
      };

      // Print profile data for debugging
      print('Profile Summary: $profileSummary');

      // Call Gemini API to get personalized recommendations
      final recommendations = await _getRecommendationsFromGemini(
        profileSummary,
      );

      setState(() {
        _recommendedSchemes = recommendations;
        _isLoadingRecommendations = false;
      });
    } catch (e) {
      print('Error fetching recommendations: $e');
      setState(() {
        _isLoadingRecommendations = false;
        _recommendedSchemes = []; // Clear recommendations on error
      });
    }
  }

  Future<List<Map<String, dynamic>>> _getRecommendationsFromGemini(
    Map<String, dynamic> profileData,
  ) async {
    try {
      // Update to use the latest gemini-2.0-flash model
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$_apiKey',
      );

      // Format the profile data for the prompt
      final formattedProfile = profileData.entries
          .map((e) => '${e.key}: ${e.value.toString()}')
          .join('\n');

      // Prepare the prompt for scheme recommendations
      final prompt = '''
Based on the following user profile, recommend 5 Indian government schemes that this person might be eligible for. 
For each scheme, provide the name, a brief description, eligibility criteria, benefits, and relevant keywords for searching.

User Profile:
$formattedProfile

Format your response as a JSON array with the following structure for each scheme:
[
  {
    "title": "Scheme Name",
    "description": "Brief description of the scheme",
    "eligibility": "Who is eligible for this scheme",
    "benefits": "What benefits the scheme provides",
    "category": "Category of the scheme (e.g., Agriculture, Healthcare, Education)",
    "keywords": ["keyword1", "keyword2", "keyword3"]
  },
  ...
]

Provide only the JSON response without any additional text.
''';

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt},
              ],
            },
          ],
          "generationConfig": {
            "temperature": 0.2,
            "topK": 32,
            "topP": 0.95,
            "maxOutputTokens": 1024,
          },
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Extract text from the Gemini response
        final generatedContent =
            responseData['candidates'][0]['content']['parts'][0]['text'];

        // Parse the JSON string from the response
        try {
          // Find the JSON array in the response
          final jsonStartIndex = generatedContent.indexOf('[');
          final jsonEndIndex = generatedContent.lastIndexOf(']') + 1;

          if (jsonStartIndex >= 0 && jsonEndIndex > jsonStartIndex) {
            final jsonString = generatedContent.substring(
              jsonStartIndex,
              jsonEndIndex,
            );

            final List<dynamic> schemesData = jsonDecode(jsonString);

            // Convert to the expected format
            return schemesData.map((scheme) {
              // Add an icon based on the category
              IconData icon = Icons.policy;

              switch (scheme['category'].toString().toLowerCase()) {
                case 'agriculture':
                  icon = Icons.agriculture;
                  break;
                case 'healthcare':
                  icon = Icons.health_and_safety;
                  break;
                case 'education':
                  icon = Icons.school;
                  break;
                case 'housing':
                  icon = Icons.home;
                  break;
                case 'employment':
                  icon = Icons.work;
                  break;
                case 'financial':
                  icon = Icons.account_balance;
                  break;
                case 'women':
                  icon = Icons.female;
                  break;
                case 'children':
                  icon = Icons.child_care;
                  break;
                case 'elderly':
                  icon = Icons.elderly;
                  break;
                case 'disability':
                  icon = Icons.accessible;
                  break;
                default:
                  icon = Icons.policy;
              }

              return {
                'title': scheme['title'],
                'description': scheme['description'],
                'eligibility': scheme['eligibility'],
                'benefits':
                    scheme['benefits'] ?? 'Benefits as per scheme guidelines',
                'category': scheme['category'],
                'keywords': scheme['keywords'] ?? [],
                'icon': icon,
                'isRecommended': true,
              };
            }).toList();
          } else {
            throw Exception('No valid JSON found in response');
          }
        } catch (e) {
          print('Error parsing Gemini response: $e');
          return [];
        }
      } else {
        throw Exception(
          'API request failed with status: ${response.statusCode}, message: ${response.body}',
        );
      }
    } catch (e) {
      print('Error in Gemini API call: $e');
      return [];
    }
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfilePage()),
    ).then((_) {
      // Refresh profile status when returning from profile page
      _checkProfileStatus();
    });
  }

  void _filterSchemes(String query) {
    setState(() {
      if (query.isEmpty) {
        // Show schemes based on current tab
        if (_tabController.index == 1) {
          _filteredSchemes = List.from(_recommendedSchemes);
        } else {
          _filteredSchemes = List.from(_schemes);
        }
      } else {
        // Search in schemes based on current tab
        final sourceSchemesToSearch =
            _tabController.index == 1 ? _recommendedSchemes : _schemes;

        _filteredSchemes =
            sourceSchemesToSearch
                .where(
                  (scheme) =>
                      scheme['title'].toString().toLowerCase().contains(
                        query.toLowerCase(),
                      ) ||
                      scheme['description'].toString().toLowerCase().contains(
                        query.toLowerCase(),
                      ) ||
                      scheme['category'].toString().toLowerCase().contains(
                        query.toLowerCase(),
                      ) ||
                      (scheme.containsKey('keywords') &&
                          (scheme['keywords'] as List<dynamic>).any(
                            (keyword) => keyword
                                .toString()
                                .toLowerCase()
                                .contains(query.toLowerCase()),
                          )),
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
        bottom:
            _hasCompletedProfile
                ? TabBar(
                  controller: _tabController,
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.black,
                  tabs: const [
                    Tab(text: 'All Schemes'),
                    Tab(text: 'Recommended'),
                  ],
                )
                : null,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: _navigateToProfile,
              child: const CircleAvatar(
                backgroundColor: Colors.black,
                radius: 18,
                child: Icon(Icons.person, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : !_hasCompletedProfile
              ? _buildProfilePrompt()
              : RefreshIndicator(
                key: _refreshIndicatorKey,
                onRefresh: _fetchPersonalizedRecommendations,
                child: Column(
                  children: [
                    Container(
                      color: Colors.white,
                      child: Column(
                        children: [
                          _buildSearchBar(),
                          _buildCategoryFilters(),
                          if (_isLoadingRecommendations)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12.0,
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.black,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Finding schemes for you...',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 12.0),
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
          hintStyle: TextStyle(color: Colors.grey[500]),
        ),
        style: const TextStyle(fontSize: 16),
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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SizedBox(
        height: 40,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: FilterChip(
                label: Text(
                  categories[index],
                  style: const TextStyle(fontSize: 13),
                ),
                selected: false,
                onSelected: (selected) {
                  setState(() {
                    if (categories[index] == 'All') {
                      // Show schemes based on current tab
                      if (_tabController.index == 1) {
                        _filteredSchemes = List.from(_recommendedSchemes);
                      } else {
                        _filteredSchemes = List.from(_schemes);
                      }
                    } else {
                      // Filter schemes based on current tab
                      final sourceSchemesToFilter =
                          _tabController.index == 1
                              ? _recommendedSchemes
                              : _schemes;
                      _filteredSchemes =
                          sourceSchemesToFilter
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
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSchemesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _filteredSchemes.length,
      itemBuilder: (context, index) {
        final scheme = _filteredSchemes[index];
        final bool isRecommended = scheme['isRecommended'] == true;

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
                          color:
                              isRecommended
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.black.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Icon(
                          scheme['icon'],
                          color: isRecommended ? Colors.green : Colors.black,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    scheme['title'],
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (isRecommended)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                      vertical: 4.0,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12.0),
                                      border: Border.all(
                                        color: Colors.green,
                                        width: 1.0,
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                          size: 12,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Recommended',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
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
                  if (scheme.containsKey('keywords') &&
                      (scheme['keywords'] as List).isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children:
                            (scheme['keywords'] as List).map<Widget>((keyword) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6.0,
                                  vertical: 2.0,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(4.0),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Text(
                                  keyword.toString(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
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
    final bool isRecommended = scheme['isRecommended'] == true;
    final List<dynamic> keywords =
        scheme.containsKey('keywords') ? scheme['keywords'] as List : [];

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
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    scheme['title'],
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (isRecommended)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                      vertical: 4.0,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12.0),
                                      border: Border.all(
                                        color: Colors.green,
                                        width: 1.0,
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                          size: 12,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Recommended',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
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
                    'Benefits',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    scheme.containsKey('benefits')
                        ? scheme['benefits']
                        : 'Financial assistance, subsidies, and other benefits as per the scheme guidelines.',
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  if (keywords.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Keywords',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          keywords.map<Widget>((keyword) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12.0,
                                vertical: 6.0,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(20.0),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Text(
                                keyword.toString(),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ],
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

  Widget _buildProfilePrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_outline,
                size: 60,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Complete Your Profile',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'To check your eligibility for government schemes, we need some additional information about you.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _navigateToProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Complete Profile'),
            ),
          ],
        ),
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
}
