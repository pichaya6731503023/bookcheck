import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import '../globals.dart' as globals;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? (globals.isThai ? 'เข้าสู่ระบบล้มเหลว' : 'Login failed'))),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _guestLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen(isGuest: true)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // UI Update: ใช้ Gradient Background
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [globals.mainColor.withValues(alpha: 0.8), globals.mainColor.withValues(alpha: 0.1), Colors.white],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 8, // UI Update: เพิ่มเงาให้นุ่มขึ้น
              shadowColor: Colors.black26,
              surfaceTintColor: Colors.white,
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), // UI Update: มุมโค้งมากขึ้น
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: globals.mainColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.menu_book_rounded, size: 48, color: globals.mainColor),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      globals.isThai ? "ยินดีต้อนรับสู่ Bookcheck" : "Welcome to Bookcheck",
                      style: TextStyle(
                        fontSize: 22, 
                        fontWeight: FontWeight.bold, 
                        color: Colors.grey[800],
                        letterSpacing: 0.5
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    
                    // UI Update: ช่องกรอกข้อมูลแบบ Modern
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: globals.isThai ? 'อีเมล' : 'Email',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: globals.isThai ? 'รหัสผ่าน' : 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 32),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 52, // UI Update: ปุ่มสูงขึ้น
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: globals.mainColor,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(globals.isThai ? "เข้าสู่ระบบ" : "Login", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RegisterScreen()),
                        );
                      },
                      child: Text(
                        globals.isThai ? "ยังไม่มีบัญชี? สมัครสมาชิก" : "Don't have an account? Register",
                        style: TextStyle(color: globals.mainColor, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(),
                    ),
                    
                    TextButton.icon(
                      onPressed: _guestLogin,
                      icon: Icon(Icons.person_outline, color: Colors.grey[600]),
                      label: Text(
                        globals.isThai ? "ใช้งานแบบผู้เยี่ยมชม" : "Continue as Guest", 
                        style: TextStyle(color: Colors.grey[600])
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}