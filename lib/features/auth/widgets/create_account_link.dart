import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:appcherrylt/core/utils/url_utils.dart';

class CreateAccountLink extends StatelessWidget {
  const CreateAccountLink({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => openUrl('https://app.cherrymusic.com/plan/'),
      child: Text(
        'Create New Account',
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
