// views/story_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StoryDetailScreen extends StatefulWidget {
  final String storyId;
  final Map<String, dynamic>? storyData;
  const StoryDetailScreen({Key? key, required this.storyId, this.storyData}) : super(key: key);

  @override
  State<StoryDetailScreen> createState() => _StoryDetailScreenState();
}

class _StoryDetailScreenState extends State<StoryDetailScreen> {
  late DocumentReference storyRef;
  Map<String, dynamic>? story;
  bool isLoading = true;
  int likes = 0;
  bool liked = false;
  final TextEditingController _commentController = TextEditingController();
  String? uid;

  @override
  void initState() {
    super.initState();
    storyRef = FirebaseFirestore.instance.collection('stories').doc(widget.storyId);
    uid = FirebaseAuth.instance.currentUser?.uid;
    _loadStory();
    _checkIfLiked();
  }

  Future<void> _checkIfLiked() async {
    if (uid == null) return;
    final doc = await storyRef.collection('likes').doc(uid).get();
    setState(() {
      liked = doc.exists;
    });
  }

  Future<void> _loadStory() async {
    if (widget.storyData != null) {
      setState(() {
        story = widget.storyData;
        isLoading = false;
      });
    } else {
      final doc = await storyRef.get();
      setState(() {
        story = doc.data() as Map<String, dynamic>?;
        isLoading = false;
      });
    }
    _updateLikesCount();
  }

  Future<void> _updateLikesCount() async {
    final snap = await storyRef.collection('likes').get();
    setState(() {
      likes = snap.docs.length;
    });
  }

  Future<void> _likeStory() async {
    if (uid == null) return;
    if (!liked) {
      await storyRef.collection('likes').doc(uid).set({
        'liked': true,
        'timestamp': FieldValue.serverTimestamp(),
      });
      setState(() {
        liked = true;
        likes++;
      });
    } else {
      await storyRef.collection('likes').doc(uid).delete();
      setState(() {
        liked = false;
        likes = likes > 0 ? likes - 1 : 0;
      });
    }
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    await storyRef.collection('comments').add({
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });
    _commentController.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = {
      'نجاة': Color(0xFF2980B9),
      'نزوح': Color(0xFFF6B93B),
      'شهادة': Color(0xFFC0392B),
      'أخرى': Color(0xFF2C3E50),
    };
    String dateString = '';
    if (story != null && story!['timestamp'] != null) {
      final ts = story!['timestamp'];
      DateTime dt;
      if (ts is Timestamp) {
        dt = ts.toDate();
      }
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل القصة'),
      ),
      body: isLoading || story == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: typeColor[story!['type']] ?? const Color(0xFF2C3E50),
                          child: Text(
                            story!['name'] != null && story!['name'].toString().isNotEmpty
                                ? story!['name'].toString().substring(0, 1)
                                : '?',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Cairo'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          story!['name'] ?? '',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          story!['type'] ?? '',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14,
                            color: typeColor[story!['type']] ?? const Color(0xFF2C3E50),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      story!['text'] ?? '',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 16,
                        color: Color(0xFF555555),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(liked ? Icons.favorite : Icons.favorite_border, color: Colors.red),
                          onPressed: _likeStory,
                        ),
                        Text('$likes', style: const TextStyle(fontFamily: 'Cairo', fontSize: 16)),
                        const SizedBox(width: 24),
                        Icon(Icons.comment, color: Color(0xFF2C3E50)),
                        const SizedBox(width: 6),
                        const Text('تعليقات', style: TextStyle(fontFamily: 'Cairo', fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            decoration: InputDecoration(
                              hintText: 'أضف تعليقك...',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _addComment,
                          child: const Text('إرسال'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Text('كل التعليقات:', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    StreamBuilder<QuerySnapshot>(
                      stream: storyRef.collection('comments').orderBy('timestamp', descending: true).snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final comments = snapshot.data!.docs;
                        if (comments.isEmpty) {
                          return const Text('لا توجد تعليقات بعد', style: TextStyle(fontFamily: 'Cairo'));
                        }
                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: comments.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, i) {
                            final data = comments[i].data() as Map<String, dynamic>;
                            return ListTile(
                              leading: const Icon(Icons.person, color: Color(0xFF2C3E50)),
                              title: Text(data['text'] ?? '', style: const TextStyle(fontFamily: 'Cairo')),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 