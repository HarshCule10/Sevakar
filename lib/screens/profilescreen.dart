import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _step = 1;
  final int _totalSteps = 3;
  bool _isLoading = true;
  bool _hasSubmittedDetails = false;
  Map<String, dynamic>? _userDetails;

  // Form controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _familyMembersController =
      TextEditingController();

  // Form values
  String _gender = 'male';
  String _caste = '';
  String _maritalStatus = '';
  String _state = '';
  String _residenceArea = 'urban';
  String _occupation = '';
  String _education = '';
  String _annualIncome = '';
  String _employmentStatus = 'employed';

  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _checkUserDetails();
  }

  Future<void> _checkUserDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(currentUser.uid).get();

        if (userDoc.exists) {
          Map<String, dynamic>? userData =
              userDoc.data() as Map<String, dynamic>?;

          if (userData != null && userData.containsKey('additionalDetails')) {
            setState(() {
              _hasSubmittedDetails = true;
              _userDetails =
                  userData['additionalDetails'] as Map<String, dynamic>;
            });
          }
        }
      }
    } catch (e) {
      print('Error checking user details: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _nextStep() {
    if (_step < _totalSteps) {
      setState(() {
        _step++;
      });
      // Scroll to top
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 300),
        );
      });
    }
  }

  void _prevStep() {
    if (_step > 1) {
      setState(() {
        _step--;
      });
      // Scroll to top
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 300),
        );
      });
    }
  }

  Future<void> _submitForm() async {
    // Set submitting state
    setState(() {
      _isSubmitting = true;
    });

    try {
      // Get current user
      User? currentUser = _auth.currentUser;

      if (currentUser != null) {
        // Create a map of all form data
        Map<String, dynamic> additionalDetails = {
          'personalInfo': {
            'firstName': _firstNameController.text,
            'lastName': _lastNameController.text,
            'age': _ageController.text,
            'gender': _gender,
            'caste': _caste,
            'maritalStatus': _maritalStatus,
          },
          'locationInfo': {
            'address': _addressController.text,
            'city': _cityController.text,
            'district': _districtController.text,
            'state': _state,
            'pincode': _pincodeController.text,
            'phone': _phoneController.text,
            'residenceArea': _residenceArea,
          },
          'economicInfo': {
            'occupation': _occupation,
            'education': _education,
            'annualIncome': _annualIncome,
            'familyMembers': _familyMembersController.text,
            'employmentStatus': _employmentStatus,
          },
          'lastUpdated': FieldValue.serverTimestamp(),
        };

        // Save to Firestore
        await _firestore.collection('users').doc(currentUser.uid).set({
          'additionalDetails': additionalDetails,
          'hasCompletedProfile': true,
        }, SetOptions(merge: true));

        setState(() {
          _hasSubmittedDetails = true;
          _userDetails = additionalDetails;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // Reset submitting state
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _editProfile() {
    setState(() {
      _hasSubmittedDetails = false;
    });
  }

  @override
  void dispose() {
    // Dispose controllers
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _pincodeController.dispose();
    _phoneController.dispose();
    _familyMembersController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      backgroundColor: Colors.grey[50],
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                ),
              )
              : _hasSubmittedDetails
              ? _buildCompletedProfileView()
              : _buildProfileForm(),
    );
  }

  Widget _buildCompletedProfileView() {
    final personalInfo = _userDetails?['personalInfo'] as Map<String, dynamic>?;
    final locationInfo = _userDetails?['locationInfo'] as Map<String, dynamic>?;
    final economicInfo = _userDetails?['economicInfo'] as Map<String, dynamic>?;

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeader(personalInfo),
                  const SizedBox(height: 24),
                  _buildProfileSummaryCard(
                    personalInfo,
                    locationInfo,
                    economicInfo,
                  ),
                ],
              ),
            ),
          ),
          _buildProfileFooter(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic>? personalInfo) {
    final firstName = personalInfo?['firstName'] as String? ?? '';
    final lastName = personalInfo?['lastName'] as String? ?? '';
    final fullName = '$firstName $lastName';

    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.person, size: 60, color: Colors.black),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            fullName,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            _auth.currentUser?.email ?? '',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _editProfile,
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Edit Profile'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black,
              side: const BorderSide(color: Colors.black),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSummaryCard(
    Map<String, dynamic>? personalInfo,
    Map<String, dynamic>? locationInfo,
    Map<String, dynamic>? economicInfo,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Personal Information'),
            const SizedBox(height: 12),
            _buildInfoRow('Age', personalInfo?['age'] ?? ''),
            _buildInfoRow(
              'Gender',
              _formatValue(personalInfo?['gender'] ?? ''),
            ),
            _buildInfoRow(
              'Caste/Category',
              _formatValue(personalInfo?['caste'] ?? ''),
            ),
            _buildInfoRow(
              'Marital Status',
              _formatValue(personalInfo?['maritalStatus'] ?? ''),
            ),

            const Divider(height: 32),
            _buildSectionHeader('Location & Contact'),
            const SizedBox(height: 12),
            _buildInfoRow('Address', locationInfo?['address'] ?? ''),
            _buildInfoRow('City', locationInfo?['city'] ?? ''),
            _buildInfoRow('State', _formatValue(locationInfo?['state'] ?? '')),
            _buildInfoRow('Phone', locationInfo?['phone'] ?? ''),

            const Divider(height: 32),
            _buildSectionHeader('Economic Details'),
            const SizedBox(height: 12),
            _buildInfoRow(
              'Occupation',
              _formatValue(economicInfo?['occupation'] ?? ''),
            ),
            _buildInfoRow(
              'Education',
              _formatValue(economicInfo?['education'] ?? ''),
            ),
            _buildInfoRow(
              'Annual Income',
              _formatValue(economicInfo?['annualIncome'] ?? ''),
            ),
            _buildInfoRow(
              'Family Members',
              economicInfo?['familyMembers'] ?? '',
            ),
          ],
        ),
      ),
    );
  }

  String _formatValue(String value) {
    if (value.isEmpty) return '';

    // Convert kebab-case or snake_case to readable format
    String formatted = value.replaceAll('-', ' ').replaceAll('_', ' ');

    // Capitalize each word
    List<String> words = formatted.split(' ');
    words =
        words.map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1);
        }).toList();

    return words.join(' ');
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildProfileFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          TextButton(
            onPressed: FirebaseAuth.instance.signOut,
            child: const Text(
              'Sign Out',
              style: TextStyle(color: Colors.black),
            ),
          ),
          const Spacer(),
          const Icon(Icons.verified_user, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Text(
            'Profile Complete',
            style: TextStyle(
              fontSize: 14,
              color: Colors.green[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileForm() {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildFormCard(),
                  ],
                ),
              ),
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Complete Your Profile',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'We need some information to help determine which government schemes you may be eligible for.',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(height: 24),
        Row(
          children: List.generate(_totalSteps * 2 - 1, (index) {
            // Even indices are steps, odd indices are connectors
            if (index % 2 == 0) {
              final stepNumber = (index ~/ 2) + 1;
              return Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getStepColor(stepNumber),
                ),
                child: Center(
                  child: Text(
                    '$stepNumber',
                    style: TextStyle(
                      color: _getStepTextColor(stepNumber),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            } else {
              final connectorStepNumber = (index ~/ 2) + 1;
              return Expanded(
                child: Container(
                  height: 4,
                  color:
                      connectorStepNumber <= _step
                          ? Colors.black
                          : Colors.grey[300],
                ),
              );
            }
          }),
        ),
      ],
    );
  }

  Color _getStepColor(int step) {
    if (step == _step) {
      return Colors.black;
    } else if (step < _step) {
      return Colors.black.withOpacity(0.2);
    } else {
      return Colors.grey[300]!;
    }
  }

  Color _getStepTextColor(int step) {
    if (step == _step) {
      return Colors.white;
    } else if (step < _step) {
      return Colors.black;
    } else {
      return Colors.grey[600]!;
    }
  }

  Widget _buildFormCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _step == 1
                  ? 'Personal Information'
                  : _step == 2
                  ? 'Location & Contact Details'
                  : 'Economic & Occupation Details',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              _step == 1
                  ? 'Please provide your basic personal details'
                  : _step == 2
                  ? 'Where do you currently live?'
                  : 'Information about your income and occupation',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            _buildFormFields(),
            const SizedBox(height: 24),
            _buildFormNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildFormFields() {
    switch (_step) {
      case 1:
        return _buildPersonalInfoFields();
      case 2:
        return _buildLocationFields();
      case 3:
        return _buildEconomicFields();
      default:
        return Container();
    }
  }

  Widget _buildPersonalInfoFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                label: 'First Name',
                controller: _firstNameController,
                hint: 'First Name',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                label: 'Last Name',
                controller: _lastNameController,
                hint: 'Last Name',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField(
          label: 'Age',
          controller: _ageController,
          hint: 'Your age',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        _buildRadioField(
          label: 'Gender',
          value: _gender,
          options: const {'male': 'Male', 'female': 'Female', 'other': 'Other'},
          onChanged: (value) {
            setState(() {
              _gender = value!;
            });
          },
        ),
        const SizedBox(height: 16),
        _buildDropdownField(
          label: 'Caste/Category',
          value: _caste,
          hint: 'Select your category',
          options: const {
            'general': 'General',
            'obc': 'OBC',
            'sc': 'SC',
            'st': 'ST',
            'other': 'Other',
          },
          onChanged: (value) {
            setState(() {
              _caste = value!;
            });
          },
        ),
        const SizedBox(height: 16),
        _buildDropdownField(
          label: 'Marital Status',
          value: _maritalStatus,
          hint: 'Select your marital status',
          options: const {
            'single': 'Single',
            'married': 'Married',
            'divorced': 'Divorced',
            'widowed': 'Widowed',
          },
          onChanged: (value) {
            setState(() {
              _maritalStatus = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildLocationFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          label: 'Address',
          controller: _addressController,
          hint: 'Your address',
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                label: 'City',
                controller: _cityController,
                hint: 'City',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                label: 'District',
                controller: _districtController,
                hint: 'District',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildDropdownField(
                label: 'State',
                value: _state,
                hint: 'Select state',
                options: const {
                  'andhra-pradesh': 'Andhra Pradesh',
                  'assam': 'Assam',
                  'bihar': 'Bihar',
                  'delhi': 'Delhi',
                  'gujarat': 'Gujarat',
                  'karnataka': 'Karnataka',
                  'kerala': 'Kerala',
                  'maharashtra': 'Maharashtra',
                  'tamil-nadu': 'Tamil Nadu',
                  'uttar-pradesh': 'Uttar Pradesh',
                  'west-bengal': 'West Bengal',
                },
                onChanged: (value) {
                  setState(() {
                    _state = value!;
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                label: 'PIN Code',
                controller: _pincodeController,
                hint: 'PIN Code',
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField(
          label: 'Phone Number',
          controller: _phoneController,
          hint: 'Your phone number',
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        _buildRadioField(
          label: 'Residence Area',
          value: _residenceArea,
          options: const {
            'urban': 'Urban',
            'rural': 'Rural',
            'semi-urban': 'Semi-Urban',
          },
          onChanged: (value) {
            setState(() {
              _residenceArea = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildEconomicFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDropdownField(
          label: 'Current Occupation',
          value: _occupation,
          hint: 'Select your occupation',
          options: const {
            'student': 'Student',
            'salaried': 'Salaried Employee',
            'business': 'Business Owner',
            'self-employed': 'Self-Employed',
            'farmer': 'Farmer',
            'daily-wage': 'Daily Wage Worker',
            'unemployed': 'Unemployed',
            'retired': 'Retired',
            'homemaker': 'Homemaker',
            'other': 'Other',
          },
          onChanged: (value) {
            setState(() {
              _occupation = value!;
            });
          },
        ),
        const SizedBox(height: 16),
        _buildDropdownField(
          label: 'Highest Education',
          value: _education,
          hint: 'Select your highest education',
          options: const {
            'no-formal': 'No Formal Education',
            'primary': 'Primary School',
            'secondary': 'Secondary School',
            'higher-secondary': 'Higher Secondary',
            'diploma': 'Diploma',
            'graduate': 'Graduate',
            'post-graduate': 'Post Graduate',
            'doctorate': 'Doctorate',
          },
          onChanged: (value) {
            setState(() {
              _education = value!;
            });
          },
        ),
        const SizedBox(height: 16),
        _buildDropdownField(
          label: 'Annual Household Income (₹)',
          value: _annualIncome,
          hint: 'Select income range',
          options: const {
            'below-50k': 'Below ₹50,000',
            '50k-1l': '₹50,000 - ₹1,00,000',
            '1l-2.5l': '₹1,00,000 - ₹2,50,000',
            '2.5l-5l': '₹2,50,000 - ₹5,00,000',
            '5l-10l': '₹5,00,000 - ₹10,00,000',
            'above-10l': 'Above ₹10,00,000',
          },
          onChanged: (value) {
            setState(() {
              _annualIncome = value!;
            });
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          label: 'Number of Family Members',
          controller: _familyMembersController,
          hint: 'Including yourself',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        _buildRadioField(
          label: 'Employment Status',
          value: _employmentStatus,
          options: const {
            'employed': 'Employed',
            'unemployed': 'Unemployed',
            'self-employed': 'Self-Employed',
          },
          onChanged: (value) {
            setState(() {
              _employmentStatus = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.black),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required String hint,
    required Map<String, String> options,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value.isEmpty ? null : value,
          hint: Text(hint, style: TextStyle(color: Colors.grey[400])),
          isExpanded: true,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.black),
            ),
          ),
          items:
              options.entries
                  .map(
                    (entry) => DropdownMenuItem<String>(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                  )
                  .toList(),
          onChanged: onChanged,
          dropdownColor: Colors.white,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
        ),
      ],
    );
  }

  Widget _buildRadioField({
    required String label,
    required String value,
    required Map<String, String> options,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        ...options.entries.map(
          (entry) => RadioListTile<String>(
            title: Text(entry.value),
            value: entry.key,
            groupValue: value,
            onChanged: onChanged,
            contentPadding: EdgeInsets.zero,
            activeColor: Colors.black,
            dense: true,
          ),
        ),
      ],
    );
  }

  Widget _buildFormNavigation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_step > 1)
          OutlinedButton(
            onPressed: _prevStep,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              side: const BorderSide(color: Colors.black),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Previous',
              style: TextStyle(color: Colors.black),
            ),
          )
        else
          const SizedBox(),
        ElevatedButton(
          onPressed:
              _isSubmitting
                  ? null
                  : (_step < _totalSteps ? _nextStep : _submitForm),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            backgroundColor: Colors.black,
            disabledBackgroundColor: Colors.grey,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child:
              _isSubmitting
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                  : Text(
                    _step < _totalSteps ? 'Next' : 'Submit',
                    style: TextStyle(color: Colors.white),
                  ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          TextButton(
            onPressed: FirebaseAuth.instance.signOut,
            child: const Text(
              'Sign Out',
              style: TextStyle(color: Colors.black),
            ),
          ),
          const Icon(Icons.lock, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Your information is secure and will only be used to check eligibility for government schemes.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }
}
