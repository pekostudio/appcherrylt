import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:appcherrylt/api/api.dart';
import 'package:appcherrylt/core/models/user_session.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;

  const LoginForm({
    super.key,
    required this.formKey,
  });

  @override
  LoginFormState createState() => LoginFormState();
}

class LoginFormState extends State<LoginForm> {
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;
  bool _isLoading = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadRememberMe();
  }

  Future<void> _loadRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool('remember_me') ?? false;
    if (!mounted) return;
    setState(() {
      _rememberMe = saved;
    });
  }

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextFormField(
              controller: _loginController,
              decoration: InputDecoration(
                hintText: 'Vartotojas',
                prefixIcon:
                    const Icon(Icons.email_outlined, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6.0),
                  borderSide: BorderSide.none,
                ),
                errorStyle: const TextStyle(
                  color: Colors.white, // Change this to your desired color
                  fontSize: 14, // Optional: change the font size
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Prašome įvesti savo prisijungimo vardą';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscureText,
              decoration: InputDecoration(
                hintText: 'Slaptažodis',
                prefixIcon: const Icon(Icons.key_outlined, color: Colors.grey),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6.0),
                  borderSide: BorderSide.none,
                ),
                errorStyle: const TextStyle(
                  color: Colors.white, // Change this to your desired color
                  fontSize: 14, // Optional: change the font size
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Prašome įvesti savo slaptažodį';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Checkbox(
                  value: _rememberMe,
                  onChanged: (value) {
                    setState(() {
                      _rememberMe = value ?? false;
                    });
                  },
                ),
                Text(
                  'Prisiminti mane',
                  style: GoogleFonts.radioCanada(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    letterSpacing: -0.5,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () async {
                      if (widget.formKey.currentState!.validate()) {
                        setState(() {
                          _isLoading = true;
                        });
                        String login = _loginController.text;
                        String password = _passwordController.text;
                        await _handleLogin(login, password);
                        setState(() {
                          _isLoading = false;
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: const Color(0xFF2C2C2C),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('PRISIJUNGTI'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogin(String login, String password) async {
    try {
      String? token = await API().getAccessToken(login, password);

      if (!mounted) return;

      if (token == null) {
        // Show error message if login failed
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Invalid credentials. Please try again.',
                style: TextStyle(color: Colors.red),
              ),
              backgroundColor: Colors.white,
            ),
          );
        }
        return;
      }

      // Save token in shared preferences for background service
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', token);
      await prefs.setBool('remember_me', _rememberMe);

      Provider.of<UserSession>(context, listen: false).setGlobalToken(token);
      Navigator.pushReplacementNamed(context, 'index');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Invalid credentials. Please try again.',
              style: TextStyle(color: Colors.red),
            ),
            backgroundColor: Colors.white,
          ),
        );
      }
    }
  }
}
