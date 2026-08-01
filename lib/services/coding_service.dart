import 'dart:async';

import '../models/coding.dart';

abstract class CodingService {
  Stream<CodingState> codingStream();
  Future<CodingState> startCoding(CodingModule module);
}

class MockCodingService implements CodingService {
  final _controller = StreamController<CodingState>.broadcast();

  @override
  Stream<CodingState> codingStream() => _controller.stream;

  @override
  Future<CodingState> startCoding(CodingModule module) async {
    final states = [
      CodingState.downloading,
      CodingState.writing,
      CodingState.verifying,
      CodingState.done,
    ];
    for (final state in states) {
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      _controller.add(state);
    }
    return CodingState.done;
  }
}
