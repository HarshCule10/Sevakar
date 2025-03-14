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

    try {
      final history = await FirebaseHelper.getChatHistory();

      // Sort history by timestamp (newest first)
      history.sort((a, b) {
        final aTimestamp = a['timestamp'] as Timestamp?;
        final bTimestamp = b['timestamp'] as Timestamp?;

        if (aTimestamp == null && bTimestamp == null) return 0;
        if (aTimestamp == null) return 1;
        if (bTimestamp == null) return -1;

        return bTimestamp.compareTo(aTimestamp);
      });

      setState(() {
        _historyItems = history;
        _isLoading = false;
      });

      print('Loaded ${history.length} history items');
    } catch (e) {
      print('Error loading chat history: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredHistory {
    return _historyItems.where((item) {
      // Check if the item has the required fields
      if (!item.containsKey('claim') || !item.containsKey('factCheckResult')) {
        return false;
      }

      final claim = item['claim'].toString();
      final factCheckResult = item['factCheckResult'] as Map<String, dynamic>?;

      if (factCheckResult == null) {
        return false;
      }

      final matchesSearch = claim.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );

      // For filter, check accuracy level
      bool matchesFilter = _selectedFilter == 'All';

      if (!matchesFilter && factCheckResult.containsKey('accuracy')) {
        final accuracy = factCheckResult['accuracy'] as int?;
        if (accuracy != null) {
          if (_selectedFilter == 'True' && accuracy >= 70) {
            matchesFilter = true;
          } else if (_selectedFilter == 'Partially True' &&
              accuracy >= 40 &&
              accuracy < 70) {
            matchesFilter = true;
          } else if (_selectedFilter == 'False' && accuracy < 40) {
            matchesFilter = true;
          }
        }
      }

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
            item['factCheckResult'] as Map<String, dynamic>? ?? {};
        final int accuracy = factCheckResult['accuracy'] as int? ?? 0;

        return Dismissible(
          key: Key(
            timestamp?.toDate().toString() ??
                DateTime.now().toString() + index.toString(),
          ),
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
                widget.onHistoryItemSelected(claim, factCheckResult);
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
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              if (timestamp != null)
                                Text(
                                  DateFormat(
                                    'MMM d, yyyy • h:mm a',
                                  ).format(timestamp.toDate()),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
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
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildMetricChip(
                          'Accuracy',
                          accuracy,
                          accuracy >= 70
                              ? Colors.green
                              : accuracy >= 40
                              ? Colors.orange
                              : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        _buildMetricChip(
                          'Credibility',
                          factCheckResult['credibility'] as int? ?? 0,
                          Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        _buildMetricChip(
                          'Bias',
                          factCheckResult['bias'] as int? ?? 0,
                          Colors.purple,
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

    if (accuracy >= 70) {
      color = Colors.green;
      icon = Icons.check_circle;
    } else if (accuracy >= 40) {
      color = Colors.orange;
      icon = Icons.warning;
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

  Widget _buildMetricChip(String label, int value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              flex: 3,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Flexible(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$value%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
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
          Icon(Icons.history, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No History Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your fact check history will appear here',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Clear History'),
            content: const Text(
              'Are you sure you want to clear your entire fact check history?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await FirebaseHelper.clearChatHistory();
                  _loadChatHistory();
                },
                child: const Text('Clear', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }
}
