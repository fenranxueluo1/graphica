import 'package:flutter_test/flutter_test.dart';
import 'package:graphica/core/math/expression.dart';

void main() {
  double ev(
    String source, {
    Map<String, double> variables = const {},
    AngleMode angleMode = AngleMode.radians,
  }) {
    return MathEngine.evaluate(
      source,
      variables: variables,
      angleMode: angleMode,
    );
  }

  group('precedence and operators', () {
    test('multiplication binds before addition', () {
      expect(ev('2 + 3 * 4'), 14);
    });

    test('exponentiation is right associative', () {
      expect(ev('2^3^2'), 512);
    });

    test('unary minus applies after exponentiation', () {
      expect(ev('-3^2'), -9);
      expect(ev('(-3)^2'), 9);
    });

    test('division and modulo', () {
      expect(ev('7 / 2'), 3.5);
      expect(ev('7 % 3'), 1);
    });

    test('factorial binds to its operand', () {
      expect(ev('5!'), 120);
      expect(ev('3! + 1'), 7);
    });
  });

  group('implicit multiplication', () {
    test('number and variable', () {
      expect(ev('2x', variables: {'x': 5}), 10);
    });

    test('adjacent parentheses', () {
      expect(ev('(1 + 2)(3 + 4)'), 21);
    });

    test('number and constant', () {
      expect(ev('2pi'), closeTo(6.283185307, 1e-9));
    });

    test('number and function', () {
      expect(ev('3sin(pi / 2) + 1'), closeTo(4, 1e-12));
    });
  });

  group('functions and constants', () {
    test('trigonometry in radians', () {
      expect(ev('sin(pi / 2)'), closeTo(1, 1e-12));
      expect(ev('cos(0)'), 1);
    });

    test('trigonometry in degrees', () {
      expect(ev('sin(30)', angleMode: AngleMode.degrees), closeTo(0.5, 1e-12));
      expect(ev('asin(1)', angleMode: AngleMode.degrees), closeTo(90, 1e-9));
    });

    test('logarithms', () {
      expect(ev('log(100)'), closeTo(2, 1e-12));
      expect(ev('ln(e)'), closeTo(1, 1e-12));
      expect(ev('log(8, 2)'), closeTo(3, 1e-12));
      expect(ev('log2(8)'), closeTo(3, 1e-12));
    });

    test('roots and absolute value', () {
      expect(ev('sqrt(16)'), 4);
      expect(ev('cbrt(-8)'), closeTo(-2, 1e-12));
      expect(ev('abs(-4)'), 4);
    });

    test('variadic min and max', () {
      expect(ev('min(3, 1, 2)'), 1);
      expect(ev('max(3, 1, 9, 2)'), 9);
    });

    test('gcd and lcm', () {
      expect(ev('gcd(12, 18)'), 6);
      expect(ev('lcm(4, 6)'), 12);
    });

    test('non-integer factorial uses the gamma function', () {
      expect(ev('gamma(5)'), closeTo(24, 1e-9));
    });

    test('theta variable is available for polar input', () {
      expect(ev('2cos(theta)', variables: {'theta': 0}), closeTo(2, 1e-12));
    });
  });

  group('errors', () {
    test('missing closing parenthesis', () {
      expect(() => ev('sin(1'), throwsA(isA<MathException>()));
    });

    test('trailing operator', () {
      expect(() => ev('2 +'), throwsA(isA<MathException>()));
    });

    test('unknown variable', () {
      expect(() => ev('foo + 1'), throwsA(isA<MathException>()));
    });

    test('invalid characters', () {
      expect(() => ev('2 @ 3'), throwsA(isA<MathException>()));
    });

    test('validate reports a message without throwing', () {
      expect(MathEngine.validate('sin('), isNotNull);
      expect(MathEngine.validate('sin(x)'), isNull);
    });
  });
}
