import '../../../core/api/api_client.dart';
import '../../../core/storage/token_storage.dart';
import 'user.dart';

class AuthRepository {
  AuthRepository({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
  })  : _apiClient = apiClient,
        _tokenStorage = tokenStorage;

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  /// Returns the previously logged-in user if a token is still stored,
  /// or null if the user needs to log in.
  Future<User?> restoreSession() async {
    final token = await _tokenStorage.readToken();
    if (token == null) return null;
    final id = await _tokenStorage.readUserId();
    final name = await _tokenStorage.readUserName();
    final email = await _tokenStorage.readUserEmail();
    final role = await _tokenStorage.readUserRole();
    if (id == null || name == null || email == null || role == null) {
      return null;
    }
    return User(id: id, name: name, email: email, role: role);
  }

  Future<User> login({required String email, required String password}) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    final data = response.data!;
    final user = User.fromJson(data['user'] as Map<String, dynamic>);
    await _tokenStorage.saveSession(
      token: data['accessToken'] as String,
      userId: user.id,
      userName: user.name,
      userEmail: user.email,
      userRole: user.role,
    );
    return user;
  }

  Future<void> logout() => _tokenStorage.clear();
}
