import 'package:flutter_test/flutter_test.dart';
import 'package:graphica/core/math/latex.dart';

void main() {
  group('LaTeX conversion', () {
    test('roots and powers', () {
      final latex = expressionToLatex('sqrt(x^2 + y^2)');
      expect(latex, isNotNull);
      expect(latex, contains(r'\sqrt'));
      expect(latex, contains('{x}^{2}'));
    });

    test('fractions', () {
      expect(expressionToLatex('x / 2'), contains(r'\frac{x}{2}'));
    });

    test('constants and functions', () {
      expect(expressionToLatex('2pi'), contains(r'\pi'));
      expect(expressionToLatex('sin(x)'), contains(r'\operatorname{sin}'));
    });

    test('implicit equations keep both sides', () {
      final latex = equationToLatex('x^2 + y^2 = 9');
      expect(latex, isNotNull);
      expect(latex, contains('='));
      expect(latex, contains('9'));
    });

    test('invalid input returns null', () {
      expect(expressionToLatex('sin('), isNull);
      expect(equationToLatex('x^2 ='), isNull);
    });
  });
}
