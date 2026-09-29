import 'package:dio/dio.dart';
import 'api_exception.dart';
import 'auth_storage.dart';

/// Points at the FastAPI backend. Override with --dart-define=API_BASE_URL=...
/// for a device/emulator that can't reach localhost directly.
const String _defaultBaseUrl = 'http://localhost:4000/api/v1';
const String apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: _defaultBaseUrl);

/// Thin wrapper around Dio that unwraps the standard `{success, data, error}`
/// envelope, attaches the bearer token, and transparently retries once after a
/// refresh-token rotation on a 401.
class ApiClient {
  final AuthStorage authStorage;
  late final Dio _dio;
  // Shared by every concurrent 401 — without this, only the first of several
  // requests that expire around the same time gets refreshed-and-retried; the
  // others would previously see !_isRefreshing already false and fail outright
  // instead of waiting for the in-flight refresh and retrying with its result.
  Future<bool>? _refreshFuture;

  ApiClient({required this.authStorage}) {
    _dio = Dio(BaseOptions(baseUrl: apiBaseUrl, connectTimeout: const Duration(seconds: 12), receiveTimeout: const Duration(seconds: 12)));
    _dio.interceptors.add(InterceptorsWrapper(onRequest: _onRequest, onError: _onError));
  }

  Future<void> _onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await authStorage.accessToken;
    if (token != null) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }

  Future<void> _onError(DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;
    final path = err.requestOptions.path;

    if (status == 401 && path != '/auth/token/refresh' && path != '/auth/otp/verify') {
      final refreshFuture = _refreshFuture ??= _tryRefresh().whenComplete(() => _refreshFuture = null);
      try {
        final refreshed = await refreshFuture;
        if (refreshed) {
          final clone = await _dio.fetch(err.requestOptions);
          return handler.resolve(clone);
        }
      } catch (_) {
        // Fall through — original error is reported below.
      }
    }
    handler.next(err);
  }

  Future<bool> _tryRefresh() async {
    final refreshToken = await authStorage.refreshToken;
    if (refreshToken == null) return false;
    try {
      final res = await _dio.post('/auth/token/refresh', data: {'refresh_token': refreshToken});
      final data = res.data['data'] as Map<String, dynamic>;
      await authStorage.updateAccessToken(data['access_token'], data['refresh_token']);
      return true;
    } catch (_) {
      await authStorage.clear();
      return false;
    }
  }

  dynamic _unwrap(Response res) {
    final body = res.data as Map<String, dynamic>;
    if (body['success'] == true) return body['data'];
    throw ApiException.fromEnvelope(body['error'] as Map<String, dynamic>);
  }

  ApiException _mapDioError(DioException e) {
    final body = e.response?.data;
    if (body is Map<String, dynamic> && body['error'] != null) {
      return ApiException.fromEnvelope(body['error'] as Map<String, dynamic>);
    }
    if (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout) {
      return ApiException.network();
    }
    return ApiException(code: 'UNKNOWN_ERROR', message: e.message ?? 'Something went wrong');
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    try {
      return _unwrap(await _dio.get(path, queryParameters: query));
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? data, Map<String, dynamic>? query, Map<String, String>? headers}) async {
    try {
      return _unwrap(await _dio.post(path, data: data, queryParameters: query, options: Options(headers: headers)));
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<dynamic> patch(String path, {Map<String, dynamic>? data, Map<String, dynamic>? query}) async {
    try {
      return _unwrap(await _dio.patch(path, data: data, queryParameters: query));
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<dynamic> delete(String path) async {
    try {
      return _unwrap(await _dio.delete(path));
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }
}
