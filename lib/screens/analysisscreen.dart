import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';


class FactCheckDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> factCheckData;
  final String originalClaim;

  const FactCheckDetailsScreen({
    Key? key, 
    required this.factCheckData,
    required this.originalClaim,
  }) : super(key: key);

  @override
  _FactCheckDetailsScreenState createState() => _FactCheckDetailsScreenState();
}

class _FactCheckDetailsScreenState extends State<FactCheckDetailsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _accuracyAnimation;
  late Animation<double> _credibilityAnimation;
  late Animation<double> _biasAnimation;
  
  bool _showSources = false;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _accuracyAnimation = Tween<double>(begin: 0, end: widget.factCheckData['accuracy'] / 100).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    
    _credibilityAnimation = Tween<double>(begin: 0, end: widget.factCheckData['credibility'] / 100).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
      ),
    );
    
    _biasAnimation = Tween<double>(begin: 0, end: widget.factCheckData['bias'] / 100).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );
    
    _controller.forward();
    
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) {
        setState(() {
          _showSources = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Fact Check Analysis',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.black),
            onPressed: () {
              // Share functionality would go here
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildClaimCard(),
              const SizedBox(height: 24),
              _buildAnalysisSection(),
              const SizedBox(height: 24),
              _buildSummarySection(),
              const SizedBox(height: 32),
              _buildSourcesSection(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClaimCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue, Colors.indigo],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.format_quote,
                color: Colors.white,
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                'Original Claim',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.originalClaim,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Analysis Results',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildAnimatedGaugeChart('Accuracy', _accuracyAnimation, Colors.green),
              ),
              Expanded(
                child: _buildAnimatedGaugeChart('Credibility', _credibilityAnimation, Colors.blue),
              ),
              Expanded(
                child: _buildAnimatedGaugeChart('Bias Level', _biasAnimation, Colors.orange),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.summarize,
                  color: Colors.indigo,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Analysis Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.factCheckData['summary'],
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourcesSection() {
    return AnimatedOpacity(
      opacity: _showSources ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 800),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sources',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(
              (widget.factCheckData['sources'] as List).length,
              (index) => _buildSourceItem(widget.factCheckData['sources'][index], index),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceItem(String source, int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      margin: EdgeInsets.only(bottom: 12, left: index * 2.0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Icon(
                _getSourceIcon(source),
                color: Colors.blue,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              source,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getSourceIcon(String source) {
    if (source.contains('wikipedia') || source.contains('wiki')) {
      return Icons.article_outlined;
    } else if (source.contains('gov') || source.contains('edu')) {
      return Icons.account_balance_outlined;
    } else if (source.contains('news') || source.contains('times') || source.contains('post')) {
      return Icons.newspaper_outlined;
    } else if (source.contains('study') || source.contains('research') || source.contains('journal')) {
      return Icons.science_outlined;
    } else {
      return Icons.public;
    }
  }

  Widget _buildAnimatedGaugeChart(String label, Animation<double> animation, Color color) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Column(
          children: [
            SizedBox(
              height: 120,
              width: 120,
              child: Stack(
                children: [
                  Center(
                    child: SizedBox(
                      height: 100,
                      width: 100,
                      child: PieChart(
                        dataMap: {
                          "Value": animation.value * 100,
                          "Remaining": 100 - (animation.value * 100),
                        },
                        animationDuration: Duration.zero,
                        chartType: ChartType.ring,
                        chartRadius: 50,
                        ringStrokeWidth: 15,
                        colorList: [color, Colors.grey.shade200],
                        chartValuesOptions: const ChartValuesOptions(showChartValues: false),
                        legendOptions: const LegendOptions(showLegends: false),
                      ),
                    ),
                  ),
                  Center(
                    child: Container(
                      height: 70,
                      width: 70,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(35),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.1),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${(animation.value * 100).toInt()}%',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            _getMetricDescription(label, animation.value * 100),
          ],
        );
      },
    );
  }

  Widget _getMetricDescription(String metric, double value) {
    String text;
    Color color;
    
    if (metric == 'Bias Level') {
      if (value < 30) {
        text = 'Low Bias';
        color = Colors.green;
      } else if (value < 70) {
        text = 'Medium Bias';
        color = Colors.orange;
      } else {
        text = 'High Bias';
        color = Colors.red;
      }
    } else {
      if (value > 70) {
        text = 'High';
        color = Colors.green;
      } else if (value > 40) {
        text = 'Medium';
        color = Colors.orange;
      } else {
        text = 'Low';
        color = Colors.red;
      }
    }
    
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }
}