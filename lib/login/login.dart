import 'package:flutter/material.dart';

import '../account/account_store.dart';
import '../design_system/app_colors.dart';
import '../home/home_page.dart';
import 'auth_ui/auth_ui.dart';
import 'sign_up/basic_info.dart';

/// 이 기기에 저장된 계정(AccountStore)으로 로그인·가입하는 화면. 성공하면 홈으로 이동합니다.
class LoginPageV2 extends StatefulWidget {
  const LoginPageV2({super.key, this.store, this.onForgotPassword});

  /// 기본값은 AccountStore.instance.
  final AccountStore? store;
  final VoidCallback? onForgotPassword;
  @override
  State<LoginPageV2> createState() => _LoginPageV2State();
}

class _LoginPageV2State extends State<LoginPageV2> {
  late final AccountStore _store = widget.store ?? AccountStore.instance;
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
  void _openHome() => Navigator.of(context).pushReplacement<void, void>(
    MaterialPageRoute(builder: (_) => const HomePageV2()),
  );

  Future<void> login() async {
    if (!form.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      await _store.login(id.text.trim(), password.text);
      if (!mounted) return;
      _openHome();
    } on AuthException catch (e) {
      if (mounted) message(e.message);
    } catch (_) {
      if (mounted) message('로그인하지 못했어요. 다시 시도해주세요');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> register() async {
    // 계정은 하나만 저장하므로, 새로 가입하면 기존 계정과 러닝 기록이 사라집니다.
    if (_store.hasAccount) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('새로 가입할까요?'),
          content: const Text(
            '이 기기에는 계정을 하나만 저장해요. 새로 가입하면 기존 계정과 러닝 기록이 모두 삭제돼요.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('가입하기'),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    final data = await Navigator.push<RegistrationData>(
      context,
      MaterialPageRoute(builder: (_) => const BasicInfoPage()),
    );
    if (!mounted || data == null) return;
    setState(() => busy = true);
    try {
      await _store.register(data);
      if (!mounted) return;
      _openHome();
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
              painter: _BrandLinesV2(),
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

class _BrandLinesV2 extends CustomPainter {
  const _BrandLinesV2();
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
  bool shouldRepaint(covariant _BrandLinesV2 oldDelegate) => false;
}

/// 앱을 켤 때 저장된 로그인 상태를 읽어 홈 또는 로그인 화면을 엽니다.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key, this.store});
  final AccountStore? store;
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final AccountStore _store = widget.store ?? AccountStore.instance;
  late final Future<void> _loaded = _store.load().catchError((Object _) {});

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: _loaded,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Scaffold(backgroundColor: AppColors.background);
      }
      return _store.isLoggedIn
          ? const HomePageV2()
          : LoginPageV2(store: _store);
    },
  );
}
