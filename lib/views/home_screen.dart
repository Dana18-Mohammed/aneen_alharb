// views/home_screen.dart
import 'package:flutter/material.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'dart:async';
import 'add_story_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'story_detail_screen.dart';
import 'explore_screen.dart';
import 'profile_screen.dart';
import 'inspiration_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late AnimationController _fabAnimController;
  late Animation<double> _fabScaleAnim;
  
  // تحسين الأداء - إضافة متغيرات للتخزين المؤقت
  int _cachedStoriesCount = 0;
  DateTime? _lastStoriesFetch;
  static const Duration _cacheDuration = Duration(minutes: 5);

  final List<Map<String, String>> recentStories = [
    {
      'title': 'قصة أمل',
      'type': 'نجاة',
      'snippet': 'نجوت من الحرب، لكن الذكرى لا تغادرني...',
      'image': 'assets/images/story1.png',
    },
    {
      'title': 'ذكريات تحت الأنقاض',
      'type': 'نزوح',
      'snippet': 'تركت بيتي وأحمل معي صور أطفالي...',
      'image': 'assets/images/story2.png',
    },
    {
      'title': 'طفل من الغد',
      'type': 'شهادة',
      'snippet': 'كان حلمه أن يصبح طبيبًا...',
      'image': 'assets/images/story3.png',
    },
  ];

  final List<Map<String, String>> martyrsStories = [
    {
      'title': 'حكاية الشهيد محمد', 
      'icon': '🕯️',
      'description': 'محمد كان شابًا لا يتجاوز العشرين من عمره، عاش طفولته وسط أزقة غزة الضيقة، حيث كان حلمه البسيط أن يكمل تعليمه ويصبح مهندسًا يساعد في بناء وطنه.\n\nفي صباح أحد الأيام، بينما كان محمد يتجه إلى جامعته، وقع القصف فجأة على الحي الذي يسكنه. هرع محمد إلى مأوى صغير في المنزل، لكن القذيفة كانت أسرع. فقد محمد حياته وهو يحاول حماية أسرته، تاركًا خلفه حلمًا لم يُكتب له أن يتحقق.\n\nلكن رغم رحيله، تبقى قصته نبع إلهام لكل من عرفه. زهرته لم تذبل، بل ارتفعت إلى السماء كطفل لا يموت، تذكر الجميع أن الأمل والكرامة لا ينتهيان مع الغياب.\n\nعائلته وروحه الحية تظل شاهدة على صمود غزة، وقصته تُروى بين الأصدقاء والطلاب كرمز للشجاعة والإصرار على العيش بكرامة رغم الألم.'
    },
    {
      'title': 'زهرة لن تموت', 
      'icon': '🌹',
      'description': 'أنا أم سارة، طفلتي الصغيرة التي كانت تملأ بيتنا بالضحك والفرح، كانت زهرة نمت وسط صخور الألم. كانت تشبه الربيع ببراءتها، تملأ حياتنا ألوانًا وأحلامًا صغيرة.\n\nفي ذلك اليوم الأسود، كانت سارة تلعب في فناء المنزل، تجمع بعض الزهور الصغيرة التي كانت تحبها كثيرًا. كان الجو هادئًا نسبيًا، ولم نتوقع ما سيحدث بعد لحظات.\n\nفجأة، سمعنا صوت صفارات الإنذار، ثم وقع الانفجار بالقرب من بيتنا. ركضت لأجلبها بسرعة إلى داخل المنزل، لكن في تلك اللحظة، سقطت قذيفة على الحي الذي نعيش فيه.\n\nسقطت جدران المنزل، وغبار كثيف ملأ المكان. كان صوت صراخ الأطفال والنساء يملأ الأرجاء. حاولت أن أجد سارة وسط الركام، ووجدتها تحت الأنقاض، صغيرة وجميلة، لكن بلا حراك.\n\nلم تترك سارة هذه الدنيا إلا بعد لحظات من الألم، لكن روحها كانت قوية، كزهرة لم تذبل. استشهدت لتكون رمزًا للبراءة التي لم تستطع الحرب تدميرها.\n\nزهرتي لم تمت، فهي في قلبي وفي كل صوت طفل ينادي بالأمل، وفي كل حلم نزرعه لأجل مستقبل أفضل.'
    },
    {
      'title': 'طفل السماء', 
      'icon': '👼',
      'description': 'طفلي الذي كان نجمًا صغيرًا في عائلتنا، قادماً من السماء ليضيء حياتنا. كان يركض في أرجاء البيت بابتسامة لا تفارق وجهه، يحمل بين يديه أحلامًا صغيرة كبذور تنتظر النمو.\n\nفي يومٍ لم نتوقع فيه شيئًا، هبت عاصفة الحرب على حيّنا. كان سامي يلعب أمام المنزل، ينثر الضحكات والفرح، حين سقط القصف فجأة.\n\nهرعت إليه، لكن لم يكن في يديّ أن أُبعده عن الموت. سقطت قذيفة قريبة، وحملها الهواء بعيدًا إلى السماء. في لحظة واحدة، أصبح سامي "طفل السماء" الذي ارتفع فوق الألم.\n\nلكن روحه لم تذهب بعيدًا، إنها هنا بيننا، تنمو في قلوبنا مثل زهرة تتفتح مع كل يوم جديد، تعلمنا كيف نحب رغم الحزن، وكيف نستمر رغم الفقد.\n\nسامي هو طفل السماء، رمز البراءة والصفاء، الذي سيظل يلهمنا بالأمل والسلام مهما طال الظلام.'
    },
  ];

  // متغيرات البحث والفلترة
  String _searchQuery = '';
  String _selectedTypeFilter = 'الكل';
  final List<String> _storyTypes = ['الكل', 'نجاة', 'نزوح', 'شهادة', 'أخرى'];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(begin: const Offset(0, -0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      lowerBound: 0.0,
      upperBound: 0.15,
    );
    _fabScaleAnim = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _fabAnimController, curve: Curves.easeInOut),
    );
    
    // تحسين الأداء - تحميل البيانات عند بدء التطبيق
    _fetchStoriesCount();
  }

  @override
  void dispose() {
    _animController.dispose();
    _fabAnimController.dispose();
    super.dispose();
  }

  // تحسين الأداء - إضافة timeout وcache للطلبات
  Future<void> _fetchStoriesCount() async {
    // التحقق من التخزين المؤقت
    if (_lastStoriesFetch != null && 
        DateTime.now().difference(_lastStoriesFetch!) < _cacheDuration) {
      return;
    }

    try {
      final snap = await FirebaseFirestore.instance
          .collection('stories')
          .get()
          .timeout(const Duration(seconds: 10));
      
      if (mounted) {
        setState(() {
          _cachedStoriesCount = snap.docs.length;
          _lastStoriesFetch = DateTime.now();
        });
      }
    } catch (e) {
      debugPrint('Error fetching stories count: $e');
      // في حالة الخطأ، استخدم القيمة المخزنة مؤقتاً
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF181A20) : const Color(0xFFFAF3E0);
    final textColor = isDark ? Colors.white : const Color(0xFF2C3E50);
    final cardColor = isDark ? const Color(0xFF23262F) : Colors.white;
    
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Row(
            children: [
              // تحسين الأداء - إزالة الصورة لتقليل استهلاك الذاكرة
              const Icon(Icons.auto_stories, color: Color(0xFFC0392B), size: 36),
              const SizedBox(width: 12),
              Text(
                'أنين الحرب',
                style: TextStyle(
                  color: textColor,
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              const Spacer(),
              Text(
                'أهلاً بك 🕊️',
                style: TextStyle(
                  color: isDark ? Colors.white70 : const Color(0xFF273C75),
                  fontFamily: 'Cairo',
                  fontSize: 16,
                ),
              ),
            ],
          ),
          toolbarHeight: 70,
        ),
        body: _buildBody(),
        bottomNavigationBar: ConvexAppBar(
          style: TabStyle.fixedCircle,
          backgroundColor: cardColor,
          activeColor: const Color(0xFFC0392B),
          color: isDark ? Colors.white70 : const Color(0xFF2C3E50),
          items: const [
            TabItem(icon: Icons.home, title: 'الرئيسية'),
            TabItem(icon: Icons.search, title: 'استكشاف'),
            TabItem(icon: Icons.add_circle, title: 'أضف'),
            TabItem(icon: Icons.map, title: 'إلهام غزة'),
            TabItem(icon: Icons.person, title: 'حسابي'),
          ],
          initialActiveIndex: _selectedIndex,
          onTap: (int i) async {
            if (i == 2) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddStoryScreen()),
              );
            } else {
              setState(() {
                _selectedIndex = i;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_selectedIndex == 0) {
      // محتوى الرئيسية
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // بطاقة دعوة للمشاركة
              FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: _buildInviteCard(),
                ),
              ),
              const SizedBox(height: 32),
              // قسم حكايات الشهداء
              _buildMartyrsSection(),
              const SizedBox(height: 32),
              // إحصائيات وتفاعل
              _buildStatsSection(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      );
    } else if (_selectedIndex == 1) {
      // قسم استكشاف القصص
      return const ExploreScreen();
    } else if (_selectedIndex == 3) {
      // قسم الإلهام
      return const InspirationScreen();
    } else if (_selectedIndex == 4) {
      // قسم الملف الشخصي
      return const ProfileScreen();
    }
    return const SizedBox.shrink();
  }

  Widget _buildInviteCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24), 
      decoration: BoxDecoration(
        color: const Color(0xFFC0392B).withOpacity(isDark ? 0.95 : 0.93),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC0392B).withOpacity(isDark ? 0.2 : 0.13),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.mic, color: Colors.white, size: 36),
              SizedBox(width: 12),
              Icon(Icons.edit, color: Colors.white, size: 32),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'هل أنت ناجٍ؟ نازح؟ أو فقدت من تحب؟',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'شارك حكايتك... كل كلمة تصنع أثرًا.',
            style: TextStyle(
              color: Color(0xFFF6B93B),
              fontFamily: 'Cairo',
              fontSize: 15,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF6B93B),
                foregroundColor: const Color(0xFFC0392B),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddStoryScreen()),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'احكِ قصتك الآن',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('📣', style: TextStyle(fontSize: 20)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMartyrsSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF23262F) : const Color(0xFFF5F5F5);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.2) : const Color(0xFF2C3E50).withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.favorite, color: Color(0xFFC0392B), size: 24),
              const SizedBox(width: 8),
              const Text(
                'قصص من رحلوا وأثرهم باقٍ',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFFC0392B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('stories')
                .orderBy('timestamp', descending: true)
                .limit(10)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              // فلترة القصص من نوع شهادة من Firebase
              List<Map<String, dynamic>> firebaseMartyrStories = [];
              if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                firebaseMartyrStories = snapshot.data!.docs.where((doc) {
                  final story = doc.data() as Map<String, dynamic>;
                  return story['type'] == 'شهادة';
                }).take(5).map((doc) {
                  final story = doc.data() as Map<String, dynamic>;
                  return {
                    ...story,
                    'id': doc.id,
                    'isFromFirebase': true,
                  };
                }).toList();
              }

              // دمج القصص الثابتة مع قصص Firebase
              List<Map<String, dynamic>> allMartyrStories = [
                ...martyrsStories.map((story) => {
                  ...story,
                  'isFromFirebase': false,
                }),
                ...firebaseMartyrStories,
              ];

              return SizedBox(
                height: 110,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: allMartyrStories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (context, i) {
                    final story = allMartyrStories[i];
                    final isFromFirebase = story['isFromFirebase'] ?? false;
                    
                    return GestureDetector(
                      onTap: () {
                        if (isFromFirebase) {
                          // قصة من Firebase
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => StoryDetailScreen(
                                storyId: story['id'],
                                storyData: story,
                              ),
                            ),
                          );
                        } else {
                          // قصة ثابتة
                          final mockStory = {
                            'name': story['title'] ?? 'قصة شهيد',
                            'text': story['description'] ?? 'هذه قصة من قصص الشهداء الذين رحلوا عنا ولكن أثرهم باقٍ في قلوبنا. قصص من الشجاعة والإيمان والتضحية من أجل الوطن.',
                            'type': 'شهادة',
                            'timestamp': DateTime.now(),
                          };
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => StoryDetailScreen(
                                storyId: 'martyr_story_$i',
                                storyData: mockStory,
                              ),
                            ),
                          );
                        }
                      },
                      child: Container(
                        width: 120,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFC0392B).withOpacity(0.07),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isFromFirebase) ...[
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: const Color(0xFFC0392B),
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
                            ] else ...[
                              Text(
                                story['icon'] ?? '🕯️',
                                style: const TextStyle(fontSize: 30),
                              ),
                            ],
                            const SizedBox(height: 6),
                            Flexible(
                              child: Text(
                                isFromFirebase 
                                    ? (story['name'] ?? 'قصة شهادة')
                                    : (story['title'] ?? ''),
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFF2C3E50),
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF23262F) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF2C3E50);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.2) : const Color(0xFF2C3E50).withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics, color: Color(0xFFC0392B), size: 24),
              const SizedBox(width: 8),
              Text(
                'إحصائيات وتفاعل',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('stories').snapshots(),
            builder: (context, snapshot) {
              int totalStories = 0;
              int martyrStories = 0;
              int survivalStories = 0;
              int displacementStories = 0;

              if (snapshot.hasData) {
                totalStories = snapshot.data!.docs.length;
                for (var doc in snapshot.data!.docs) {
                  final story = doc.data() as Map<String, dynamic>;
                  switch (story['type']) {
                    case 'شهادة':
                      martyrStories++;
                      break;
                    case 'نجاة':
                      survivalStories++;
                      break;
                    case 'نزوح':
                      displacementStories++;
                      break;
                  }
                }
              }

              return Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.auto_stories,
                      title: 'إجمالي القصص',
                      value: totalStories.toString(),
                      color: const Color(0xFF2980B9),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.favorite,
                      title: 'قصص شهادة',
                      value: martyrStories.toString(),
                      color: const Color(0xFFC0392B),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.psychology,
                      title: 'قصص نجاة',
                      value: survivalStories.toString(),
                      color: const Color(0xFF27AE60),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddStoryScreen()),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFC0392B), Color(0xFFE74C3C)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFC0392B).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.add_circle, color: Colors.white, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'أضف قصتك الآن',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF2C3E50);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.1 : 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              color: textColor,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentStoryCard(Map<String, String> story) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF23262F) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF2C3E50);
    final subtitleColor = isDark ? Colors.white70 : const Color(0xFF555555);
    
    return Container(
      width: 180,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.2) : const Color(0xFF2C3E50).withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: const Color(0xFFF6B93B),
                  backgroundImage: AssetImage(story['image'] ?? ''),
                  child: story['image'] == null ? const Icon(Icons.person, size: 26, color: Color(0xFF2C3E50)) : null,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC0392B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    story['type'] ?? '',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: Color(0xFFC0392B),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              story['title'] ?? '',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: textColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              story['snippet'] ?? '',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                color: subtitleColor,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: const [
                Icon(Icons.favorite, color: Color(0xFFC0392B), size: 18),
                SizedBox(width: 6),
                Text('120', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Color(0xFFC0392B))),
                SizedBox(width: 12),
                Icon(Icons.chat_bubble_outline, color: Color(0xFF2C3E50), size: 18),
                SizedBox(width: 6),
                Text('8', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Color(0xFF2C3E50))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFirestoreStoryCard(Map<String, dynamic> story, {String? storyId}) {
    final typeColor = {
      'نجاة': Color(0xFF2980B9),
      'نزوح': Color(0xFFF6B93B),
      'شهادة': Color(0xFFC0392B),
      'أخرى': Color(0xFF2C3E50),
    };
    return InkWell(
      onTap: storyId == null ? null : () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StoryDetailScreen(storyId: storyId, storyData: story),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2C3E50).withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: typeColor[story['type']] ?? const Color(0xFF2C3E50),
                    child: Text(
                      story['name'] != null && story['name'].toString().isNotEmpty
                          ? story['name'].toString().substring(0, 1)
                          : '?',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20, fontFamily: 'Cairo'),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: (typeColor[story['type']] ?? const Color(0xFF2C3E50)).withOpacity(0.13),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      story['type'] ?? '',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        color: typeColor[story['type']] ?? const Color(0xFF2C3E50),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                story['name'] ?? '',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF2C3E50),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                story['text'] ?? '',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  color: Color(0xFF555555),
                ),
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // دالة بناء الاستعلام حسب البحث والفلترة
  Query _buildStoriesQuery() {
    Query query = FirebaseFirestore.instance.collection('stories').orderBy('timestamp', descending: true);
    if (_selectedTypeFilter != 'الكل') {
      query = query.where('type', isEqualTo: _selectedTypeFilter);
    }
    // البحث بالاسم أو نص القصة (يتم على الكلاينت بعد الجلب)
    return query;
  }
} 