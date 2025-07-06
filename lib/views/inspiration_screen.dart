// views/inspiration_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';

class InspirationScreen extends StatefulWidget {
  const InspirationScreen({Key? key}) : super(key: key);

  @override
  State<InspirationScreen> createState() => _InspirationScreenState();
}

class _InspirationScreenState extends State<InspirationScreen> {
  int _storiesCount = 0;
  String _quote = '';
  String? _randomImageUrl;
  bool _isLoadingImage = false;
  String _lastQuote = '';
  bool _isOfflineMode = false;
  
  // تحسين الأداء - تخزين مؤقت للصور
  static const Map<String, String> _cachedImages = {
    'peace': 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400&h=400&fit=crop&q=80',
    'olive': 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=400&h=400&fit=crop&q=80',
    'jerusalem': 'https://images.unsplash.com/photo-1542810634-71277d95dcbb?w=400&h=400&fit=crop&q=80',
    'hope': 'https://images.unsplash.com/photo-1518837695005-2083093ee35b?w=400&h=400&fit=crop&q=80',
    'mediterranean': 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=400&h=400&fit=crop&q=80',
  };
  
  final List<String> _quotes = [
    'الأمل هو أن تزرع زهرة في صحراء الألم.',
    'من قلب المعاناة يولد الإبداع.',
    'كل قصة نجاة هي رسالة أمل للعالم.',
    'الصمود هو أن تبتسم رغم الدموع.',
    'لا شيء أقوى من إنسان لم يفقد الأمل.',
    'قصصنا نور في عتمة الطريق.',
    'من غزة... نكتب الحياة من جديد.',
    'الأمل هو النور الذي لا ينطفئ مهما طال الظلام.',
    'في قلب الألم يولد السلام.',
    'الصبر مفتاح الفرج، والكرامة تاج الحياة.',
    'كل زهرة تتفتح رغم العواصف.',
    'قصة كل نازح تحمل صوت إنسان لا يموت.',
    'الحرية تبدأ بحلم صغير في قلب مظلم.',
    'الأرض التي تُروى بالدم ليست إلا أرض حياة.',
    'لن تُكسر الروح التي تعرف طريق النور.',
    'الصمود هو أجمل قصيدة تكتبها الأرواح.',
    'في وجوه الأطفال نرى المستقبل رغم الحزن.',
    'الحرب تقتل الجسد، لكن لا تقتل الإرادة.',
    'الصوت الذي لا يسمع لا يعني أنه غير موجود.',
    'كل قصة تحمل رسالة، وكل رسالة تبني جسراً.',
    'نحن نزرع السلام في تربة الألم.',
    'كل دمعة تروي قصة أمل جديد.',
    'العدالة ليست حلماً بعيداً، بل حقاً يستحق النضال.',
    'حتى في الظلام الدامس، هناك نجوم تضيء الطريق.',
    'أصواتنا ستظل ترتفع فوق صوت القصف.',
    'الحب هو السلاح الذي لا ينفد.',
    'كل نهاية مؤلمة تفتح أبواب بداية جديدة.',
    'شجاعة القلب تصنع المعجزات.',
    'أرواح الشهداء تحلق فوق السماء لتحرسنا.',
    'لن نسقط طالما نحن معاً.',
    'الذاكرة حكاية لا تموت.',
    'من رحم المعاناة يولد السلام.',
    'الأطفال هم زهور الحياة التي لا تموت.',
    'القصة التي تُروى تبقى حية في النفوس.',
    'لن ننسى ولن ننسى أبداً.',
    'الوحدة قوة، والصمود رسالة.',
    'كل جرح يحمل بصمة نضال.',
    'الحقيقة هي ضوء لا يخبو.',
    'سلامنا يبدأ من داخلنا.',
    'الكرامة هي وطن الروح.',
    'الألم لا يُقاس بكبره، بل بعمق تأثيره.',
    'حتى في أقسى اللحظات، هناك بصيص أمل.',
    'أصواتنا تصنع التاريخ.',
    'القصص هي جسر بين الماضي والمستقبل.',
    'كل قصة إنسانية تبدأ بخطوة شجاعة.',
    'الأمل هو الريح التي تحملنا نحو الغد.',
    'أرواحنا لا تنكسر مهما حاولوا.',
    'كل ضحكة طفل هي انتصار على الألم.',
    'الذكريات هي نسيج الحياة.',
    'لن يكون هناك نصر دون صمود.',
    'الحياة تستمر رغم كل شيء.',
    'الأبطال الحقيقيون هم من يكتبون السلام.',
    'كل صوت هو رسالة حب وسلام.',
    'الإنسانية تجمعنا رغم كل الجراح.',
    'التاريخ يكتب بأقلام الشجاعة.',
    'كل زهرة ترويها دموع الشهداء تزهر بالسلام.',
    'في كل قصة نجد بصيص نور للحياة.',
  ];

  final List<String> _searchTerms = [
    'gaza palestine',
    'peace dove',
    'olive branch',
    'jerusalem old city',
    'palestinian culture',
    'peace symbol',
    'war destruction',
    'hope light',
    'mediterranean sea',
    'arabic architecture',
    'peaceful protest',
    'humanitarian aid',
    'children hope',
    'resistance art',
    'peaceful coexistence',
    'war aftermath',
    'peaceful resistance',
    'human rights',
    'solidarity',
    'peace building',
  ];

  @override
  void initState() {
    super.initState();
    _fetchStoriesCount();
    _pickRandomQuote();
    _fetchRandomImage();
  }

  // تحسين الأداء - إضافة timeout للطلبات
  void _fetchStoriesCount() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('stories')
          .get()
          .timeout(const Duration(seconds: 10));
      if (mounted) {
        setState(() {
          _storiesCount = snap.docs.length;
        });
      }
    } catch (e) {
      debugPrint('Error fetching stories count: $e');
      if (mounted) {
        setState(() {
          _storiesCount = 0;
        });
      }
    }
  }

  void _pickRandomQuote() {
    final random = Random();
    String newQuote;
    
    // تجنب تكرار نفس الاقتباس مرتين متتاليتين
    do {
      newQuote = _quotes[random.nextInt(_quotes.length)];
    } while (newQuote == _lastQuote && _quotes.length > 1);
    
    setState(() {
      _lastQuote = _quote;
      _quote = newQuote;
    });
  }

  // تحسين الأداء - تقليل استهلاك الإنترنت
  Future<void> _fetchRandomImage() async {
    if (_isOfflineMode) {
      _useLocalImages();
      return;
    }

    setState(() {
      _isLoadingImage = true;
    });

    try {
      final random = Random();
      final searchTerm = _searchTerms[random.nextInt(_searchTerms.length)];
      
      // تحسين الأداء - استخدام timeout وتقليل حجم الصورة
      const String accessKey = 'Cqam6PpHTokdZ8UFtFJvjd4Uq6J-JFiID_x-e8RkWb4';
      
      final response = await http.get(
        Uri.parse('https://api.unsplash.com/photos/random?query=$searchTerm&orientation=portrait&w=400&h=400&fit=crop&q=80&client_id=$accessKey'),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _randomImageUrl = data['urls']['small']; // استخدام صورة أصغر
            _isLoadingImage = false;
          });
        }
      } else {
        _useLocalImages();
      }
    } catch (e) {
      debugPrint('Error fetching image: $e');
      _useLocalImages();
    }
  }

  void _useLocalImages() {
    final random = Random();
    final imageKeys = _cachedImages.keys.toList();
    final randomKey = imageKeys[random.nextInt(imageKeys.length)];
    
    setState(() {
      _randomImageUrl = _cachedImages[randomKey];
      _isLoadingImage = false;
      _isOfflineMode = true;
    });
  }

  Widget _buildDefaultImage() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark 
            ? [const Color(0xFFC0392B).withOpacity(0.3), const Color(0xFF2C3E50).withOpacity(0.3)]
            : [const Color(0xFFC0392B).withOpacity(0.1), const Color(0xFF2C3E50).withOpacity(0.1)],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite,
            size: 80,
            color: const Color(0xFFC0392B).withOpacity(0.7),
          ),
          const SizedBox(height: 12),
          Text(
            'اضغط لتغيير الصورة',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : const Color(0xFF2C3E50),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'صور السلام والأمل من غزة',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11,
              color: isDark ? Colors.white54 : const Color(0xFF555555),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mainColor = isDark ? const Color(0xFF23262F) : const Color(0xFF2C3E50);
    final accentColor = const Color(0xFFC0392B);
    final textColor = isDark ? Colors.white : const Color(0xFF2C3E50);
    final subtitleColor = isDark ? Colors.white70 : const Color(0xFF273C75);
    final cardColor = isDark ? const Color(0xFF23262F) : Colors.white;
    
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(0),
        child: SizedBox.shrink(),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lightbulb, color: Color(0xFFC0392B), size: 36),
                  SizedBox(width: 10),
                  Text(
                    'إلهام غزة',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'قصص وصور وعبارات تلهمنا من غزة الصمود',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  color: subtitleColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const SizedBox(height: 24),
              // صورة عشوائية من غزة والمنطقة
              GestureDetector(
                onTap: _fetchRandomImage,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: isDark ? Colors.black26 : Colors.black12, blurRadius: 12)],
                    border: Border.all(color: accentColor, width: 4),
                    color: cardColor,
                  ),
                  child: ClipOval(
                    child: _isLoadingImage
                        ? Center(
                            child: CircularProgressIndicator(
                              color: accentColor,
                            ),
                          )
                        : _randomImageUrl != null
                            ? CachedNetworkImage(
                                imageUrl: _randomImageUrl!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Center(
                                  child: CircularProgressIndicator(
                                    color: accentColor,
                                  ),
                                ),
                                errorWidget: (context, url, error) => _buildDefaultImage(),
                                // تحسين الأداء - إعدادات التخزين المؤقت
                                memCacheWidth: 400,
                                memCacheHeight: 400,
                                maxWidthDiskCache: 400,
                                maxHeightDiskCache: 400,
                              )
                            : _buildDefaultImage(),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // عداد القصص
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: isDark ? Colors.black26 : Colors.black12, blurRadius: 6)],
                ),
                child: Text(
                  'عدد القصص: $_storiesCount',
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 32),
              // اقتباس ملهم
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Card(
                  color: mainColor.withOpacity(0.92),
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Icon(Icons.format_quote, color: Colors.white.withOpacity(0.7), size: 36),
                        const SizedBox(height: 12),
                        Text(
                          _quote,
                          style: const TextStyle(fontFamily: 'Cairo', fontSize: 20, color: Colors.white, fontStyle: FontStyle.italic),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: TextButton.icon(
                            onPressed: _pickRandomQuote,
                            icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
                            label: const Text(
                              'اقتباس آخر', 
                              style: TextStyle(
                                color: Colors.white, 
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
} 