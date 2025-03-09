import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  // Form key to validate form fields
  final _formKey = GlobalKey<FormState>();

  // Controllers to manage text input fields
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _businessNameController = TextEditingController();

  // Dropdown selections
  String? _selectedRole;
  String? _selectedHearAbout;
  String? _selectedCountry;

  // Toggle password visibility
  bool _obscurePassword = true;

  // Loading state for registration process
  bool _isLoading = false;

  // List of roles for dropdown
  final List<Map<String, String>> _roles = [
    {'value': 'business', 'label': 'Business Owner'},
    {'value': 'individual', 'label': 'Individual'},
  ];

  // List of available countries
  final List<String> _countries = [
    'Pakistan',
    'USA',
    'Canada',
    'UK',
    'Australia'
  ];

  // Function to handle user registration with Firebase
  Future<void> _registerWithEmail() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        if (!mounted) return;
        Navigator.pushReplacementNamed(
            context, '/home'); // Navigate to home after successful registration
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Registration failed')),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // First Name & Last Name fields
                _buildFieldRow(
                  left: _buildTextField(
                    controller: _firstNameController,
                    label: 'First Name',
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                  ),
                  right: _buildTextField(
                    controller: _lastNameController,
                    label: 'Last Name',
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(height: 20),

                // Email & Username fields
                _buildFieldRow(
                  left: _buildTextField(
                    controller: _emailController,
                    label: 'Email',
                    validator: (value) {
                      if (value!.isEmpty) return 'Required';
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}\$')
                          .hasMatch(value)) {
                        return 'Invalid email';
                      }
                      return null;
                    },
                  ),
                  right: _buildTextField(
                    controller: _usernameController,
                    label: 'Username',
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(height: 20),

                // Password & Confirm Password fields
                _buildFieldRow(
                  left: _buildPasswordField(
                    controller: _passwordController,
                    label: 'Password',
                    validator: (value) {
                      if (value!.isEmpty) return 'Required';
                      if (value.length < 8) return 'Minimum 8 characters';
                      return null;
                    },
                  ),
                  right: _buildPasswordField(
                    controller: _confirmPasswordController,
                    label: 'Confirm Password',
                    validator: (value) {
                      if (value != _passwordController.text)
                        return 'Passwords must match';
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Role & Referral dropdowns
                _buildFieldRow(
                  left: _buildDropdown(
                    value: _selectedRole,
                    items: _roles,
                    hint: 'Choose your role...',
                    label: 'Select Role',
                    onChanged: (value) => setState(() => _selectedRole = value),
                  ),
                  right: _buildDropdown(
                    value: _selectedHearAbout,
                    items: const [
                      'Social Media',
                      'Friend',
                      'Advertisement',
                      'Other'
                    ],
                    hint: 'Choose an option',
                    label: 'How did you hear about us?',
                    onChanged: (value) =>
                        setState(() => _selectedHearAbout = value),
                  ),
                ),
                const SizedBox(height: 20),

                // Business Name & Country dropdown
                _buildFieldRow(
                  left: _buildTextField(
                    controller: _businessNameController,
                    label: 'Business Name',
                    hint: 'Enter Business Name',
                    validator: (value) =>
                    _selectedRole == 'business' && value!.isEmpty
                        ? 'Required for business'
                        : null,
                  ),
                  right: _buildDropdown(
                    value: _selectedCountry,
                    items: _countries,
                    hint: 'Select Country',
                    label: 'Country',
                    onChanged: (value) =>
                        setState(() => _selectedCountry = value),
                  ),
                ),
                const SizedBox(height: 30),

                // Register Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _registerWithEmail,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text(
                        'Register', style: TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(height: 20),

                // Navigate to Login Page
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  child: const Text.rich(
                    TextSpan(
                      text: 'Already registered? ',
                      children: [
                        TextSpan(
                          text: 'Login here',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Builds a row containing two widgets with spacing in between
  Widget _buildFieldRow({required Widget left, required Widget right}) {
    return Container(
      width: double.infinity, // Ensures it doesn't exceed available space
      child: Row(
        children: [
          Flexible(child: left), // Allows widget to take only needed space
          const SizedBox(width: 16), // Spacing
          Flexible(child: right),
        ],
      ),
    );
  }


// Builds a standard text input field with optional hint and validation
  Widget _buildTextField({
    required TextEditingController controller, // Controller for handling input text
    required String label, // Label text for the field
    String? hint, // Optional hint text
    String? Function(String?)? validator, // Optional validation function
  }) {
    return TextFormField(
      controller: controller, // Binds controller to field
      decoration: InputDecoration(
        isDense: true, // Reduces the size of input fields
        labelText: label, // Displays label above input field
        hintText: hint, // Displays hint inside input field
        border: const OutlineInputBorder(), // Adds a border around the field
      ),
      maxLines: 1, // Prevents expansion
      validator: validator, // Applies validation function
    );
  }

// Builds a password input field with toggle visibility functionality
  Widget _buildPasswordField({
    required TextEditingController controller, // Controller for handling input text
    required String label, // Label text for the field
    String? Function(String?)? validator, // Optional validation function
  }) {
    return TextFormField(
      controller: controller, // Binds controller to field
      obscureText: _obscurePassword, // Toggles password visibility
      decoration: InputDecoration(
        isDense: true, // Reduces the size of input fields
        labelText: label, // Displays label above input field
        border: const OutlineInputBorder(), // Adds a border around the field
        suffixIcon: IconButton( // Adds an eye icon button to toggle visibility
          icon: Icon(
              _obscurePassword ? Icons.visibility : Icons.visibility_off),
          onPressed: () => setState(() => _obscurePassword =
          !_obscurePassword), // Updates state to toggle visibility
        ),
      ),
      maxLines: 1, // Prevents expansion
      validator: validator, // Applies validation function
    );
  }

// Builds a dropdown field with dynamic values and validation
  Widget _buildDropdown({
    required dynamic value, // Selected value for the dropdown
    required List<dynamic> items, // List of dropdown items
    required String hint, // Placeholder hint for dropdown
    required String label, // Label text for dropdown
    required Function(dynamic) onChanged, // Function to handle value changes
  }) {
    return DropdownButtonFormField(
      value: value,
      // Binds the current selected value
      decoration: InputDecoration(
        isDense: true, // Reduces the size of input fields
        labelText: label, // Displays label above dropdown
        border: const OutlineInputBorder(), // Adds a border around dropdown
      ),
      hint: Text(hint),
      // Displays hint when no selection is made
      items: items.map<DropdownMenuItem>((item) {
        return DropdownMenuItem(
          value: item is Map ? item['value'] : item,
          // Uses item value if it's a map, else uses item directly
          child: Text(item is Map ? item['label']! : item
              .toString()), // Displays item label if it's a map, else uses item directly
        );
      }).toList(),
      onChanged: onChanged,
      // Handles value selection
      validator: (value) =>
      value == null
          ? 'Required'
          : null, // Ensures selection is made
    );
  }

// Disposes controllers to free up memory when the widget is removed
  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _businessNameController.dispose();
    super.dispose(); // Calls the parent class dispose method
  }
}