import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Change this to your server.
/// Android emulator -> 10.0.2.2 maps to your machine's localhost.
/// Real device/production -> put your https URL here.
const String kBaseUrl = String.fromEnvironment('API',
    defaultValue: 'https://naitriassociatellp.com/api/app');

class Api {
  Api._();
  static final Api i = Api._();

  String? _token;
  String? get token => _token;

  Future<void> loadToken() async {
    final p = await SharedPreferences.getInstance();
    _token = p.getString('token');
  }

  Future<void> _save(String t) async {
    _token = t;
    (await SharedPreferences.getInstance()).setString('token', t);
  }

  Future<void> logout() async {
    _token = null;
    (await SharedPreferences.getInstance()).remove('token');
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Uri _u(String path) => Uri.parse('$kBaseUrl$path');

  dynamic _decode(http.Response r) {
    final body = r.body.isEmpty ? {} : jsonDecode(r.body);
    if (r.statusCode >= 200 && r.statusCode < 300) return body;
    throw ApiError(body is Map && body['error'] != null
        ? body['error'].toString()
        : 'Something went wrong (${r.statusCode})');
  }

  // ---- auth ----
  Future<String?> requestOtp(String phone) async {
    final r = await http.post(_u('/request-otp'),
        headers: _headers, body: jsonEncode({'phone': phone}));
    final d = _decode(r);
    return d['dev_otp'] as String?; // present only in dev
  }

  Future<Map> verifyOtp(String phone, String otp) async {
    final r = await http.post(_u('/verify-otp'),
        headers: _headers, body: jsonEncode({'phone': phone, 'otp': otp}));
    final d = _decode(r) as Map;
    await _save(d['token']);
    return d['member'];
  }

  // ---- data ----
  Future<Map> home() async => _decode(await http.get(_u('/home'), headers: _headers));
  Future<Map> loan(int id) async => _decode(await http.get(_u('/loans/$id'), headers: _headers));
  Future<Map> dues() async => _decode(await http.get(_u('/dues'), headers: _headers));
  Future<Map> device(int loanId) async => _decode(await http.get(_u('/device/$loanId'), headers: _headers));

  Future<void> pay({required int loanId, int? emiId, required num amount, String method = 'upi', String? reference}) async {
    final r = await http.post(_u('/pay'),
        headers: _headers,
        body: jsonEncode({'loan_id': loanId, 'emi_id': emiId, 'amount': amount, 'method': method, 'reference': reference}));
    _decode(r);
  }

  // Razorpay: create an order (mode 'checkout') or get a razorpay.me link (mode 'link')
  Future<Map> payOrder({required int loanId, int? emiId, required num amount}) async {
    final r = await http.post(_u('/pay/order'),
        headers: _headers,
        body: jsonEncode({'loan_id': loanId, 'emi_id': emiId, 'amount': amount}));
    return _decode(r) as Map;
  }

  // Razorpay: verify a Checkout success and record the payment
  Future<void> payVerify({required String orderId, required String paymentId, required String signature,
      required int loanId, int? emiId, required num amount}) async {
    final r = await http.post(_u('/pay/verify'),
        headers: _headers,
        body: jsonEncode({'order_id': orderId, 'payment_id': paymentId, 'signature': signature,
          'loan_id': loanId, 'emi_id': emiId, 'amount': amount}));
    _decode(r);
  }

  Future<List> documents(int loanId) async =>
      _decode(await http.get(_u('/loans/$loanId/documents'), headers: _headers)) as List;

  Future<List<int>> statementCsv(int loanId) async {
    final r = await http.get(_u('/loans/$loanId/statement.csv'), headers: _headers);
    if (r.statusCode >= 200 && r.statusCode < 300) return r.bodyBytes;
    throw ApiError('Could not download the statement (${r.statusCode})');
  }

  Future<void> uploadSelfie({required File file, required String kind, int? loanId}) async {
    final req = http.MultipartRequest('POST', _u('/selfies'))
      ..headers['Authorization'] = 'Bearer $_token'
      ..fields['kind'] = kind
      ..files.add(await http.MultipartFile.fromPath('file', file.path));
    if (loanId != null) req.fields['loan_id'] = '$loanId';
    final res = await http.Response.fromStream(await req.send());
    _decode(res);
  }
}

class ApiError implements Exception {
  final String message;
  ApiError(this.message);
  @override
  String toString() => message;
}
