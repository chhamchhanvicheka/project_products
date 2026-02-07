import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  // Sign In controllers
  final TextEditingController _signInUsername = TextEditingController();
  final TextEditingController _signInPassword = TextEditingController();

  // Sign Up controllers
  final TextEditingController _signUpUsername = TextEditingController();
  final TextEditingController _signUpPassword = TextEditingController();
  final TextEditingController _signUpConfirmPassword = TextEditingController();

  bool _signInPasswordVisible = false;
  bool _signUpPasswordVisible = false;
  bool _signUpConfirmPasswordVisible = false;
  bool _isLoading = false;

  // Sign Up form errors
  String? _signUpUsernameError;
  String? _signUpPasswordError;
  String? _signUpConfirmPasswordError;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
    _checkExistingSession();
  }

  Future<void> _checkExistingSession() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    if (isLoggedIn && mounted) {
      Navigator.of(context).pushReplacementNamed('/dashboard');
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _tabController.dispose();
    _signInUsername.dispose();
    _signInPassword.dispose();
    _signUpUsername.dispose();
    _signUpPassword.dispose();
    _signUpConfirmPassword.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (_signInUsername.text.isEmpty || _signInPassword.text.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _db
          .collection('collection_credential')
          .where('username', isEqualTo: _signInUsername.text)
          .where('password', isEqualTo: _signInPassword.text)
          .get();

      if (result.docs.isEmpty) {
        _showError('Invalid username or password');
      } else {
        // Save session
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('username', _signInUsername.text);

        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/dashboard');
        }
      }
    } catch (e) {
      _showError('Sign in failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSignUp() async {
    // Reset errors
    setState(() {
      _signUpUsernameError = null;
      _signUpPasswordError = null;
      _signUpConfirmPasswordError = null;
    });

    bool hasError = false;

    if (_signUpUsername.text.trim().isEmpty) {
      _signUpUsernameError = 'Username is required';
      hasError = true;
    } else if (_signUpUsername.text.trim().length < 5) {
      _signUpUsernameError = 'Username must be at least 5 characters';
      hasError = true;
    }

    if (_signUpPassword.text.isEmpty) {
      _signUpPasswordError = 'Password is required';
      hasError = true;
    } else if (_signUpPassword.text.length < 8) {
      _signUpPasswordError = 'Password must be at least 8 characters';
      hasError = true;
    }

    if (_signUpConfirmPassword.text.isEmpty) {
      _signUpConfirmPasswordError = 'Please confirm your password';
      hasError = true;
    } else if (_signUpPassword.text != _signUpConfirmPassword.text) {
      _signUpConfirmPasswordError = 'Passwords do not match';
      hasError = true;
    }

    if (hasError) {
      setState(() {});
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Check if username already exists
      final existing = await _db
          .collection('collection_credential')
          .where('username', isEqualTo: _signUpUsername.text.trim())
          .get();

      if (existing.docs.isNotEmpty) {
        setState(() {
          _signUpUsernameError = 'Username already taken';
          _isLoading = false;
        });
        return;
      }

      await _db.collection('collection_credential').add({
        'username': _signUpUsername.text.trim(),
        'password': _signUpPassword.text,
        'created_at': DateTime.now(),
        'updated_at': DateTime.now(),
      });

      _showSuccess('Account created! Please sign in.');
      _tabController.animateTo(0);
      _signUpUsername.clear();
      _signUpPassword.clear();
      _signUpConfirmPassword.clear();
      setState(() {
        _signUpUsernameError = null;
        _signUpPasswordError = null;
        _signUpConfirmPasswordError = null;
      });
    } catch (e) {
      _showError('Sign up failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF14141A) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1C1C28);
    final textMuted = isDark ? Colors.white70 : Colors.grey.shade600;
    final chipBg = isDark ? const Color(0xFF1E1E26) : Colors.grey.shade100;
    final chipUnselected = isDark ? Colors.white70 : Colors.grey.shade700;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.deepPurple.shade700,
              Colors.blue.shade500,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: FadeTransition(
              opacity: _fadeIn,
              child: SlideTransition(
                position: _slideUp,
                child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: EdgeInsets.fromLTRB(24, 20, 24, 16),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inventory_2,
                          size: 48,
                          color: Colors.deepPurple.shade700,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Product Scanner',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.deepPurple.shade200 : Colors.deepPurple.shade700,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Inventory Management System',
                          style: TextStyle(
                            fontSize: 13,
                            color: textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tab Bar
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: chipBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: Colors.deepPurple.shade700,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: chipUnselected,
                      tabs: [
                        Tab(text: 'Sign In'),
                        Tab(text: 'Sign Up'),
                      ],
                    ),
                  ),

                  SizedBox(height: 16),

                  // Tab Views
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: _tabController.index == 0
                        ? _buildSignInForm()
                        : _buildSignUpForm(),
                  ),
                ],
              ),
            ),
          ),
          ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignInForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _signInUsername,
          decoration: InputDecoration(
            labelText: 'Username',
            prefixIcon: Icon(Icons.person),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        SizedBox(height: 16),
        TextField(
          controller: _signInPassword,
          obscureText: !_signInPasswordVisible,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: Icon(Icons.lock),
            suffixIcon: IconButton(
              icon: Icon(
                _signInPasswordVisible
                    ? Icons.visibility_off
                    : Icons.visibility,
              ),
              onPressed: () {
                setState(
                    () => _signInPasswordVisible = !_signInPasswordVisible);
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleSignIn,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Sign In',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpForm() {
    return SingleChildScrollView(
      child: Column(
        children: [
          TextField(
            controller: _signUpUsername,
            decoration: InputDecoration(
              labelText: 'Username',
              prefixIcon: Icon(Icons.person_outline),
              errorText: _signUpUsernameError,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          SizedBox(height: 16),
          TextField(
            controller: _signUpPassword,
            obscureText: !_signUpPasswordVisible,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock_outline),
              errorText: _signUpPasswordError,
              suffixIcon: IconButton(
                icon: Icon(
                  _signUpPasswordVisible
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
                onPressed: () {
                  setState(
                      () => _signUpPasswordVisible = !_signUpPasswordVisible);
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          SizedBox(height: 16),
          TextField(
            controller: _signUpConfirmPassword,
            obscureText: !_signUpConfirmPasswordVisible,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              prefixIcon: Icon(Icons.lock_reset_rounded),
              errorText: _signUpConfirmPasswordError,
              suffixIcon: IconButton(
                icon: Icon(
                  _signUpConfirmPasswordVisible
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
                onPressed: () {
                  setState(() => _signUpConfirmPasswordVisible =
                      !_signUpConfirmPasswordVisible);
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSignUp,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple.shade700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Sign Up',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
