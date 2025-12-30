import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import "package:dosya_paylasimi/file_detail_page.dart";

class FileListPage extends StatefulWidget {
  const FileListPage({super.key});

  @override
  State<FileListPage> createState() => _FileListPageState();
}

class _FileListPageState extends State<FileListPage> {
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  String _formatDateTime(Timestamp? timestamp) {
    if (timestamp == null) return "Bilinmiyor";
    DateTime date = timestamp.toDate();
    return "${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} "
        "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
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
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.black,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white.withOpacity(0.9),
        elevation: 10,
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: () async {
          await FirebaseFirestore.instance.collection("files").add({
            "fileName": "YENİ BELGE",
            "content": "",
            "createdBy": user?.email,
            "lastEditedBy": user?.email,
            "createdAt": Timestamp.now(),
            "updatedAt": Timestamp.now(),
          });
        },
      ),
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
          SafeArea(
            child: Column(
              children: [

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 48),
                      Text("DOSYALAR", style: modernStyle(size: 17, bold: true, spacing: 4)),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white, size: 20),
                        onPressed: () => FirebaseAuth.instance.signOut(),
                      ),
                    ],
                  ),
                ),


                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                          decoration: InputDecoration(
                            hintText: "BELGE VEYA E-POSTA ARA...",
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), letterSpacing: 2, fontSize: 9, fontWeight: FontWeight.w600),
                            prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.4), size: 18),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 18),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),


                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection("files")
                        .orderBy("updatedAt", descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.white24));

                      var docs = snapshot.data!.docs;
                      if (_searchQuery.isNotEmpty) {
                        docs = docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return (data["fileName"] ?? "").toString().toLowerCase().contains(_searchQuery) ||
                                 (data["createdBy"] ?? "").toString().toLowerCase().contains(_searchQuery);
                        }).toList();
                      }

                      if (docs.isEmpty) {
                        return Center(child: Text("SONUÇ BULUNAMADI", style: modernStyle(size: 11, opacity: 0.3, spacing: 2)));
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data = docs[index].data() as Map<String, dynamic>;
                          final docId = docs[index].id;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 15),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => FileDetailPage(fileId: docId, fileName: data["fileName"] ?? "BELGE")));
                              },
                              onLongPress: () => _showRenameDialog(context, docId, data["fileName"] ?? ""),
                              borderRadius: BorderRadius.circular(20),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                (data["fileName"] ?? "İSİMSİZ BELGE").toString().toUpperCase(),
                                                style: modernStyle(size: 14, bold: true, spacing: 1),
                                              ),
                                              const SizedBox(height: 10),
                                              Text("✍️ ${data["lastEditedBy"] ?? "-"}", style: modernStyle(size: 10, opacity: 0.5, spacing: 0.5)),
                                              const SizedBox(height: 2),
                                              Text("📅 ${_formatDateTime(data["updatedAt"])}", style: modernStyle(size: 9, opacity: 0.4, spacing: 0.5)),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                          onPressed: () => _confirmDelete(context, docId),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, String docId) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (context) => Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("EMİN MİSİNİZ?", style: modernStyle(size: 15, bold: true, spacing: 2)),
                      const SizedBox(height: 15),
                      Text("Bu belge kalıcı olarak silinecek.", textAlign: TextAlign.center, style: modernStyle(size: 12, opacity: 0.6, spacing: 0.5)),
                      const SizedBox(height: 25),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: Text("İPTAL", style: modernStyle(size: 11, opacity: 0.5))),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.withOpacity(0.8), shape: const StadiumBorder()),
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text("SİL", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    if (result == true) await FirebaseFirestore.instance.collection("files").doc(docId).delete();
  }

  void _showRenameDialog(BuildContext context, String fileId, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(left: 20, right: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20, top: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("İSİM DEĞİŞTİR", style: modernStyle(size: 15, bold: true, spacing: 2)),
                        const SizedBox(height: 20),
                        TextField(
                          controller: controller,
                          autofocus: true,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.05),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 25),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(onPressed: () => Navigator.pop(context), child: Text("VAZGEÇ", style: modernStyle(size: 11, opacity: 0.5))),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, shape: const StadiumBorder()),
                              onPressed: () async {
                                if (controller.text.trim().isNotEmpty) {
                                  await FirebaseFirestore.instance.collection("files").doc(fileId).update({
                                    "fileName": controller.text.trim().toUpperCase(),
                                    "updatedAt": Timestamp.now(),
                                    "lastEditedBy": FirebaseAuth.instance.currentUser?.email,
                                  });
                                }
                                Navigator.pop(context);
                              },
                              child: const Text("KAYDET", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
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
    _snows = List.generate(35, (_) => _Snow.random(_random));
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 18))..repeat();
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
  factory _Snow.random(Random r) { return _Snow(r.nextDouble(), r.nextDouble(), 0.0004 + r.nextDouble() * 0.0007, 2 + r.nextDouble() * 3, 0.25 + r.nextDouble() * 0.5); }
  void fall() { y += speed; if (y > 1) { y = 0; x = Random().nextDouble(); } }
}

class _SnowPainter extends CustomPainter {
  final List<_Snow> snows;
  _SnowPainter(this.snows);
  @override
  void paint(Canvas canvas, Size size) {
    for (var s in snows) {
      final paint = Paint()..color = Colors.white.withOpacity(s.opacity)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(Offset(s.x * size.width, s.y * size.height), s.size, paint);
    }
  }
  @override
  bool shouldRepaint(_) => true;
}
