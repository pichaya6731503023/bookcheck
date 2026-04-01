import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../globals.dart' as globals;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _register() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(globals.isThai ? "รหัสผ่านไม่ตรงกัน" : "Passwords do not match")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(globals.isThai ? "สร้างบัญชีสำเร็จ! กรุณาเข้าสู่ระบบ" : "Account created! Please login.")),
        );
        Navigator.pop(context); 
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? (globals.isThai ? 'สมัครสมาชิกไม่สำเร็จ' : 'Registration failed'))),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(globals.isThai ? "สมัครสมาชิก" : "Register", style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              globals.isThai ? "สร้างบัญชีใหม่" : "Create Account",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: globals.mainColor),
            ),
            const SizedBox(height: 8),
            Text(
              globals.isThai ? "กรอกข้อมูลเพื่อเริ่มต้นใช้งาน" : "Please fill in the details to get started.",
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 40),

            _buildTextField(_emailController, globals.isThai ? 'อีเมล' : 'Email', Icons.email_outlined, false),
            const SizedBox(height: 20),
            _buildTextField(_passwordController, globals.isThai ? 'รหัสผ่าน' : 'Password', Icons.lock_outline, true),
            const SizedBox(height: 20),
            // แก้ไขตรงนี้ครับ เปลี่ยนจาก Icons.lock_check เป็น Icons.check_circle_outline
            _buildTextField(_confirmPasswordController, globals.isThai ? 'ยืนยันรหัสผ่าน' : 'Confirm Password', Icons.check_circle_outline, true),
            
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                   backgroundColor: globals.mainColor,
                   foregroundColor: Colors.white,
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                   elevation: 2,
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : Text(globals.isThai ? "สร้างบัญชี" : "Create Account", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, bool obscure) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        filled: true,
        fillColor: Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
      obscureText: obscure,
    );
  }
}