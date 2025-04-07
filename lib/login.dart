import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'profile_setup_screen.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  SignInPageState createState() => SignInPageState();
}

class SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRememberedEmail();
  }

  Future<void> _loadRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberedEmail = prefs.getString('rememberedEmail');
    if (rememberedEmail != null) {
      setState(() {
        _emailController.text = rememberedEmail;
        _rememberMe = true;
      });
    }
  }

  Future<void> _saveRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('rememberedEmail', _emailController.text.trim());
    } else {
      await prefs.remove('rememberedEmail');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        await _saveRememberedEmail();

// Add this new code to check profile existence
        final user = FirebaseAuth.instance.currentUser!;
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (!mounted) return;

        if (!userDoc.exists) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileSetupScreen(userId: user.uid, registrationData: {}),
            ),
          );
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } on FirebaseAuthException catch (e) {
        _handleAuthError(e);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        _showErrorSnackbar(
          'No account found with this email. Would you like to register?',
          action: () => Navigator.pushNamed(
            context,
            '/register',
            arguments: _emailController.text.trim(),
          ),
          actionLabel: 'SIGN UP',
        );
        break;
      case 'wrong-password':
        _showErrorSnackbar(
          'Incorrect password. Please try again or reset your password.',
          action: _showPasswordResetDialog,
          actionLabel: 'RESET PASSWORD',
        );
        break;
      case 'invalid-email':
        _showErrorSnackbar('Please enter a valid email address');
        break;
      default:
        _showErrorSnackbar('Authentication failed. Please try again.');
    }
  }

  void _showErrorSnackbar(String message, {VoidCallback? action, String actionLabel = ''}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: action != null
            ? SnackBarAction(
          label: actionLabel,
          onPressed: action,
          textColor: Colors.white,
        )
            : null,
      ),
    );
  }

  Future<void> _showPasswordResetDialog() async {
    final emailController = TextEditingController(text: _emailController.text.trim());
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(
            labelText: 'Enter your email',
            hintText: 'example@email.com',
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await FirebaseAuth.instance.sendPasswordResetEmail(
                  email: emailController.text.trim(),
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password reset email sent!'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context);
              } on FirebaseAuthException catch (e) {
                _showErrorSnackbar(e.message ?? 'Failed to send reset email');
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
        backgroundColor: const Color(0xff582562),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.fromLTRB(40.0, 120.0, 40.0, 40.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  _buildTextField(
                    controller: _emailController,
                    label: 'Email',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildPasswordField(
                    controller: _passwordController,
                    label: 'Password',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  Row(
                    children: <Widget>[
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() => _rememberMe = value!);
                        },
                      ),
                      const Text('Remember Me'),
                    ],
                  ),
                  TextButton(
                    onPressed: _isLoading ? null : _showPasswordResetDialog,
                    child: const Text('Forgot your password?'),
                  ),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _signInWithEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE4450F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 15),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Sign in'),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/register'),
                    child: const Text.rich(
                      TextSpan(
                        text: 'Don\'t have an account? ',
                        children: [
                          TextSpan(
                            text: 'Sign Up',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xff582562),
                            ),
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
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      autofillHints: const [AutofillHints.email],
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white54,
      ),
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      validator: validator,
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      autofillHints: const [AutofillHints.password],
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white54,
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      validator: validator,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _signInWithEmail(),
    );
  }
}