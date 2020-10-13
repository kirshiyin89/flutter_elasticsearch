import 'package:universal_io/io.dart';
import 'package:universal_io/prefer_universal/io.dart';
import 'dart:convert';
import 'package:elastic_client/console_http_transport.dart';

class OwnHttpTransport extends UniversalHttpTransport {
  OwnHttpTransport(Uri uri, {BasicAuth basicAuth})
      : super(HttpClient(), uri, basicAuth: basicAuth);
}

class UniversalHttpTransport implements Transport {
  final Uri _uri;
  final HttpClient _httpClient;
  final Duration _timeout;
  final BasicAuth _basicAuth;

  UniversalHttpTransport(this._httpClient, this._uri,
      {Duration timeout = const Duration(minutes: 1), BasicAuth basicAuth})
      : _timeout = timeout,
        _basicAuth = basicAuth;

  @override
  Future<Response> send(Request request) async {
    final pathSegments = <String>[
      ...?_uri.pathSegments,
      ...?request.pathSegments,
    ];
    final newUri = _uri.replace(
        pathSegments: pathSegments, queryParameters: request.params);

    _httpClient.autoUncompress = true;
    _httpClient.idleTimeout = _timeout;

    final req = await _httpClient.open(
        request.method, _uri.host, _uri.port, newUri.path);

    req.headers.contentType = ContentType.json;
    req.headers.add('Accept', ContentType.json);
    _mergeHeader(request.headers).forEach((k, v) => req.headers.add(k, v));

    req.write(request.bodyText);

    final rs = await req.close();
    var resultBody = await rs.transform(utf8.decoder).join("");

    return Response(rs.statusCode, resultBody);
  }

  @override
  Future close() async {
    _httpClient.close();
  }

  Map<String, String> _mergeHeader(Map<String, String> headerToMerge) {
    if (_basicAuth != null) {
      final headers = Map<String, String>.from(_basicAuth.toMap());
      headers.addAll(headerToMerge);
      return headers;
    }
    return headerToMerge;
  }
}
