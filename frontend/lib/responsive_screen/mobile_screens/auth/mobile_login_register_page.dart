import 'package:finance_dashboard/constants/colors.dart';
import 'package:finance_dashboard/services/auth_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class MobileLoginRegisterPage extends StatefulWidget {
  const MobileLoginRegisterPage({super.key});

  @override
  State<MobileLoginRegisterPage> createState() => _MobileLoginRegisterPageState();
}

class _MobileLoginRegisterPageState extends State<MobileLoginRegisterPage> {
  bool _isLogin = true;
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _authServices = AuthServices();

  void _setLoading(bool value) => setState(() => _isLoading = value);
  void _setIsLogin(bool value) => setState(() => _isLogin = value);

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.w),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _isLogin ? 'Welcome Back' : 'Create Account',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 32.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      _isLogin
                          ? 'Sign in to continue'
                          : 'Get started in just a few steps',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 16.sp,
                        color: Colors.grey[400],
                      ),
                    ),
                    SizedBox(height: 60.h),

                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _isLogin ? _buildLoginForm() : _buildRegisterForm(),
                    ),
                    SizedBox(height: 40.h),

                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : SizedBox(
                            height: 55.h,
                            child: ElevatedButton(
                              onPressed: _isLogin
                                  ? () => _authServices.login(
                                        context: context,
                                        formKey: _formKey,
                                        usernameController: _usernameController,
                                        passwordController: _passwordController,
                                        setLoading: _setLoading,
                                      )
                                  : () => _authServices.register(
                                        context: context,
                                        formKey: _formKey,
                                        usernameController: _usernameController,
                                        emailController: _emailController,
                                        passwordController: _passwordController,
                                        setLoading: _setLoading,
                                        setIsLogin: _setIsLogin,
                                      ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.yellow.shade700,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15.r),
                                ),
                              ),
                              child: Text(
                                _isLogin ? 'Sign In' : 'Sign Up',
                                style: GoogleFonts.poppins(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ),
                    SizedBox(height: 20.h),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isLogin
                              ? "Don't have an account?"
                              : "Already have an account?",
                          style:
                              TextStyle(color: Colors.grey[400], fontSize: 14.sp),
                        ),
                        TextButton(
                          onPressed: () {
                            _formKey.currentState?.reset();
                            _usernameController.clear();
                            _emailController.clear();
                            _passwordController.clear();
                            _setIsLogin(!_isLogin);
                          },
                          child: Text(
                            _isLogin ? 'Sign Up' : 'Sign In',
                            style: TextStyle(
                              color: Colors.yellow.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
                            ),
                          ),
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
    );
  }

  Widget _buildLoginForm() => Column(
        key: const ValueKey('login'),
        children: [
          _buildTextField(
            controller: _usernameController,
            hintText: 'Username',
            prefixIcon: Icons.person_outline,
          ),
          SizedBox(height: 20.h),
          _buildTextField(
            controller: _passwordController,
            hintText: 'Password',
            prefixIcon: Icons.lock_outline,
            obscureText: true,
          ),
        ],
      );

  Widget _buildRegisterForm() => Column(
        key: const ValueKey('register'),
        children: [
          _buildTextField(
            controller: _usernameController,
            hintText: 'Username',
            prefixIcon: Icons.person_outline,
          ),
          SizedBox(height: 20.h),
          _buildTextField(
            controller: _emailController,
            hintText: 'Email Address',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          SizedBox(height: 20.h),
          _buildTextField(
            controller: _passwordController,
            hintText: 'Password',
            prefixIcon: Icons.lock_outline,
            obscureText: true,
          ),
        ],
      );

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      validator: (v) => v!.isEmpty ? 'This field cannot be empty' : null,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[600]),
        prefixIcon: Icon(prefixIcon, color: Colors.grey[400]),
        filled: true,
        fillColor: primaryColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.r),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.r),
          borderSide: BorderSide(color: Colors.yellow.shade700, width: 1.5),
        ),
      ),
    );
  }
}
