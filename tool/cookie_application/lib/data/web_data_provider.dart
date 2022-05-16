import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cookie_consent_vis/data/cookie.dart';

class WebDataProvider {
  static final String kHost = 'sv.home.lu';
  static final String kBasePath = '/';
  Uri kBaseUrl = new Uri.https(kHost, kBasePath);

  var headers = {
    'Content-Type': 'application/json',
    'Accept' : '*/*',

  };

  /**List<Cookie> parseCookies(String responseBody) {
    final parsed = jsonDecode(responseBody).cast<Map<String, dynamic>>();

    return parsed.map<Cookie>((json) => Cookie.fromJsonWeb(json)).toList();
  }*/

  List<Cookie> parseCookies2(List jsonList) {
    return jsonList.map((jsonCookie) => Cookie.fromJsonWeb(jsonCookie)).toList();
  }

  Future<int> baseRoute() async {
    var url = Uri.parse('http://localhost:58080/');
    final response = await http.get(url);
    print(response.body);
    return 1;
  }

  Future<int> insertCookies(var cookiesJsonText) async {
    var url = Uri.parse('https://sv.home.lu/api/insert');

    var body = json.decode(cookiesJsonText);

    var jsonBody = jsonEncode(body);
    final response = await http.post(url, headers: headers, body: jsonBody);

    print("in insertCookies");
    print(response.body);
    return 1;
  }

  Future<List<Cookie>> selectCookies(String userId) async {
    var url = Uri.parse('https://sv.home.lu/api/select');

    var body = new Map<String, String>();
    body["userId"] = userId;

    var jsonBody = jsonEncode(body);
    final response = await http.post(url, headers: headers, body: jsonBody);

    if(response.statusCode == 200) {
      try {
        List<Cookie> cookies = parseCookies2(jsonDecode(response.body));
        return cookies;
      } catch (e) {
        throw Exception('Failed to load cookies.');
      }
    }
    return null;
  }

  Future<int> deleteCookies(String userId) async {
    var url = Uri.parse('https://sv.home.lu/api/delete');

    var body = new Map<String, String>();
    body["userId"] = userId;

    var jsonBody = jsonEncode(body);
    final response = await http.post(url, headers: headers, body: jsonBody);

    print("in deleteCookies");
    print(response.body);
    return 1;
  }
}
