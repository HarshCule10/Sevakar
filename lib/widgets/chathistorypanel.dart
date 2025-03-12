import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fchecker/helpers/firebasehelpers.dart';
import 'package:intl/intl.dart';

class FactCheckHistoryPanel extends StatefulWidget {
  final Function(String, Map<String, dynamic>) onHistoryItemSelected;

  const FactCheckHistoryPanel({Key? key, required this.onHistoryItemSelected})
    : super(key: key);

  @override
  _FactCheckHistoryPanelState createState() => _FactCheckHistoryPanelState();
}

class _FactCheckHistoryPanelState extends State<FactCheckHistoryPanel> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _historyItems = [];
  String _searchQuery = '';
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    setState(() {
      _isLoading = true;
    });

    final history = await FirebaseHelper.getChatHistory();

    setState(() {
      _historyItems = history;
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> get _filteredHistory {
    return _historyItems.where((item) {
      final matchesSearch = item['claim'].toString().toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      final matchesFilter =
          _selectedFilter == 'All' ||
          (item['factCheckResult']?['verdict'] ?? '')
                  .toString()
                  .toLowerCase() ==
              _selectedFilter.toLowerCase();
      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildSearchBar(),
          _buildFilterChips(),
          Expanded(
            child:
                _isLoading
                    ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                    : _filteredHistory.isEmpty
                    ? _buildEmptyState()
                    : _buildHistoryList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Fact Check History',
            style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadChatHistory,
                tooltip: 'Refresh History',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _showClearHistoryDialog(),
                tooltip: 'Clear History',
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Close',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search history...',
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

  Widget _buildFilterChips() {
    final filters = ['All', 'True', 'Partially True', 'False', 'Unverified'];

    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: Text(filter),
              selected: _selectedFilter == filter,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = selected ? filter : 'All';
                });
              },
              backgroundColor: Colors.grey[100],
              selectedColor: Colors.black,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: _selectedFilter == filter ? Colors.white : Colors.black,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHistoryList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _filteredHistory.length,
      itemBuilder: (context, index) {
        final item = _filteredHistory[index];
        final String claim = item['claim'] ?? 'Unknown claim';
        final timestamp = item['timestamp'] as Timestamp?;
        final factCheckResult =
            item['factCheckResult'] as Map<String, dynamic>?;
        final String verdict = factCheckResult?['verdict'] ?? 'No verdict';
        final int accuracy = factCheckResult?['accuracy'] as int? ?? 0;

        return Dismissible(
          key: Key(timestamp?.toDate().toString() ?? DateTime.now().toString()),
          background: Container(
            decoration: BoxDecoration(
              color: Colors.red[400],
              borderRadius: BorderRadius.circular(12.0),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20.0),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          direction: DismissDirection.endToStart,
          onDismissed: (direction) {
            FirebaseHelper.deleteChatHistoryItem(item);
            setState(() {
              _historyItems.remove(item);
            });
          },
          child: Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: InkWell(
              onTap: () {
                widget.onHistoryItemSelected(claim, factCheckResult ?? {});
                Navigator.of(context).pop();
              },
              borderRadius: BorderRadius.circular(12.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAccuracyIndicator(accuracy),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                claim,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getVerdictColor(
                                        verdict,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      verdict,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _getVerdictColor(verdict),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (timestamp != null)
                                    Text(
                                      _formatTimestamp(timestamp.toDate()),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAccuracyIndicator(int accuracy) {
    Color color;
    IconData icon;

    if (accuracy > 70) {
      color = Colors.green;
      icon = Icons.check_circle;
    } else if (accuracy > 30) {
      color = Colors.orange;
      icon = Icons.info;
    } else {
      color = Colors.red;
      icon = Icons.cancel;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? 'No fact check history yet'
                : 'No results found',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Your fact check history will appear here',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ],
      ),
    );
  }

  Color _getVerdictColor(String verdict) {
    switch (verdict.toLowerCase()) {
      case 'true':
        return Colors.green;
      case 'partially true':
        return Colors.orange;
      case 'false':
        return Colors.red;
      default:
        return Colors.grey;
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
      return DateFormat('MMM d, y').format(timestamp);
    }
  }

  Future<void> _showClearHistoryDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear History'),
          content: const Text(
            'Are you sure you want to clear your entire fact check history? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Clear', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                await FirebaseHelper.clearChatHistory();
                setState(() {
                  _historyItems.clear();
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
