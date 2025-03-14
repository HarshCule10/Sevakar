import 'package:fchecker/helpers/firebasehelpers.dart';
import 'package:fchecker/screens/analysisscreen.dart';
import 'package:fchecker/screens/profilescreen.dart';
import 'package:fchecker/widgets/chathistorypanel.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isAnalyzing = false;
  final ScrollController _scrollController = ScrollController();

  // API key
  final String _apiKey = 'AIzaSyBDpgJ2C4bV1DOgX3yTwixnpxv4zjizdNM';

  Future<Map<String, dynamic>> _analyzeWithGemini(String claim) async {
    try {
      // Update to use the latest gemini-2.0-flash model
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$_apiKey',
      );

      // Prepare the prompt for fact-checking
      final prompt = '''
    Analyze the following claim for factual accuracy, credibility, and bias. 
    Your response should be in JSON format with the following structure:
    {
      "accuracy": (number between 0-100),
      "credibility": (number between 0-100),
      "bias": (number between 0-100, where lower is less biased),
      "sources": ["source1", "source2", ...],
      "summary": "brief analysis of the claim"
    }
    
    Claim to analyze: "$claim"
    
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
            "maxOutputTokens": 800,
          },
        }),
      );

      // Add detailed debugging information
      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Extract text from the Gemini response
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
            final factCheckData = jsonDecode(jsonString);

            // Ensure all required fields are present
            return {
              'accuracy': factCheckData['accuracy'] ?? 50,
              'credibility': factCheckData['credibility'] ?? 50,
              'bias': factCheckData['bias'] ?? 50,
              'sources': factCheckData['sources'] ?? ['No sources provided'],
              'summary': factCheckData['summary'] ?? 'No summary provided',
            };
          } else {
            throw Exception('No valid JSON found in response');
          }
        } catch (e) {
          // Fallback if JSON parsing fails
          return {
            'accuracy': 50,
            'credibility': 50,
            'bias': 50,
            'sources': ['Unable to retrieve sources'],
            'summary':
                'Unable to parse the response from the AI model. The claim may be too complex or ambiguous.',
          };
        }
      } else {
        throw Exception(
          'API request failed with status: ${response.statusCode}, message: ${response.body}',
        );
      }
    } catch (e) {
      print('Error in API call: $e');
      return {
        'accuracy': 50,
        'credibility': 50,
        'bias': 50,
        'sources': ['Error retrieving sources'],
        'summary':
            'An error occurred while analyzing this claim. Please try again later.',
      };
    }
  }

  void _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;

    _messageController.clear();

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isAnalyzing = true;
    });

    // Scroll to the bottom after adding a new message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });

    try {
      // Call the Gemini API for fact checking
      final factCheckResult = await _analyzeWithGemini(text);

      setState(() {
        _messages.add(
          ChatMessage(
            text: 'Fact Check Analysis:',
            isUser: false,
            factCheckData: factCheckResult,
          ),
        );
        _isAnalyzing = false;
      });

      // Save fact check to Firebase with better error handling
      try {
        print('Attempting to save fact check to Firebase: $text');
        await FirebaseHelper.saveFactCheck(text, factCheckResult);
        print('Successfully saved fact check to Firebase');
      } catch (saveError) {
        print('Error saving fact check to Firebase: $saveError');
        // Show a snackbar to inform the user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Note: Unable to save this fact check to history.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Error in _handleSubmitted: $e');
      setState(() {
        _messages.add(
          ChatMessage(
            text:
                'Sorry, I encountered an error while analyzing your claim. Please try again.',
            isUser: false,
          ),
        );
        _isAnalyzing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _messages.isEmpty ? _buildEmptyState() : _buildChatList(),
            ),
            const Divider(height: 1.0, color: Colors.black12),
            _buildAnalyzingIndicator(),
            _buildMessageComposer(),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text(
        'Sevakar',
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      ),
      backgroundColor: Colors.white,
      elevation: 1,
      automaticallyImplyLeading: false,
      iconTheme: const IconThemeData(color: Colors.black),
      actions: [
        // History button
        IconButton(
          icon: const Icon(Icons.history, color: Colors.black),
          tooltip: 'Fact Check History',
          onPressed: () {
            _showFactCheckHistoryDialog();
          },
        ),
        // New Chat button
        IconButton(
          icon: const Icon(Icons.add_comment, color: Colors.black),
          tooltip: 'New Chat',
          onPressed: () {
            // Show confirmation dialog
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Start New Chat'),
                  content: const Text(
                    'This will clear the current conversation. Continue?',
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  actions: [
                    TextButton(
                      child: const Text('Cancel'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    TextButton(
                      child: const Text('Clear Chat'),
                      onPressed: () {
                        // Clear the messages list
                        setState(() {
                          _messages.clear();
                        });
                        _messageController.clear();
                        Navigator.of(context).pop();

                        // Show a confirmation snackbar
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Chat cleared!'),
                            duration: Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            );
          },
        ),
        // Profile button
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: GestureDetector(
            onTap: () {
              // Profile screen navigation would go here
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
    );
  }

  void _showFactCheckHistoryDialog() {
    print('Opening fact check history dialog');

    // First check if the user is logged in
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      print('Cannot show history: No user is logged in');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You need to be logged in to view history'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print('User is logged in: ${currentUser.uid}');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        print('Building fact check history dialog');
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: FactCheckHistoryPanel(
            onHistoryItemSelected: (claim, factCheckResult) {
              print('History item selected: $claim');
              setState(() {
                _messages.add(ChatMessage(text: claim, isUser: true));

                _messages.add(
                  ChatMessage(
                    text: 'Fact Check Analysis:',
                    isUser: false,
                    factCheckData: factCheckResult,
                  ),
                );
              });
            },
          ),
        );
      },
    );
  }

  // Method to show chat history dialog

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.fact_check,
              size: 80,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Fact Check Assistant',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'Enter a claim or statement to verify its accuracy, credibility, and potential bias.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      reverse: true,
      itemCount: _messages.length,
      itemBuilder: (_, int index) => _messages[_messages.length - 1 - index],
    );
  }

  Widget _buildAnalyzingIndicator() {
    return _isAnalyzing
        ? Container(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Analyzing facts...',
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        )
        : Container();
  }

  Widget _buildMessageComposer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -1),
            blurRadius: 3,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(24.0),
                border: Border.all(color: Colors.black12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: _messageController,
                  maxLines: null,
                  decoration: const InputDecoration(
                    hintText: 'Enter a claim to fact check...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.black54),
                    contentPadding: EdgeInsets.symmetric(vertical: 12.0),
                  ),
                  style: const TextStyle(color: Colors.black),
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          Container(
            height: 45.0,
            width: 45.0,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(22.5),
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed:
                  _isAnalyzing
                      ? null
                      : () => _handleSubmitted(_messageController.text),
            ),
          ),
        ],
      ),
    );
  }
}

// Modify the ChatMessage class to make the fact check data clickable
class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;
  final Map<String, dynamic>? factCheckData;

  const ChatMessage({
    Key? key,
    required this.text,
    required this.isUser,
    this.factCheckData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) _buildAIAvatar(),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  decoration: BoxDecoration(
                    color: isUser ? Colors.black : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    text,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (factCheckData != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: _buildFactCheckResultsCard(context),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (isUser) _buildUserAvatar(),
        ],
      ),
    );
  }

  Widget _buildUserAvatar() {
    return const CircleAvatar(
      backgroundColor: Colors.black,
      radius: 16,
      child: Icon(Icons.person, color: Colors.white, size: 18),
    );
  }

  Widget _buildAIAvatar() {
    return const CircleAvatar(
      backgroundColor: Colors.black,
      radius: 16,
      child: Icon(Icons.assistant, color: Colors.white, size: 18),
    );
  }

  Widget _buildFactCheckResultsCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to the detailed fact check screen when tapped
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => FactCheckDetailsScreen(
                  factCheckData: factCheckData!,
                  originalClaim: isUser ? text : "Analyzed claim",
                ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(top: 6.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Fact Check Results',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.touch_app, color: Colors.blue, size: 14),
                      SizedBox(width: 4.0),
                      Text(
                        'View Details',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildFactMeter('Accuracy', factCheckData!['accuracy']),
            _buildFactMeter('Credibility', factCheckData!['credibility']),
            _buildFactMeter('Bias Level', factCheckData!['bias']),
          ],
        ),
      ),
    );
  }

  Widget _buildFactMeter(String label, int value) {
    Color meterColor;
    String assessment;

    if (label == 'Bias Level') {
      if (value < 30) {
        meterColor = Colors.green;
        assessment = 'Low';
      } else if (value < 70) {
        meterColor = Colors.orange;
        assessment = 'Medium';
      } else {
        meterColor = Colors.red;
        assessment = 'High';
      }
    } else {
      if (value > 70) {
        meterColor = Colors.green;
        assessment = 'High';
      } else if (value > 40) {
        meterColor = Colors.orange;
        assessment = 'Medium';
      } else {
        meterColor = Colors.red;
        assessment = 'Low';
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              Row(
                children: [
                  Text(
                    assessment,
                    style: TextStyle(
                      fontSize: 13,
                      color: meterColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$value%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: meterColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.0),
            child: LinearProgressIndicator(
              value: value / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(meterColor),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}
