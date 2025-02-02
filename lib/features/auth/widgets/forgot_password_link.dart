import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:appcherrylt/core/utils/url_utils.dart';

class ForgotPasswordLink extends StatelessWidget {
  const ForgotPasswordLink({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => openUrl('https://app.cherrymusic.com/en/lost-password/'),
      child: Text(
        'Forgot Password?',
        style: GoogleFonts.radioCanada(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          letterSpacing: -0.5,
          color: Colors.white,
        ),
      ),
    );
  }
}
