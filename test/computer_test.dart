import 'package:computer/computer.dart';
import 'package:test/test.dart';

void main() {
  test('Computer turn on', () async {
    final computer = Computer();
    await computer.turnOn();
    expect(computer.isRunning, equals(true));
    await computer.turnOff();
  });

  test('Computer initially turned off', () async {
    final computer = Computer();
    expect(computer.isRunning, equals(false));
  });

  test('Computer turn off', () async {
    final computer = Computer();
    await computer.turnOn();
    await computer.turnOff();
    expect(computer.isRunning, equals(false));
  });

  test('Computer reload', () async {
    final computer = Computer();
    await computer.turnOn();
    expect(computer.isRunning, equals(true));
    await computer.turnOff();
    expect(computer.isRunning, equals(false));
    await computer.turnOn();
    expect(computer.isRunning, equals(true));
    expect(await computer.compute(fib, param: 20), equals(fib(20)));
    await computer.turnOff();
  });

  test('Execute function with param', () async {
    final computer = Computer();
    await computer.turnOn();

    expect(await computer.compute(fib, param: 20), equals(fib(20)));

    await computer.turnOff();
  });

  test('Stress test', () async {
    final computer = Computer();
    await computer.turnOn();

    const numOfTasks = 500;

    final result = await Future.wait(
      List<Future<int>>.generate(
        numOfTasks,
        (_) async => await computer.compute(fib, param: 30),
      ),
    );

    final forComparison = List<int>.generate(
      numOfTasks,
      (_) => 832040,
    );

    expect(result, forComparison);

    await computer.turnOff();
  });

  test('Execute function without params', () async {
    final computer = Computer();
    await computer.turnOn();

    expect(await computer.compute(fib20), equals(fib20()));

    await computer.turnOff();
  });

  test('Execute static method', () async {
    final computer = Computer();
    await computer.turnOn();

    expect(await computer.compute(Fibonacci.fib, param: 20), equals(Fibonacci.fib(20)));

    await computer.turnOff();
  });

  test('Execute async method', () async {
    final computer = Computer();
    await computer.turnOn();

    expect(await computer.compute(fibAsync, param: 20), equals(await fibAsync(20)));

    await computer.turnOff();
  });
}

int fib(int n) {
  if (n < 2) {
    return n;
  }
  return fib(n - 2) + fib(n - 1);
}

Future<int> fibAsync(int n) async {
  await Future.delayed(const Duration(milliseconds: 100));

  return fib(n);
}

int fib20() {
  return fib(20);
}

abstract class Fibonacci {
  static int fib(int n) {
    if (n < 2) {
      return n;
    }
    return fib(n - 2) + fib(n - 1);
  }
}