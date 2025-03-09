import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fchecker/helpers/firebasehelpers.dart';

class FactCheckHistoryPanel extends StatefulWidget {
  final Function(String, Map<String, dynamic>) onHistoryItemSelected;
  
  const FactCheckHistoryPanel({
    Key? key, 
    required this.onHistoryItemSelected,
  }) : super(key: key);

  @override
  _FactCheckHistoryPanelState createState() => _FactCheckHistoryPanelState();
}

class _FactCheckHistoryPanelState extends State<FactCheckHistoryPanel> {
  bool _isLoading = true;
  List<DocumentSnapshot> _historyItems = [];

  @override
  void initState() {
    super.initState();
    _loadFactCheckHistory();
  }

  Future<void> _loadFactCheckHistory() async {
    setState(() {
      _isLoading = true;
    });
    
    final historyDocs = await FirebaseHelper.getFactCheckHistory();
    
    setState(() {
      _historyItems = historyDocs;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Fact Check History',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 8.0),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _historyItems.isEmpty
                    ? const Center(
                        child: Text(
                          'No fact check history found.',
                          style: TextStyle(
                            fontSize: 16.0,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _historyItems.length,
                        itemBuilder: (context, index) {
                          final data = _historyItems[index].data() as Map<String, dynamic>;
                          final String claim = data['claim'] ?? 'Unknown claim';
                          
                          Timestamp timestamp = data['timestamp'] ?? Timestamp.now();
                          DateTime dateTime = timestamp.toDate();
                          
                          Map<String, dynamic> factCheckResult = data['factCheckResult'] ?? {};
                          
                          // Extract verdict or summary if available
                          String verdict = factCheckResult['verdict'] ?? 'No verdict available';
                          
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 4.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: InkWell(
                              onTap: () {
                                widget.onHistoryItemSelected(claim, factCheckResult);
                                Navigator.of(context).pop();
                              },
                              borderRadius: BorderRadius.circular(12.0),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            claim.length > 60 ? '${claim.substring(0, 60)}...' : claim,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 16.0,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            size: 20.0,
                                            color: Colors.grey,
                                          ),
                                          onPressed: () {
                                            _deleteHistoryItem(_historyItems[index].id);
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4.0),
                                    Text(
                                      'Verdict: $verdict',
                                      style: const TextStyle(
                                        fontSize: 14.0,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4.0),
                                    Text(
                                      _formatTimestamp(dateTime),
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteHistoryItem(String itemId) async {
    try {
      await FirebaseHelper.deleteFactCheck(itemId);
      
      setState(() {
        _historyItems.removeWhere((doc) => doc.id == itemId);
      });
      
      // Show confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('History item deleted'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      print('Error deleting history item: $e');
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} min ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}