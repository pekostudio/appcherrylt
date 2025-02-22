import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../widgets/login_form.dart';
import '../widgets/forgot_password_link.dart';
import '../widgets/create_account_link.dart';
import '../../../core/providers/connectivity_provider.dart';

class LoginPage extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();

  LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Check connectivity when the page is built
    final connectivityProvider = Provider.of<ConnectivityProvider>(context);
    if (!connectivityProvider.isOnline) {
      // Use addPostFrameCallback to avoid calling setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, 'offline');
      });
    }

    return Scaffold(
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          image: DecorationImage(
            fit: BoxFit.cover,
            image: AssetImage('assets/images/login-bg.png'),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/images/cherry-logo.svg',
                width: MediaQuery.of(context).size.width * 0.8,
                height: 67,
              ),
              const SizedBox(height: 20),
              LoginForm(formKey: _formKey),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ForgotPasswordLink(),
                    CreateAccountLink(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
