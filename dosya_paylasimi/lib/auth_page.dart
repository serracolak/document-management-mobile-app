import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with SingleTickerProviderStateMixin {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLogin = true;
  bool isLoading = false;
  bool _obscurePassword = true;

  late AnimationController _animationController;
  late Animation<double> _iconScale;
  late Animation<double> _iconOpacity;
  late Animation<double> _iconSlide;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _iconScale = Tween(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _iconOpacity = Tween(begin: 0.6, end: 0.9).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _iconSlide = Tween(begin: -30.0, end: 30.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) return;
    setState(() => isLoading = true);
    try {
      if (isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen bilgilerinizi kontrol edin.")),
      );
    }
    setState(() => isLoading = false);
  }

  Future<void> resetPassword() async {
    if (emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen e-posta adresinizi girin.")),
      );
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: emailController.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sıfırlama e-postası gönderildi.")));
    } catch (_) {}
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
          const SnowOverlay(),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, _) {
                      return Transform.translate(
                        offset: Offset(_iconSlide.value, 0),
                        child: Opacity(
                          opacity: _iconOpacity.value,
                          child: Transform.scale(
                            scale: _iconScale.value,
                            child: const Icon(
                              Icons.folder_shared_outlined, 
                              size: 70, 
                              color: Colors.white,
                              shadows: [Shadow(blurRadius: 20, color: Colors.black45)],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                  Text(
                    isLogin ? "GİRİŞ YAP" : "KAYIT OL", 
                    style: modernStyle(size: 17, bold: true, spacing: 4)
                  ),
                  const SizedBox(height: 60),
                  
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Column(
                      children: [
                        TextField(
                          controller: emailController,
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w400),
                          decoration: InputDecoration(
                            hintText: "E-POSTA",

                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.7), letterSpacing: 4, fontSize: 10, fontWeight: FontWeight.w600),

                            prefixIcon: Icon(Icons.mail_outline, color: Colors.white.withOpacity(0.8), size: 18),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 22),
                          ),
                        ),
                        Container(height: 1, color: Colors.white.withOpacity(0.1)),
                        TextField(
                          controller: passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w400),
                          decoration: InputDecoration(
                            hintText: "ŞİFRE",

                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.7), letterSpacing: 4, fontSize: 10, fontWeight: FontWeight.w600),

                            prefixIcon: Icon(Icons.lock_open, color: Colors.white.withOpacity(0.8), size: 18),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, 
                                  color: Colors.white.withOpacity(0.7), size: 16),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 22),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  InkWell(
                    onTap: isLoading ? null : submit,
                    borderRadius: BorderRadius.circular(15),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          width: double.infinity,
                          height: 60,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                          ),
                          child: isLoading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text(
                                  isLogin ? "DEVAM ET" : "HESAP AÇ", 
                                  style: modernStyle(size: 13, bold: true, spacing: 4).copyWith(shadows: [])
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 45),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: resetPassword, 
                        child: Text("ŞİFREMİ UNUTTUM", style: modernStyle(size: 10, bold: true, opacity: 0.6, spacing: 1))
                      ),
                      TextButton(
                        onPressed: () => setState(() => isLogin = !isLogin), 
                        child: Text(isLogin ? "KAYIT OL" : "GİRİŞ YAP", style: modernStyle(size: 11, bold: true, opacity: 0.9, spacing: 1))
                      ),
                    ],
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

class SnowOverlay extends StatefulWidget {
  const SnowOverlay({super.key});
  @override
  State<SnowOverlay> createState() => _SnowOverlayState();
}

class _SnowOverlayState extends State<SnowOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random();
  late List<_Snow> _snows;
  @override
  void initState() {
    super.initState();
    _snows = List.generate(40, (_) => _Snow.random(_random));
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 15))..repeat();
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(animation: _controller, builder: (_, __) { for (var s in _snows) { s.fall(); } return CustomPaint(painter: _SnowPainter(_snows), size: Size.infinite); });
  }
}

class _Snow {
  double x, y, speed, size, opacity;
  _Snow(this.x, this.y, this.speed, this.size, this.opacity);
  factory _Snow.random(Random r) { return _Snow(r.nextDouble(), r.nextDouble(), 0.0005 + r.nextDouble() * 0.001, 2 + r.nextDouble() * 3, 0.3 + r.nextDouble() * 0.5); }
  void fall() { y += speed; if (y > 1) { y = 0; x = Random().nextDouble(); } }
}

class _SnowPainter extends CustomPainter {
  final List<_Snow> snows;
  _SnowPainter(this.snows);
  @override
  void paint(Canvas canvas, Size size) {
    for (var s in snows) {
      final paint = Paint()..color = Colors.white.withOpacity(s.opacity)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(Offset(s.x * size.width, s.y * size.height), s.size, paint);
    }
  }
  @override
  bool shouldRepaint(_) => true;
}
