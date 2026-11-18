import 'dart:async';
import 'dart:collection';

import 'package:bloc_signals/bloc_signals.dart';

export 'package:bloc_signals/bloc_signals.dart'
    hide EventHandler, EventTransformer, droppable, restartable, sequential;

/// The `emit` of an event handler with the contract of `package:bloc`:
/// [isDone] turns true when the handler completed, was cancelled by a newer
/// event ([restartable]) or the bloc closed, and a call after that is
/// ignored. Handlers check `if (emit.isDone) return;` after every `await`.
final class Emitter<State> implements _Completable {
  Emitter._(this._emit, this._isClosed);

  final void Function(State state) _emit;
  final bool Function() _isClosed;
  bool _done = false;

  bool get isDone => _done || _isClosed();

  void call(State state) {
    if (isDone) return;
    _emit(state);
  }

  @override
  void _complete() => _done = true;
}

/// The part of an [Emitter] the runners use, independent of the state type.
abstract interface class _Completable {
  void _complete();
}

typedef EventHandler<E, State> =
    FutureOr<void> Function(E event, Emitter<State> emit);

/// How a [SignalBloc] runs overlapping events of one type, with the
/// semantics of `package:bloc_concurrency`.
sealed class EventConcurrency {
  const EventConcurrency();

  _Runner _createRunner();
}

/// Every event runs at once (the default).
EventConcurrency concurrent() => const _Concurrent();

/// Events run one after another, in order.
EventConcurrency sequential() => const _Sequential();

/// An event that arrives while one runs is dropped.
EventConcurrency droppable() => const _Droppable();

/// A new event cancels the running one: its `emit.isDone` turns true.
EventConcurrency restartable() => const _Restartable();

final class _Concurrent extends EventConcurrency {
  const _Concurrent();

  @override
  _Runner _createRunner() => _ConcurrentRunner();
}

final class _Sequential extends EventConcurrency {
  const _Sequential();

  @override
  _Runner _createRunner() => _SequentialRunner();
}

final class _Droppable extends EventConcurrency {
  const _Droppable();

  @override
  _Runner _createRunner() => _DroppableRunner();
}

final class _Restartable extends EventConcurrency {
  const _Restartable();

  @override
  _Runner _createRunner() => _RestartableRunner();
}

abstract class _Runner {
  Future<void> run(_Completable emitter, Future<void> Function() body);
}

Future<void> _execute(
  _Completable emitter,
  Future<void> Function() body,
) async {
  try {
    await body();
  } finally {
    emitter._complete();
  }
}

final class _ConcurrentRunner implements _Runner {
  @override
  Future<void> run(_Completable emitter, Future<void> Function() body) =>
      _execute(emitter, body);
}

final class _SequentialRunner implements _Runner {
  final Queue<Future<void> Function()> _queue =
      Queue<Future<void> Function()>();
  bool _running = false;

  @override
  Future<void> run(_Completable emitter, Future<void> Function() body) {
    final Completer<void> done = Completer<void>();
    _queue.add(() async {
      try {
        await _execute(emitter, body);
        done.complete();
      } on Object catch (error, stackTrace) {
        done.completeError(error, stackTrace);
      }
    });
    unawaited(_drain());
    return done.future;
  }

  Future<void> _drain() async {
    if (_running) return;
    _running = true;
    while (_queue.isNotEmpty) {
      await _queue.removeFirst()();
    }
    _running = false;
  }
}

final class _DroppableRunner implements _Runner {
  bool _busy = false;

  @override
  Future<void> run(
    _Completable emitter,
    Future<void> Function() body,
  ) async {
    if (_busy) {
      emitter._complete();
      return;
    }
    _busy = true;
    try {
      await _execute(emitter, body);
    } finally {
      _busy = false;
    }
  }
}

final class _RestartableRunner implements _Runner {
  _Completable? _active;

  @override
  Future<void> run(_Completable emitter, Future<void> Function() body) {
    _active?._complete();
    _active = emitter;
    return _execute(emitter, body).whenComplete(() {
      if (identical(_active, emitter)) _active = null;
    });
  }
}

/// A [BlocSignal] whose handlers keep the `package:bloc` shape:
/// `handle<E>(_onE, transformer: restartable())` with
/// `Future<void> _onE(E event, Emitter<State> emit)`.
///
/// Read the current state with [stateValue]; [state] is the signal that
/// `bloc_signals_jaspr` components subscribe to.
abstract class SignalBloc<Event, State> extends BlocSignal<Event, State> {
  SignalBloc(State initialState) : super(initialState: initialState);

  StreamController<State>? _streamController;
  void Function()? _unsubscribeStream;

  /// States emitted after a listener subscribes, closed by [close] — the
  /// `stream` of `package:bloc`. (The `stream` extension of `bloc_signals`
  /// replays the current state to its first listener and never closes.)
  Stream<State> get stream {
    final StreamController<State> controller = _streamController ??=
        StreamController<State>.broadcast();
    if (_unsubscribeStream == null && !isClosed) {
      // `subscribe` calls back at once with the current value; skip it.
      bool isInitialValue = true;
      _unsubscribeStream = state.subscribe((State value) {
        if (isInitialValue) {
          isInitialValue = false;
          return;
        }
        if (!controller.isClosed) controller.add(value);
      });
    }
    return controller.stream;
  }

  @override
  Future<void> close() async {
    _unsubscribeStream?.call();
    _unsubscribeStream = null;
    await super.close();
    await _streamController?.close();
  }

  /// Registers [handler] for events of type [E]. Without [transformer]
  /// overlapping events run concurrently, as in `package:bloc`.
  void handle<E extends Event>(
    EventHandler<E, State> handler, {
    EventConcurrency? transformer,
  }) {
    final _Runner runner = (transformer ?? concurrent())._createRunner();
    on<E>((E event, void Function(State state) emit) {
      final Emitter<State> emitter = Emitter<State>._(emit, () => isClosed);
      return runner.run(emitter, () async {
        // `package:bloc` delivers events asynchronously; `bloc_signals`
        // would run the handler inside `add`. Start it on the next
        // microtask so the code after `add(...)` runs first, as before.
        await Future<void>.value();
        if (emitter.isDone) return;
        await handler(event, emitter);
      });
    });
  }
}
