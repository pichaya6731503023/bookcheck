import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'volume_manager_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import '../globals.dart' as globals;

class HomeScreen extends StatefulWidget {
  final bool isGuest;
  const HomeScreen({super.key, this.isGuest = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CollectionReference booksCollection = FirebaseFirestore.instance.collection('books');
  final TextEditingController _searchController = TextEditingController();
  String _searchText = "";
  String _sortBy = 'createdAt';

  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchText = _searchController.text.toLowerCase().trim());
    });
  }

  // --- แก้ไขบั๊กตรงนี้: ระบุ Type ให้ชัดเจนและดัก Error ---
  Future<void> _addSeries(String title) async {
    if (widget.isGuest || currentUserId == null) return;
    
    try {
      await booksCollection.add({
        'title': title,
        'ownedVolumes': <int>[], // ระบุ <int> ให้ชัดเจน
        'readVolumes': <int>[],  // ระบุ <int> ให้ชัดเจน
        'userId': currentUserId,
        'status': 'Ongoing',
        'maxVolumes': 50,
        'note': '',
        'imageUrl': null,
        'price': 0,
        'genre': 'Other', 
        'specificPrices': <String, dynamic>{}, // ระบุ <String, dynamic> ป้องกันพัง
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  ImageProvider? _getImageProvider(String? imageData) {
    if (imageData == null || imageData.isEmpty) return null;
    try {
      if (imageData.startsWith('http')) return NetworkImage(imageData);
      return MemoryImage(base64Decode(imageData));
    } catch (e) { return null; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.isGuest 
            ? (globals.isThai ? 'โหมดผู้เยี่ยมชม' : 'Guest Mode') 
            : (globals.isThai ? 'คลังหนังสือของฉัน' : 'My Collection'),
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 2,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort_rounded, color: Colors.black87),
            onSelected: (value) => setState(() => _sortBy = value),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            itemBuilder: (context) => [
              PopupMenuItem(value: 'createdAt', child: Text(globals.isThai ? "ใหม่ล่าสุด" : "Newest First")),
              PopupMenuItem(value: 'title', child: Text(globals.isThai ? "ชื่อเรื่อง (ก-ฮ)" : "Title (A-Z)")),
            ],
          ),
          IconButton(
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: globals.mainColor.withValues(alpha: 0.1),
              child: Icon(Icons.person, size: 20, color: globals.mainColor),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              ).then((_) {
                setState(() {});
              });
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))]
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: globals.isThai ? 'ค้นหาชื่อ, หมวดหมู่, สถานะ...' : 'Search title, genre, status...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
                  suffixIcon: _searchText.isNotEmpty 
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() { _searchText = ""; });
                        },
                      )
                    : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  fillColor: Colors.white, filled: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                ),
              ),
            ),
          ),
        ),
      ),
      body: widget.isGuest ? _buildGuestView() : _buildUserView(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (widget.isGuest) {
             showDialog(
              context: context,
              builder: (c) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: Text(globals.isThai ? 'กรุณาเข้าสู่ระบบ' : 'Login Required', style: const TextStyle(fontWeight: FontWeight.bold)),
                content: Text(globals.isThai ? 'คุณอยู่ในโหมดผู้เยี่ยมชม กรุณาเข้าสู่ระบบเพื่อบันทึกข้อมูล' : 'You are in Guest Mode. Please login to save your collection.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(c), child: Text(globals.isThai ? 'ตกลง' : 'OK', style: const TextStyle(color: Colors.grey))),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(c);
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: globals.mainColor, foregroundColor: Colors.white),
                    child: Text(globals.isThai ? 'ไปหน้าเข้าสู่ระบบ' : 'Go to Login'),
                  )
                ],
              ),
            );
          } else {
            _showAddDialog();
          }
        },
        backgroundColor: widget.isGuest ? Colors.grey : globals.mainColor,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: Text(globals.isThai ? 'เพิ่มเรื่อง' : 'Add Series', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildGuestView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            globals.isThai ? 'โหมดผู้เยี่ยมชม' : 'Guest Mode',
            style: TextStyle(fontSize: 18, color: Colors.grey[500], fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildUserView() {
    return StreamBuilder<QuerySnapshot>(
      stream: booksCollection.where('userId', isEqualTo: currentUserId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: globals.mainColor));
        
        // --- แก้ไขบั๊กตรงนี้: เติม .toList() เพื่อไม่ให้เกิด Error เวลาเรียงลำดับข้อมูล ---
        var docs = snapshot.data?.docs.toList() ?? [];
        
        if (_searchText.isNotEmpty) {
          docs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            
            final title = (data['title'] ?? '').toString().toLowerCase();
            final genre = (data['genre'] ?? '').toString().toLowerCase();
            final rawStatus = (data['status'] ?? '').toString();
            final statusLower = rawStatus.toLowerCase(); 
            final note = (data['note'] ?? '').toString().toLowerCase();

            String statusKeywords = ""; 
            if (statusLower == 'ongoing') statusKeywords = "ยังไม่จบ ongoing";
            if (statusLower == 'completed') statusKeywords = "จบแล้ว จบ บริบูรณ์ completed"; 
            if (statusLower == 'hiatus') statusKeywords = "ดอง หยุด hiatus";

            final searchableText = "$title $genre $statusLower $statusKeywords $note";

            return searchableText.contains(_searchText);
          }).toList();
        }

        docs.sort((a, b) {
          final dataA = a.data() as Map<String, dynamic>;
          final dataB = b.data() as Map<String, dynamic>;
          if (_sortBy == 'title') {
            return dataA['title'].toString().compareTo(dataB['title'].toString());
          } else {
            final timeA = (dataA['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
            final timeB = (dataB['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
            return timeB.compareTo(timeA);
          }
        });

        if (docs.isEmpty) return Center(child: Text(globals.isThai ? 'ไม่พบข้อมูล' : 'No books found.', style: TextStyle(color: Colors.grey[500])));

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final List owned = data['ownedVolumes'] ?? [];
            final List read = data['readVolumes'] ?? []; 
            final String status = data['status'] ?? 'Ongoing';
            final String? imageUrl = data['imageUrl'];
            final String genre = data['genre'] ?? 'Other'; 
            final Map<String, dynamic> specificPrices = data['specificPrices'] ?? {};

            String displayStatus = status;
            Color statusColor = Colors.green;
            Color statusBg = Colors.green.shade50;

            if (globals.isThai) {
              if (status == 'Ongoing') { displayStatus = 'ยังไม่จบ'; statusColor = Colors.blue; statusBg = Colors.blue.shade50; }
              if (status == 'Completed') { displayStatus = 'จบแล้ว'; statusColor = Colors.red; statusBg = Colors.red.shade50; }
              if (status == 'Hiatus') { displayStatus = 'ดอง'; statusColor = Colors.orange; statusBg = Colors.orange.shade50; }
            } else {
               if (status == 'Ongoing') { statusColor = Colors.blue; statusBg = Colors.blue.shade50; }
               if (status == 'Completed') { statusColor = Colors.red; statusBg = Colors.red.shade50; }
               if (status == 'Hiatus') { statusColor = Colors.orange; statusBg = Colors.orange.shade50; }
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), spreadRadius: 1, blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => VolumeManagerScreen(
                      docId: doc.id, 
                      title: data['title'], 
                      currentOwned: List<int>.from(owned),
                      currentRead: List<int>.from(read), 
                      currentMax: data['maxVolumes'] ?? 50, 
                      currentStatus: status, 
                      currentNote: data['note'] ?? '', 
                      currentImageUrl: imageUrl,
                      currentPrice: data['price'] ?? 0,
                      currentGenre: genre, 
                      currentSpecificPrices: specificPrices,
                    )));
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 60, height: 85,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200, 
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)],
                            image: imageUrl != null ? DecorationImage(image: _getImageProvider(imageUrl)!, fit: BoxFit.cover) : null,
                          ),
                          child: imageUrl == null ? Center(child: Text(data['title'][0].toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[500]))) : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: Text(genre, style: TextStyle(fontSize: 10, color: Colors.grey[700], fontWeight: FontWeight.w500)),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: statusBg,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(displayStatus, style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(Icons.library_books_rounded, size: 14, color: globals.mainColor),
                                  const SizedBox(width: 4),
                                  Text("${owned.length} ${globals.isThai ? 'เล่ม' : 'vols'}", style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                                  const SizedBox(width: 12),
                                  const Icon(Icons.visibility_rounded, size: 14, color: Colors.cyan),
                                  const SizedBox(width: 4),
                                  Text("${globals.isThai ? 'อ่าน' : 'Read'}: ${read.length}", style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  void _showAddDialog() {
      final controller = TextEditingController();
      showDialog(context: context, builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(globals.isThai ? 'เพิ่มเรื่องใหม่' : 'New Series', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller, 
          autofocus: true, 
          decoration: InputDecoration(
            hintText: globals.isThai ? 'ชื่อเรื่อง (เช่น นารูโตะ)' : 'Title (e.g. Naruto)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey[50],
          )
        ),
        actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(globals.isThai ? 'ยกเลิก' : 'Cancel', style: const TextStyle(color: Colors.grey))),
            ElevatedButton(
              onPressed: (){ 
                if(controller.text.isNotEmpty) { _addSeries(controller.text); Navigator.pop(context); } 
              }, 
              style: ElevatedButton.styleFrom(backgroundColor: globals.mainColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: Text(globals.isThai ? 'เพิ่ม' : 'Add')
            )
        ],
      ));
  }
}