import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FileDetailPage extends StatefulWidget {
  final String fileId;
  final String fileName;

  const FileDetailPage({
    super.key,
    required this.fileId,
    required this.fileName,
  });

  @override
  State<FileDetailPage> createState() => _FileDetailPageState();
}

class _FileDetailPageState extends State<FileDetailPage> {
  final TextEditingController _addController = TextEditingController();

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

  Future<void> _addNewParagraph() async {
    if (_addController.text.trim().isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    final text = _addController.text.trim();
    _addController.clear();

    await FirebaseFirestore.instance
        .collection("files")
        .doc(widget.fileId)
        .collection("notes")
        .add({
      "text": text,
      "author": user?.email,
      "lastEditedBy": user?.email,
      "createdAt": FieldValue.serverTimestamp(),
      "isEdited": false,
    });
    
    _updateMainFileTimestamp();
  }

  void _editParagraph(String docId, String currentText, String author, String lastEditedBy, String dateStr) {
    final editController = TextEditingController(text: currentText);
    showDialog(
      context: context,
      useSafeArea: true,
      builder: (context) => Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                left: 20, 
                right: 20, 
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 20
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text("DÜZENLE", style: modernStyle(size: 17, bold: true, spacing: 4)),
                        ),
                        const SizedBox(height: 20),

                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Yazar: $author", style: modernStyle(size: 10, opacity: 0.5, spacing: 1)),
                              const SizedBox(height: 4),
                              Text("Son Düzenleme: $lastEditedBy", style: modernStyle(size: 10, opacity: 0.5, spacing: 1)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: editController,
                          maxLines: 5,
                          minLines: 1,
                          style: const TextStyle(color: Colors.white, fontSize: 15),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.05),
                            hintText: "Metni buraya yazın...",
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () async {
                                await FirebaseFirestore.instance.collection("files").doc(widget.fileId).collection("notes").doc(docId).delete();
                                Navigator.pop(context);
                              },
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text("VAZGEÇ", style: modernStyle(size: 11, bold: true, opacity: 0.6)),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () async {
                                await FirebaseFirestore.instance.collection("files").doc(widget.fileId).collection("notes").doc(docId).update({
                                  "text": editController.text.trim(),
                                  "lastEditedBy": FirebaseAuth.instance.currentUser?.email,
                                  "isEdited": true,
                                });
                                Navigator.pop(context);
                              },
                              child: const Text("GÜNCELLE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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

  void _updateMainFileTimestamp() {
    final user = FirebaseAuth.instance.currentUser;
    FirebaseFirestore.instance.collection("files").doc(widget.fileId).update({
      "updatedAt": FieldValue.serverTimestamp(),
      "lastEditedBy": user?.email,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.fileName, style: modernStyle(size: 16, bold: true, spacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset("assets/images/agac.jpg", fit: BoxFit.cover),
          Container(color: Colors.black.withOpacity(0.55)),
          const SnowOverlay(),
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 110, 20, 20),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Container(
                            width: double.infinity,
                            constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height * 0.7),
                            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 40),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                            ),
                            child: StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection("files")
                                  .doc(widget.fileId)
                                  .collection("notes")
                                  .orderBy("createdAt", descending: false)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.white30));
                                final docs = snapshot.data!.docs;
                                if (docs.isEmpty) return Center(child: Text("Belge henüz boş...", style: modernStyle(size: 13, opacity: 0.3)));

                                return Wrap(
                                  children: docs.map((doc) {
                                    final data = doc.data() as Map<String, dynamic>;
                                    final text = data["text"] ?? "";
                                    final author = data["author"] ?? "";
                                    final lastEditedBy = data["lastEditedBy"] ?? author;
                                    final dateStr = _formatDateTime(data["createdAt"] as Timestamp?);

                                    return Tooltip(
                                      message: "Yazar: $author\nDüzenleyen: $lastEditedBy\n$dateStr",
                                      triggerMode: TooltipTriggerMode.tap,
                                      child: InkWell(
                                        onLongPress: () => _editParagraph(doc.id, text, author, lastEditedBy, dateStr),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 1),
                                          child: Text(text + " ", style: modernStyle(size: 15, opacity: 0.9, spacing: 0.5)),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _addController,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w400),
                              decoration: InputDecoration(
                                hintText: "Metne devam edin...",
                                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13, letterSpacing: 1),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _addNewParagraph,
                            icon: const Icon(Icons.add_circle, color: Colors.white, size: 32),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() { _addController.dispose(); super.dispose(); }
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
