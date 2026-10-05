import 'profile_mail_page.dart';
export 'profile_mail_page.dart';

/// 기존 main 파일명을 사용하는 호출부와의 호환 진입점.
class ProfileMainPage extends ProfileMailPage {
  const ProfileMainPage({
    super.key,
    super.onHome,
    super.onRecords,
    super.onEditProfile,
    super.onLogout,
  });
}
