import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
    final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$_apiKey');
    
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
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {
                "text": prompt
              }
            ]
          }
        ],
        "generationConfig": {
          "temperature": 0.2,
          "topK": 32,
          "topP": 0.95,
          "maxOutputTokens": 800
        }
      }),
    );
    
    // Add detailed debugging information
    print('Response status code: ${response.statusCode}');
    print('Response body: ${response.body}');
    
    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      
      // Extract text from the Gemini response
      final generatedContent = responseData['candidates'][0]['content']['parts'][0]['text'];
      
      // Parse the JSON string from the response
      try {
        // Find the JSON object in the response
        final jsonStartIndex = generatedContent.indexOf('{');
        final jsonEndIndex = generatedContent.lastIndexOf('}') + 1;
        
        if (jsonStartIndex >= 0 && jsonEndIndex > jsonStartIndex) {
          final jsonString = generatedContent.substring(jsonStartIndex, jsonEndIndex);
          final factCheckData = jsonDecode(jsonString);
          
          // Ensure all required fields are present
          return {
            'accuracy': factCheckData['accuracy'] ?? 50,
            'credibility': factCheckData['credibility'] ?? 50,
            'bias': factCheckData['bias'] ?? 50,
            'sources': factCheckData['sources'] ?? ['No sources provided'],
            'summary': factCheckData['summary'] ?? 'No summary provided'
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
          'summary': 'Unable to parse the response from the AI model. The claim may be too complex or ambiguous.'
        };
      }
    } else {
      throw Exception('API request failed with status: ${response.statusCode}, message: ${response.body}');
    }
  } catch (e) {
    print('Error in API call: $e');
    return {
      'accuracy': 50,
      'credibility': 50,
      'bias': 50,
      'sources': ['Error retrieving sources'],
      'summary': 'An error occurred while analyzing this claim. Please try again later.'
    };
  }
}
  void _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;
    
    _messageController.clear();

    setState(() {
      _messages.add(
        ChatMessage(
          text: text,
          isUser: true,
        ),
      );
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
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(
            text: 'Sorry, I encountered an error while analyzing your claim. Please try again.',
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
              child: _messages.isEmpty 
                  ? _buildEmptyState() 
                  : _buildChatList(),
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
        'Fact Check Assistant',
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      ),
      backgroundColor: Colors.white,
      elevation: 1,
      iconTheme: const IconThemeData(color: Colors.black),
      actions: [
        // Search button
        IconButton(
          icon: const Icon(Icons.search, color: Colors.black),
          onPressed: () {
            // Search functionality would go here
          },
        ),
        // Profile button
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: GestureDetector(
            onTap: () {
              // Profile action would go here
            },
            child: const CircleAvatar(
              backgroundColor: Colors.black,
              radius: 18,
              child: Icon(
                Icons.person,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

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
              style: TextStyle(
                fontSize: 15,
                color: Colors.black54,
              ),
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
                Text('Analyzing facts...', style: TextStyle(color: Colors.black54)),
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
              onPressed: _isAnalyzing
                  ? null
                  : () => _handleSubmitted(_messageController.text),
            ),
          ),
        ],
      ),
    );
  }
}

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
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) _buildAIAvatar(),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
                    child: _buildFactCheckResults(context),
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
      child: Icon(
        Icons.person,
        color: Colors.white,
        size: 18,
      ),
    );
  }

  Widget _buildAIAvatar() {
    return const CircleAvatar(
      backgroundColor: Colors.black,
      radius: 16,
      child: Icon(
        Icons.assistant,
        color: Colors.white,
        size: 18,
      ),
    );
  }

  Widget _buildFactCheckResults(BuildContext context) {
    return Container(
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
          const Text(
            'Fact Check Results',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          _buildFactMeter('Accuracy', factCheckData!['accuracy']),
          _buildFactMeter('Credibility', factCheckData!['credibility']),
          _buildFactMeter('Bias Level', factCheckData!['bias']),
          const SizedBox(height: 16),
          const Text(
            'Summary',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            factCheckData!['summary'],
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Sources:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          ...List.generate(
            (factCheckData!['sources'] as List).length,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.link,
                    size: 16,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      factCheckData!['sources'][index],
                      style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFactMeter(String label, int value) {
    Color meterColor;
    String assessment;
    
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