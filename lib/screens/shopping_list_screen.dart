import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../globals.dart' as globals;

class ShoppingListScreen extends StatelessWidget {
  const ShoppingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(globals.isThai ? 'รายการที่ต้องซื้อ' : 'Shopping List', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('books')
            .where('userId', isEqualTo: user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator(color: globals.mainColor));

          final docs = snapshot.data!.docs;
          List<Map<String, dynamic>> missingList = [];
          int totalEstimatedCost = 0;

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final String title = data['title'];
            final int maxVol = data['maxVolumes'] ?? 0;
            final List owned = List<int>.from(data['ownedVolumes'] ?? []);
            final int price = data['price'] ?? 0;

            List<int> missingVols = [];
            for (int i = 1; i <= maxVol; i++) {
              if (!owned.contains(i)) {
                missingVols.add(i);
              }
            }

            if (missingVols.isNotEmpty) {
              missingList.add({
                'title': title,
                'missing': missingVols,
                'price': price,
              });
              totalEstimatedCost += (missingVols.length * price);
            }
          }

          if (missingList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded, size: 100, color: Colors.green.shade300),
                  const SizedBox(height: 20),
                  Text(
                    globals.isThai ? "ครบทุกเล่มแล้ว! สุดยอด!" : "Collection Complete!",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // UI Update: Modern Summary Header
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.shopping_bag_outlined, color: Colors.amber, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            globals.isThai 
                              ? "ขาดอีก ${missingList.fold(0, (sum, item) => sum + (item['missing'] as List).length)} เล่ม"
                              : "Missing ${missingList.fold(0, (sum, item) => sum + (item['missing'] as List).length)} vols",
                            style: TextStyle(color: Colors.amber[900], fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "฿$totalEstimatedCost",
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.amber[900]),
                          ),
                          Text(globals.isThai ? "งบประมาณโดยประมาณ" : "Estimated Cost", style: TextStyle(fontSize: 10, color: Colors.amber[800])),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: ListView.builder(
                  itemCount: missingList.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    final item = missingList[index];
                    final List<int> missing = item['missing'];
                    String missingText = missing.join(", ");

                    return Card(
                      elevation: 0,
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(child: Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                                Text("฿${missing.length * (item['price'] as int)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Divider(),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.warning_amber_rounded, size: 16, color: Colors.red[300]),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "${globals.isThai ? 'เล่มที่ขาด' : 'Missing Vols'}: $missingText",
                                    style: TextStyle(color: Colors.red.shade400, height: 1.4),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}