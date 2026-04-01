import 'dart:convert';
import 'dart:typed_data'; // เพิ่มตัวนี้มาแทน dart:io เพื่อจัดการข้อมูลไฟล์
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../globals.dart' as globals;

class VolumeManagerScreen extends StatefulWidget {
  final String docId;
  final String title;
  final List<int> currentOwned;
  final List<int> currentRead; 
  final int currentMax;
  final String currentStatus;
  final String currentNote;
  final String? currentImageUrl;
  final int currentPrice;
  final String currentGenre;
  final Map<String, dynamic> currentSpecificPrices; 

  const VolumeManagerScreen({
    super.key,
    required this.docId,
    required this.title,
    required this.currentOwned,
    this.currentRead = const [], 
    this.currentMax = 50,
    this.currentStatus = 'Ongoing',
    this.currentNote = '',
    this.currentImageUrl,
    this.currentPrice = 0,
    this.currentGenre = 'Other',
    this.currentSpecificPrices = const {}, 
  });

  @override
  State<VolumeManagerScreen> createState() => _VolumeManagerScreenState();
}

class _VolumeManagerScreenState extends State<VolumeManagerScreen> {
  late List<int> _ownedVolumes;
  late List<int> _readVolumes;
  late int _maxVolumes;
  late String _status;
  late String _note;
  late String _title;
  late int _price; 
  late String _genre; 
  late Map<String, int> _specificPrices; 
  
  String? _imageBase64;
  bool _isUploading = false;
  bool _isEditCollectionMode = true; 

  @override
  void initState() {
    super.initState();
    _ownedVolumes = List.from(widget.currentOwned);
    _readVolumes = List.from(widget.currentRead);
    _maxVolumes = widget.currentMax;
    _status = widget.currentStatus;
    _note = widget.currentNote;
    _title = widget.title;
    _price = widget.currentPrice;
    _genre = widget.currentGenre;
    _imageBase64 = widget.currentImageUrl;
    
    _specificPrices = widget.currentSpecificPrices.map((key, value) => MapEntry(key, value as int));
  }

  Future<void> _toggleVolume(int vol) async {
    setState(() {
      if (_isEditCollectionMode) {
        if (_ownedVolumes.contains(vol)) {
          _ownedVolumes.remove(vol);
        } else {
          _ownedVolumes.add(vol);
        }
        _ownedVolumes.sort();
      } else {
        if (_readVolumes.contains(vol)) {
          _readVolumes.remove(vol);
        } else {
          _readVolumes.add(vol);
        }
        _readVolumes.sort();
      }
    });
    _saveData();
  }

  Future<void> _setSpecificPrice(int vol) async {
    int currentVolPrice = _specificPrices[vol.toString()] ?? _price;
    TextEditingController priceCtrl = TextEditingController(text: currentVolPrice.toString());

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("${globals.isThai ? 'ราคาเล่มที่' : 'Price for Vol'} $vol"),
        content: TextField(
          controller: priceCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: globals.isThai ? 'ระบุราคา (บาท)' : 'Enter Price',
            suffixText: "฿",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _specificPrices.remove(vol.toString());
              });
              _saveData();
              Navigator.pop(context);
            },
            child: Text(globals.isThai ? 'ใช้ราคามาตรฐาน' : 'Use Default', style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              int? newPrice = int.tryParse(priceCtrl.text);
              if (newPrice != null) {
                setState(() {
                  _specificPrices[vol.toString()] = newPrice;
                });
                _saveData();
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: globals.mainColor, foregroundColor: Colors.white),
            child: Text(globals.isThai ? 'บันทึก' : 'Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveData() async {
    await FirebaseFirestore.instance.collection('books').doc(widget.docId).update({
      'ownedVolumes': _ownedVolumes,
      'readVolumes': _readVolumes,
      'specificPrices': _specificPrices, 
    });
  }

  int _calculateTotalValue() {
    int total = 0;
    for (int vol in _ownedVolumes) {
      if (_specificPrices.containsKey(vol.toString())) {
        total += _specificPrices[vol.toString()]!;
      } else {
        total += _price;
      }
    }
    return total;
  }

  Future<void> _deleteSeries() async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(globals.isThai ? 'ลบเรื่องนี้?' : "Delete Series?"),
        content: Text(globals.isThai ? 'ยืนยันการลบ?' : "Are you sure?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(globals.isThai ? 'ยกเลิก' : "Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(globals.isThai ? 'ลบ' : "Delete", style: const TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;
    if (confirm) {
      await FirebaseFirestore.instance.collection('books').doc(widget.docId).delete();
      if (mounted) { Navigator.pop(context); Navigator.pop(context); }
    }
  }

  // --- แก้ไขฟังก์ชันอัปโหลดรูปให้รองรับ Web ---
  Future<void> _pickAndSaveImage() async {
    final picker = ImagePicker();
    
    // เลือกและย่อขนาดรูป (สำคัญมากสำหรับ Firestore limit 1MB)
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery, 
      maxWidth: 600,  // จำกัดความกว้าง
      maxHeight: 600, // จำกัดความสูง
      imageQuality: 50 // คุณภาพ 50%
    );

    if (image == null) return;

    setState(() => _isUploading = true);
    
    try {
      // ใช้ readAsBytes() ของ XFile โดยตรง เพื่อให้ทำงานได้ทั้ง Web และ Mobile
      final Uint8List bytes = await image.readAsBytes();
      
      // เช็คขนาดไฟล์อีกรอบ (ถ้าเกิน 800KB เตือนไว้ก่อน เพราะ Base64 จะขนาดเพิ่มขึ้น)
      if (bytes.lengthInBytes > 800000) {
         throw Exception("File size too large for Firestore document");
      }

      String base64String = base64Encode(bytes);
      
      await FirebaseFirestore.instance
          .collection('books')
          .doc(widget.docId)
          .update({'imageUrl': base64String});
      
      setState(() { 
        _imageBase64 = base64String; 
        _isUploading = false; 
      });

    } catch (e) { 
      setState(() => _isUploading = false);
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(globals.isThai ? 'อัปโหลดล้มเหลว: ไฟล์อาจใหญ่เกินไป' : 'Upload Failed: File too large'),
            backgroundColor: Colors.red,
          )
        );
      }
      debugPrint("Error picking image: $e");
    }
  }

  ImageProvider? _getImageProvider(String? imageData) {
    if (imageData == null || imageData.isEmpty) return null;
    try {
      if (imageData.startsWith('http')) return NetworkImage(imageData);
      return MemoryImage(base64Decode(imageData));
    } catch (e) { return null; }
  }

  Future<void> _updateMetadata(String newTitle, int newMax, String newStatus, String newNote, int newPrice, String newGenre) async {
    if (newMax < _maxVolumes) {
      _ownedVolumes.removeWhere((vol) => vol > newMax);
      _readVolumes.removeWhere((vol) => vol > newMax);
      _specificPrices.removeWhere((key, val) => int.parse(key) > newMax);
    }

    setState(() {
      _title = newTitle;
      _maxVolumes = newMax;
      _status = newStatus;
      _note = newNote;
      _price = newPrice;
      _genre = newGenre;
    });

    await FirebaseFirestore.instance.collection('books').doc(widget.docId).update({
      'title': newTitle,
      'maxVolumes': newMax,
      'status': newStatus,
      'note': newNote,
      'price': newPrice,
      'genre': newGenre,
      'ownedVolumes': _ownedVolumes, 
      'readVolumes': _readVolumes,
      'specificPrices': _specificPrices,
    });
  }

  String _getDisplayStatus(String status) {
    if (!globals.isThai) return status;
    if (status == 'Ongoing') return 'ยังไม่จบ';
    if (status == 'Completed') return 'จบแล้ว';
    if (status == 'Hiatus') return 'ดอง';
    return status;
  }

  @override
  Widget build(BuildContext context) {
    int totalValue = _calculateTotalValue();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined), 
            onPressed: _showEditDialog
          )
        ],
      ),
      body: Column(
        children: [
          // UI Update: Information Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.05), spreadRadius: 1, blurRadius: 10, offset: const Offset(0, 5))],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: _pickAndSaveImage,
                  child: Container(
                    width: 90, height: 130,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2))],
                      image: _imageBase64 != null ? DecorationImage(image: _getImageProvider(_imageBase64)!, fit: BoxFit.cover) : null,
                    ),
                    child: _isUploading 
                      ? const Center(child: CircularProgressIndicator(strokeWidth: 2)) 
                      : _imageBase64 == null ? Icon(Icons.add_a_photo_rounded, color: Colors.grey[400]) : null,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: globals.mainColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(_genre, style: TextStyle(fontSize: 12, color: globals.mainColor, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 8),
                      Text("${globals.isThai ? 'สถานะ' : 'Status'}: ${_getDisplayStatus(_status)}", style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text("${globals.isThai ? 'ทั้งหมด' : 'Total'}: $_maxVolumes ${globals.isThai ? 'เล่ม' : 'vols'}"),
                      
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _readVolumes.isEmpty ? 0 : _readVolumes.length / _maxVolumes,
                        backgroundColor: Colors.grey[200],
                        color: Colors.cyan,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${globals.isThai ? 'อ่านแล้ว' : 'Read'}: ${_readVolumes.length}/$_maxVolumes",
                        style: const TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      
                      const SizedBox(height: 8),
                      Text(
                        "฿ $totalValue", 
                        style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold, fontSize: 18)
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          if (_isEditCollectionMode)
            Container(
              width: double.infinity,
              color: Colors.amber.shade50,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lightbulb_outline, size: 16, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text(
                    globals.isThai ? "กดค้างที่เล่มเพื่อแก้ราคาเฉพาะเล่ม" : "Long press a volume to set custom price",
                    style: TextStyle(fontSize: 12, color: Colors.brown.shade700),
                  ),
                ],
              ),
            ),

          // UI Update: Modern Toggle Switch
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              children: [
                Expanded(child: _buildToggleButton(globals.isThai ? "จัดการสต็อก" : "Collection", _isEditCollectionMode, globals.mainColor)),
                Expanded(child: _buildToggleButton(globals.isThai ? "บันทึกการอ่าน" : "Reading", !_isEditCollectionMode, Colors.cyan)),
              ],
            ),
          ),

          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5, crossAxisSpacing: 12, mainAxisSpacing: 12,
              ),
              itemCount: _maxVolumes,
              itemBuilder: (context, index) {
                final int volNum = index + 1;
                final bool isOwned = _ownedVolumes.contains(volNum);
                final bool isRead = _readVolumes.contains(volNum);
                final bool hasCustomPrice = _specificPrices.containsKey(volNum.toString());
                
                // UI Update: Grid Logic สีสันชัดเจน
                Color bgColor = Colors.grey.shade100;
                Color textColor = Colors.grey.shade600;
                Border? border;

                if (isOwned) {
                  bgColor = globals.mainColor;
                  textColor = Colors.white;
                  if (hasCustomPrice) border = Border.all(color: Colors.amberAccent, width: 3);
                } else if (isRead) {
                  bgColor = Colors.cyan.shade50;
                  textColor = Colors.cyan.shade700;
                  border = Border.all(color: Colors.cyan.shade200, width: 2);
                }

                return InkWell(
                  onTap: () => _toggleVolume(volNum),
                  onLongPress: () {
                    if (_isEditCollectionMode) {
                      if (!isOwned) {
                        _toggleVolume(volNum);
                      }
                      _setSpecificPrice(volNum);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12), // Round Square
                      border: border,
                      boxShadow: isOwned ? [BoxShadow(color: globals.mainColor.withValues(alpha: 0.4), blurRadius: 4, offset: const Offset(0, 2))] : null,
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "$volNum", 
                                style: TextStyle(
                                  color: textColor, 
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18
                                )
                              ),
                              if (hasCustomPrice && isOwned)
                                const Icon(Icons.attach_money, size: 14, color: Colors.amberAccent),
                            ],
                          ),
                        ),
                        if (isRead && !_isEditCollectionMode) // Show eye icon only in reading mode if read
                          Positioned(
                            right: 4, bottom: 4,
                            child: Icon(Icons.visibility, size: 14, color: isOwned ? Colors.white70 : Colors.cyan),
                          )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String text, bool isActive, Color activeColor) {
    return GestureDetector(
      onTap: () => setState(() => _isEditCollectionMode = (text == (globals.isThai ? "จัดการสต็อก" : "Collection"))),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isActive ? [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))] : null,
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: isActive ? activeColor : Colors.grey[600], 
              fontWeight: FontWeight.bold
            ),
          ),
        ),
      ),
    );
  }

  void _showEditDialog() {
    final titleCtrl = TextEditingController(text: _title);
    final maxCtrl = TextEditingController(text: _maxVolumes.toString());
    final priceCtrl = TextEditingController(text: _price.toString());
    final noteCtrl = TextEditingController(text: _note);
    String tempStatus = _status;
    String tempGenre = _genre;

    final List<String> genres = [
      'Action', 'Adventure', 'Comedy', 'Drama', 'Fantasy', 
      'Horror', 'Mystery', 'Romance', 'Sci-Fi', 'Slice of Life', 'Sports', 'Other'
    ];
    if (!genres.contains(tempGenre)) tempGenre = 'Other';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(globals.isThai ? 'แก้ไขข้อมูล' : "Edit Series Info"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: titleCtrl, decoration: InputDecoration(labelText: globals.isThai ? 'ชื่อเรื่อง' : "Series Title", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: maxCtrl, 
                          decoration: InputDecoration(labelText: globals.isThai ? 'จำนวนเล่ม' : "Total Vols", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), 
                          keyboardType: TextInputType.number
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: priceCtrl, 
                          decoration: InputDecoration(labelText: globals.isThai ? 'ราคาปกติ' : "Base Price", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), 
                          keyboardType: TextInputType.number
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: tempGenre,
                    decoration: InputDecoration(labelText: globals.isThai ? 'หมวดหมู่' : "Genre", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    items: genres.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                    onChanged: (val) => setDialogState(() => tempGenre = val!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: tempStatus,
                    decoration: InputDecoration(labelText: globals.isThai ? 'สถานะ' : "Status", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    items: [
                      DropdownMenuItem(value: "Ongoing", child: Text(globals.isThai ? "ยังไม่จบ" : "Ongoing")),
                      DropdownMenuItem(value: "Completed", child: Text(globals.isThai ? "จบแล้ว" : "Completed")),
                      DropdownMenuItem(value: "Hiatus", child: Text(globals.isThai ? "ดอง" : "Hiatus")),
                    ],
                    onChanged: (val) => setDialogState(() => tempStatus = val!),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: noteCtrl, decoration: InputDecoration(labelText: globals.isThai ? 'บันทึกช่วยจำ' : "Note", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), maxLines: 2),
                  const SizedBox(height: 20),
                  const Divider(),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      icon: const Icon(Icons.delete_forever, color: Colors.red),
                      label: Text(globals.isThai ? 'ลบเรื่องนี้' : "Delete This Series", style: const TextStyle(color: Colors.red)),
                      onPressed: () { _deleteSeries(); },
                    ),
                  )
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text(globals.isThai ? 'ยกเลิก' : "Cancel", style: const TextStyle(color: Colors.grey))),
              ElevatedButton(
                onPressed: () {
                  int newMax = int.tryParse(maxCtrl.text) ?? _maxVolumes;
                  int newPrice = int.tryParse(priceCtrl.text) ?? _price;
                  if (newMax < 1) newMax = 1;
                  _updateMetadata(titleCtrl.text, newMax, tempStatus, noteCtrl.text, newPrice, tempGenre);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: globals.mainColor, foregroundColor: Colors.white),
                child: Text(globals.isThai ? 'บันทึก' : "Save"),
              ),
            ],
          );
        }
      ),
    );
  }
}