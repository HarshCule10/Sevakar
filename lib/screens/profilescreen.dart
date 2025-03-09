import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _step = 1;
  final int _totalSteps = 3;

  // Form controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _familyMembersController = TextEditingController();

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

  void _nextStep() {
    if (_step < _totalSteps) {
      setState(() {
        _step++;
      });
      // Scroll to top
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Scrollable.ensureVisible(context, duration: const Duration(milliseconds: 300));
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
        Scrollable.ensureVisible(context, duration: const Duration(milliseconds: 300));
      });
    }
  }

  void _submitForm() {
    // Handle form submission
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile submitted successfully!'),
        backgroundColor: Colors.green,
      ),
    );
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
        title: const Text('Complete Profile'),),
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
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
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.shield, color: Theme.of(context).primaryColor, size: 24),
          const SizedBox(width: 8),
          Text(
            'Sevakar',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
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
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'We need some information to help determine which government schemes you may be eligible for.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: List.generate(
            _totalSteps * 2 - 1,
            (index) {
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
                    color: connectorStepNumber <= _step
                        ? Theme.of(context).primaryColor
                        : Colors.grey[300],
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Color _getStepColor(int step) {
    if (step == _step) {
      return Theme.of(context).primaryColor;
    } else if (step < _step) {
      return Theme.of(context).primaryColor.withOpacity(0.2);
    } else {
      return Colors.grey[300]!;
    }
  }

  Color _getStepTextColor(int step) {
    if (step == _step) {
      return Colors.white;
    } else if (step < _step) {
      return Theme.of(context).primaryColor;
    } else {
      return Colors.grey[600]!;
    }
  }

  Widget _buildFormCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _step == 1
                  ? 'Please provide your basic personal details'
                  : _step == 2
                      ? 'Where do you currently live?'
                      : 'Information about your income and occupation',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
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
          label: 'Street Address',
          controller: _addressController,
          hint: 'Your street address',
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                label: 'City/Town/Village',
                controller: _cityController,
                hint: 'City/Town/Village',
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
                      borderSide: BorderSide(color: Theme.of(context).primaryColor),
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
                      borderSide: BorderSide(color: Theme.of(context).primaryColor),
                    ),
                  ),
                  items: options.entries
                      .map((entry) => DropdownMenuItem<String>(
                            value: entry.key,
                            child: Text(entry.value),
                          ))
                      .toList(),
                  onChanged: onChanged,
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
                ...options.entries.map((entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Radio<String>(
                            value: entry.key,
                            groupValue: value,
                            activeColor: Theme.of(context).primaryColor,
                            onChanged: onChanged,
                          ),
                          Text(
                            entry.value,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    )),
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
                      side: BorderSide(color: Theme.of(context).primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Previous'),
                  )
                else
                  const SizedBox(),
                ElevatedButton(
                  onPressed: _step < _totalSteps ? _nextStep : _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(_step < _totalSteps ? 'Next' : 'Submit'),
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
                  const Icon(Icons.lock, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your information is secure and will only be used to check eligibility for government schemes.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        }