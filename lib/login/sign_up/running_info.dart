import 'package:flutter/material.dart';

import '../../design_system/app_colors.dart';
import '../auth_ui/auth_ui.dart';

class RunningInfoPage extends StatefulWidget {
  const RunningInfoPage({
    super.key,
    this.name = '',
    this.email = '',
    this.id = '',
    this.password = '',
  });
  final String name, email, id, password;
  @override
  State<RunningInfoPage> createState() => _RunningInfoPageState();
}

class _RunningInfoPageState extends State<RunningInfoPage> {
  final form = GlobalKey<FormState>();
  final age = TextEditingController();
  final ruler = ScrollController(initialScrollOffset: 2040);
  String gender = '선택 안 함';
  double weight = 60;
  @override
  void initState() {
    super.initState();
    ruler.addListener(() {
      setState(() => weight = (ruler.offset / 34 * 10).round() / 10);
    });
  }

  @override
  void dispose() {
    age.dispose();
    ruler.dispose();
    super.dispose();
  }

  void complete() {
    if (!form.currentState!.validate()) return;
    if (weight <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('체중을 선택해주세요')));
      return;
    }
    Navigator.pop(
      context,
      RegistrationData(
        name: widget.name,
        email: widget.email,
        id: widget.id,
        password: widget.password,
        age: int.parse(age.text),
        gender: gender,
        weight: weight,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AuthFrame(
    content: Form(
      key: form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SignupHeading(
            step: 3,
            title: 'RUNNING\nINFORMATION',
            description: '정확한 칼로리 계산을 위해 필요해요',
          ),
          const SizedBox(height: 32),
          AuthField(
            label: 'AGE',
            controller: age,
            hint: '나이를 입력해주세요',
            suffix: '세',
            keyboard: TextInputType.number,
            action: TextInputAction.done,
            validator: (v) =>
                (int.tryParse(v ?? '') ?? 0) > 0 ? null : '나이를 숫자로 입력해주세요',
          ),
          const SizedBox(height: 24),
          const Text('GENDER', style: authLabelStyle),
          const SizedBox(height: 10),
          Row(
            children: ['여성', '남성', '선택 안 함']
                .map(
                  (value) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: value == '선택 안 함' ? 0 : 8,
                      ),
                      child: Semantics(
                        selected: gender == value,
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              backgroundColor: gender == value
                                  ? AppColors.surfacePressed
                                  : Colors.transparent,
                              foregroundColor: gender == value
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              side: BorderSide(
                                color: gender == value
                                    ? Colors.white
                                    : AppColors.borderDefault,
                              ),
                            ),
                            onPressed: () => setState(() => gender = value),
                            child: Text(value),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('WEIGHT', style: authLabelStyle),
              Text(
                '칼로리 계산에만 사용돼요',
                style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: weight.toStringAsFixed(1),
                    style: const TextStyle(
                      fontFamily: 'Archivo',
                      fontVariations: [FontVariation('wdth', 75)],
                      fontSize: 52,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const TextSpan(text: ' KG', style: authLabelStyle),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 58,
            child: LayoutBuilder(
              builder: (context, box) => Semantics(
                label: '체중',
                value: '${weight.toStringAsFixed(1)} 킬로그램',
                onIncrease: () => ruler.jumpTo(
                  (ruler.offset + 3.4).clamp(0, ruler.position.maxScrollExtent),
                ),
                onDecrease: () => ruler.jumpTo(
                  (ruler.offset - 3.4).clamp(0, ruler.position.maxScrollExtent),
                ),
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    SingleChildScrollView(
                      controller: ruler,
                      scrollDirection: Axis.horizontal,
                      physics: const ClampingScrollPhysics(),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: box.maxWidth / 2,
                        ),
                        child: CustomPaint(
                          size: const Size(10200, 58),
                          painter: _WeightRuler(),
                        ),
                      ),
                    ),
                    IgnorePointer(
                      child: Container(
                        width: 2,
                        height: 28,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
    actions: AuthButton(label: '가입 완료', onPressed: complete),
  );
}

class _WeightRuler extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.borderControl
      ..strokeWidth = 1;
    for (int i = 0; i <= 1500; i++) {
      final x = i * 6.8;
      canvas.drawLine(Offset(x, i % 5 == 0 ? 6 : 16), Offset(x, 24), paint);
      if (i % 10 == 0) {
        final label = TextPainter(
          text: TextSpan(
            text: (i / 5).round().toString(),
            style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        label.paint(canvas, Offset(x - label.width / 2, 32));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WeightRuler oldDelegate) => false;
}
