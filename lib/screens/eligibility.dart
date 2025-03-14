import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SchemeElgibility extends StatefulWidget {
  const SchemeElgibility({super.key, required this.schemeData});
  final Map<String, dynamic> schemeData;

  @override
  State<SchemeElgibility> createState() => _SchemeElgibilityState();
}

class _SchemeElgibilityState extends State<SchemeElgibility>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isLoading = true;
  Map<String, dynamic>? _userProfileData;
  List<Map<String, dynamic>> _eligibilityCriteria = [];
  double _eligibilityScore = 0.0;
  String _geminiAnalysis = '';
  List<String> _requiredDocuments = [];

  // API key
  final String _apiKey = 'AIzaSyBDpgJ2C4bV1DOgX3yTwixnpxv4zjizdNM';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _fetchUserProfile();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();
        if (doc.exists) {
          print(doc.data());
          setState(() {
            _userProfileData = doc.data() as Map<String, dynamic>;
          });
          await _analyzeEligibility();
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      print('Error fetching user profile: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _analyzeEligibility() async {
    if (_userProfileData == null) return;

    final additionalDetails =
        _userProfileData!['additionalDetails'] as Map<String, dynamic>? ?? {};

    // Check if profile is incomplete
    if (additionalDetails.isEmpty ||
        additionalDetails.values.every((value) => value == null)) {
      setState(() {
        _eligibilityScore = 0.0;
        _geminiAnalysis = 'Please complete your profile to check eligibility.';
        _eligibilityCriteria = [];
        _requiredDocuments = [];
      });
      return;
    }

    // Create a prompt for Gemini
    final prompt = '''
    Analyze the eligibility of a person for the following government scheme:

    Scheme Details:
    ${widget.schemeData['title']}
    Description: ${widget.schemeData['description']}
    Eligibility Criteria: ${widget.schemeData['eligibility']}

    User Profile:
    Age: ${additionalDetails['age'] ?? 'Not provided'}
    Annual Income: ${additionalDetails['annualIncome'] != null ? '₹${additionalDetails['annualIncome']}' : 'Not provided'}
    Residence Area: ${additionalDetails['residenceArea'] ?? 'Not provided'}
    Occupation: ${additionalDetails['occupation'] ?? 'Not provided'}
    Education: ${additionalDetails['education'] ?? 'Not provided'}
    Marital Status: ${additionalDetails['maritalStatus'] ?? 'Not provided'}
    Caste: ${additionalDetails['caste'] ?? 'Not provided'}

    Please provide:
    1. A detailed analysis of eligibility (in percentage)
    2. List of specific criteria met and not met
    3. Required documents for application
    
    Format the response as JSON with the following structure:
    {
      "eligibilityScore": number,
      "analysis": "string",
      "criteriaList": [{"criteria": "string", "met": boolean, "details": "string"}],
      "requiredDocuments": ["string"]
    }
    ''';

    try {
      // Update to use the latest gemini-pro model
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$_apiKey',
      );

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
            "maxOutputTokens": 800,
          },
        }),
      );

      // Add detailed debugging information
      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final generatedContent =
            responseData['candidates'][0]['content']['parts'][0]['text'];

        // Parse the JSON string from the response
        try {
          // Find the JSON object in the response
          final jsonStartIndex = generatedContent.indexOf('{');
          final jsonEndIndex = generatedContent.lastIndexOf('}') + 1;

          if (jsonStartIndex >= 0 && jsonEndIndex > jsonStartIndex) {
            final jsonString = generatedContent.substring(
              jsonStartIndex,
              jsonEndIndex,
            );
            final analysisData = jsonDecode(jsonString);

            setState(() {
              _eligibilityScore = analysisData['eligibilityScore'] / 100;
              _geminiAnalysis = analysisData['analysis'];
              _eligibilityCriteria = List<Map<String, dynamic>>.from(
                analysisData['criteriaList'].map(
                  (item) => {
                    'criteria': item['criteria'],
                    'met': item['met'] ?? false, // Ensure 'met' is never null
                    'details': item['details'],
                  },
                ),
              );
              _requiredDocuments = List<String>.from(
                analysisData['requiredDocuments'],
              );
            });
          } else {
            throw Exception('No valid JSON found in response');
          }
        } catch (e) {
          print('Error parsing Gemini response: $e');
          _calculateBasicEligibility();
        }
      } else {
        throw Exception(
          'API request failed with status: ${response.statusCode}, message: ${response.body}',
        );
      }
    } catch (e) {
      print('Error analyzing eligibility: $e');
      _calculateBasicEligibility();
    }
  }

  void _calculateBasicEligibility() {
    if (_userProfileData == null) return;

    final additionalDetails =
        _userProfileData!['additionalDetails'] as Map<String, dynamic>? ?? {};
    int matchingCriteria = 0;
    _eligibilityCriteria = [];

    // Example criteria checks - customize based on scheme requirements
    if (additionalDetails['age'] != null) {
      bool ageMatch = int.parse(additionalDetails['age'].toString()) >= 18;
      _eligibilityCriteria.add({
        'criteria': 'Age Requirement (18+)',
        'met': ageMatch,
        'details': 'Your age: ${additionalDetails['age']}',
      });
      if (ageMatch) matchingCriteria++;
    }

    if (additionalDetails['annualIncome'] != null) {
      bool incomeMatch =
          double.parse(additionalDetails['annualIncome'].toString()) <= 500000;
      _eligibilityCriteria.add({
        'criteria': 'Income Limit (≤5L)',
        'met': incomeMatch,
        'details': 'Your income: ₹${additionalDetails['annualIncome']}',
      });
      if (incomeMatch) matchingCriteria++;
    }

    if (additionalDetails['residenceArea'] != null) {
      bool areaMatch =
          additionalDetails['residenceArea'].toString().toLowerCase() ==
          'rural';
      _eligibilityCriteria.add({
        'criteria': 'Rural Residence',
        'met': areaMatch,
        'details': 'Your area: ${additionalDetails['residenceArea']}',
      });
      if (areaMatch) matchingCriteria++;
    }

    setState(() {
      _eligibilityScore =
          _eligibilityCriteria.isEmpty
              ? 0.0
              : matchingCriteria / _eligibilityCriteria.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.schemeData['title'] ?? 'Scheme Details',
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 1,
          foregroundColor: Colors.black,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Colors.grey.shade50],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 5,
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Lottie.network(
                        'https://assets2.lottiefiles.com/packages/lf20_p8bfn5to.json',
                        width: 150,
                        height: 150,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Analyzing your eligibility...',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Please wait while we process your information',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Check if profile is incomplete
    final additionalDetails =
        _userProfileData?['additionalDetails'] as Map<String, dynamic>? ?? {};
    final bool isProfileIncomplete =
        additionalDetails.isEmpty ||
        additionalDetails.values.every((value) => value == null);

    if (isProfileIncomplete) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.schemeData['title'] ?? 'Scheme Details',
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 1,
          foregroundColor: Colors.black,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 24),
                Text(
                  'Complete Your Profile',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Please complete your profile to check eligibility for this scheme.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    // Navigate to profile page
                    Navigator.pushNamed(context, '/profile');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Complete Profile',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.schemeData['title'] ?? 'Scheme Details',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildEligibilityScoreCard(),
              const SizedBox(height: 24),
              if (_geminiAnalysis.isNotEmpty) ...[
                _buildAnalysisCard(),
                const SizedBox(height: 24),
              ],
              _buildEligibilityCriteria(),
              const SizedBox(height: 24),
              _buildRequiredDocuments(),
              const SizedBox(height: 24),
              _buildNextSteps(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed:
                _eligibilityScore > 0.5
                    ? () {
                      // TODO: Implement application process
                    }
                    : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
              disabledBackgroundColor: Colors.grey[300],
            ),
            child: Text(
              _eligibilityScore > 0.5
                  ? 'Start Application Process'
                  : 'Not Eligible',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEligibilityScoreCard() {
    final color =
        _eligibilityScore >= 0.7
            ? Colors.green
            : _eligibilityScore >= 0.4
            ? Colors.orange
            : Colors.red;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              'Your Eligibility Score',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                LinearPercentIndicator(
                  width: MediaQuery.of(context).size.width - 100,
                  animation: true,
                  lineHeight: 25.0,
                  animationDuration: 1500,
                  percent: _eligibilityScore,
                  center: Text(
                    "${(_eligibilityScore * 100).toInt()}%",
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  barRadius: const Radius.circular(16),
                  progressColor: color,
                  backgroundColor: Colors.grey[200],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _eligibilityScore >= 0.7
                  ? 'You are likely eligible!'
                  : _eligibilityScore >= 0.4
                  ? 'You might be eligible'
                  : 'You may not be eligible',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics_outlined, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'AI Analysis',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _geminiAnalysis,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEligibilityCriteria() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.checklist_outlined, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Eligibility Criteria',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _eligibilityCriteria.length,
              separatorBuilder: (context, index) => const Divider(height: 24),
              itemBuilder: (context, index) {
                final criteria = _eligibilityCriteria[index];
                final bool isMet =
                    criteria['met'] as bool? ?? false; // Handle null safely

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:
                            isMet
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isMet ? Icons.check_circle : Icons.cancel,
                        color: isMet ? Colors.green : Colors.red,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            criteria['criteria'] as String? ?? 'Criteria',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            criteria['details'] as String? ??
                                'No details available',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequiredDocuments() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.folder_outlined, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Required Documents',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_requiredDocuments.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'No specific documents required at this time',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _requiredDocuments.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.description_outlined,
                            color: Colors.blue,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _requiredDocuments[index],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextSteps() {
    final steps = [
      {
        'title': 'Gather Required Documents',
        'subtitle': 'Collect all the documents listed above',
        'color': Colors.blue,
        'icon': Icons.folder_copy_outlined,
      },
      {
        'title': 'Visit Nearest Center',
        'subtitle': 'Find your nearest Common Service Center (CSC)',
        'color': Colors.green,
        'icon': Icons.location_on_outlined,
      },
      {
        'title': 'Submit Application',
        'subtitle': 'Complete the application process with assistance',
        'color': Colors.orange,
        'icon': Icons.task_outlined,
      },
    ];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.timeline_outlined, color: Colors.purple),
                const SizedBox(width: 8),
                Text(
                  'Next Steps',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: steps.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final step = steps[index];
                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (step['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            step['icon'] as IconData,
                            color: step['color'] as Color,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: step['color'] as Color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step['title'] as String,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            step['subtitle'] as String,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
