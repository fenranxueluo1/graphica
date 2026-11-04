import '../../core/utils/formatters.dart';

/// Error raised when a matrix operation has invalid dimensions or is undefined.
///
/// [code] is an l10n key (e.g. `matrix.error.singular`); [details] holds the
/// placeholder values used to fill the `{...}` slots in the translated text.
class MatrixException implements Exception {
  const MatrixException(this.code, [this.details = const <String, String>{}]);

  final String code;
  final Map<String, String> details;

  @override
  String toString() => code;
}

/// Immutable rectangular matrix of doubles.
class Matrix {
  Matrix(this.rows, this.cols, [List<List<double>>? values])
    : assert(rows >= 0 && cols >= 0),
      data = _normalize(rows, cols, values);

  factory Matrix.zero(int rows, int cols) =>
      Matrix(rows, cols, List.generate(rows, (_) => List.filled(cols, 0.0)));

  factory Matrix.identity(int size) {
    final value = Matrix.zero(size, size);
    for (var i = 0; i < size; i++) {
      value.data[i][i] = 1;
    }
    return value;
  }

  factory Matrix.fromRows(List<List<double>> rows) {
    final cols = rows.isEmpty ? 0 : rows.first.length;
    return Matrix(rows.length, cols, rows);
  }

  final int rows;
  final int cols;
  final List<List<double>> data;

  static List<List<double>> _normalize(
    int rows,
    int cols,
    List<List<double>>? values,
  ) {
    return List.generate(rows, (r) {
      return List.generate(cols, (c) {
        if (values == null || r >= values.length || c >= values[r].length) {
          return 0;
        }
        return values[r][c];
      });
    });
  }

  bool get isSquare => rows == cols;

  double at(int row, int col) => data[row][col];

  void set(int row, int col, double value) => data[row][col] = value;

  Matrix copy() => Matrix(rows, cols, [
    for (final row in data) [...row],
  ]);

  void _requireShape(Matrix other, String operation) {
    if (rows != other.rows || cols != other.cols) {
      throw MatrixException('matrix.error.shapeMismatch', <String, String>{
        'op': operation,
        'a': '$rows×$cols',
        'b': '${other.rows}×${other.cols}',
      });
    }
  }

  Matrix operator +(Matrix other) {
    _requireShape(other, 'matrix.op.add');
    return Matrix(rows, cols, [
      for (var r = 0; r < rows; r++)
        [for (var c = 0; c < cols; c++) data[r][c] + other.data[r][c]],
    ]);
  }

  Matrix operator -(Matrix other) {
    _requireShape(other, 'matrix.op.sub');
    return Matrix(rows, cols, [
      for (var r = 0; r < rows; r++)
        [for (var c = 0; c < cols; c++) data[r][c] - other.data[r][c]],
    ]);
  }

  Matrix operator *(Matrix other) {
    if (cols != other.rows) {
      throw MatrixException('matrix.error.mulMismatch', <String, String>{
        'a': '$rows×$cols',
        'b': '${other.rows}×${other.cols}',
      });
    }
    final result = Matrix.zero(rows, other.cols);
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < other.cols; c++) {
        var sum = 0.0;
        for (var k = 0; k < cols; k++) {
          sum += data[r][k] * other.data[k][c];
        }
        result.data[r][c] = sum;
      }
    }
    return result;
  }

  Matrix scale(double factor) {
    return Matrix(rows, cols, [
      for (var r = 0; r < rows; r++)
        [for (var c = 0; c < cols; c++) data[r][c] * factor],
    ]);
  }

  Matrix transpose() {
    return Matrix(cols, rows, [
      for (var c = 0; c < cols; c++)
        [for (var r = 0; r < rows; r++) data[r][c]],
    ]);
  }

  double get trace {
    if (!isSquare) {
      throw const MatrixException('matrix.error.square.trace');
    }
    var sum = 0.0;
    for (var i = 0; i < rows; i++) {
      sum += data[i][i];
    }
    return sum;
  }

  /// Determinant via Gaussian elimination with partial pivoting.
  double determinant() {
    if (!isSquare) {
      throw const MatrixException('matrix.error.square.det');
    }
    final n = rows;
    if (n == 0) return 1;
    final work = copy().data;
    var result = 1.0;
    for (var col = 0; col < n; col++) {
      var pivotRow = col;
      for (var r = col + 1; r < n; r++) {
        if (work[r][col].abs() > work[pivotRow][col].abs()) {
          pivotRow = r;
        }
      }
      if (work[pivotRow][col].abs() < 1e-12) return 0;
      if (pivotRow != col) {
        final temp = work[pivotRow];
        work[pivotRow] = work[col];
        work[col] = temp;
        result = -result;
      }
      final pivot = work[col][col];
      result *= pivot;
      for (var r = col + 1; r < n; r++) {
        final factor = work[r][col] / pivot;
        for (var c = col; c < n; c++) {
          work[r][c] -= factor * work[col][c];
        }
      }
    }
    return result;
  }

  /// Inverse via Gauss-Jordan elimination. Throws when singular.
  Matrix inverse() {
    if (!isSquare) {
      throw const MatrixException('matrix.error.square.inverse');
    }
    final n = rows;
    final work = [
      for (var r = 0; r < n; r++)
        [...data[r], ...List<double>.generate(n, (c) => r == c ? 1 : 0)],
    ];

    for (var col = 0; col < n; col++) {
      var pivotRow = col;
      for (var r = col + 1; r < n; r++) {
        if (work[r][col].abs() > work[pivotRow][col].abs()) {
          pivotRow = r;
        }
      }
      if (work[pivotRow][col].abs() < 1e-12) {
        throw const MatrixException('matrix.error.singular');
      }
      if (pivotRow != col) {
        final temp = work[pivotRow];
        work[pivotRow] = work[col];
        work[col] = temp;
      }
      final pivot = work[col][col];
      for (var c = 0; c < 2 * n; c++) {
        work[col][c] /= pivot;
      }
      for (var r = 0; r < n; r++) {
        if (r == col) continue;
        final factor = work[r][col];
        if (factor == 0) continue;
        for (var c = 0; c < 2 * n; c++) {
          work[r][c] -= factor * work[col][c];
        }
      }
    }

    return Matrix(n, n, [for (var r = 0; r < n; r++) work[r].sublist(n)]);
  }

  /// Pretty multi-line text used in result cards.
  String display({int precision = 6}) {
    final cells = [
      for (final row in data)
        [for (final value in row) formatNumber(value, precision: precision)],
    ];
    final widths = List.generate(cols, (c) {
      var width = 1;
      for (final row in cells) {
        if (row[c].length > width) width = row[c].length;
      }
      return width;
    });
    return cells
        .map(
          (row) => row
              .asMap()
              .entries
              .map((entry) => entry.value.padLeft(widths[entry.key]))
              .join('  '),
        )
        .join('\n');
  }
}
