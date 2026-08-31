import 'package:finance_dashboard/constants/colors.dart';
import 'package:finance_dashboard/services/auth_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class DesktopLoginRegisterPage extends StatefulWidget {
  const DesktopLoginRegisterPage({super.key});

  @override
  State<DesktopLoginRegisterPage> createState() => _DesktopLoginRegisterPageState();
}

class _DesktopLoginRegisterPageState extends State<DesktopLoginRegisterPage> {
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
      backgroundColor: backgroundColor,
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              color: primaryColor,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.savings_rounded, color: Colors.yellow.shade700, size: 100.sp),
                    SizedBox(height: 20.h),
                    Text(
                      'NoBroke',
                      style: GoogleFonts.poppins(
                        fontSize: 60.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Your Personal Finance Dashboard',
                      style: GoogleFonts.poppins(
                        fontSize: 22.sp,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 100.w),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isLogin ? 'Welcome Back' : 'Create Account',
                          style: GoogleFonts.poppins(
                            fontSize: 42.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 10.h),
                        Text(
                          _isLogin
                              ? 'Please enter your details to sign in.'
                              : 'Get started by creating a new account.',
                          style: GoogleFonts.poppins(
                            fontSize: 18.sp,
                            color: Colors.grey[400],
                          ),
                        ),
                        SizedBox(height: 50.h),

                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _isLogin ? _buildLoginForm() : _buildRegisterForm(),
                        ),
                        SizedBox(height: 40.h),

                        _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : SizedBox(
                                width: double.infinity,
                                height: 60.h,
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
                                      fontSize: 20.sp,
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
                              style: TextStyle(color: Colors.grey[400], fontSize: 16.sp),
                            ),
                            TextButton(
                              onPressed: () => setState(() => _isLogin = !_isLogin),
                              child: Text(
                                _isLogin ? 'Sign Up' : 'Sign In',
                                style: TextStyle(
                                  color: Colors.yellow.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.sp,
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
        ],
      ),
    );
  }

  Widget _buildLoginForm() => Column(
        key: const ValueKey('login'),
        children: [
          _buildTextField(_usernameController, 'Username', Icons.person_outline),
          SizedBox(height: 20.h),
          _buildTextField(_passwordController, 'Password', Icons.lock_outline,
              obscureText: true),
        ],
      );

  Widget _buildRegisterForm() => Column(
        key: const ValueKey('register'),
        children: [
          _buildTextField(_usernameController, 'Username', Icons.person_outline),
          SizedBox(height: 20.h),
          _buildTextField(_emailController, 'Email Address', Icons.email_outlined,
              keyboardType: TextInputType.emailAddress),
          SizedBox(height: 20.h),
          _buildTextField(_passwordController, 'Password', Icons.lock_outline,
              obscureText: true),
        ],
      );

  Widget _buildTextField(
    TextEditingController controller,
    String hintText,
    IconData prefixIcon, {
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      validator: (v) => v!.isEmpty ? 'Required field' : null,
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
          borderSide: BorderSide(color: Colors.yellow.shade700, width: 2),
        ),
      ),
    );
  }
}
