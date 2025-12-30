import 'dart:async';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  bool isEmailVerified = false;
  bool canResendEmail = false;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    isEmailVerified = FirebaseAuth.instance.currentUser!.emailVerified;

    if (!isEmailVerified) {
      sendVerificationEmail();
      timer = Timer.periodic(
        const Duration(seconds: 3),
        (_) => checkEmailVerified(),
      );
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future checkEmailVerified() async {
    await FirebaseAuth.instance.currentUser!.reload();
    setState(() {
      isEmailVerified = FirebaseAuth.instance.currentUser!.emailVerified;
    });
    if (isEmailVerified) timer?.cancel();
  }

  Future sendVerificationEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      await user.sendEmailVerification();
      setState(() => canResendEmail = false);
      await Future.delayed(const Duration(seconds: 10));
      if (mounted) setState(() => canResendEmail = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata: $e")),
        );
      }
    }
  }

  TextStyle modernStyle({required double size, bool bold = false, double opacity = 1.0, double spacing = 2.0}) {
    return TextStyle(
      fontSize: size,
      fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
      color: Colors.white.withOpacity(opacity),
      letterSpacing: spacing,
      shadows: [
        Shadow(blurRadius: 10, color: Colors.black.withOpacity(0.8), offset: const Offset(0, 2)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [

          Image.asset("assets/images/agac.jpg", fit: BoxFit.cover),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.5),
                  Colors.transparent,
                  Colors.black.withOpacity(0.7)
                ],
              ),
            ),
          ),
          
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  const Icon(Icons.mark_email_read_outlined, size: 70, color: Colors.white, shadows: [Shadow(blurRadius: 20, color: Colors.black45)]),
                  const SizedBox(height: 40),
                  

                  Text("DOĞRULAMA", style: modernStyle(size: 17, bold: true, spacing: 4)),
                  const SizedBox(height: 20),
                  

                  Text(
                    "Devam edebilmek için e-postanıza gönderdiğimiz linke tıklamanız gerekiyor.",
                    textAlign: TextAlign.center,
                    style: modernStyle(size: 14, opacity: 0.7, spacing: 0.5),
                  ),
                  const SizedBox(height: 50),
                  

                  InkWell(
                    onTap: canResendEmail ? sendVerificationEmail : null,
                    borderRadius: BorderRadius.circular(15),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          width: double.infinity,
                          height: 55,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(canResendEmail ? 0.15 : 0.05),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                          ),
                          child: Text(
                            canResendEmail ? "TEKRAR GÖNDER" : "BEKLEYİN...", 
                            style: modernStyle(size: 12, bold: true, spacing: 2).copyWith(shadows: [])
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 35),
                  

                  TextButton(
                    onPressed: () => FirebaseAuth.instance.signOut(),
                    child: Text(
                      "İPTAL VE ÇIKIŞ YAP", 
                      style: modernStyle(size: 10, bold: true, opacity: 0.5, spacing: 1)
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
