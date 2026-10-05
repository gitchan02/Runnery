import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../design_system/app_text_styles.dart';

const recordBackground = Color(0xFF0A0B0B);
const recordMuted = Color(0xFF7D8890);
const recordSecondary = Color(0xFF999B9B);
const recordLine = Color(0xFF202527);
const recordOrange = Color(0xFFFF8A00);

TextStyle recordText(
  double size, {
  Color color = Colors.white,
  FontWeight weight = FontWeight.w500,
}) => TextStyle(
  fontSize: size,
  color: color,
  fontWeight: weight,
  letterSpacing: -.35,
);
TextStyle recordNumber(double size, {Color color = Colors.white}) =>
    AppTextStyles.statValue.copyWith(
      fontSize: size,
      color: color,
      fontWeight: FontWeight.w700,
      height: 1.15,
      letterSpacing: -1,
    );

/// 저장된 GPS 위도/경도를 그대로 전달할 수 있는 경로 모델.
@immutable
class RecordCoordinate {
  const RecordCoordinate(this.latitude, this.longitude);
  final double latitude;
  final double longitude;
}

@immutable
class RunningRecord {
  const RunningRecord({
    required this.id,
    required this.startedAt,
    required this.distanceKm,
    required this.movingSeconds,
    required this.calories,
    required this.route,
    this.pauseSeconds = 178,
    this.place = '여의도 한강공원',
    this.startPlace = '여의도 한강공원 이벤트광장',
    this.endPlace = '여의도 한강공원 물빛광장',
    this.memo = '',
    this.speeds = const [],
    this.splitSeconds = const [],
    this.pauseFractions = const [],
  });
  final String id;
  final DateTime startedAt;
  final double distanceKm;
  final int movingSeconds, pauseSeconds, calories;
  final String place, startPlace, endPlace, memo;
  final List<RecordCoordinate> route;

  /// 시간 순서의 km/h 샘플과 1km별 초 단위 페이스. 데이터 소스 연결 지점.
  final List<double> speeds;
  final List<int> splitSeconds;

  /// 전체 경로에서 일시정지한 위치(0~1).
  final List<double> pauseFractions;
  DateTime get endedAt =>
      startedAt.add(Duration(seconds: movingSeconds + pauseSeconds));
  int get paceSeconds =>
      distanceKm > 0 ? (movingSeconds / distanceKm).round() : 0;
  double get averageSpeed =>
      movingSeconds > 0 ? distanceKm / movingSeconds * 3600 : 0;
  double get maxSpeed =>
      speeds.isEmpty ? averageSpeed : speeds.reduce(math.max);
  String get dateLabel =>
      '${startedAt.month}월 ${startedAt.day}일 ${const ['월', '화', '수', '목', '금', '토', '일'][startedAt.weekday - 1]}요일';
  String get durationLabel => durationWords(movingSeconds);
  String get paceLabel => paceText(paceSeconds);
}

String clockText(DateTime time) =>
    '${time.hour < 12 ? '오전' : '오후'} ${time.hour % 12 == 0 ? 12 : time.hour % 12}:${time.minute.toString().padLeft(2, '0')}';
String paceText(int seconds) =>
    "${seconds ~/ 60}'${(seconds % 60).toString().padLeft(2, '0')}\"";
String durationWords(int seconds) =>
    '${seconds >= 3600 ? '${seconds ~/ 3600}시간 ' : ''}${seconds ~/ 60 % 60}분 ${(seconds % 60).toString().padLeft(2, '0')}초';

/// 시안에 맞춘 예시 저장소. 실제 조회 결과를 각 페이지의 records에 주입합니다.
final demoRunningRecords = <RunningRecord>[
  _demo(28, 19, 42, 5.24, 1935, 315, 0),
  _demo(26, 7, 8, 7.10, 2642, 430, 1),
  _demo(24, 20, 5, 3.02, 1060, 182, 2),
  _demo(21, 19, 30, 10.05, 3769, 603, 3),
  _demo(19, 6, 52, 5.00, 1865, 300, 4),
  _demo(17, 20, 12, 8.03, 3003, 482, 5),
];
RunningRecord _demo(
  int day,
  int hour,
  int minute,
  double km,
  int seconds,
  int kcal,
  int shape,
) {
  const shapes = <List<Offset>>[
    [
      Offset(.08, .76),
      Offset(.23, .72),
      Offset(.25, .86),
      Offset(.43, .86),
      Offset(.63, .78),
      Offset(.79, .64),
      Offset(.87, .41),
      Offset(.47, .44),
      Offset(.46, .53),
    ],
    [
      Offset(.84, .85),
      Offset(.77, .85),
      Offset(.74, .81),
      Offset(.78, .15),
      Offset(.77, .1),
      Offset(.15, .17),
      Offset(.12, .21),
      Offset(.14, .87),
      Offset(.13, .92),
      Offset(.66, .87),
    ],
    [
      Offset(.76, .39),
      Offset(.71, .26),
      Offset(.13, .39),
      Offset(.12, .62),
      Offset(.26, .71),
      Offset(.86, .54),
    ],
    [
      Offset(.17, .52),
      Offset(.29, .65),
      Offset(.45, .69),
      Offset(.62, .67),
      Offset(.76, .57),
      Offset(.85, .38),
      Offset(.25, .43),
    ],
    [
      Offset(.1, .4),
      Offset(.22, .57),
      Offset(.42, .66),
      Offset(.64, .66),
      Offset(.85, .56),
    ],
    [
      Offset(.13, .18),
      Offset(.15, .48),
      Offset(.79, .42),
      Offset(.82, .45),
      Offset(.81, .83),
      Offset(.59, .85),
      Offset(.58, .93),
    ],
  ];
  return RunningRecord(
    id: 'demo-september-$day',
    startedAt: DateTime(2026, 9, day, hour, minute),
    distanceKm: km,
    movingSeconds: seconds,
    calories: kcal,
    route: List.unmodifiable(
      shapes[shape].map(
        (p) => RecordCoordinate(37.54 - p.dy * .008, 126.92 + p.dx * .018),
      ),
    ),
    memo: '아침 공기가 좋아서 다리 두 개를 건넜다. 다음엔 원효대교까지.',
    pauseFractions: const [.27, .69],
    speeds: List.unmodifiable(
      List.generate(
        100,
        (i) => i == 86
            ? 11.6
            : 9.7 + math.sin(i * .61) * .26 + math.cos(i * 1.8) * .14,
      ),
    ),
    splitSeconds: List.unmodifiable(
      List.generate(
        km.floor(),
        (i) => day == 26
            ? [380, 375, 369, 378, 365, 371, 366][i]
            : (seconds / km + math.sin(i * 2) * 9).round(),
      ),
    ),
  );
}

/// GPS 경로를 종횡비를 유지해 축소합니다. 지도나 API에 의존하지 않습니다.
class MiniRunningRoute extends StatelessWidget {
  const MiniRunningRoute({
    super.key,
    required this.coordinates,
    this.strokeWidth = 1.8,
  });
  final List<RecordCoordinate> coordinates;
  final double strokeWidth;
  @override
  Widget build(BuildContext context) => Semantics(
    label: '러닝 GPS 경로',
    child: CustomPaint(
      painter: _MiniRoutePainter(coordinates, strokeWidth),
      size: Size.infinite,
    ),
  );
}

List<Offset> _project(List<RecordCoordinate> coordinates, Rect bounds) {
  if (coordinates.isEmpty) return [];
  final latitude =
      coordinates.map((p) => p.latitude).reduce((a, b) => a + b) /
      coordinates.length;
  final points = coordinates
      .map(
        (p) => Offset(
          p.longitude * math.cos(latitude * math.pi / 180),
          -p.latitude,
        ),
      )
      .toList();
  final minX = points.map((p) => p.dx).reduce(math.min),
      maxX = points.map((p) => p.dx).reduce(math.max);
  final minY = points.map((p) => p.dy).reduce(math.min),
      maxY = points.map((p) => p.dy).reduce(math.max);
  final scale = math.min(
    bounds.width / math.max(maxX - minX, .00000001),
    bounds.height / math.max(maxY - minY, .00000001),
  );
  return points
      .map(
        (p) =>
            bounds.center +
            Offset(
              (p.dx - (maxX + minX) / 2) * scale,
              (p.dy - (maxY + minY) / 2) * scale,
            ),
      )
      .toList();
}

Path _polyline(List<Offset> points) {
  final path = Path();
  if (points.isNotEmpty) {
    path.moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
  }
  return path;
}

class _MiniRoutePainter extends CustomPainter {
  const _MiniRoutePainter(this.coordinates, this.strokeWidth);
  final List<RecordCoordinate> coordinates;
  final double strokeWidth;
  @override
  void paint(Canvas canvas, Size size) {
    final points = _project(
      coordinates,
      (Offset.zero & size).deflate(strokeWidth),
    );
    final paint = Paint()
      ..color = recordOrange
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    if (points.length == 1) {
      canvas.drawCircle(
        points.first,
        strokeWidth,
        Paint()..color = recordOrange,
      );
    } else {
      canvas.drawPath(_polyline(points), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MiniRoutePainter oldDelegate) =>
      oldDelegate.coordinates != coordinates ||
      oldDelegate.strokeWidth != strokeWidth;
}

/// 임시 벡터 지도. 실제 지도 연동 시 이 위젯만 지도 SDK로 교체하면 됩니다.
class RecordRouteMap extends StatelessWidget {
  const RecordRouteMap({
    super.key,
    required this.record,
    this.detailed = false,
    this.borderRadius = 20,
  });
  final RunningRecord record;
  final bool detailed;
  final double borderRadius;
  @override
  Widget build(BuildContext context) => Semantics(
    label: '${record.place} 예시 지도 및 러닝 경로',
    child: ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CustomPaint(
        painter: _RecordMapPainter(record.route, detailed),
        size: Size.infinite,
      ),
    ),
  );
}

class _RecordMapPainter extends CustomPainter {
  const _RecordMapPainter(this.route, this.detailed);
  final List<RecordCoordinate> route;
  final bool detailed;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.scale(size.width / 342, size.height / 200);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 342, 200),
      Paint()..color = const Color(0xFF1E2633),
    );
    for (var y = -20.0; y < 240; y += 19) {
      for (var x = -20.0; x < 380; x += 16) {
        canvas.drawRect(
          Rect.fromLTWH(x + 3, y + 3, 6, 9),
          Paint()..color = const Color(0xFF293342),
        );
      }
      canvas.drawLine(
        Offset(0, y),
        Offset(342, y + 20),
        Paint()
          ..color = const Color(0xFF363E4B)
          ..strokeWidth = 2,
      );
    }
    for (var x = 0.0; x < 390; x += 43) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x - 20, 200),
        Paint()
          ..color = const Color(0xFF505C6D)
          ..strokeWidth = 3,
      );
    }
    final river = Path()
      ..moveTo(-10, 57)
      ..lineTo(352, 30)
      ..lineTo(352, 146)
      ..lineTo(-10, 177)
      ..close();
    canvas.drawPath(
      river,
      Paint()
        ..color = const Color(0xFF1C4735)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 22,
    );
    canvas.drawPath(river, Paint()..color = const Color(0xFF173C5C));
    for (final y in [43.0, 181.0]) {
      canvas.drawLine(
        Offset(-10, y),
        Offset(352, y - 29),
        Paint()
          ..color = const Color(0xFF101B24)
          ..strokeWidth = 10,
      );
      canvas.drawLine(
        Offset(-10, y),
        Offset(352, y - 29),
        Paint()
          ..color = const Color(0xFF627181)
          ..strokeWidth = 5,
      );
    }
    final rail = Path()
      ..moveTo(250, -10)
      ..lineTo(284, 161)
      ..quadraticBezierTo(300, 192, 225, 201);
    canvas.drawPath(
      rail,
      Paint()
        ..color = const Color(0xFF8470BE)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final physicalBounds = detailed
        ? Rect.fromLTWH(
            size.width * .14,
            size.height * .34,
            size.width * .72,
            size.height * .49,
          )
        : Rect.fromLTWH(
            size.width * .12,
            size.height * .16,
            size.width * .76,
            size.height * .67,
          );
    final points = _project(route, physicalBounds)
        .map((p) => Offset(p.dx * 342 / size.width, p.dy * 200 / size.height))
        .toList();
    for (final style in [
      (9.0, const Color(0xFF163429)),
      (5.5, const Color(0xFF8A4300)),
      (2.8, recordOrange),
    ]) {
      canvas.drawPath(
        _polyline(points),
        Paint()
          ..color = style.$2
          ..strokeWidth = style.$1
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
    }
    void label(String text, Offset p, double fontSize, Color color) {
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontFamily: AppTextStyles.bodyFontFamily,
            fontSize: fontSize,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, p);
    }

    if (size.width > 150) {
      label('한  강', const Offset(274, 79), 17, const Color(0xFF78A7CB));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(118, 91, 15, 16),
          const Radius.circular(5),
        ),
        Paint()..color = const Color(0xFF399A60),
      );
      label('♣', const Offset(121, 92), 12, Colors.white);
      label('밤섬', const Offset(137, 94), 10, Colors.white);
    }
    if (points.isNotEmpty) {
      for (final point in [points.first, points.last]) {
        canvas.drawCircle(point, 7, Paint()..color = const Color(0xFF18251F));
        canvas.drawCircle(point, 5.3, Paint()..color = Colors.white);
      }
      canvas.drawPath(
        Path()
          ..moveTo(points.first.dx - 1.5, points.first.dy - 3)
          ..lineTo(points.first.dx + 2.5, points.first.dy)
          ..lineTo(points.first.dx - 1.5, points.first.dy + 3)
          ..close(),
        Paint()..color = recordBackground,
      );
      canvas.drawRect(
        Rect.fromCenter(center: points.last, width: 4, height: 4),
        Paint()..color = recordBackground,
      );
    }
    if (detailed) {
      label('500 m', const Offset(15, 183), 9, Colors.white);
      canvas.drawLine(
        const Offset(15, 180),
        const Offset(61, 180),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 2,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RecordMapPainter oldDelegate) =>
      oldDelegate.route != route || oldDelegate.detailed != detailed;
}

class RecordDetailPage extends StatefulWidget {
  const RecordDetailPage({super.key, this.record, this.onMemoChanged});
  final RunningRecord? record;

  /// 저장소 연결 시 메모 변경 내용을 영속화하는 콜백.
  final ValueChanged<String>? onMemoChanged;
  @override
  State<RecordDetailPage> createState() => _RecordDetailPageState();
}

class _RecordDetailPageState extends State<RecordDetailPage> {
  RunningRecord get record => widget.record ?? demoRunningRecords[1];
  late String memo = record.memo;
  Future<void> _editMemo() async {
    final controller = TextEditingController(text: memo);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF171818),
        title: const Text('메모'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 5,
          maxLength: 500,
          decoration: const InputDecoration(hintText: '오늘의 러닝을 기록해보세요'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('저장'),
          ),
        ],
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 300));
    controller.dispose();
    if (result != null && mounted) {
      setState(() => memo = result);
      widget.onMemoChanged?.call(result);
    }
  }

  void _expandMap() => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: recordBackground,
        appBar: AppBar(
          title: const Text('러닝 경로'),
          backgroundColor: recordBackground,
        ),
        body: InteractiveViewer(
          minScale: 1,
          maxScale: 5,
          child: SizedBox.expand(
            child: RecordRouteMap(
              record: record,
              detailed: true,
              borderRadius: 0,
            ),
          ),
        ),
      ),
    ),
  );
  Widget _section(String title, {String? trailing}) => Padding(
    padding: const EdgeInsets.only(top: 38, bottom: 20),
    child: Row(
      children: [
        Text(title, style: recordText(14, weight: FontWeight.w700)),
        const SizedBox(width: 12),
        const Expanded(child: Divider(color: recordLine)),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          Text(trailing, style: recordText(11, color: recordMuted)),
        ],
      ],
    ),
  );
  Widget _metric(String title, String value, String unit) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: recordText(12, color: recordSecondary)),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text.rich(
            TextSpan(
              children: [
                for (final part in RegExp(
                  r'[0-9.]+|[^0-9.]+',
                ).allMatches(value))
                  TextSpan(
                    text: part.group(0),
                    style: RegExp(r'^[0-9]').hasMatch(part.group(0)!)
                        ? recordNumber(30)
                        : recordText(12, color: recordSecondary),
                  ),
                TextSpan(
                  text: ' $unit',
                  style: recordText(12, color: recordSecondary),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
  Widget _pair(Widget a, Widget b) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: a),
        const VerticalDivider(width: 36, color: recordLine),
        Expanded(child: b),
      ],
    ),
  );
  Widget _timeRow(String title, String value) => Container(
    padding: const EdgeInsets.symmetric(vertical: 14),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: recordLine)),
    ),
    child: Row(
      children: [
        Text(title, style: recordText(12, color: recordSecondary)),
        const Spacer(),
        Text(value, style: recordText(14, weight: FontWeight.w700)),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) {
    final r = record;
    return Scaffold(
      backgroundColor: recordBackground,
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 405,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  RecordRouteMap(record: r, detailed: true, borderRadius: 0),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.center,
                        colors: [Color(0xB3000000), Colors.transparent],
                      ),
                    ),
                  ),
                  SafeArea(
                    bottom: false,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                        child: Row(
                          children: [
                            _mapButton(
                              Icons.chevron_left,
                              () => Navigator.maybePop(context),
                              '뒤로',
                            ),
                            Expanded(
                              child: Text(
                                '기록 상세',
                                textAlign: TextAlign.center,
                                style: recordText(14, weight: FontWeight.w700),
                              ),
                            ),
                            PopupMenuButton<String>(
                              tooltip: '기록 메뉴',
                              icon: const Icon(Icons.more_horiz),
                              color: const Color(0xFF202323),
                              onSelected: (_) => _editMemo(),
                              itemBuilder: (_) => [
                                const PopupMenuItem(
                                  value: 'memo',
                                  child: Text('메모 수정'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: TextButton.icon(
                      onPressed: _expandMap,
                      style: TextButton.styleFrom(
                        backgroundColor: recordBackground,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.open_in_full, size: 13),
                      label: const Text(
                        '지도 크게 보기',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${r.startedAt.year}년 ${r.dateLabel}',
                        style: recordText(22, weight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${clockText(r.startedAt)} - ${clockText(r.endedAt)} · 여의도 · 마포',
                        style: recordText(12, color: recordSecondary),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        '${r.place}에서 출발해 마포대교와 서강대교를 건너 한 바퀴, ${r.distanceKm.toStringAsFixed(2)} km를 달렸어요.',
                        style: recordText(
                          15,
                          weight: FontWeight.w600,
                        ).copyWith(height: 1.7),
                      ),
                      const SizedBox(height: 26),
                      _endpoint(
                        '출발',
                        r.startPlace,
                        clockText(r.startedAt),
                        Icons.play_arrow,
                      ),
                      Container(
                        margin: const EdgeInsets.only(left: 10),
                        padding: const EdgeInsets.fromLTRB(24, 12, 0, 12),
                        decoration: const BoxDecoration(
                          border: Border(
                            left: BorderSide(color: recordOrange, width: 2),
                          ),
                        ),
                        child: Text(
                          '${r.distanceKm.toStringAsFixed(2)} km · ${r.durationLabel} 동안 달린 길',
                          style: recordText(11, color: recordMuted),
                        ),
                      ),
                      _endpoint(
                        '도착',
                        r.endPlace,
                        clockText(r.endedAt),
                        Icons.stop,
                      ),
                      const SizedBox(height: 34),
                      const Divider(color: recordLine),
                      const SizedBox(height: 14),
                      Text(
                        '총 거리',
                        style: recordText(12, color: recordSecondary),
                      ),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: r.distanceKm.toStringAsFixed(2),
                              style: recordNumber(80),
                            ),
                            TextSpan(
                              text: ' km',
                              style: recordText(20, color: recordSecondary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Divider(height: 1, color: recordLine),
                      _pair(
                        _metric(
                          '운동 시간',
                          '${r.movingSeconds ~/ 60}분 ${(r.movingSeconds % 60).toString().padLeft(2, '0')}',
                          '초',
                        ),
                        _metric(
                          '평균 페이스',
                          '${r.paceSeconds ~/ 60}분 ${r.paceSeconds % 60}초',
                          '/km',
                        ),
                      ),
                      const Divider(height: 1, color: recordLine),
                      _pair(
                        _metric(
                          '평균 속도',
                          r.averageSpeed.toStringAsFixed(1),
                          'km/h',
                        ),
                        _metric('최고 속도', r.maxSpeed.toStringAsFixed(1), 'km/h'),
                      ),
                      const Divider(height: 1, color: recordLine),
                      _pair(
                        _metric(
                          '최고 페이스',
                          r.maxSpeed > 0
                              ? '${(3600 / r.maxSpeed).round() ~/ 60}분 ${(3600 / r.maxSpeed).round() % 60}초'
                              : '—',
                          '/km',
                        ),
                        _metric('소모 칼로리', '${r.calories}', 'kcal'),
                      ),
                      _section(
                        '시간',
                        trailing:
                            '전체 ${durationWords(r.movingSeconds + r.pauseSeconds)}',
                      ),
                      LinearProgressIndicator(
                        value: r.movingSeconds + r.pauseSeconds == 0
                            ? 0
                            : r.movingSeconds /
                                  (r.movingSeconds + r.pauseSeconds),
                        minHeight: 10,
                        color: Colors.white,
                        backgroundColor: const Color(0xFF37424A),
                      ),
                      _pair(
                        _metric(
                          '■  이동 시간',
                          '${r.movingSeconds ~/ 60}분 ${r.movingSeconds % 60}',
                          '초',
                        ),
                        _metric(
                          '■  일시정지 시간',
                          '${r.pauseSeconds ~/ 60}분 ${r.pauseSeconds % 60}',
                          '초',
                        ),
                      ),
                      _timeRow('시작 시간', clockText(r.startedAt)),
                      _timeRow('종료 시간', clockText(r.endedAt)),
                      _section(
                        '속도',
                        trailing:
                            '평균 ${r.averageSpeed.toStringAsFixed(1)} km/h · 점선',
                      ),
                      SizedBox(
                        height: 170,
                        width: double.infinity,
                        child: CustomPaint(painter: _SpeedPainter(r)),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'ⓟ  일시정지한 지점',
                        style: recordText(11, color: recordMuted),
                      ),
                      _section('구간 기록', trailing: '1 km 페이스'),
                      if (r.splitSeconds.isEmpty)
                        Text(
                          '구간 기록이 없어요',
                          style: recordText(13, color: recordMuted),
                        )
                      else
                        ..._splits(r),
                      const SizedBox(height: 14),
                      Text(
                        '선이 길수록 빠르게 달린 구간이에요',
                        style: recordText(11, color: recordMuted),
                      ),
                      _section('소모 칼로리'),
                      Row(
                        children: [
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: '${r.calories}',
                                    style: recordNumber(54),
                                  ),
                                  TextSpan(
                                    text: ' kcal',
                                    style: recordText(
                                      16,
                                      color: recordSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const CircleAvatar(
                            backgroundColor: Color(0xFF161818),
                            child: Icon(
                              Icons.rice_bowl_outlined,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '햇반 약 ${(r.calories / 315).toStringAsFixed(1)}개',
                                style: recordText(15, weight: FontWeight.w700),
                              ),
                              Text(
                                '1개(210g) = 315 kcal',
                                style: recordText(11, color: recordMuted),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(child: _section('메모')),
                          Padding(
                            padding: const EdgeInsets.only(top: 18, left: 14),
                            child: IconButton(
                              tooltip: '메모 수정',
                              onPressed: _editMemo,
                              icon: const Icon(
                                Icons.edit_outlined,
                                size: 17,
                                color: recordSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: _editMemo,
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFF151616),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            memo.isEmpty ? '오늘의 러닝을 기록해보세요' : memo,
                            style: recordText(14).copyWith(height: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 42),
                      const Divider(color: recordLine),
                      const SizedBox(height: 10),
                      Text(
                        '예시 GPS 경로 · 통계 데이터\n실제 GPS 수집 및 계정 저장은 추후 연결됩니다.',
                        style: recordText(
                          11,
                          color: recordMuted,
                        ).copyWith(height: 1.6),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mapButton(IconData icon, VoidCallback onTap, String tooltip) =>
      IconButton(
        onPressed: onTap,
        tooltip: tooltip,
        style: IconButton.styleFrom(backgroundColor: recordBackground),
        icon: Icon(icon),
      );
  Widget _endpoint(String label, String place, String time, IconData icon) =>
      Row(
        children: [
          CircleAvatar(
            radius: 11,
            backgroundColor: Colors.white,
            child: Icon(icon, color: recordBackground, size: 15),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: recordText(11, color: recordMuted)),
                const SizedBox(height: 4),
                Text(place, style: recordText(14, weight: FontWeight.w700)),
              ],
            ),
          ),
          Text(time, style: recordText(12, color: recordSecondary)),
        ],
      );
  List<Widget> _splits(RunningRecord r) {
    final fastest = r.splitSeconds.reduce(math.min);
    return [
      for (var i = 0; i < r.splitSeconds.length; i++)
        Container(
          height: 41,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: recordLine)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 54,
                child: Text(
                  '${i + 1} km',
                  style: recordText(12, color: recordMuted),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, c) => Row(
                    children: [
                      Container(
                        width:
                            (c.maxWidth -
                                (r.splitSeconds[i] == fastest ? 76 : 0)) *
                            (.55 + (400 - r.splitSeconds[i]) / 100).clamp(
                              .35,
                              1,
                            ),
                        height: r.splitSeconds[i] == fastest ? 3 : 2,
                        color: r.splitSeconds[i] == fastest
                            ? recordOrange
                            : recordSecondary,
                      ),
                      if (r.splitSeconds[i] == fastest) ...[
                        const SizedBox(width: 8),
                        Text(
                          '가장 빠른 구간',
                          style: recordText(10, color: recordOrange),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Text(
                paceText(r.splitSeconds[i]),
                style: recordNumber(
                  17,
                  color: r.splitSeconds[i] == fastest
                      ? recordOrange
                      : Colors.white,
                ),
              ),
            ],
          ),
        ),
      if (r.distanceKm % 1 > .001)
        _timeRow(
          '${(r.distanceKm % 1).toStringAsFixed(2)} km  ·  남은 구간',
          r.paceLabel,
        ),
    ];
  }
}

class _SpeedPainter extends CustomPainter {
  const _SpeedPainter(this.record);
  final RunningRecord record;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTRB(26, 25, size.width - 24, size.height - 28);
    void label(String text, Offset p, {Color color = recordMuted}) {
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontFamily: AppTextStyles.bodyFontFamily,
            fontSize: 10,
            color: color,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, p);
    }

    for (final speed in [8, 10, 12]) {
      final y = rect.bottom - (speed - 7) / 6 * rect.height;
      canvas.drawLine(
        Offset(rect.left, y),
        Offset(rect.right, y),
        Paint()..color = recordLine,
      );
      label('$speed', Offset(0, y - 6));
    }
    final averageY = rect.bottom - (record.averageSpeed - 7) / 6 * rect.height;
    for (var x = rect.left; x < rect.right; x += 5) {
      canvas.drawLine(
        Offset(x, averageY),
        Offset(x + 2, averageY),
        Paint()..color = recordMuted,
      );
    }
    final points = <Offset>[];
    for (final fraction in record.pauseFractions) {
      final x = rect.left + fraction.clamp(0, 1) * rect.width;
      for (var y = rect.top; y < rect.bottom; y += 5) {
        canvas.drawLine(
          Offset(x, y),
          Offset(x, y + 2),
          Paint()..color = recordMuted,
        );
      }
      canvas.drawCircle(
        Offset(x, rect.top - 12),
        8,
        Paint()
          ..color = recordMuted
          ..style = PaintingStyle.stroke,
      );
      canvas.drawLine(
        Offset(x - 2, rect.top - 15),
        Offset(x - 2, rect.top - 9),
        Paint()
          ..color = recordMuted
          ..strokeWidth = 1.5,
      );
      canvas.drawLine(
        Offset(x + 2, rect.top - 15),
        Offset(x + 2, rect.top - 9),
        Paint()
          ..color = recordMuted
          ..strokeWidth = 1.5,
      );
    }
    for (var i = 0; i < record.speeds.length; i++) {
      points.add(
        Offset(
          rect.left + i / math.max(1, record.speeds.length - 1) * rect.width,
          rect.bottom - (record.speeds[i] - 7) / 6 * rect.height,
        ),
      );
    }
    canvas.drawPath(
      _polyline(points),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    if (points.isNotEmpty) {
      final maxIndex = record.speeds.indexOf(record.maxSpeed);
      canvas.drawCircle(points[maxIndex], 4, Paint()..color = recordOrange);
      label(
        '최고 ${record.maxSpeed.toStringAsFixed(1)} km/h',
        Offset(
          (points[maxIndex].dx - 60).clamp(0, math.max(0, size.width - 90)),
          points[maxIndex].dy - 22,
        ),
        color: Colors.white,
      );
    }
    for (var i = 0; i <= record.distanceKm.floor(); i++) {
      label(
        '$i',
        Offset(
          rect.left + i / math.max(.01, record.distanceKm) * rect.width,
          rect.bottom + 13,
        ),
      );
    }
    label('km', Offset(size.width - 16, rect.bottom + 13));
  }

  @override
  bool shouldRepaint(covariant _SpeedPainter oldDelegate) =>
      oldDelegate.record != record;
}
