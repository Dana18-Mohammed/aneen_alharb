// views/add_story_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddStoryScreen extends StatefulWidget {
  const AddStoryScreen({Key? key}) : super(key: key);

  @override
  State<AddStoryScreen> createState() => _AddStoryScreenState();
}

class _AddStoryScreenState extends State<AddStoryScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final _formKeyText = GlobalKey<FormState>();
  String? _selectedType;
  final List<String> _storyTypes = ['نجاة', 'نزوح', 'شهادة', 'أخرى'];
  bool _isLoading = false;

  @override
  void dispose() {
    _textController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submitStory() async {
    if (!_formKeyText.currentState!.validate() || _selectedType == null) return;
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('stories').add({
        'name': _nameController.text.trim(),
        'text': _textController.text.trim(),
        'type': _selectedType,
        'uid': user?.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء إرسال القصة. حاول مرة أخرى.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF181A20) : const Color(0xFFFAF3E0);
    final mainColor = isDark ? Colors.white : const Color(0xFF2C3E50);
    final accentColor = const Color(0xFFC0392B);
    final cardColor = isDark ? const Color(0xFF23262F) : Colors.white;
    return Scaffold(
      appBar: AppBar(
        title: const Text('احكي قصتك', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        backgroundColor: backgroundColor,
        foregroundColor: mainColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: mainColor),
      ),
      body: Container(
        color: backgroundColor,
        child: Form(
          key: _formKeyText,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'اسمك',
                    labelStyle: TextStyle(color: mainColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: Icon(Icons.person, color: mainColor),
                    filled: true,
                    fillColor: cardColor,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'الاسم مطلوب';
                    }
                    return null;
                  },
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: InputDecoration(
                    labelText: 'نوع القصة',
                    labelStyle: TextStyle(color: mainColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: cardColor,
                    prefixIcon: Icon(Icons.category, color: mainColor),
                  ),
                  items: _storyTypes.map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(type, style: TextStyle(color: mainColor)),
                  )).toList(),
                  onChanged: (val) => setState(() => _selectedType = val),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى اختيار نوع القصة';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: TextFormField(
                    controller: _textController,
                    maxLines: null,
                    expands: true,
                    decoration: InputDecoration(
                      hintText: 'اكتب قصتك هنا...',
                      filled: true,
                      fillColor: cardColor,
                      hintStyle: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF555555)),
                    ),
                    textDirection: TextDirection.rtl,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'يرجى كتابة القصة';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send),
                    label: const Text('إرسال القصة'),
                    onPressed: _isLoading ? null : _submitStory,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 