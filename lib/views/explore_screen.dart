// views/explore_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'story_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({Key? key}) : super(key: key);

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  String _searchQuery = '';
  String? _selectedType = 'الكل';
  final List<String> _storyTypes = ['الكل', 'نجاة', 'نزوح', 'شهادة', 'أخرى'];
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF2C3E50);
    final cardColor = isDark ? const Color(0xFF23262F) : Colors.white;
    final subtitleColor = isDark ? Colors.white70 : const Color(0xFF2C3E50);
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, left: 24, right: 24, bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'قصص الناجين',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                  color: const Color(0xFFC0392B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'حيث يلتقي الألم بالأمل... اقرأ حكايات حقيقية من قلب المعاناة',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  color: subtitleColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // البحث والفلترة في صف واحد
              Row(
                children: [
                  // البحث
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'ابحث باسم صاحب القصة...',
                        prefixIcon: Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _searchQuery = '';
                                    _searchController.clear();
                                  });
                                },
                              )
                            : null,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // الفلترة
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration: InputDecoration(
                        labelText: 'النوع',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: cardColor,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      ),
                      items: _storyTypes.map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type, style: const TextStyle(fontFamily: 'Cairo')),
                      )).toList(),
                      onChanged: (val) => setState(() => _selectedType = val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('stories')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('لا توجد قصص بعد', style: TextStyle(fontFamily: 'Cairo')));
              }
              final docs = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = (data['name'] ?? '').toString();
                final type = (data['type'] ?? '').toString();
                final matchesSearch = _searchQuery.isEmpty || name.contains(_searchQuery);
                final matchesType = (_selectedType == null || _selectedType == 'الكل') || type == _selectedType;
                final text = data['text'];
                final isText = text != null && (text as String).trim().isNotEmpty;
                return matchesSearch && matchesType && isText;
              }).toList();
              if (docs.isEmpty) {
                return const Center(child: Text('لا توجد نتائج مطابقة', style: TextStyle(fontFamily: 'Cairo')));
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  final name = data['name'] ?? 'بدون اسم';
                  final type = data['type'] ?? 'غير محدد';
                  final text = data['text'];
                  final docId = docs[i].id;
                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => StoryDetailScreen(
                            storyData: data,
                            storyId: docId,
                          ),
                        ),
                      );
                    },
                    child: Card(
                      color: cardColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: isDark ? 4 : 3,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.edit,
                                  color: textColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  name,
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: textColor,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE3F0FF),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(type, style: TextStyle(fontFamily: 'Cairo', color: textColor, fontSize: 13)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10.0),
                              child: Text(
                                text,
                                style: TextStyle(fontFamily: 'Cairo', fontSize: 15, color: textColor),
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Row(
                              children: [
                                Flexible(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2C3E50),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                    ),
                                    icon: const Icon(Icons.chrome_reader_mode),
                                    label: const Text('قراءة'),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Text('القصة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                                          content: Text(text, style: TextStyle(fontFamily: 'Cairo')),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(context).pop(),
                                              child: const Text('إغلاق'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
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
    );
  }
} 