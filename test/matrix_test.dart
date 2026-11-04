import 'package:flutter_test/flutter_test.dart';
import 'package:graphica/core/math/matrix.dart';

void main() {
  final a = Matrix.fromRows([
    [1, 2],
    [3, 4],
  ]);
  final b = Matrix.fromRows([
    [5, 6],
    [7, 8],
  ]);

  group('arithmetic', () {
    test('addition', () {
      final result = a + b;
      expect(result.data, [
        [6, 8],
        [10, 12],
      ]);
    });

    test('subtraction', () {
      final result = a - b;
      expect(result.data, [
        [-4, -4],
        [-4, -4],
      ]);
    });

    test('multiplication', () {
      final result = a * b;
      expect(result.data, [
        [19, 22],
        [43, 50],
      ]);
    });

    test('scalar multiplication', () {
      expect(a.scale(2).data, [
        [2, 4],
        [6, 8],
      ]);
    });

    test('shape mismatch is reported', () {
      final c = Matrix.zero(3, 3);
      expect(() => a + c, throwsA(isA<MatrixException>()));
      expect(() => a * c, throwsA(isA<MatrixException>()));
    });
  });

  group('linear algebra', () {
    test('determinant of a 2x2 matrix', () {
      expect(a.determinant(), closeTo(-2, 1e-12));
    });

    test('determinant of a 3x3 matrix', () {
      final m = Matrix.fromRows([
        [6, 1, 1],
        [4, -2, 5],
        [2, 8, 7],
      ]);
      expect(m.determinant(), closeTo(-306, 1e-9));
    });

    test('transpose', () {
      expect(a.transpose().data, [
        [1, 3],
        [2, 4],
      ]);
    });

    test('inverse', () {
      final inverse = a.inverse();
      expect(inverse.at(0, 0), closeTo(-2, 1e-12));
      expect(inverse.at(0, 1), closeTo(1, 1e-12));
      expect(inverse.at(1, 0), closeTo(1.5, 1e-12));
      expect(inverse.at(1, 1), closeTo(-0.5, 1e-12));

      final identity = a * inverse;
      expect(identity.at(0, 0), closeTo(1, 1e-9));
      expect(identity.at(0, 1), closeTo(0, 1e-9));
      expect(identity.at(1, 0), closeTo(0, 1e-9));
      expect(identity.at(1, 1), closeTo(1, 1e-9));
    });

    test('singular matrix has no inverse', () {
      final singular = Matrix.fromRows([
        [1, 2],
        [2, 4],
      ]);
      expect(() => singular.inverse(), throwsA(isA<MatrixException>()));
      expect(singular.determinant(), closeTo(0, 1e-12));
    });

    test('trace', () {
      expect(a.trace, 5);
    });
  });

  group('construction', () {
    test('identity', () {
      expect(Matrix.identity(3).data, [
        [1, 0, 0],
        [0, 1, 0],
        [0, 0, 1],
      ]);
    });

    test('display aligns columns', () {
      final text = a.display();
      expect(text.split('\n').length, 2);
      expect(text.contains('1'), isTrue);
      expect(text.contains('4'), isTrue);
    });
  });
}
