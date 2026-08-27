class AppLinks {
  const AppLinks._();

  static const String privacyPolicyUrl = String.fromEnvironment(
    'PRIVACY_POLICY_URL',
  );
  static const String supportEmail = String.fromEnvironment('SUPPORT_EMAIL');
}
