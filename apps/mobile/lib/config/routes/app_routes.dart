/// Centralized route path constants for the QuickServe mobile app.
///
/// Use these instead of hard-coded string literals to prevent typos
/// and enable compile-time safety for navigation paths.
abstract final class AppRoutes {
  // ── Auth ──────────────────────────────────────────────────────────
  static const splash = '/splash';
  static const login = '/login';
  static const agentLogin = '/agent-login';
  static const register = '/register';
  static const passwordReset = '/password-reset';

  // ── Core ──────────────────────────────────────────────────────────
  static const home = '/home';
  static const profile = '/profile';
  static const notifications = '/notifications';
  static const settings = '/settings';

  // ── Agent ─────────────────────────────────────────────────────────
  static const agentRequests = '/agent/requests';
  static const agentHistory = '/agent/history';

  // ── Customer / Requests ───────────────────────────────────────────
  static const services = '/services';
  static const serviceDetail = '/services/detail';
  static const requests = '/requests';
  static const createRequest = '/requests/create';
  static const requestSuccess = '/requests/success';

  /// Returns the detail route for a given [requestId].
  static String requestDetail(String requestId) => '/requests/$requestId';

  // ── Profile sub-screens ───────────────────────────────────────────
  static const securitySettings = '/security-settings';
  static const savedAddresses = '/saved-addresses';

  /// Returns the agent-contact route for a given [agentId].
  static String agentContact(String agentId) => '/agents/$agentId';

  /// All paths that don't require authentication.
  static const publicPaths = {
    splash,
    login,
    agentLogin,
    register,
    passwordReset,
  };
}
