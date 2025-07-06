// views/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../main.dart';
import 'auth_tabs.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'story_detail_screen.dart';
import 'add_story_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? user;
  int myStoriesCount = 0;
  bool isLoading = true;
  bool isUploadingImage = false;
  String? photoUrl;
  String? userName;
  
  // تحسين الأداء - إضافة متغيرات للتخزين المؤقت
  DateTime? _lastStoriesFetch;
  static const Duration _cacheDuration = Duration(minutes: 3);

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    photoUrl = user?.photoURL;
    _fetchMyStoriesCount();
    _fetchUserName();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // تحديث عدد القصص عند العودة من شاشة إضافة قصة
    _fetchMyStoriesCount();
  }

  // تحسين الأداء - إضافة timeout وcache للطلبات
  Future<void> _fetchMyStoriesCount() async {
    if (user == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }
    
    // التحقق من التخزين المؤقت
    if (_lastStoriesFetch != null && 
        DateTime.now().difference(_lastStoriesFetch!) < _cacheDuration) {
      return;
    }
    
    try {
      // استخدام StreamBuilder للحصول على التحديثات في الوقت الفعلي
      FirebaseFirestore.instance
          .collection('stories')
          .where('uid', isEqualTo: user!.uid)
          .snapshots()
          .listen((snapshot) {
        if (mounted) {
          setState(() {
            myStoriesCount = snapshot.docs.length;
            isLoading = false;
            _lastStoriesFetch = DateTime.now();
          });
        }
      });
    } catch (e) {
      debugPrint('Error fetching stories count: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchUserName() async {
    if (user == null) return;
    
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get()
          .timeout(const Duration(seconds: 10));
      
      if (doc.exists && doc.data()!.containsKey('name')) {
        if (mounted) {
          setState(() {
            userName = doc.data()!['name'] as String;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching user name: $e');
      // تجاهل الأخطاء، سيتم استخدام displayName من Firebase Auth
    }
  }

  Future<void> _pickAndUploadImage() async {
    // طلب أذونات الكاميرا والتخزين
    final cameraStatus = await Permission.camera.request();
    final storageStatus = await Permission.storage.request();
    if (cameraStatus.isDenied || storageStatus.isDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يجب السماح بأذونات الكاميرا والتخزين لاختيار صورة.')),
        );
      }
      return;
    }
    
    final picker = ImagePicker();
    final picked = await showModalBottomSheet<XFile?>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('التقاط صورة بالكاميرا'),
              onTap: () async {
                final img = await picker.pickImage(
                  source: ImageSource.camera, 
                  imageQuality: 70,
                  maxWidth: 800, // تحسين الأداء - تقليل حجم الصورة
                  maxHeight: 800,
                );
                Navigator.pop(context, img);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('اختيار صورة من المعرض'),
              onTap: () async {
                final img = await picker.pickImage(
                  source: ImageSource.gallery, 
                  imageQuality: 70,
                  maxWidth: 800, // تحسين الأداء - تقليل حجم الصورة
                  maxHeight: 800,
                );
                Navigator.pop(context, img);
              },
            ),
          ],
        ),
      ),
    );
    
    if (picked == null) return;
    
    setState(() => isUploadingImage = true);
    
    try {
      final file = File(picked.path);
      final ref = FirebaseStorage.instance.ref().child('profile_pics/${user!.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      await user!.updatePhotoURL(url);
      
      if (mounted) {
        setState(() {
          photoUrl = url;
          isUploadingImage = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث الصورة الشخصية')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => isUploadingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل رفع الصورة: $e')));
      }
    }
  }

  void _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      setState(() {
        user = null;
        myStoriesCount = 0;
      });
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthTabs()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mainColor = isDark ? Colors.white : const Color(0xFF2C3E50);
    final accentColor = const Color(0xFFC0392B);
    final backgroundColor = isDark ? const Color(0xFF23262F) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF2C3E50);
    final subtitleColor = isDark ? Colors.white70 : const Color(0xFF555555);
    
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // صورة شخصية دائرية كبيرة مع زر كاميرا
                  Center(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.13),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 56,
                            backgroundColor: backgroundColor,
                            child: CircleAvatar(
                              radius: 52,
                              backgroundColor: accentColor,
                              backgroundImage: (photoUrl != null && photoUrl!.isNotEmpty)
                                  ? NetworkImage(photoUrl!)
                                  : null,
                              child: (photoUrl == null || photoUrl!.isEmpty)
                                  ? const Icon(Icons.person, size: 60, color: Colors.white)
                                  : null,
                            ),
                          ),
                        ),
                        if (user != null && !isUploadingImage)
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: _pickAndUploadImage,
                              child: CircleAvatar(
                                radius: 18,
                                backgroundColor: backgroundColor,
                                child: Icon(Icons.camera_alt, color: accentColor, size: 20),
                              ),
                            ),
                          ),
                        if (isUploadingImage)
                          const Positioned.fill(
                            child: Center(child: CircularProgressIndicator()),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  // اسم المستخدم من Firebase
                  Text(
                    userName ?? user?.displayName ?? 'زائر',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 6),
                  // البريد الإلكتروني
                  Text(
                    user?.email ?? 'لم تقم بتسجيل الدخول',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 15, color: subtitleColor),
                  ),
                  const SizedBox(height: 18),
                  // قائمة الإجراءات
                  Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: isDark ? 4 : 2,
                    color: backgroundColor,
                    child: ListTile(
                      leading: const Icon(Icons.edit, color: Color(0xFFC0392B)),
                      title: Text('تعديل الحساب', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: textColor)),
                      trailing: Icon(Icons.arrow_forward_ios, size: 18, color: subtitleColor),
                      onTap: user != null
                          ? () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const ProfileSettingsScreen()),
                              );
                            }
                          : null,
                    ),
                  ),
                  Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: isDark ? 4 : 2,
                    color: backgroundColor,
                    child: ListTile(
                      leading: const Icon(Icons.lock_reset, color: Color(0xFFC0392B)),
                      title: Text('تغيير كلمة المرور', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: textColor)),
                      trailing: Icon(Icons.arrow_forward_ios, size: 18, color: subtitleColor),
                      onTap: user != null
                          ? () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const ProfileSettingsScreen(tabIndex: 1)),
                              );
                            }
                          : null,
                    ),
                  ),
                  Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: isDark ? 4 : 2,
                    color: backgroundColor,
                    child: SwitchListTile(
                      secondary: Icon(
                        isDark ? Icons.light_mode : Icons.dark_mode,
                        color: const Color(0xFFC0392B),
                      ),
                      title: Text(
                        isDark ? 'الوضع الليلي' : 'الوضع النهاري',
                        style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: textColor),
                      ),
                      value: isDark,
                      onChanged: (val) async {
                        themeModeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                        // حفظ الاختيار في التخزين المحلي
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('isDarkMode', val);
                        
                        // عرض رسالة تأكيد
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                val ? 'تم تفعيل الوضع الليلي' : 'تم تفعيل الوضع النهاري',
                                style: const TextStyle(fontFamily: 'Cairo'),
                              ),
                              backgroundColor: const Color(0xFFC0392B),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      activeColor: accentColor,
                    ),
                  ),
                  if (user != null)
                    Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: isDark ? 4 : 2,
                      color: backgroundColor,
                      child: ListTile(
                        leading: const Icon(Icons.logout, color: Color(0xFFC0392B)),
                        title: Text('تسجيل الخروج', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: textColor)),
                        trailing: Icon(Icons.arrow_forward_ios, size: 18, color: subtitleColor),
                        onTap: _signOut,
                      ),
                    ),
                  const SizedBox(height: 24),
                  // عدد القصص فقط بدون زر أو سهم
                  Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: isDark ? 4 : 2,
                    color: backgroundColor,
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC0392B).withOpacity(isDark ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.auto_stories, color: Color(0xFFC0392B)),
                      ),
                      title: Text(
                        'قصصي',
                        style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
                      ),
                      subtitle: Text(
                        myStoriesCount > 0 
                            ? '${myStoriesCount.toString().replaceAll('0', '٠').replaceAll('1', '١').replaceAll('2', '٢').replaceAll('3', '٣').replaceAll('4', '٤').replaceAll('5', '٥').replaceAll('6', '٦').replaceAll('7', '٧').replaceAll('8', '٨').replaceAll('9', '٩')} ${myStoriesCount == 1 ? 'قصة' : 'قصص'}'
                            : 'لا توجد قصص بعد',
                        style: TextStyle(fontFamily: 'Cairo', color: subtitleColor),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
  }
}

class ProfileSettingsScreen extends StatefulWidget {
  final int tabIndex;
  const ProfileSettingsScreen({Key? key, this.tabIndex = 0}) : super(key: key);

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  User? user;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    _nameController.text = user?.displayName ?? '';
    _emailController.text = user?.email ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);
    try {
      if (_nameController.text.trim().isNotEmpty && _nameController.text.trim() != user?.displayName) {
        await user?.updateDisplayName(_nameController.text.trim());
      }
      if (_emailController.text.trim().isNotEmpty && _emailController.text.trim() != user?.email) {
        await user?.updateEmail(_emailController.text.trim());
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث البيانات بنجاح')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    }
    setState(() => isLoading = false);
  }

  Future<void> _changePassword() async {
    if (_passwordController.text.trim().length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('كلمة المرور يجب أن تكون 6 أحرف على الأقل')));
      return;
    }
    setState(() => isLoading = true);
    try {
      await user?.updatePassword(_passwordController.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تغيير كلمة المرور بنجاح')));
      _passwordController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = const Color(0xFFC0392B);
    return Scaffold(
      appBar: AppBar(
        title: const Text('إعدادات الحساب'),
        backgroundColor: isDark ? const Color(0xFF23262F) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF2C3E50),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'الاسم'),
                      validator: (val) => val == null || val.trim().isEmpty ? 'الاسم مطلوب' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
                      validator: (val) => val == null || val.trim().isEmpty ? 'البريد الإلكتروني مطلوب' : null,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _updateProfile,
                      icon: const Icon(Icons.save),
                      label: const Text('حفظ التعديلات'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'كلمة مرور جديدة'),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _changePassword,
                      icon: const Icon(Icons.lock_reset),
                      label: const Text('تغيير كلمة المرور'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class MyStoriesScreen extends StatefulWidget {
  final String userId;
  const MyStoriesScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<MyStoriesScreen> createState() => _MyStoriesScreenState();
}

class _MyStoriesScreenState extends State<MyStoriesScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('قصصي', style: TextStyle(fontFamily: 'Cairo')),
        backgroundColor: isDark ? const Color(0xFF23262F) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF2C3E50),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('stories')
            .where('uid', isEqualTo: widget.userId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.auto_stories_outlined,
                    size: 80,
                    color: Color(0xFFC0392B),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'لا توجد قصص بعد',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 18, color: Color(0xFF2C3E50)),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'ابدأ بمشاركة قصتك مع العالم',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 14, color: Color(0xFF555555)),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AddStoryScreen()),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('أضف قصة جديدة'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC0392B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                    ),
                  ),
                ],
              ),
            );
          }

          final stories = snapshot.data!.docs;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: stories.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final story = stories[index].data() as Map<String, dynamic>;
              final storyId = stories[index].id;
              
              final typeColor = {
                'نجاة': const Color(0xFF2980B9),
                'نزوح': const Color(0xFFF6B93B),
                'شهادة': const Color(0xFFC0392B),
                'أخرى': const Color(0xFF2C3E50),
              };

              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: isDark ? 4 : 2,
                color: isDark ? const Color(0xFF23262F) : Colors.white,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => StoryDetailScreen(
                          storyId: storyId,
                          storyData: story,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: typeColor[story['type']] ?? const Color(0xFF2C3E50),
                              child: Text(
                                story['name'] != null && story['name'].toString().isNotEmpty
                                    ? story['name'].toString().substring(0, 1)
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    story['name'] ?? 'بدون اسم',
                                    style: const TextStyle(
                                      fontFamily: 'Cairo',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Color(0xFF2C3E50),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: (typeColor[story['type']] ?? const Color(0xFF2C3E50)).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      story['type'] ?? 'غير محدد',
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 12,
                                        color: typeColor[story['type']] ?? const Color(0xFF2C3E50),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                                                         Icon(Icons.arrow_forward_ios, size: 16, color: isDark ? Colors.white70 : const Color(0xFF2C3E50)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          story['text'] ?? '',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14,
                            color: Color(0xFF555555),
                            height: 1.4,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (story['timestamp'] != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _formatDate(story['timestamp']),
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              color: Color(0xFF888888),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddStoryScreen()),
          );
        },
        backgroundColor: const Color(0xFFC0392B),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year}';
    }
    return '';
  }
} 