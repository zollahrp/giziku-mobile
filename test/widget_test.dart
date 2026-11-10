import 'package:flutter_test/flutter_test.dart';
import 'package:gizify/screens/profile_screen.dart';
import 'package:gizify/screens/profiles/edit_profile_screen.dart';

void main() {
  test('Smoke test app configuration and screen compilation', () {
    expect(ProfileScreen, isNotNull);
    expect(EditProfileScreen, isNotNull);
  });
}
