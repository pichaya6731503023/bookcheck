import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'login_screen.dart';
import 'shopping_list_screen.dart'; 
import '../globals.dart' as globals;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _sendEmail(String message) async {
    final String supportEmail = 'support@bookcheck.com'; 
    final String subject = globals.isThai 
        ? 'แจ้งปัญหาการใช้งาน Bookcheck' 
        : 'Bookcheck Support Request';

    final String body = "User ID: ${user?.uid ?? 'Guest'}\n\n"
        "----------------------------------------\n"
        "${globals.isThai ? 'รายละเอียดปัญหา:' : 'Issue Description:'}\n"
        "$message\n"
        "----------------------------------------";

    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: supportEmail,
      query: _encodeQueryParameters(<String, String>{
        'subject': subject,
        'body': body,
      }),
    );

    try {
      await launchUrl(emailLaunchUri);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not launch email app: $e")),
        );
      }
    }
  }

  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  void _showReportDialog() {
    final messageCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(globals.isThai ? 'ช่วยเหลือและแจ้งปัญหา' : 'Help & Support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(globals.isThai 
              ? 'กรุณากรอกรายละเอียดปัญหา ทีมงานจะตอบกลับทางอีเมล' 
              : 'Please describe your issue. We will reply via email.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: messageCtrl,
              decoration: InputDecoration(
                hintText: globals.isThai ? 'พิมพ์ข้อความที่นี่...' : 'Type here...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true, fillColor: Colors.grey[50],
              ),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(globals.isThai ? 'ยกเลิก' : 'Cancel', style: const TextStyle(color: Colors.grey))),
          ElevatedButton.icon(
            icon: const Icon(Icons.email),
            label: Text(globals.isThai ? 'ส่งอีเมล' : 'Send Email'),
            onPressed: () {
              if (messageCtrl.text.isNotEmpty) {
                Navigator.pop(context);
                _sendEmail(messageCtrl.text);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: globals.mainColor, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  void _showMoreMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 24),
                  _buildMenuItem(
                    Icons.language, Colors.blue, 
                    globals.isThai ? 'เปลี่ยนภาษา' : 'Change Language',
                    globals.isThai ? 'ไทย' : 'English',
                    () async {
                      Navigator.pop(context);
                      await showDialog(
                        context: context,
                        builder: (context) => _buildLanguageDialogContent(),
                      );
                      setState(() {});
                    }
                  ),
                  const SizedBox(height: 12),
                  _buildMenuItem(
                    Icons.mail_outline, Colors.orange, 
                    globals.isThai ? 'ช่วยเหลือ (ส่งอีเมล)' : 'Help & Support (Email)',
                    null,
                    () {
                      Navigator.pop(context);
                      _showReportDialog();
                    }
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  _buildMenuItem(
                    Icons.logout, Colors.red, 
                    globals.isThai ? 'ออกจากระบบ' : 'Logout',
                    null,
                    () {
                      Navigator.pop(context);
                      _logout();
                    },
                    isDestructive: true
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }
  
  Widget _buildMenuItem(IconData icon, Color color, String title, String? subtitle, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isDestructive ? Colors.red : Colors.black87)),
      subtitle: subtitle != null ? Text(subtitle) : null,
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: Colors.grey[50],
    );
  }
  
  Widget _buildLanguageDialogContent() {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(globals.isThai ? 'เปลี่ยนภาษา' : 'Change Language'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text("English"),
            leading: Radio(
                value: false,
                groupValue: globals.isThai,
                activeColor: globals.mainColor,
                onChanged: (val) async {
                  await globals.saveLanguage(false);
                  setState(() {});
                  if (mounted) Navigator.pop(context);
                }),
          ),
          ListTile(
            title: const Text("Thai (ไทย)"),
            leading: Radio(
                value: true,
                groupValue: globals.isThai,
                activeColor: globals.mainColor,
                onChanged: (val) async {
                  await globals.saveLanguage(true);
                  setState(() {});
                  if (mounted) Navigator.pop(context);
                }),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(globals.isThai ? 'โปรไฟล์' : 'Profile', style: const TextStyle(fontWeight: FontWeight.bold)), 
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: _showMoreMenu,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(4), // Border
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: globals.mainColor.withOpacity(0.2), width: 2)),
              child: CircleAvatar(
                radius: 40,
                backgroundColor: globals.mainColor,
                child: const Icon(Icons.person, size: 40, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            Text(user?.email ?? (globals.isThai ? "ผู้เยี่ยมชม" : "Guest User"), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('books')
                  .where('userId', isEqualTo: user?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator(color: globals.mainColor));

                final docs = snapshot.data!.docs;
                int totalSeries = docs.length;
                int totalVolumes = 0;
                int totalValue = 0;

                for (var doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final List owned = data['ownedVolumes'] ?? [];
                  final int defaultPrice = data['price'] ?? 0;
                  final Map<String, dynamic> specificPrices = data['specificPrices'] ?? {};
                  
                  totalVolumes += owned.length;
                  
                  for (var vol in owned) {
                    if (specificPrices.containsKey(vol.toString())) {
                      totalValue += (specificPrices[vol.toString()] as int);
                    } else {
                      totalValue += defaultPrice;
                    }
                  }
                }

                return Column(
                  children: [
                    Row(
                      children: [
                        _buildStatCard(
                          globals.isThai ? 'จำนวนเรื่อง' : 'Series', 
                          "$totalSeries", 
                          Icons.library_books_outlined, 
                          Colors.blue,
                        ),
                        const SizedBox(width: 16),
                        _buildStatCard(
                          globals.isThai ? 'จำนวนเล่ม' : 'Volumes', 
                          "$totalVolumes", 
                          Icons.layers_outlined, 
                          Colors.green,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.amber.shade400, Colors.amber.shade700]),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))]
                      ),
                      child: Column(
                        children: [
                          Text(globals.isThai ? 'มูลค่าของสะสม' : 'Collection Value', style: const TextStyle(color: Colors.white, fontSize: 14)),
                          const SizedBox(height: 8),
                          Text("฿$totalValue", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // --- ปุ่ม Shopping List ---
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                        label: Text(
                          globals.isThai ? 'รายการที่ต้องซื้อ' : 'Shopping List',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal, 
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          elevation: 4,
                          shadowColor: Colors.teal.withOpacity(0.4),
                        ),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const ShoppingListScreen()));
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String count, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), spreadRadius: 2, blurRadius: 10)],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(count, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
      ),
    );
  }
}