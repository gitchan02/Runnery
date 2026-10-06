# Record 테스트 버전 작업 보고

## 연결 및 복구

기존 lib/record/list/record_list_page.dart는 수정하지 않았습니다. 작업 전후 바이트 비교로 동일함을 확인했습니다.
현재 Record 탭은 lib/record/list/record_list_page_1.dart의 RecordListPageV2를 사용합니다.

기존 화면으로 되돌리려면 아래 두 파일에서 동일한 두 변경을 적용합니다.

- lib/home/home_page.dart
- lib/profile/profile_mail_page.dart (내 정보 탭의 공통 화면)

현재 import '../record/list/record_list_page_1.dart'; 를 import '../record/list/record_list_page.dart'; 로 바꾸고,
const RecordListPageV2() 를 const RecordListPage() 로 바꾸면 됩니다.

독립 달력 라우트까지 기존 목록으로 연결하려면 lib/record/record_calendar_page.dart에서
import 'list/record_list_page_1.dart'; 를 import 'list/record_list_page.dart'; 로,
return RecordListPageV2( 를 return RecordListPage( 로 바꿉니다.

GPS 저장 기능과 로컬 파일은 그대로 두어도 됩니다. 공통 달력·상세 화면의 실제 데이터 처리 개선은 유지됩니다.

## 파일

기존 빈 파일 구현:
- lib/record/list/record_list_page_1.dart

새 파일:
- lib/record/models/running_record.dart: 기존 상세 화면의 모델을 이동·확장. UI와 분리, JSON 직렬화, 실제 종료 시각, 좌표 시각·구간 정보.
- lib/record/data/running_record_store.dart: 로컬 파일 저장 및 변경 알림.
- lib/record/data/record_from_session.dart: 기존 GPS 결과 모델을 저장용 모델로 변환. 측정 계산 재사용.
- test/record_storage_test.dart
- test/record_v2_test.dart
- docs/record-v2.md

수정 파일:
- lib/home/home_page.dart
- lib/profile/profile_mail_page.dart
- lib/home/running/running_start_page.dart
- lib/record/record_calendar_page.dart
- lib/record/list/detail/record_detail_page.dart
- pubspec.yaml, pubspec.lock: path_provider 추가. 새 지도 SDK는 추가하지 않음.
- flutter pub get 과정에서 플랫폼 자동 등록 파일 갱신: linux/flutter/generated_plugins.cmake, windows/flutter/generated_plugins.cmake 등.

기존 러닝 세션의 RunningRecord 타입은 그대로 유지했습니다. 기록 UI용 기존 RunningRecord는 별도 모델 파일로 이동했고 상세 파일에서 다시 export하므로 백업 화면 import가 계속 동작합니다. 변환 파일은 GPS 타입에 session 별칭을 사용합니다.

## 저장과 동작

getApplicationDocumentsDirectory() 아래 running_records/<record-id>.json에 저장합니다.
Android는 앱 전용 문서 디렉터리, iOS는 앱 샌드박스 Documents 하위입니다. 앱 종료·재실행 후 유지되며 앱 삭제/데이터 초기화는 별개입니다.

RunningStartPage의 _openEndSheet()에서 종료하고 저장 선택 → 기존 RunningSession.finish() → recordFromSession() → RunningRecordStore.instance.save() 완료 → RunningResultPage로 이동합니다.
저장 실패 시 다시 저장 또는 저장하지 않고 종료를 선택할 수 있습니다. 같은 id의 재시도는 중복 기록을 만들지 않습니다.
finish()의 종료 시각을 실제 종료 순간으로 수정하여 마지막 일시정지도 포함합니다.

GPS 좌표·시각, 일시정지/신호 복구 구간 경계, 거리, 운동/휴식 시간, 기존 속도 샘플·구간 기록·칼로리 계산을 재사용합니다.
목록은 최신순, 월간 통계는 선택한 월 기준입니다. 주별 거리 합계는 월 경계와 관계없이 해당 주 전체 기록을 합산합니다. 목록 행 자체는 선택한 월에 한정됩니다.

달력은 기록 날짜에만 저장 좌표를 축소 표시합니다. 일시정지로 분리된 구간을 선으로 이어 붙이지 않습니다.
실제 기록이 없으면 목록은 0 통계와 '아직 저장된 러닝 기록이 없습니다.'를 표시합니다.
파일 읽기 실패·손상은 빈 기록으로 숨기지 않고 오류와 재시도를 표시합니다.
메모 수정도 같은 JSON에 저장합니다.

## 실제 데이터의 한계

- 칼로리/햇반은 기존 세션 계산 결과를 재사용합니다. 현재 기본 체중 65kg 기반 추정치이며 개인 체중 연동은 기존 코드에도 없습니다. 상세에서 추정치임을 표시합니다.
- 충분한 속도 샘플이 없으면 최고 속도·최고 페이스를 —로 표시하고 JSON에 null로 저장합니다. 10m 미만 평균 페이스도 —로 표시합니다.
- 출발/도착 지명은 로컬 기록에 연동하지 않아 '위치 정보 없음'으로 표시합니다. 기존 세션의 결과 화면 지오코딩은 유지됩니다.
- Record의 지도 배경은 실제 지도로 연결하지 않았습니다. 허구의 한강·다리·축척 배경을 제거하고 실제 GPS 경로만 정규화해 표시합니다. 기존 러닝 화면의 지도는 유지됩니다.
- 기존 GPS는 전경 측정 방식입니다. 백그라운드 GPS, 러닝 중 강제 종료 복구, 자동 일시정지 등을 새로 구현하지 않았습니다. 종료 후 저장 완료된 기록의 영속성을 구현한 작업입니다.

## 검증

- flutter analyze: 통과.
- flutter test test/record_storage_test.dart test/record_v2_test.dart: 10건 통과.
- 새 저장소 인스턴스의 파일 복원, 최신순, 동일 id 재저장, 메모, 저장 실패 후 재시도, 손상 파일 오류, GPS 시각·구간/측정치 보존, 빈 화면/달력, 월 변경, 상세 전달, 저장 알림에 따른 화면 갱신 검증.
- 전체 flutter test: 기존 테스트 3건 실패. 작업 전 소스의 별도 복사본에서도 동일하게 재현됨.
  - home_page_test: 320px 확대 글꼴에서 37px 가로 넘침.
  - profile_page_test: 0.5px 세로 넘침.
  - widget_test: 현재 홈으로 이동하는 시작 화면에 대해 LoginPage를 기대하는 테스트.

## 실제 기기/에뮬레이터 체크리스트

1. 앱 데이터 없는 상태: Record 목록의 0.00km / 0회 / 0분 / 햇반 0개와 빈 상태 확인. 달력 경로 없음 확인.
2. 위치 권한 허용 후 실제 이동 또는 에뮬레이터 GPS 경로 재생, 일시정지→재개→종료하고 저장.
3. 홈과 내 정보 양쪽 Record 탭에서 최신 기록 표시. 월간/주간 합계와 날짜 확인.
4. 달력의 달린 날짜에만 실제 경로 표시, 하루 여러 기록과 경로 없는 기록 확인.
5. 목록·달력에서 상세 열기. 결과 화면의 거리/시간/속도/칼로리와 비교. 종료/휴식 시각 확인.
6. 정지 중 이동한 두 구간 사이에 가짜 연결선이 없는지 확인.
7. 메모 저장 후 앱 완전 종료·재실행. 기록·GPS·메모 유지 확인.
8. 저장하지 않고 종료 시 새 기록 없음 확인. 짧은 러닝·GPS 수신 실패 시 경로/페이스/최고 속도가 임의 생성되지 않는지 확인.
9. 월 경계·연도 경계와 같은 날 복수 기록, 좁은 화면의 목록/달력/상세 배치 확인.

실제 휴대폰 GPS 측정과 Android/iOS 앱 빌드는 이 작업 환경에서 수행하지 않았습니다.
