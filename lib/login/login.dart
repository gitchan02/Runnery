import 'package:flutter/material.dart';

import '../design_system/app_colors.dart';
import '../home/home_page.dart';
import 'auth_ui/auth_ui.dart';
import 'sign_up/basic_info.dart';
export 'auth_ui/auth_ui.dart' show RegistrationData;

/// 인증 콜백이 성공하면 홈 화면으로 이동합니다.
class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    this.onLogin,
    this.onRegister,
    this.onForgotPassword,
  });
  final Future<void> Function(String id, String password)? onLogin;
  final Future<void> Function(RegistrationData data)? onRegister;
  final VoidCallback? onForgotPassword;
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final form = GlobalKey<FormState>();
  final id = TextEditingController();
  final password = TextEditingController();
  bool busy = false;
  @override
  void dispose() {
    id.dispose();
    password.dispose();
    super.dispose();
  }

  void message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  Future<void> login() async {
    if (!form.currentState!.validate()) return;
    if (widget.onLogin == null) {
      message('로그인 서비스 연결 준비 중이에요');
      return;
    }
    setState(() => busy = true);
    try {
      await widget.onLogin!(id.text.trim(), password.text);
      if (!mounted) return;
      Navigator.of(context).pushReplacement<void, void>(
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } catch (_) {
      if (mounted) message('로그인하지 못했어요. 다시 시도해주세요');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> register() async {
    final data = await Navigator.push<RegistrationData>(
      context,
      MaterialPageRoute(builder: (_) => const BasicInfoPage()),
    );
    if (!mounted || data == null) return;
    if (widget.onRegister == null) {
      message('회원가입 서비스는 아직 준비 중이에요');
      return;
    }
    setState(() => busy = true);
    try {
      await widget.onRegister!(data);
    } catch (_) {
      if (mounted) message('가입하지 못했어요. 다시 시도해주세요');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AuthFrame(
    content: Form(
      key: form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 56),
          Transform.translate(
            offset: const Offset(-24, 0),
            child: const CustomPaint(
              size: Size(285, 74),
              painter: _BrandLines(),
            ),
          ),
          const SizedBox(height: 36),
          const FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'RUNNERY',
              style: TextStyle(
                fontFamily: 'Archivo',
                fontVariations: [FontVariation('wdth', 125)],
                fontSize: 40,
                height: 1.1,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.4,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text(
                '러 너 리',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              Container(
                width: 24,
                height: 1,
                color: AppColors.borderControl,
                margin: const EdgeInsets.symmetric(horizontal: 14),
              ),
              Text(
                'KM BY KM',
                style: authLabelStyle.copyWith(color: AppColors.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: 48),
          AuthField(
            label: 'ID',
            controller: id,
            hint: '아이디를 입력하세요',
            validator: (v) =>
                v == null || v.trim().isEmpty ? '아이디를 입력해주세요' : null,
          ),
          const SizedBox(height: 24),
          AuthField(
            label: 'PASSWORD',
            controller: password,
            hint: '비밀번호를 입력하세요',
            password: true,
            action: TextInputAction.done,
            validator: (v) => v == null || v.isEmpty ? '비밀번호를 입력해주세요' : null,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed:
                  widget.onForgotPassword ?? () => message('비밀번호 찾기는 준비 중이에요'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                padding: EdgeInsets.zero,
              ),
              child: const Text(
                '비밀번호 찾기',
                style: TextStyle(
                  fontSize: 12,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
    actions: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthButton(
          label: busy ? '처리 중…' : '로그인',
          onPressed: busy ? null : login,
        ),
        const SizedBox(height: 12),
        AuthButton(
          label: '회원가입',
          outlined: true,
          onPressed: busy ? null : register,
        ),
      ],
    ),
  );
}

class _BrandLines extends CustomPainter {
  const _BrandLines();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2;
    const widths = [200.0, 230.0, 245.0, 220.0, 285.0];
    for (int i = 0; i < widths.length; i++) {
      canvas.drawLine(Offset(0, i * 18.0), Offset(widths[i], i * 18.0), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BrandLines oldDelegate) => false;
}
