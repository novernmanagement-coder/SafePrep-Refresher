import 'package:mixpanel_flutter/mixpanel_flutter.dart';

class MixpanelService {
  static final MixpanelService instance = MixpanelService._();
  MixpanelService._();

  Mixpanel? _mixpanel;

  static const String _token = 'f0e26131548137dd7fb8522bd6b88536';

  // Per-app identifiers, matching the convention already used across
  // the SafePrep suite (SP = Manager, ES = Español, AL = Alcohol).
  static const String _appName = 'SR';
  static const String _eventPrefix = 'SR_';

  Future<void> init() async {
    _mixpanel = await Mixpanel.init(_token, trackAutomaticEvents: true);
    // Sets app_name as a super property so every event fired from here on
    // carries it automatically — callers no longer need to pass it manually.
    _mixpanel?.registerSuperProperties({'app_name': _appName});
  }

  void track(String event, {Map<String, dynamic>? properties}) {
    try {
      _mixpanel?.track('$_eventPrefix$event', properties: properties);
    } catch (e) {
      // Silent fail — never crash the app over analytics
    }
  }

  void identify(String userId) {
    try {
      _mixpanel?.identify(userId);
    } catch (e) {}
  }

  void reset() {
    try {
      _mixpanel?.reset();
    } catch (e) {}
  }
}
