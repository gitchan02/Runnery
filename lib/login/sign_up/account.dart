import 'package:flutter/material.dart';

import '../auth_ui/auth_ui.dart';
import 'running_info.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key, this.name = '', this.email = ''});
  final String name, email;
  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final form = GlobalKey<FormState>();
  final id = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();
  @override
  void dispose() {
    id.dispose();
    password.dispose();
    confirm.dispose();
    super.dispose();
  }

  Future<void> next() async {
    if (!form.currentState!.validate()) return;
    final result = await Navigator.push<RegistrationData>(
      context,
      MaterialPageRoute(
        builder: (_) => RunningInfoPage(
          name: widget.name,
          email: widget.email,
          id: id.text.trim(),
          password: password.text,
        ),
      ),
    );
    if (mounted && result != null) Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) => AuthFrame(
    content: Form(
      key: form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SignupHeading(
            step: 2,
            title: 'ACCOUNT',
            description: '로그인에 사용할 아이디와 비밀번호를 만들어주세요',
          ),
          const SizedBox(height: 40),
          AuthField(
            label: 'ID',
            controller: id,
            hint: '아이디를 입력해주세요',
            validator: (v) =>
                v == null || v.trim().isEmpty ? '아이디를 입력해주세요' : null,
          ),
          const SizedBox(height: 24),
          AuthField(
            label: 'PASSWORD',
            controller: password,
            password: true,
            hint: '비밀번호를 입력해주세요',
            success: '영문·숫자 포함 8자 이상',
            validator: (v) =>
                v != null &&
                    v.length >= 8 &&
                    RegExp('[a-zA-Z]').hasMatch(v) &&
                    RegExp('[0-9]').hasMatch(v)
                ? null
                : '영문·숫자 포함 8자 이상 입력해주세요',
          ),
          const SizedBox(height: 24),
          AuthField(
            label: 'CONFIRM PASSWORD',
            controller: confirm,
            password: true,
            hint: '비밀번호를 다시 입력해주세요',
            action: TextInputAction.done,
            validator: (v) => v != null && v.isNotEmpty && v == password.text
                ? null
                : '비밀번호가 일치하지 않아요',
            success: '비밀번호가 일치해요',
          ),
        ],
      ),
    ),
    actions: AuthButton(label: '다음', arrow: true, onPressed: next),
  );
}
