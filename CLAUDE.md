# CLAUDE.md

이 파일은 이 저장소에서 작업하는 Claude Code를 위한 안내서입니다.

## 대화 방식

- 불필요한 인사말 없이 바로 답합니다.
- 불필요한 수식어를 사용하지 않습니다.
- 간단한 질문은 짧게, 복잡한 작업은 충분히 자세히 답합니다.
- 확실하지 않은 사실, 날짜, 수치, 출처는 먼저 불확실하다고 말합니다.
- 사용자는 코드를 직접 읽지 못합니다. 설명은 코드 대신 "어떤 화면에서 무엇이 바뀌는지" 기준으로, 전문용어 없이 쉬운 한국어로 합니다.


## 변경 통제

- 현재 요청을 처리하는 데 꼭 필요한 파일과 코드만 수정합니다.
- 요청과 직접 관련 없는 수정(정리, 리팩터링, 다른 버그 수정)은 하지 말고, 필요해 보이면 먼저 물어봅니다.
- 큰 변경, 파일 삭제, 덮어쓰기는 먼저 무엇을 바꿀지 설명하고 확인을 받습니다.
- 수정 후 `flutter analyze`로 오류가 없는지 확인합니다.
- 작업이 끝나면 수정한 파일 목록, 각 파일을 고친 이유, 사용자가 직접 확인해야 할 점을 짧게 정리합니다.

## 고위험 행동 차단

- 패키지 추가·삭제, 로컬 저장 데이터 구조 변경, 외부 전송, 삭제처럼 되돌리기 어려운 행동은 먼저 확인을 받습니다.
- 서버나 외부 백엔드를 붙이지 않습니다. 데이터는 기기 안에만 저장합니다.

## 기억과 연속성

- 중요한 결정은 저장소 맨 위의 [MEMORY.md](MEMORY.md)에 날짜와 함께 남깁니다.
- 세션을 끝낼 때 완료한 일, 진행 중인 일, 다음 할 일을 요약합니다.

## 명령어

Flutter 앱(Dart SDK ^3.13.3)이며 UI는 한국어("러너리 / RUNNERY")입니다. `analysis_options.yaml`에서 플랫폼 폴더를 제외하므로 `lib/`와 `test/`만 분석합니다.

```
flutter pub get
flutter run
flutter analyze
flutter test                                # 전체 테스트
flutter test test/record_storage_test.dart  # 파일 하나
flutter test --plain-name "some test name"  # 테스트 하나
```

## 아키텍처

- **상태 관리 패키지, 라우터, 백엔드가 없습니다.** 화면 이동은 일반 `Navigator` push를 쓰고, 상태는 `ChangeNotifier` 싱글턴이 들고 있으며 `path_provider`로 로컬 파일에 저장합니다. 생성자가 디렉터리 주입(`Future<Directory> Function()`)을 받아서 테스트에서 임시 디렉터리를 쓸 수 있습니다.
  - `AccountStore` ([lib/account/account_store.dart](lib/account/account_store.dart)): 기기 하나에 계정 하나와 로그인 상태를 관리합니다(비밀번호는 `crypto`로 해시). 새 계정을 만들면 `RunningRecordStore`도 비웁니다.
  - `RunningRecordStore` ([lib/record/data/running_record_store.dart](lib/record/data/running_record_store.dart)): 러닝 한 번당 JSON 파일 하나를 `<documents>/running_records/`에 저장합니다. 임시 파일에 먼저 쓴 뒤 게시하며, 작업은 `_pending` future 체인으로 직렬화됩니다.
- **시작 흐름:** `main.dart` → `AppStartPage`(스플래시, [lib/app_start.dart](lib/app_start.dart)) → `AuthGate`(`lib/login/login.dart`) → 회원가입 / `HomePage`. `main()`은 `RecordRouteMap.basemapEnabled = true`를 설정합니다(기록 상세의 MapLibre 베이스맵). 기본값은 `false`라서 위젯 테스트에서 네이티브 지도가 생성되지 않습니다.
- **러닝 파이프라인:** `home/running/running_start_page.dart`(`geolocator`로 GPS 수집, wakelock, 정확도·흔들림 필터링과 햇반 칼로리 단위를 담은 `RunningConfig`) → `running_result_page.dart` → `record/data/record_from_session.dart`가 세션 결과를 저장용 `RunningRecord` 모델(`record/models/`)로 변환합니다. 지도 렌더링은 `maplibre_gl`을 씁니다.
- **기록 UI:** 기록 탭은 [lib/record/list/record_list_page.dart](lib/record/list/record_list_page.dart)의 `RecordListPageV2`를 사용합니다(스와이프 삭제 포함). 상세 화면은 `record/list/detail/record_detail_page.dart`이며 우측 상단 메뉴에서 메모 수정·기록 삭제를 합니다. [docs/record-v2.md](docs/record-v2.md)는 병합 전 작업 보고라 `record_list_page_1.dart` 등 지금과 다른 파일 이름이 나옵니다.
- **디자인 시스템:** `lib/design_system/`에는 브랜드 가이드([lib/design_system/design_guide.md](lib/design_system/design_guide.md))에서 추출한 토큰(색, 텍스트 스타일, 간격, 모서리, 그림자, 모션, 컴포넌트 치수)이 있습니다(다크/블랙 테마, 기준 프레임 390×844, 주황은 경로·현재 위치·시작에만 사용). 값을 직접 쓰지 말고 이 토큰을 쓰세요. 앱 테마는 `AppTheme.dark`입니다.

## 코드 규칙

- 코드 주석과 UI 문자열은 한국어로 씁니다. UI 문구는 짧은 해요체를 씁니다.
- 테스트는 `test/`에 있습니다(페이지 위젯 테스트와, 임시 디렉터리를 주입하는 스토어 테스트).
