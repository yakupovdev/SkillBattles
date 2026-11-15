import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

/// A 1x1 PNG.
final List<int> kTestPngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGA'
  'hKmMIQAAAABJRU5ErkJggg==',
);

/// HTTP client behind `NetworkImage` in tests: records every requested URL
/// and answers with the next status from [statuses] (the last one repeats);
/// a 200 carries [body] (default [kTestPngBytes]).
///
/// Install it with [install]; it removes itself in a tear-down.
final class FakeImageHttpClient extends Fake implements HttpClient {
  FakeImageHttpClient({this.statuses = const <int>[200], this.body});

  final List<int> statuses;
  final List<int>? body;
  final List<Uri> requests = <Uri>[];

  @override
  bool autoUncompress = false;

  void install() {
    debugNetworkImageHttpClientProvider = () => this;
    addTearDown(() {
      debugNetworkImageHttpClientProvider = null;
      PaintingBinding.instance.imageCache
        ..clear()
        ..clearLiveImages();
    });
  }

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    final int index = requests.length;
    requests.add(url);
    final int status =
        statuses[index < statuses.length ? index : statuses.length - 1];
    return _FakeRequest(
      _FakeResponse(
        status,
        status == 200 ? (body ?? kTestPngBytes) : const <int>[],
      ),
    );
  }
}

final class _FakeRequest extends Fake implements HttpClientRequest {
  _FakeRequest(this._response);

  final _FakeResponse _response;

  @override
  Future<HttpClientResponse> close() async => _response;
}

final class _FakeResponse extends Stream<List<int>>
    implements HttpClientResponse {
  _FakeResponse(this.statusCode, this._bytes);

  final List<int> _bytes;

  @override
  final int statusCode;

  @override
  int get contentLength => _bytes.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream<List<int>>.value(_bytes).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Encodes a white PNG of [width] x [height]; call inside `tester.runAsync`.
Future<List<int>> encodeTestPng(int width, int height) async {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()..color = const Color(0xFFFFFFFF),
  );
  final ui.Image image = await recorder.endRecording().toImage(width, height);
  final ByteData? data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}
