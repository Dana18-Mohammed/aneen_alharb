// views/auth_tabs.dart
import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import 'forgot_password_screen.dart';

class AuthTabs extends StatefulWidget {
  const AuthTabs({Key? key}) : super(key: key);

  @override
  State<AuthTabs> createState() => _AuthTabsState();
}

class _AuthTabsState extends State<AuthTabs> with SingleTickerProviderStateMixin {
  final AuthController _authController = AuthController();
  final _signInEmailController = TextEditingController();
  final _signInPasswordController = TextEditingController();
  final _signUpNameController = TextEditingController();
  final _signUpEmailController = TextEditingController();
  final _signUpPasswordController = TextEditingController();
  final _signUpConfirmPasswordController = TextEditingController();
  String? _signInError;
  String? _signUpError;
  bool _isLoading = false;
  late TabController _tabController;
  
  // State for password visibility
  bool _signInPasswordVisible = false;
  bool _signUpPasswordVisible = false;
  bool _signUpConfirmPasswordVisible = false;
  bool _agreedToPrivacy = false;
  bool _showPrivacyWarning = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabAnimation);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabAnimation() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _signInError = null;
        _signUpError = null;
        _showPrivacyWarning = false;
        if (_tabController.index == 0) {
          // عند الانتقال إلى تسجيل الدخول، امسح حقول التسجيل
          _signUpNameController.clear();
          _signUpEmailController.clear();
          _signUpPasswordController.clear();
          _signUpConfirmPasswordController.clear();
          _agreedToPrivacy = false;
        } else {
          // عند الانتقال إلى إنشاء حساب، امسح حقول تسجيل الدخول
          _signInEmailController.clear();
          _signInPasswordController.clear();
        }
      });
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF2C3E50)),
      filled: true,
      fillColor: Colors.white,
      labelStyle: const TextStyle(
        color: Color(0xFF2C3E50),
        fontFamily: 'Cairo',
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: const Color(0xFF2C3E50).withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFC0392B), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFC0392B)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFC0392B), width: 2),
      ),
    );
  }

  Widget _background() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAF3E0),
        image: DecorationImage(
          image: const AssetImage('assets/images/pattern.png'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            const Color(0xFFFAF3E0).withOpacity(0.95),
            BlendMode.lighten,
          ),
        ),
      ),
    );
  }

  Widget _buildButton({
    required IconData icon,
    required String label,
    VoidCallback? onPressed,
    bool isLoading = false,
    bool isPrimary = true,
  }) {
    final backgroundColor = isPrimary ? const Color(0xFFC0392B) : const Color(0xFF2C3E50);
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.95 + (0.05 * value),
          child: Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  backgroundColor,
                  backgroundColor.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: backgroundColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: isLoading ? null : onPressed,
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!isLoading) Icon(icon, color: Colors.white),
                      if (!isLoading) const SizedBox(width: 12),
                      if (isLoading)
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      else
                        Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
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
  }

  Widget _buildForm({required bool isSignIn}) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width > 600 ? 400 : double.infinity,
      ),
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2C3E50).withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isSignIn ? 'مرحباً بعودتك' : 'أنشئ حسابك الآن',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSignIn ? 'سجل دخولك للمتابعة' : 'بمشاركتك، تكتب سطراً من ذاكرة الوطن',
            style: TextStyle(
              fontSize: 16,
              color: const Color(0xFF2C3E50).withOpacity(0.7),
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 32),
          if (!isSignIn) ...[
            _buildAnimatedTextField(
              controller: _signUpNameController,
              decoration: _inputDecoration('الاسم الكامل', Icons.person),
              index: 0,
            ),
            const SizedBox(height: 16),
          ],
          _buildAnimatedTextField(
            controller: isSignIn ? _signInEmailController : _signUpEmailController,
            decoration: _inputDecoration('البريد الإلكتروني', Icons.email),
            keyboardType: TextInputType.emailAddress,
            index: isSignIn ? 0 : 1,
          ),
          const SizedBox(height: 16),
          _buildAnimatedTextField(
            controller: isSignIn ? _signInPasswordController : _signUpPasswordController,
            decoration: _inputDecoration('كلمة المرور', Icons.lock),
            obscureText: true,
            index: isSignIn ? 1 : 2,
            isPassword: true,
            isVisible: isSignIn ? _signInPasswordVisible : _signUpPasswordVisible,
            onToggleVisibility: () {
              setState(() {
                if (isSignIn) {
                  _signInPasswordVisible = !_signInPasswordVisible;
                } else {
                  _signUpPasswordVisible = !_signUpPasswordVisible;
                }
              });
            },
          ),
          if (!isSignIn) ...[
            const SizedBox(height: 16),
            _buildAnimatedTextField(
              controller: _signUpConfirmPasswordController,
              decoration: _inputDecoration('تأكيد كلمة المرور', Icons.lock_outline),
              obscureText: true,
              index: 3,
              isPassword: true,
              isVisible: _signUpConfirmPasswordVisible,
              onToggleVisibility: () {
                setState(() {
                  _signUpConfirmPasswordVisible = !_signUpConfirmPasswordVisible;
                });
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Checkbox(
                  value: _agreedToPrivacy,
                  onChanged: (val) {
                    setState(() {
                      _agreedToPrivacy = val ?? false;
                    });
                  },
                  activeColor: const Color(0xFFC0392B),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('سياسة الخصوصية الكاملة', style: TextStyle(fontFamily: 'Cairo')),
                          content: const SingleChildScrollView(
                            child: Text(
                              '''سياسة الخصوصية – تطبيق أنين الحرب

نحن في "أنين الحرب" نولي أهمية كبيرة لخصوصيتك وحماية بياناتك الشخصية. باستخدامك لهذا التطبيق، فإنك توافق على سياسة الخصوصية التالية:

1. المعلومات التي نجمعها:
- لا نطلب منك أي معلومات شخصية إلا إذا رغبت في إنشاء حساب أو المشاركة بقصة.
- يمكنك استخدام التطبيق كزائر دون تقديم أي بيانات شخصية.
- عند التسجيل، نقوم بجمع اسمك وبريدك الإلكتروني فقط.

2. استخدام المعلومات:
- تُستخدم بياناتك فقط لتقديم خدمات التطبيق (مثل: إنشاء الحساب، التواصل معك عند الضرورة).
- لا نشارك بياناتك مع أي جهة خارجية دون إذنك المسبق.

3. حماية البيانات:
- نستخدم أحدث وسائل الحماية التقنية للحفاظ على بياناتك من الوصول غير المصرح به.

4. ملفات تعريف الارتباط (Cookies):
- قد نستخدم ملفات تعريف الارتباط لتحسين تجربتك داخل التطبيق.

5. حقوق المستخدم:
- يمكنك طلب حذف حسابك أو بياناتك في أي وقت عبر التواصل معنا.
- لديك الحق في معرفة كيف نستخدم بياناتك.

6. التعديلات على السياسة:
- قد نقوم بتحديث سياسة الخصوصية من وقت لآخر. سيتم إعلامك بأي تغييرات جوهرية.

لمزيد من المعلومات أو الاستفسارات، يرجى التواصل مع فريق الدعم عبر التطبيق.

نحن ملتزمون باحترام خصوصيتك وجعل تجربتك آمنة وموثوقة.''',
                              style: TextStyle(fontFamily: 'Cairo', fontSize: 14),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('إغلاق', style: TextStyle(fontFamily: 'Cairo')),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text(
                        '[قراءة سياسة الخصوصية الكاملة]',
                        style: TextStyle(
                          color: Color(0xFFC0392B),
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (!isSignIn && _showPrivacyWarning)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: const [
                  Icon(Icons.warning, color: Color(0xFFC0392B), size: 20),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'يجب الموافقة على سياسة الخصوصية أولاً',
                      style: TextStyle(
                        color: Color(0xFFC0392B),
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (isSignIn && _signInError != null || !isSignIn && _signUpError != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                isSignIn ? _signInError! : _signUpError!,
                style: const TextStyle(
                  color: Color(0xFFC0392B),
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
          const SizedBox(height: 24),
          _buildButton(
            icon: isSignIn ? Icons.login : Icons.person_add,
            label: isSignIn ? 'تسجيل الدخول' : 'إنشاء حساب',
            isLoading: _isLoading,
            isPrimary: isSignIn,
            onPressed: (!isSignIn && !_agreedToPrivacy)
                ? () {
                    setState(() {
                      _showPrivacyWarning = true;
                    });
                  }
                : () {
                    if (_isLoading) return;
                    setState(() {
                      if (isSignIn) _signInError = null;
                      else _signUpError = null;
                      _isLoading = true;
                      _showPrivacyWarning = false;
                    });
                    Future(() async {
                      if (!isSignIn && _signUpPasswordController.text != _signUpConfirmPasswordController.text) {
                        setState(() {
                          _signUpError = 'كلمات المرور غير متطابقة';
                          _isLoading = false;
                        });
                        return;
                      }
                      final error = isSignIn
                          ? await _authController.signIn(
                              _signInEmailController.text,
                              _signInPasswordController.text,
                            )
                          : await _authController.signUp(
                              _signUpNameController.text,
                              _signUpEmailController.text,
                              _signUpPasswordController.text,
                            );
                      setState(() {
                        if (isSignIn) _signInError = error;
                        else _signUpError = error;
                        _isLoading = false;
                      });
                      if (error == null) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isSignIn ? 'تم تسجيل الدخول بنجاح!' : 'تم إنشاء الحساب بنجاح!',
                              style: const TextStyle(fontFamily: 'Cairo'),
                            ),
                            backgroundColor: isSignIn ? const Color(0xFF2C3E50) : const Color(0xFFC0392B),
                          ),
                        );
                        Navigator.pushReplacementNamed(context, '/home');
                      }
                    });
                  },
          ),
          if (isSignIn) ...[
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                  );
                },
                child: const Text(
                  'نسيت كلمة المرور؟',
                  style: TextStyle(
                    color: Color(0xFF2C3E50),
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnimatedTextField({
    required TextEditingController controller,
    required InputDecoration decoration,
    TextInputType? keyboardType,
    bool obscureText = false,
    required int index,
    bool? isPassword,
    VoidCallback? onToggleVisibility,
    bool? isVisible,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 200 + (index * 100)),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: TextField(
        controller: controller,
        decoration: decoration.copyWith(
          suffixIcon: isPassword == true
              ? IconButton(
                  icon: Icon(
                    isVisible == true ? Icons.visibility : Icons.visibility_off,
                    color: const Color(0xFF2C3E50),
                  ),
                  onPressed: onToggleVisibility,
                )
              : null,
        ),
        keyboardType: keyboardType,
        obscureText: isPassword == true ? !(isVisible ?? false) : obscureText,
        style: const TextStyle(
          fontFamily: 'Cairo',
          color: Color(0xFF2C3E50),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _background(),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: const Color(0xFF2C3E50),
            elevation: 0,
            title: const Text(
              'أنين الحرب',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Colors.white,
                fontFamily: 'Cairo',
              ),
            ),
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Container(
                alignment: Alignment.center,
                child: TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'تسجيل الدخول'),
                    Tab(text: 'إنشاء حساب'),
                  ],
                  indicator: UnderlineTabIndicator(
                    borderSide: BorderSide(
                      width: 6.0,
                      color: Color(0xFFC0392B),
                    ),
                    insets: EdgeInsets.symmetric(horizontal: 36.0),
                  ),
                  indicatorWeight: 6,
                  indicatorColor: Color(0xFFC0392B),
                  labelColor: Color(0xFFC0392B),
                  unselectedLabelColor: Color(0xFF888888),
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              Center(
                child: SingleChildScrollView(
                  child: _buildForm(isSignIn: true),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  child: _buildForm(isSignIn: false),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}