import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart'
    show
        CameraPosition,
        CameraUpdate,
        LatLng,
        MapLibreMap,
        MapLibreMapController,
        MinMaxZoomPreference;

import '../../design_system/app_colors.dart';
import '../../design_system/app_component_metrics.dart';
import '../../design_system/app_motion.dart';
import '../../design_system/app_radius.dart';
import '../../design_system/app_spacing.dart';
import '../../design_system/app_text_styles.dart';
import 'running_start_page.dart';

enum RunningMode { free, distanceGoal, timeGoal }

/// 시작 화면에서 고른 옵션. 카운트다운이 끝나면 러닝 화면으로 전달합니다.
class RunningStartOptions {
  const RunningStartOptions({
    required this.mode,
    required this.voiceGuide,
    required this.autoPause,
  });

  final RunningMode mode;
  final bool voiceGuide;
  final bool autoPause;
}

/// 05 러닝 시작 + 05-1 카운트다운.
/// 시작하기 → 3·2·1 카운트다운(화면을 누르면 바로) → [RunningStartPage].
class RunningHomePage extends StatefulWidget {
  const RunningHomePage({super.key});

  @override
  State<RunningHomePage> createState() => _RunningHomePageState();
}

enum RunningLocationState {
  checking,
  ready,
  serviceDisabled,
  denied,
  deniedForever,
}

/// 러닝용 GPS 설정. 1초 간격.
/// [background]가 true면 화면이 꺼지거나 다른 앱으로 가도 위치를 계속 받습니다(러닝 중에만).
LocationSettings runningLocationSettings({bool background = false}) =>
    switch (defaultTargetPlatform) {
      TargetPlatform.iOS => AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        activityType: ActivityType.fitness,
        pauseLocationUpdatesAutomatically: false,
        allowBackgroundLocationUpdates: background,
        showBackgroundLocationIndicator: background,
      ),
      TargetPlatform.android => AndroidSettings(
        accuracy: LocationAccuracy.best,
        intervalDuration: const Duration(seconds: 1),
      ),
      _ => const LocationSettings(accuracy: LocationAccuracy.best),
    };

class _RunningHomePageState extends State<RunningHomePage> {
  /// 위치를 받기 전 지도 중심(서울시청).
  static const _fallbackCenter = LatLng(37.5665, 126.9780);
  static const _initialZoom = MapZoom.start;

  final _map = RunneryMapController();
  StreamSubscription<Position>? _positionSub;
  RunningLocationState _locationState = RunningLocationState.checking;
  Position? _position;
  bool _followUser = true;
  bool _showMapLabels = true;

  String? _placeName;
  LatLng? _lastGeocodedAt;
  bool _geocoding = false;

  RunningMode _mode = RunningMode.free;
  bool _voiceGuide = true;
  bool _autoPause = true;
  bool _countingDown = false;

  @override
  void initState() {
    super.initState();
    _startLocation();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _map.dispose();
    super.dispose();
  }

  // ── 위치 ────────────────────────────────────────────

  Future<RunningLocationState> _checkLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return RunningLocationState.serviceDisabled;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return switch (permission) {
      LocationPermission.whileInUse ||
      LocationPermission.always => RunningLocationState.ready,
      LocationPermission.deniedForever => RunningLocationState.deniedForever,
      LocationPermission.denied ||
      LocationPermission.unableToDetermine => RunningLocationState.denied,
    };
  }

  Future<void> _startLocation() async {
    final state = await _checkLocation();
    if (!mounted) return;
    setState(() => _locationState = state);
    if (state != RunningLocationState.ready || _positionSub != null) return;

    _positionSub = Geolocator.getPositionStream(
      locationSettings: runningLocationSettings(),
    ).listen(_onPosition, onError: (_) => setState(() => _position = null));
  }

  void _onPosition(Position position) {
    setState(() => _position = position);
    final point = LatLng(position.latitude, position.longitude);
    if (_followUser) _map.moveTo(point);
    _updatePlaceName(point);
  }

  Future<void> _updatePlaceName(LatLng point) async {
    final last = _lastGeocodedAt;
    if (_geocoding ||
        (last != null &&
            Geolocator.distanceBetween(
                  last.latitude,
                  last.longitude,
                  point.latitude,
                  point.longitude,
                ) <
                30)) {
      return;
    }
    _geocoding = true;
    try {
      final places = await Geocoding().placemarkFromCoordinates(
        point.latitude,
        point.longitude,
      );
      final place = places.firstOrNull;
      final name = [
        place?.name,
        place?.thoroughfare,
        place?.subLocality,
      ].firstWhere((s) => s != null && s.isNotEmpty, orElse: () => null);
      _lastGeocodedAt = point;
      if (mounted) setState(() => _placeName = name);
    } catch (_) {
      // 지명은 부가 정보라 실패해도 칩만 숨깁니다.
    } finally {
      _geocoding = false;
    }
  }

  void _recenter() {
    setState(() => _followUser = true);
    final p = _position;
    if (p != null) {
      _map.moveTo(LatLng(p.latitude, p.longitude), zoom: _initialZoom);
    }
  }

  // ── 시작 ────────────────────────────────────────────

  Future<void> _onStartPressed() async {
    if (_locationState != RunningLocationState.ready) {
      await _startLocation();
      if (!mounted) return;
      if (_locationState != RunningLocationState.ready) {
        _showLocationProblem();
        return;
      }
    }
    setState(() => _countingDown = true);
  }

  Future<void> _onCountdownFinished() async {
    final options = RunningStartOptions(
      mode: _mode,
      voiceGuide: _voiceGuide,
      autoPause: _autoPause,
    );
    // 러닝 화면이 자체 GPS 스트림을 쓰므로 미리보기 스트림은 잠시 끕니다.
    await _positionSub?.cancel();
    _positionSub = null;
    if (!mounted) return;

    // 카운트다운→러닝: Smart Animate 400ms, ease-out.
    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: AppMotion.runningTransition,
        pageBuilder: (_, _, _) => RunningStartPage(
          options: options,
          initialCenter: _position == null
              ? null
              : LatLng(_position!.latitude, _position!.longitude),
        ),
        transitionsBuilder: (_, animation, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _countingDown = false);
    _startLocation();
  }

  Future<void> _showLocationProblem() async {
    final serviceOff = _locationState == RunningLocationState.serviceDisabled;
    final openSettings = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(serviceOff ? '위치 서비스가 꺼져 있어요' : '위치 권한이 필요해요'),
        content: Text(
          serviceOff
              ? '설정에서 위치 서비스를 켜면 달린 거리를 기록할 수 있어요.'
              : '설정에서 위치 접근을 허용하면 달린 거리를 기록할 수 있어요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('닫기'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('설정 열기'),
          ),
        ],
      ),
    );
    if (openSettings != true) return;
    serviceOff
        ? await Geolocator.openLocationSettings()
        : await Geolocator.openAppSettings();
  }

  // ── 화면 ────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final position = _position;
    final point = position == null
        ? null
        : LatLng(position.latitude, position.longitude);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.mapLand,
        // 시트·버튼을 지도 children에 두면 그 위의 드래그가 지도를 움직이므로 위에 겹칩니다.
        body: Stack(
          children: [
            RunneryMap(
              controller: _map,
              initialCenter: point ?? _fallbackCenter,
              initialZoom: _initialZoom,
              showLabels: _showMapLabels,
              userLocation: point == null
                  ? null
                  : MapUserLocation(point, position!.accuracy.clamp(8, 80)),
              labels: [
                if (point != null && _placeName != null && !_countingDown)
                  MapLabel(point, MapLabelKind.current, _placeName),
              ],
              onUserGesture: () {
                if (_followUser) setState(() => _followUser = false);
              },
            ),
            AnimatedSwitcher(
              duration: AppMotion.countdownTransition,
              switchInCurve: Curves.linear,
              switchOutCurve: Curves.linear,
              child: _countingDown
                  ? _CountdownView(
                      key: const ValueKey('countdown'),
                      voiceGuide: _voiceGuide,
                      position: position,
                      onFinished: _onCountdownFinished,
                    )
                  : _buildControls(position),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(Position? position) {
    return SizedBox.expand(
      key: const ValueKey('controls'),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.space4,
                  AppSpacing.topControlSafeAreaGapMax,
                  AppSpacing.space4,
                  0,
                ),
                child: Row(
                  children: [
                    MapCircleButton(
                      icon: Icons.close,
                      tooltip: '닫기',
                      onPressed: () => Navigator.maybePop(context),
                    ),
                    const Spacer(),
                    GpsStatusChip(
                      locationState: _locationState,
                      position: position,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: AppSpacing.mapCardHorizontal,
            right: AppSpacing.mapCardHorizontal,
            bottom: AppSpacing.mapCardBottom,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                        left:
                            AppSpacing.mapScaleLeft -
                            AppSpacing.mapCardHorizontal,
                      ),
                      child: MapScaleBar(camera: _map),
                    ),
                    const Spacer(),
                    Column(
                      children: [
                        MapCircleButton(
                          icon: Icons.layers_outlined,
                          tooltip: _showMapLabels ? '지명 숨기기' : '지명 보기',
                          onPressed: () =>
                              setState(() => _showMapLabels = !_showMapLabels),
                        ),
                        const SizedBox(height: AppSpacing.mapControlGap),
                        MapCircleButton(
                          icon: _followUser
                              ? Icons.my_location
                              : Icons.location_searching,
                          tooltip: '현재 위치',
                          onPressed: _recenter,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.mapControlAboveCard),
                _StartSheet(
                  mode: _mode,
                  voiceGuide: _voiceGuide,
                  autoPause: _autoPause,
                  // 권한은 있는데 첫 위치를 아직 못 받았을 때만 비활성.
                  canStart:
                      !(_locationState == RunningLocationState.ready &&
                          position == null),
                  onModeChanged: (mode) => setState(() => _mode = mode),
                  onVoiceGuideToggled: () =>
                      setState(() => _voiceGuide = !_voiceGuide),
                  onAutoPauseToggled: () =>
                      setState(() => _autoPause = !_autoPause),
                  onStart: _onStartPressed,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 지도 ──────────────────────────────────────────────

/// 지도 위에 겹친 UI는 지도 제스처 영역 밖에 있어야 해서, 카메라 값을 따로 받습니다.
class MapScaleBar extends StatelessWidget {
  const MapScaleBar({super.key, required this.camera});

  final ValueListenable<MapViewport?> camera;

  static const _maxWidth = 80.0;
  static const _steps = [
    5,
    10,
    20,
    50,
    100,
    200,
    500,
    1000,
    2000,
    5000,
    10000,
    20000,
    50000,
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: camera,
      builder: (context, camera, _) =>
          camera == null ? const SizedBox.shrink() : _buildFor(camera),
    );
  }

  Widget _buildFor(MapViewport camera) {
    // MapLibre 512px 타일 기준 1px당 미터.
    final metersPerPixel =
        40075016.686 *
        math.cos(camera.latitude * math.pi / 180) /
        (512 * math.pow(2, camera.zoom));
    final meters = _steps.lastWhere(
      (m) => m / metersPerPixel <= _maxWidth,
      orElse: () => _steps.first,
    );
    final width = meters / metersPerPixel;
    final label = meters >= 1000 ? '${meters ~/ 1000} km' : '$meters m';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 2),
        CustomPaint(size: Size(width, 5), painter: _ScaleBarPainter()),
        const SizedBox(height: 4),
        // 지도 데이터 이용 조건의 출처 표기.
        const Text(
          '© OpenFreeMap © OpenMapTiles © OpenStreetMap',
          style: TextStyle(fontSize: 8, color: AppColors.textTertiary),
        ),
      ],
    );
  }
}

class _ScaleBarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textPrimary
      ..strokeWidth = 1;
    canvas
      ..drawLine(Offset(0, size.height), Offset(size.width, size.height), paint)
      ..drawLine(Offset.zero, Offset(0, size.height), paint)
      ..drawLine(Offset(size.width, 0), Offset(size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(_ScaleBarPainter oldDelegate) => false;
}

// ── 시작 시트 ─────────────────────────────────────────

class _StartSheet extends StatelessWidget {
  const _StartSheet({
    required this.mode,
    required this.voiceGuide,
    required this.autoPause,
    required this.canStart,
    required this.onModeChanged,
    required this.onVoiceGuideToggled,
    required this.onAutoPauseToggled,
    required this.onStart,
  });

  final RunningMode mode;
  final bool voiceGuide;
  final bool autoPause;
  final bool canStart;
  final ValueChanged<RunningMode> onModeChanged;
  final VoidCallback onVoiceGuideToggled;
  final VoidCallback onAutoPauseToggled;
  final VoidCallback onStart;

  String get _description => switch (mode) {
    RunningMode.free =>
      voiceGuide ? '목표 없이 편하게 달려요. 1 km마다 음성으로 알려드려요.' : '목표 없이 편하게 달려요.',
    RunningMode.distanceGoal =>
      voiceGuide ? '정한 거리를 채우면 음성으로 알려드려요.' : '정한 거리까지 달려요.',
    RunningMode.timeGoal =>
      voiceGuide ? '정한 시간이 되면 음성으로 알려드려요.' : '정한 시간 동안 달려요.',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space5),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.96),
        borderRadius: AppRadius.sheetBorder,
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '어떻게 달릴까요?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          _ModeSegment(selected: mode, onChanged: onModeChanged),
          const SizedBox(height: AppSpacing.space3),
          Text(
            _description,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          Wrap(
            spacing: AppSpacing.space2,
            runSpacing: AppSpacing.space2,
            children: [
              StatusChip(
                label: voiceGuide ? '음성 안내 켜짐' : '음성 안내 꺼짐',
                icon: voiceGuide
                    ? Icons.volume_up_outlined
                    : Icons.volume_off_outlined,
                floating: false,
                onTap: onVoiceGuideToggled,
              ),
              StatusChip(
                label: autoPause ? '자동 일시정지 켜짐' : '자동 일시정지 꺼짐',
                icon: Icons.pause,
                floating: false,
                onTap: onAutoPauseToggled,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space5),
          PrimaryButton(
            label: '시작하기',
            icon: Icons.play_arrow_rounded,
            onPressed: canStart ? onStart : null,
          ),
        ],
      ),
    );
  }
}

/// 세그먼트: 높이 44, 선택은 흰 배경 + 검정 글자. (가이드: 선택 탭에 주황 금지)
class _ModeSegment extends StatelessWidget {
  const _ModeSegment({required this.selected, required this.onChanged});

  final RunningMode selected;
  final ValueChanged<RunningMode> onChanged;

  static const _labels = {
    RunningMode.free: '자유 러닝',
    RunningMode.distanceGoal: '거리 목표',
    RunningMode.timeGoal: '시간 목표',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppComponentMetrics.segmentHeights[1],
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: AppRadius.pillBorder,
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Row(
        children: [
          for (final mode in RunningMode.values)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(mode),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: mode == selected
                        ? AppColors.textPrimary
                        : Colors.transparent,
                    borderRadius: AppRadius.pillBorder,
                  ),
                  child: Text(
                    _labels[mode]!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: mode == selected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: mode == selected
                          ? Colors.black
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── 카운트다운 ────────────────────────────────────────

/// 05-1 카운트다운. 3·2·1 후 자동 시작, 화면을 누르면 바로 시작합니다.
class _CountdownView extends StatefulWidget {
  const _CountdownView({
    super.key,
    required this.voiceGuide,
    required this.position,
    required this.onFinished,
  });

  final bool voiceGuide;
  final Position? position;
  final VoidCallback onFinished;

  @override
  State<_CountdownView> createState() => _CountdownViewState();
}

class _CountdownViewState extends State<_CountdownView>
    with SingleTickerProviderStateMixin {
  static final _seconds = AppMotion.countdown.inSeconds;

  late final AnimationController _controller =
      AnimationController(vsync: this, duration: AppMotion.countdown)
        ..addListener(_onTick)
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed) _finish();
        })
        ..forward();

  late int _number = _seconds;
  bool _finished = false;

  int _numberAt(double t) =>
      (_seconds - (t * _seconds).floor()).clamp(1, _seconds);

  void _onTick() {
    final number = _numberAt(_controller.value);
    if (number != _number) {
      _number = number;
      HapticFeedback.lightImpact();
    }
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    _controller.stop();
    HapticFeedback.mediumImpact();
    widget.onFinished();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ringSize = math.min(MediaQuery.sizeOf(context).width * 0.66, 280.0);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _finish,
      child: ColoredBox(
        color: AppColors.background.withValues(alpha: 0.55),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: AppSpacing.topControlSafeAreaGapMax,
                left: AppSpacing.space4,
                right: AppSpacing.space4,
                child: Row(
                  children: [
                    StatusChip(
                      label: widget.voiceGuide ? '음성 안내 켜짐' : '음성 안내 꺼짐',
                      icon: widget.voiceGuide
                          ? Icons.volume_up_outlined
                          : Icons.volume_off_outlined,
                    ),
                    const Spacer(),
                    GpsStatusChip(
                      locationState: RunningLocationState.ready,
                      position: widget.position,
                      compact: true,
                    ),
                  ],
                ),
              ),
              Align(
                alignment: const Alignment(0, -0.12),
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final elapsed = _controller.value * _seconds;
                    // 매 초 링이 12시 방향부터 시계방향으로 한 바퀴 찹니다.
                    final progress = _controller.isCompleted
                        ? 1.0
                        : elapsed % 1;
                    final number = _numberAt(_controller.value);
                    return SizedBox.square(
                      dimension: ringSize,
                      child: CustomPaint(
                        painter: _CountdownRingPainter(progress),
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: AppMotion.countdownTransition,
                            transitionBuilder: (child, animation) =>
                                FadeTransition(
                                  opacity: animation,
                                  child: ScaleTransition(
                                    scale: Tween(
                                      begin: 1.2,
                                      end: 1.0,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                ),
                            child: Text(
                              '$number',
                              key: ValueKey(number),
                              style: TextStyle(
                                fontFamily: AppTextStyles.numberFontFamily,
                                fontVariations: const [
                                  AppTextStyles.numberWidth,
                                ],
                                fontSize: ringSize * 0.6,
                                fontWeight: FontWeight.w800,
                                height: 1,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Align(
                alignment: Alignment(0, 0.5),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '곧 러닝을 시작해요',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: AppSpacing.space2),
                    Text(
                      '화면을 누르면 바로 시작돼요',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountdownRingPainter extends CustomPainter {
  _CountdownRingPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 4.0;
    final circle = (Offset.zero & size).deflate(strokeWidth / 2);

    canvas.drawOval(
      circle,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = AppColors.textPrimary.withValues(alpha: 0.15),
    );
    if (progress <= 0) return;
    canvas.drawArc(
      circle,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = AppColors.primary,
    );
  }

  @override
  bool shouldRepaint(_CountdownRingPainter old) => old.progress != progress;
}

// ── 공통 조각 ─────────────────────────────────────────

final mapFloatingColor = AppColors.mapButtonBase.withValues(
  alpha: AppColors.mapButtonOpacity,
);

/// 지도 위 원형 버튼: 지름 44, 아이콘 22.
class MapCircleButton extends StatelessWidget {
  const MapCircleButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: mapFloatingColor,
        shape: const CircleBorder(
          side: BorderSide(color: AppColors.mapButtonBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox.square(
            dimension: AppComponentMetrics.mapButtonSize,
            child: Icon(
              icon,
              size: AppComponentMetrics.mapButtonIconSize,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

/// 칩: 높이 32. 지도 위에서는 떠 있는 바탕, 시트 안에서는 테두리만.
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.icon,
    this.leading,
    this.trailing,
    this.onTap,
    this.floating = true,
  });

  final String label;
  final IconData? icon;

  /// 아이콘 대신 앞에 둘 위젯. 예: '기록 중'의 주황 점.
  final Widget? leading;

  /// 글자 뒤에 둘 위젯. 예: '쉬는 시간 00:48'의 시간.
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool floating;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: floating ? mapFloatingColor : Colors.transparent,
      shape: StadiumBorder(
        side: BorderSide(
          color: floating ? AppColors.mapButtonBorder : AppColors.borderDefault,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: AppComponentMetrics.chipHeights.last,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null)
                leading!
              else if (icon != null)
                Icon(icon, size: 14, color: AppColors.textPrimary),
              if (leading != null || icon != null) const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}

/// GPS 정확도 반경으로 신호 상태를 표시합니다. [compact]는 카운트다운의 짧은 표기.
class GpsStatusChip extends StatelessWidget {
  const GpsStatusChip({
    super.key,
    required this.locationState,
    required this.position,
    this.compact = false,
  });

  final RunningLocationState locationState;
  final Position? position;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final accuracy = position?.accuracy;
    final (label, icon) = switch (locationState) {
      RunningLocationState.serviceDisabled => (
        '위치 서비스가 꺼져 있어요',
        Icons.location_disabled,
      ),
      RunningLocationState.denied || RunningLocationState.deniedForever => (
        '위치 권한이 필요해요',
        Icons.location_disabled,
      ),
      _ when accuracy == null => (
        'GPS 신호를 찾고 있어요',
        Icons.signal_cellular_alt_1_bar,
      ),
      _ when accuracy <= 10 => (
        compact ? 'GPS 양호' : 'GPS 신호 양호',
        Icons.signal_cellular_alt,
      ),
      _ when accuracy <= 25 => (
        compact ? 'GPS 보통' : 'GPS 신호 보통',
        Icons.signal_cellular_alt_2_bar,
      ),
      _ => (compact ? 'GPS 약함' : 'GPS 신호 약함', Icons.signal_cellular_alt_1_bar),
    };
    return StatusChip(label: label, icon: icon);
  }
}

/// 주황 버튼: 높이 60, 아이콘 18 + 간격 8, 글자 검정. 눌림 #E06B00.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppComponentMetrics.primaryButtonMediumHeight,
      child: FilledButton(
        onPressed: onPressed,
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: AppRadius.pillBorder),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.primary.withValues(alpha: 0.4);
            }
            if (states.contains(WidgetState.pressed)) {
              return AppColors.primaryPressed;
            }
            return AppColors.primary;
          }),
          foregroundColor: const WidgetStatePropertyAll(Colors.black),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: AppComponentMetrics.buttonIconSize),
            const SizedBox(width: AppSpacing.buttonIconGap),
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════
// 러너리 지도: MapLibre + OpenFreeMap 벡터 타일 (API 키 불필요)
// 스타일 출처: '10 지도 · 스타일 가이드 — 어두운 지도, 가장 선명한 길'
// ═════════════════════════════════════════════════════

/// 지도 스타일 색. 스타일 JSON에 넣기 위해 HEX 문자열로 둡니다.
abstract final class MapPalette {
  static const land = '#1D2331';
  static const building = '#28303F';
  static const tower = '#2E3749';
  static const apartment = '#2C3345';
  static const park = '#1C4A31';
  static const water = '#153A5C';
  static const expressway = '#5C6882';
  static const arterial = '#4A5467';
  static const collector = '#3A4354';
  static const local = '#2F3746';
  static const alley = '#272E3A';
  static const casing = '#141922';
  static const subway5 = '#9B80F2';
  static const subway9 = '#D6AF55';
  static const labelDistrict = '#DCE2EA';
  static const labelPlace = '#CAD2DC';
  static const labelDong = '#A9B4C2';
  static const labelRoad = '#909BAB';
  static const labelWater = '#7BAFDD';
  static const labelHalo = '#181D26';

  static const poiPark = Color(0xFF3E9A5C);
  static const poiSchool = Color(0xFF4A7FC4);
  static const poiHospital = Color(0xFFCC5A5A);
  static const poiOther = Color(0xFFB4609A);
  static const poiLandmark = Color(0xFF5C6882);
  static const subwayBadge = Color(0xFF5C6882);
}

/// 확대 단계. 확대할수록 정보가 한 겹씩 늘어납니다. (MapLibre 512px 타일 기준)
abstract final class MapZoom {
  /// 개요: + 보조간선·지하철 노선·구 이름·강 이름
  static const overview = 12.5;

  /// 기본: + 건물·생활도로·역·장소·도로 이름 (러닝 중·결과·상세)
  static const basic = 13.5;

  /// 상세: + 골목·아파트·주차장·쇼핑 (러닝 시작·지도 크게 보기)
  static const detail = 14.5;

  static const start = 14.5;
  static const running = 14.0;
}

/// 경로 두께: 지도 상세·결과·상세 4.5 / 러닝 중 4 / 미리보기 3.
abstract final class RouteWidth {
  static const detail = 4.5;
  static const running = 4.0;
  static const preview = 3.0;
}

enum MapMarkerKind { start, finish, pause }

class MapMarker {
  const MapMarker(this.point, this.kind);
  final LatLng point;
  final MapMarkerKind kind;
}

enum MapLabelKind { start, finish, current }

/// 지명 칩: '▶ 출발 여의나루역', '■ 도착 여의도공원', '현재 위치 여의나루역 2번 출구'.
class MapLabel {
  const MapLabel(this.point, this.kind, this.name, {bool? above})
    : above = above ?? kind == MapLabelKind.start;
  final LatLng point;
  final MapLabelKind kind;
  final String? name;

  /// 칩을 지점 위(true)에 둘지 아래(false)에 둘지.
  final bool above;
}

class MapUserLocation {
  const MapUserLocation(this.point, this.accuracy);
  final LatLng point;
  final double accuracy;
}

/// 축척 계산에 필요한 카메라 값.
class MapViewport {
  const MapViewport({required this.latitude, required this.zoom});
  final double latitude;
  final double zoom;
}

/// 화면이 지도 카메라를 움직이고, 축척 막대가 카메라 값을 구독할 때 씁니다.
class RunneryMapController extends ValueNotifier<MapViewport?> {
  RunneryMapController() : super(null);

  MapLibreMapController? _map;
  bool _disposed = false;

  void _update(CameraPosition? position) {
    if (_disposed || position == null) return;
    value = MapViewport(
      latitude: position.target.latitude,
      zoom: position.zoom,
    );
  }

  Future<void> moveTo(LatLng target, {double? zoom}) async {
    await _map?.animateCamera(
      zoom == null
          ? CameraUpdate.newLatLng(target)
          : CameraUpdate.newLatLngZoom(target, zoom),
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _map = null;
    super.dispose();
  }
}

/// 러너리 스타일 지도. 경로·마커·지명 칩·내 위치는 지도 엔진이 직접 그립니다.
class RunneryMap extends StatefulWidget {
  const RunneryMap({
    super.key,
    required this.controller,
    required this.initialCenter,
    this.initialZoom = MapZoom.start,
    this.interactive = true,
    this.showLabels = true,
    this.route = const [],
    this.routeWidth = RouteWidth.running,
    this.routeOpacity = 1,
    this.markers = const [],
    this.labels = const [],
    this.userLocation,
    this.fitPoints = const [],
    this.fitPadding = EdgeInsets.zero,
    this.onUserGesture,
  });

  final RunneryMapController controller;
  final LatLng initialCenter;
  final double initialZoom;
  final bool interactive;

  /// 레이어 버튼: 지명·도로 이름·장소를 켜고 끕니다.
  final bool showLabels;

  /// 일시정지마다 나뉜 경로.
  final List<List<LatLng>> route;
  final double routeWidth;

  /// 1보다 작으면 겹친 경로일수록 진하게 보입니다(내 정보의 러닝 지도).
  final double routeOpacity;
  final List<MapMarker> markers;
  final List<MapLabel> labels;
  final MapUserLocation? userLocation;

  /// 처음 한 번 이 좌표들이 모두 보이게 맞춥니다.
  final List<LatLng> fitPoints;
  final EdgeInsets fitPadding;

  /// 손가락으로 지도를 움직이기 시작하면 호출. '내 위치 따라가기'를 끌 때 씁니다.
  final VoidCallback? onUserGesture;

  @override
  State<RunneryMap> createState() => _RunneryMapState();
}

class _RunneryMapState extends State<RunneryMap>
    with SingleTickerProviderStateMixin {
  static const _routeSource = 'runnery-route';
  static const _markerSource = 'runnery-markers';
  static const _labelSource = 'runnery-labels';
  static const _meSource = 'runnery-me';

  late final String _style = _runneryMapStyle(
    widget.routeWidth,
    widget.routeOpacity,
  );
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: AppMotion.locationPulseInterval,
  )..addListener(_onPulse);

  MapLibreMapController? _map;
  bool _styleReady = false;
  final _images = <String>{};
  String? _routeSignature;
  String? _markerSignature;
  String? _labelSignature;
  bool? _labelsVisible;
  int _lastPulseMs = 0;
  double _gestureDistance = 0;

  @override
  void initState() {
    super.initState();
    if (widget.userLocation != null) _pulse.repeat();
  }

  @override
  void didUpdateWidget(RunneryMap old) {
    super.didUpdateWidget(old);
    if (widget.userLocation != null && !_pulse.isAnimating) _pulse.repeat();
    if (widget.userLocation == null && _pulse.isAnimating) _pulse.stop();
    _sync();
  }

  @override
  void dispose() {
    _pulse.dispose();
    if (identical(widget.controller._map, _map)) widget.controller._map = null;
    super.dispose();
  }

  Future<void> _onStyleLoaded() async {
    final map = _map;
    if (map == null || !mounted) return;
    final images = await _baseMapImages(MediaQuery.devicePixelRatioOf(context));
    for (final MapEntry(:key, :value) in images.entries) {
      await map.addImage(key, value);
      _images.add(key);
    }
    _styleReady = true;
    await _sync();
    await _fit();
  }

  /// 바뀐 데이터만 지도에 다시 보냅니다.
  Future<void> _sync() async {
    final map = _map;
    if (map == null || !_styleReady) return;
    final dpr = MediaQuery.devicePixelRatioOf(context);

    final routeSignature = [
      widget.route.length,
      for (final s in widget.route) s.length,
      widget.route.lastOrNull?.lastOrNull,
    ].join('/');
    if (routeSignature != _routeSignature) {
      _routeSignature = routeSignature;
      await map.setGeoJsonSource(
        _routeSource,
        _features([
          for (final segment in widget.route)
            if (segment.length >= 2)
              _feature({
                'type': 'LineString',
                'coordinates': [for (final p in segment) _coord(p)],
              }),
        ]),
      );
    }

    final markerSignature = widget.markers
        .map((m) => '${m.kind.name}${m.point}')
        .join();
    if (markerSignature != _markerSignature) {
      _markerSignature = markerSignature;
      await map.setGeoJsonSource(
        _markerSource,
        _features([
          for (final m in widget.markers)
            _feature(_point(m.point), {'icon': 'marker-${m.kind.name}'}),
        ]),
      );
    }

    final labelSignature = widget.labels
        .map((l) => '${l.kind.name}${l.point}${l.name}${l.above}')
        .join();
    if (labelSignature != _labelSignature) {
      _labelSignature = labelSignature;
      final features = <Map<String, Object?>>[];
      for (final label in widget.labels) {
        final id = 'chip-${label.kind.name}-${label.name.hashCode}';
        if (_images.add(id)) {
          await map.addImage(id, await _chipImage(label, dpr));
        }
        features.add(
          _feature(_point(label.point), {
            'icon': id,
            'anchor': label.above ? 'bottom' : 'top',
          }),
        );
      }
      await map.setGeoJsonSource(_labelSource, _features(features));
    }

    if (_labelsVisible != widget.showLabels) {
      _labelsVisible = widget.showLabels;
      for (final id in _labelLayerIds) {
        await map.setLayerVisibility(id, widget.showLabels);
      }
    }

    await _syncUserLocation();
  }

  Future<void> _syncUserLocation() async {
    final map = _map;
    if (map == null || !_styleReady) return;
    final me = widget.userLocation;
    await map.setGeoJsonSource(
      _meSource,
      _features([
        if (me != null)
          _feature(_point(me.point), {
            // 줌 0에서의 정확도 반경(px). 스타일에서 줌마다 2배씩 키웁니다.
            'acc0':
                me.accuracy /
                (78271.517 * math.cos(me.point.latitude * math.pi / 180)),
            'pulse': Curves.easeOut.transform(_pulse.value),
          }),
      ]),
    );
  }

  void _onPulse() {
    // 2.2초 파동을 초당 약 15번만 갱신해 지도 엔진 부담을 줄입니다.
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastPulseMs < 66) return;
    _lastPulseMs = now;
    _syncUserLocation();
  }

  Future<void> _fit() async {
    final map = _map;
    final points = widget.fitPoints;
    if (map == null || points.length < 2) return;
    var minLat = points.map((p) => p.latitude).reduce(math.min);
    var maxLat = points.map((p) => p.latitude).reduce(math.max);
    var minLng = points.map((p) => p.longitude).reduce(math.min);
    var maxLng = points.map((p) => p.longitude).reduce(math.max);
    // 너무 짧은 경로는 과하게 확대되지 않도록 최소 약 300m 범위를 보장합니다.
    const minSpan = 0.003;
    if (maxLat - minLat < minSpan) {
      final c = (maxLat + minLat) / 2;
      minLat = c - minSpan / 2;
      maxLat = c + minSpan / 2;
    }
    if (maxLng - minLng < minSpan) {
      final c = (maxLng + minLng) / 2;
      minLng = c - minSpan / 2;
      maxLng = c + minSpan / 2;
    }
    // iOS MapLibre는 위아래 여백이 다를 때 중심을 옮겨 주지 않아서 직접 계산합니다.
    final size = context.size;
    if (size == null || size.isEmpty) return;
    final p = widget.fitPadding;
    final availableW = math.max(size.width - p.horizontal, 40.0);
    final availableH = math.max(size.height - p.vertical, 40.0);

    // 메르카토르 좌표(0~1).
    double x(double lng) => (lng + 180) / 360;
    double y(double lat) {
      final r = lat * math.pi / 180;
      return (1 - math.log(math.tan(r) + 1 / math.cos(r)) / math.pi) / 2;
    }

    double lat(double y) =>
        math.atan(_sinh(math.pi * (1 - 2 * y))) * 180 / math.pi;

    final spanX = x(maxLng) - x(minLng);
    final spanY = y(minLat) - y(maxLat);
    final zoom = math
        .min(
          _log2(availableW / (spanX * 512)),
          _log2(availableH / (spanY * 512)),
        )
        .clamp(4.0, 16.5);
    final world = 512 * math.pow(2, zoom);
    // 경로 중심이 여백을 뺀 영역 한가운데에 오도록 화면 중심을 옮깁니다.
    final centerX =
        (x(minLng) + x(maxLng)) / 2 + (p.right - p.left) / 2 / world;
    final centerY =
        (y(minLat) + y(maxLat)) / 2 + (p.bottom - p.top) / 2 / world;
    await map.moveCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(lat(centerY), centerX * 360 - 180),
        zoom,
      ),
    );
    widget.controller._update(map.cameraPosition);
  }

  @override
  Widget build(BuildContext context) {
    final map = MapLibreMap(
      styleString: _style,
      initialCameraPosition: CameraPosition(
        target: widget.initialCenter,
        zoom: widget.initialZoom,
      ),
      onMapCreated: (controller) {
        _map = controller;
        widget.controller._map = controller;
      },
      onStyleLoadedCallback: _onStyleLoaded,
      trackCameraPosition: true,
      onCameraMove: widget.controller._update,
      onCameraIdle: () => widget.controller._update(_map?.cameraPosition),
      minMaxZoomPreference: const MinMaxZoomPreference(4, 18),
      compassEnabled: false,
      rotateGesturesEnabled: false,
      tiltGesturesEnabled: false,
      scrollGesturesEnabled: widget.interactive,
      zoomGesturesEnabled: widget.interactive,
      doubleClickZoomEnabled: widget.interactive,
      dragEnabled: widget.interactive,
      // 출처는 축척 아래 글자로 표시하고, 기본 (i) 버튼은 화면 밖으로 뺍니다.
      attributionButtonMargins: const math.Point(-200, -200),
      foregroundLoadColor: AppColors.mapLand,
    );
    final onGesture = widget.onUserGesture;
    if (!widget.interactive || onGesture == null) return map;
    return Listener(
      onPointerDown: (_) => _gestureDistance = 0,
      onPointerMove: (event) {
        _gestureDistance += event.delta.distance;
        if (_gestureDistance > 12) {
          _gestureDistance = double.negativeInfinity;
          onGesture();
        }
      },
      child: map,
    );
  }
}

List<double> _coord(LatLng p) => [p.longitude, p.latitude];

Map<String, Object?> _point(LatLng p) => {
  'type': 'Point',
  'coordinates': _coord(p),
};

Map<String, Object?> _feature(
  Map<String, Object?> geometry, [
  Map<String, Object?> properties = const {},
]) => {'type': 'Feature', 'geometry': geometry, 'properties': properties};

double _log2(double v) => math.log(v) / math.ln2;

double _sinh(double v) => (math.exp(v) - math.exp(-v)) / 2;

Map<String, dynamic> _features(List<Map<String, Object?>> features) => {
  'type': 'FeatureCollection',
  'features': features,
};

// ── 스타일 JSON ───────────────────────────────────────

const _labelLayerIds = [
  'label-road',
  'label-water',
  'label-waterway',
  'label-dong',
  'label-district',
  'poi',
  'poi-detail',
  'poi-parking',
  'poi-subway',
];

String _runneryMapStyle(double routeWidth, [double routeOpacity = 1]) {
  const name = [
    'coalesce',
    ['get', 'name:ko'],
    ['get', 'name'],
  ];
  const bold = ['Noto Sans Bold'];
  const regular = ['Noto Sans Regular'];
  const notTunnel = [
    '!=',
    ['get', 'brunnel'],
    'tunnel',
  ];

  // 가이드 두께는 '상세 확대' 기준. 덜 확대하면 가늘게, 더 확대하면 굵게.
  List<Object> width(double w) => [
    'interpolate', ['exponential', 1.5], ['zoom'], //
    10, w * 0.15, 12.5, w * 0.4, MapZoom.detail, w, 17, w * 2.2,
  ];

  Map<String, Object?> fill(
    String id,
    String layer,
    Object color, {
    Object? filter,
    double? minzoom,
  }) => {
    'id': id,
    'type': 'fill',
    'source': 'omt',
    'source-layer': layer,
    'filter': ?filter,
    'minzoom': ?minzoom,
    'paint': {'fill-color': color},
  };

  // 도로 위계: 테두리를 모든 도로 아래에 먼저 깔고 도로 면을 위에 그립니다.
  const roads = [
    (
      'alley',
      ['service', 'track', 'path'],
      MapPalette.alley,
      2.9,
      MapZoom.detail,
    ),
    ('local', ['minor'], MapPalette.local, 5.0, MapZoom.basic),
    (
      'collector',
      ['secondary', 'tertiary'],
      MapPalette.collector,
      7.0,
      MapZoom.overview,
    ),
    ('arterial', ['primary'], MapPalette.arterial, 10.0, 0.0),
    ('expressway', ['motorway', 'trunk'], MapPalette.expressway, 13.0, 0.0),
  ];
  Map<String, Object?> road(
    (String, List<String>, String, double, double) r, {
    required bool casing,
  }) {
    final (id, classes, color, w, minzoom) = r;
    return {
      'id': casing ? 'road-$id-casing' : 'road-$id',
      'type': 'line',
      'source': 'omt',
      'source-layer': 'transportation',
      'minzoom': minzoom,
      'filter': [
        'all',
        [
          'match',
          ['get', 'class'],
          classes,
          true,
          false,
        ],
        notTunnel,
      ],
      'layout': {'line-cap': 'round', 'line-join': 'round'},
      'paint': {
        'line-color': casing ? MapPalette.casing : color,
        'line-width': width(casing ? w + 2.4 : w),
      },
    };
  }

  Map<String, Object?> rail(String id, String cls, String color) => {
    'id': id,
    'type': 'line',
    'source': 'omt',
    'source-layer': 'transportation',
    'minzoom': MapZoom.overview,
    'filter': [
      '==',
      ['get', 'class'],
      cls,
    ],
    'paint': {
      'line-color': color,
      'line-opacity': 0.5,
      'line-width': [
        'interpolate',
        ['linear'],
        ['zoom'],
        12,
        1,
        16,
        2.5,
      ],
    },
  };

  Map<String, Object?> label(
    String id,
    String layer, {
    required String color,
    required Object size,
    Object font = bold,
    Object? filter,
    double? minzoom,
    double spacing = 0,
    String placement = 'point',
  }) => {
    'id': id,
    'type': 'symbol',
    'source': 'omt',
    'source-layer': layer,
    'filter': ?filter,
    'minzoom': ?minzoom,
    'layout': {
      'text-field': name,
      'text-font': font,
      'text-size': size,
      'text-letter-spacing': spacing,
      'symbol-placement': placement,
      'text-max-width': 8,
    },
    'paint': {
      'text-color': color,
      'text-halo-color': MapPalette.labelHalo,
      'text-halo-width': 1.5,
    },
  };

  // 장소: 둥근 사각형 아이콘 + 이름. 지하철은 원형 배지.
  const poiIcon = [
    'match', ['get', 'class'], //
    ['park', 'garden'], 'poi-park',
    ['school', 'college', 'kindergarten'], 'poi-school',
    ['hospital', 'doctors'], 'poi-hospital',
    ['attraction', 'museum', 'town_hall', 'monument', 'castle', 'theatre'],
    'poi-landmark',
    ['parking'], 'poi-parking',
    ['shop', 'grocery', 'clothing_store'], 'poi-shop',
    '',
  ];
  Map<String, Object?> poi(
    String id,
    List<String> classes,
    double minzoom, {
    Object? extraFilter,
  }) => {
    'id': id,
    'type': 'symbol',
    'source': 'omt',
    'source-layer': 'poi',
    'minzoom': minzoom,
    'filter': [
      'all',
      [
        'match',
        ['get', 'class'],
        classes,
        true,
        false,
      ],
      ?extraFilter,
    ],
    'layout': {
      'icon-image': classes.contains('railway') ? 'poi-subway' : poiIcon,
      'text-field': name,
      'text-font': bold,
      'text-size': 11,
      'text-anchor': 'left',
      'text-offset': [0.9, 0],
      'icon-anchor': 'center',
      'text-max-width': 8,
    },
    'paint': {
      'text-color': MapPalette.labelPlace,
      'text-halo-color': MapPalette.labelHalo,
      'text-halo-width': 1.5,
    },
  };

  Map<String, Object?> geojson() => {
    'type': 'geojson',
    'data': {'type': 'FeatureCollection', 'features': <Object>[]},
  };

  return jsonEncode({
    'version': 8,
    'name': 'Runnery Dark',
    'glyphs': 'https://tiles.openfreemap.org/fonts/{fontstack}/{range}.pbf',
    'sources': {
      'omt': {'type': 'vector', 'url': 'https://tiles.openfreemap.org/planet'},
      _RunneryMapState._routeSource: geojson(),
      _RunneryMapState._markerSource: geojson(),
      _RunneryMapState._labelSource: geojson(),
      _RunneryMapState._meSource: geojson(),
    },
    'layers': [
      {
        'id': 'land',
        'type': 'background',
        'paint': {'background-color': MapPalette.land},
      },
      fill('park', 'park', MapPalette.park),
      fill(
        'landcover-green',
        'landcover',
        MapPalette.park,
        filter: [
          'match',
          ['get', 'class'],
          ['grass', 'wood'],
          true,
          false,
        ],
      ),
      fill('water', 'water', MapPalette.water, filter: notTunnel),
      {
        'id': 'waterway',
        'type': 'line',
        'source': 'omt',
        'source-layer': 'waterway',
        'filter': notTunnel,
        'paint': {
          'line-color': MapPalette.water,
          'line-width': [
            'interpolate',
            ['linear'],
            ['zoom'],
            10,
            1,
            16,
            4,
          ],
        },
      },
      for (final r in roads) road(r, casing: true),
      for (final r in roads) road(r, casing: false),
      rail('rail', 'rail', MapPalette.subway9),
      rail('subway', 'transit', MapPalette.subway5),
      fill('building', 'building', [
        'case',
        [
          '>=',
          [
            'coalesce',
            ['get', 'render_height'],
            0,
          ],
          60,
        ],
        MapPalette.tower,
        [
          '>=',
          [
            'coalesce',
            ['get', 'render_height'],
            0,
          ],
          24,
        ],
        MapPalette.apartment,
        MapPalette.building,
      ], minzoom: MapZoom.basic),
      label(
        'label-road',
        'transportation_name',
        color: MapPalette.labelRoad,
        size: 10.5,
        font: regular,
        minzoom: MapZoom.basic,
        placement: 'line',
      ),
      label(
        'label-waterway',
        'waterway',
        color: MapPalette.labelWater,
        size: 13,
        font: regular,
        minzoom: MapZoom.overview,
        spacing: 0.6,
        placement: 'line',
      ),
      label(
        'label-water',
        'water_name',
        color: MapPalette.labelWater,
        size: [
          'interpolate',
          ['linear'],
          ['zoom'],
          12,
          15,
          16,
          17,
        ],
        font: regular,
        minzoom: MapZoom.overview,
        spacing: 0.6,
      ),
      poi('poi', [
        'park', 'garden', 'school', 'college', 'kindergarten', 'hospital',
        'doctors', 'attraction', 'museum', 'town_hall', 'monument', 'castle',
        'theatre', //
      ], MapZoom.basic),
      // 쇼핑은 백화점·쇼핑몰만. 편의점까지 그리면 지도가 아이콘으로 덮입니다.
      poi(
        'poi-detail',
        ['shop'],
        MapZoom.detail,
        extraFilter: [
          'match',
          ['get', 'subclass'],
          ['department_store', 'mall'],
          true,
          false,
        ],
      ),
      poi('poi-parking', ['parking'], MapZoom.detail + 1),
      poi('poi-subway', ['railway'], MapZoom.basic),
      label(
        'label-dong',
        'place',
        color: MapPalette.labelDong,
        size: 12,
        filter: [
          'match',
          ['get', 'class'],
          ['suburb', 'quarter', 'neighbourhood', 'village'],
          true,
          false,
        ],
        minzoom: MapZoom.basic,
      ),
      label(
        'label-district',
        'place',
        color: MapPalette.labelDistrict,
        size: 13.5,
        filter: [
          'match',
          ['get', 'class'],
          ['city', 'town', 'borough'],
          true,
          false,
        ],
      ),
      // ── 러닝 데이터: 경로 > 내 위치 > 마커 > 지명 칩 ──
      {
        'id': 'route-casing',
        'type': 'line',
        'source': _RunneryMapState._routeSource,
        'layout': {'line-cap': 'round', 'line-join': 'round'},
        'paint': {
          'line-color': '#000000',
          'line-opacity': routeOpacity < 1 ? 0.25 : 0.85,
          'line-width': routeWidth + 4,
        },
      },
      {
        'id': 'route',
        'type': 'line',
        'source': _RunneryMapState._routeSource,
        'layout': {'line-cap': 'round', 'line-join': 'round'},
        'paint': {
          'line-color': '#FF7A00',
          'line-width': routeWidth,
          'line-opacity': routeOpacity,
        },
      },
      {
        'id': 'me-accuracy',
        'type': 'circle',
        'source': _RunneryMapState._meSource,
        'paint': {
          'circle-radius': [
            'interpolate', ['exponential', 2], ['zoom'], //
            0,
            ['get', 'acc0'],
            22,
            [
              '*',
              ['get', 'acc0'],
              4194304,
            ],
          ],
          'circle-color': 'rgba(255,122,0,0.16)',
          'circle-stroke-color': 'rgba(255,122,0,0.35)',
          'circle-stroke-width': 1,
        },
      },
      {
        'id': 'me-pulse',
        'type': 'circle',
        'source': _RunneryMapState._meSource,
        'paint': {
          'circle-radius': [
            '+',
            9,
            [
              '*',
              20,
              ['get', 'pulse'],
            ],
          ],
          'circle-color': '#FF7A00',
          'circle-opacity': [
            '*',
            0.35,
            [
              '-',
              1,
              ['get', 'pulse'],
            ],
          ],
        },
      },
      {
        'id': 'me-dot',
        'type': 'circle',
        'source': _RunneryMapState._meSource,
        'paint': {
          'circle-radius': 6,
          'circle-color': '#FF7A00',
          'circle-stroke-color': '#FFFFFF',
          'circle-stroke-width': 3,
        },
      },
      {
        'id': 'markers',
        'type': 'symbol',
        'source': _RunneryMapState._markerSource,
        'layout': {
          'icon-image': ['get', 'icon'],
          'icon-allow-overlap': true,
          'icon-ignore-placement': true,
        },
      },
      // 칩은 지점 위(bottom 기준) 또는 아래(top 기준)에 둡니다.
      for (final (id, anchor, dy) in const [
        ('chips-above', 'bottom', -16),
        ('chips-below', 'top', 16),
      ])
        {
          'id': id,
          'type': 'symbol',
          'source': _RunneryMapState._labelSource,
          'filter': [
            '==',
            ['get', 'anchor'],
            anchor,
          ],
          'layout': {
            'icon-image': ['get', 'icon'],
            'icon-anchor': anchor,
            'icon-offset': [0, dy],
            'icon-allow-overlap': true,
            'icon-ignore-placement': true,
          },
        },
    ],
  });
}

// ── 지도 위 그림 (앱에서 그려 지도에 이미지로 넣음) ─────────

Future<Uint8List> _drawPng(
  Size size,
  double dpr,
  void Function(Canvas canvas) paint,
) async {
  final recorder = ui.PictureRecorder();
  paint(Canvas(recorder)..scale(dpr));
  final image = await recorder.endRecording().toImage(
    (size.width * dpr).ceil(),
    (size.height * dpr).ceil(),
  );
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

void _paintIcon(Canvas canvas, IconData icon, Offset center, double size) {
  final tp = TextPainter(
    text: TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        fontSize: size,
        color: Colors.white,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
}

Future<Map<String, Uint8List>>? _baseImagesCache;
double? _baseImagesDpr;

/// 출발·도착·일시정지 마커와 장소 아이콘.
Future<Map<String, Uint8List>> _baseMapImages(double dpr) {
  if (_baseImagesCache != null && _baseImagesDpr == dpr) {
    return _baseImagesCache!;
  }
  _baseImagesDpr = dpr;
  return _baseImagesCache = () async {
    // 마커: 흰 원 L22 + 검정 기호.
    Future<Uint8List> marker(void Function(Canvas c, Offset center) glyph) {
      const size = Size.square(26);
      return _drawPng(size, dpr, (c) {
        final center = size.center(Offset.zero);
        c
          ..drawCircle(center, 12, Paint()..color = Colors.black)
          ..drawCircle(center, 10.5, Paint()..color = Colors.white);
        glyph(c, center);
      });
    }

    final black = Paint()..color = Colors.black;
    // 장소: 16px 둥근 사각형(모서리 5) + 흰 기호.
    Future<Uint8List> poi(
      Color color,
      void Function(Canvas c, Offset center) glyph,
    ) {
      const size = Size.square(18);
      return _drawPng(size, dpr, (c) {
        c.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(1, 1, 16, 16),
            const Radius.circular(5),
          ),
          Paint()..color = color,
        );
        glyph(c, size.center(Offset.zero));
      });
    }

    void letter(Canvas c, Offset center, String text) {
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(c, center - Offset(tp.width / 2, tp.height / 2));
    }

    return {
      'marker-start': await marker(
        (c, o) => c.drawPath(
          Path()
            ..moveTo(o.dx - 3, o.dy - 4.5)
            ..lineTo(o.dx + 4.5, o.dy)
            ..lineTo(o.dx - 3, o.dy + 4.5)
            ..close(),
          black,
        ),
      ),
      'marker-finish': await marker(
        (c, o) =>
            c.drawRect(Rect.fromCenter(center: o, width: 8, height: 8), black),
      ),
      'marker-pause': await marker((c, o) {
        c
          ..drawRect(
            Rect.fromCenter(
              center: o.translate(-2.2, 0),
              width: 2.6,
              height: 9,
            ),
            black,
          )
          ..drawRect(
            Rect.fromCenter(center: o.translate(2.2, 0), width: 2.6, height: 9),
            black,
          );
      }),
      'poi-park': await poi(
        MapPalette.poiPark,
        (c, o) => _paintIcon(c, Icons.park, o, 12),
      ),
      'poi-school': await poi(
        MapPalette.poiSchool,
        (c, o) => _paintIcon(c, Icons.home, o, 12),
      ),
      'poi-hospital': await poi(
        MapPalette.poiHospital,
        (c, o) => _paintIcon(c, Icons.add, o, 13),
      ),
      'poi-landmark': await poi(
        MapPalette.poiLandmark,
        (c, o) => _paintIcon(c, Icons.account_balance, o, 11),
      ),
      'poi-parking': await poi(
        MapPalette.poiSchool,
        (c, o) => letter(c, o, 'P'),
      ),
      'poi-shop': await poi(
        MapPalette.poiOther,
        (c, o) => _paintIcon(c, Icons.shopping_bag, o, 11),
      ),
      // 지하철: 원형 배지. 데이터에 노선 번호가 없어 노선 색 대신 중립색을 씁니다.
      'poi-subway': await _drawPng(const Size.square(18), dpr, (c) {
        const o = Offset(9, 9);
        c
          ..drawCircle(o, 8, Paint()..color = MapPalette.subwayBadge)
          ..drawCircle(
            o,
            8,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.2
              ..color = const Color(0xFF181D26),
          );
        _paintIcon(c, Icons.directions_subway, o, 11);
      }),
    };
  }();
}

/// 지명 칩 이미지.
Future<Uint8List> _chipImage(MapLabel label, double dpr) {
  final spans = <TextSpan>[
    if (label.kind == MapLabelKind.current)
      const TextSpan(
        text: '현재 위치  ',
        style: TextStyle(color: AppColors.textSecondary),
      )
    else
      TextSpan(
        text: label.kind == MapLabelKind.start ? '출발' : '도착',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    if (label.name != null)
      TextSpan(
        text: label.kind == MapLabelKind.current
            ? label.name
            : ' ${label.name}',
        style: label.kind == MapLabelKind.current
            ? const TextStyle(fontWeight: FontWeight.w700)
            : const TextStyle(color: AppColors.textSecondary),
      ),
  ];
  final tp = TextPainter(
    text: TextSpan(
      children: spans,
      style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
    ),
    textDirection: TextDirection.ltr,
    maxLines: 1,
    ellipsis: '…',
  )..layout(maxWidth: 220);
  final hasGlyph = label.kind != MapLabelKind.current;
  final glyph = hasGlyph ? 15.0 : 0.0;
  final size = Size(tp.width + glyph + 24, 28);
  return _drawPng(size, dpr, (c) {
    c.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(14)),
      Paint()..color = AppColors.background.withValues(alpha: 0.92),
    );
    final white = Paint()..color = Colors.white;
    if (label.kind == MapLabelKind.start) {
      c.drawPath(
        Path()
          ..moveTo(12, 9.5)
          ..lineTo(19, 14)
          ..lineTo(12, 18.5)
          ..close(),
        white,
      );
    } else if (label.kind == MapLabelKind.finish) {
      c.drawRect(const Rect.fromLTWH(12, 10.5, 7, 7), white);
    }
    tp.paint(c, Offset(12 + glyph, (size.height - tp.height) / 2));
  });
}
