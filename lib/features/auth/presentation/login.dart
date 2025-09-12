import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/login_form.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginPage extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();

  LoginPage({super.key});

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => _launchUrl(
                          'https://app.cherrymusic.lt/prarastas-slaptazodis/'),
                      child: Text(
                        'Pamiršote slaptažodį?',
                        style: GoogleFonts.radioCanada(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                          letterSpacing: -0.5,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          _launchUrl('https://cherrymusic.lt/registruotis/'),
                      child: Text(
                        'Kūrti naują paskyrą',
                        style: GoogleFonts.radioCanada(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                          letterSpacing: -0.5,
                          color: Colors.white,
                        ),
                      ),
                    ),
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
