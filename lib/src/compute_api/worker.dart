import 'dart:async';
import 'dart:isolate';

import 'package:computer/src/errors.dart';

import 'task.dart';

typedef OnResultCallback = void Function(
  TaskResult result,
  Worker worker,
);

typedef OnErrorCallback = void Function(
  RemoteExecutionError error,
  Worker worker,
);

enum WorkerStatus { idle, processing }

class IsolateInitParams {
  SendPort commands;

  IsolateInitParams({required this.commands});
}

class Worker {
  final String name;

  WorkerStatus status = WorkerStatus.idle;

  late final Isolate _isolate;
  late final SendPort _commands;
  late final ReceivePort _responses;
  late final Stream _broadcastResponses;
  late final StreamSubscription _broadcastPortSubscription;

  Worker(this.name);

  Future<void> init({
    required OnResultCallback onResult,
    required OnErrorCallback onError,
  }) async {
    _responses = ReceivePort();

    _isolate = await Isolate.spawn(
      isolateEntryPoint,
      IsolateInitParams(
        commands: _responses.sendPort,
      ),
      debugName: name,
      errorsAreFatal: false,
    );

    _broadcastResponses = _responses.asBroadcastStream();

    _commands = await _broadcastResponses.first as SendPort;

    _broadcastPortSubscription = _broadcastResponses.listen((dynamic res) {
      status = WorkerStatus.idle;
      if (res is RemoteExecutionError) {
        onError(res, this);
        return;
      }
      onResult(res as TaskResult, this);
    });
  }

  void executeStream(Task task, void Function(dynamic) onStreamResult) {
    status = WorkerStatus.processing;

    // Handle stream results directly
    final stream = task.task(task.param) as Stream;
    stream.listen(onStreamResult, onDone: () {
      onStreamResult(null); // Signal completion
      status = WorkerStatus.idle;
    }, onError: (e) {
      onStreamResult(RemoteExecutionError(e.toString(), task.capability));
    });
  }

  void execute(Task task) {
    status = WorkerStatus.processing;
    _commands.send(task);
  }

  Future<void> dispose() async {
    await _broadcastPortSubscription.cancel();
    _isolate.kill();
    _responses.close();
  }
}

Future<void> isolateEntryPoint(IsolateInitParams params) async {
  final responses = ReceivePort();
  final commands = params.commands;

  commands.send(responses.sendPort);

  await for (final Task task in responses.cast<Task>()) {
    try {
      final shouldPassParam = task.param != null;

      final dynamic computationResult =
          shouldPassParam ? await task.task(task.param) : await task.task();

      final result = TaskResult(
        result: computationResult,
        capability: task.capability,
      );
      commands.send(result);
    } catch (error) {
      commands.send(RemoteExecutionError(error.toString(), task.capability));
    }
  }
}
