import 'dart:math' as math;

/// Angular unit used by trigonometric functions.
enum AngleMode { radians, degrees }

/// Error raised for malformed input or invalid evaluation.
class MathException implements Exception {
  const MathException(this.message, [this.position]);

  final String message;
  final int? position;

  @override
  String toString() => message;
}

// ---------------------------------------------------------------------------
// Tokenizer
// ---------------------------------------------------------------------------

enum _TokenType {
  number,
  identifier,
  plus,
  minus,
  star,
  slash,
  caret,
  percent,
  lparen,
  rparen,
  comma,
  bang,
  eof,
}

class _Token {
  const _Token(this.type, this.lexeme, this.start, [this.value]);

  final _TokenType type;
  final String lexeme;
  final int start;
  final double? value;
}

class _Lexer {
  _Lexer(String source) : _source = _normalize(source);

  final String _source;
  int _index = 0;

  static String _normalize(String source) {
    return source
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll('−', '-')
        .replaceAll('–', '-')
        .replaceAll('π', 'pi')
        .replaceAll('θ', 'theta')
        .replaceAll('²', '^2')
        .replaceAll('³', '^3')
        .replaceAll('√', 'sqrt');
  }

  List<_Token> tokenize() {
    final tokens = <_Token>[];
    while (true) {
      _skipWhitespace();
      if (_index >= _source.length) {
        tokens.add(_Token(_TokenType.eof, '', _index));
        return tokens;
      }
      final start = _index;
      final char = _source[_index];

      if (_isDigit(char) ||
          (char == '.' &&
              _index + 1 < _source.length &&
              _isDigit(_source[_index + 1]))) {
        tokens.add(_number(start));
        continue;
      }

      if (_isIdentifierStart(char)) {
        tokens.add(_identifier(start));
        continue;
      }

      _index++;
      switch (char) {
        case '+':
          tokens.add(_Token(_TokenType.plus, char, start));
        case '-':
          tokens.add(_Token(_TokenType.minus, char, start));
        case '*':
          tokens.add(_Token(_TokenType.star, char, start));
        case '/':
          tokens.add(_Token(_TokenType.slash, char, start));
        case '^':
          tokens.add(_Token(_TokenType.caret, char, start));
        case '%':
          tokens.add(_Token(_TokenType.percent, char, start));
        case '(':
          tokens.add(_Token(_TokenType.lparen, char, start));
        case ')':
          tokens.add(_Token(_TokenType.rparen, char, start));
        case ',':
          tokens.add(_Token(_TokenType.comma, char, start));
        case '!':
          tokens.add(_Token(_TokenType.bang, char, start));
        default:
          throw MathException('Unexpected character "$char"', start);
      }
    }
  }

  void _skipWhitespace() {
    while (_index < _source.length && _source[_index].trim().isEmpty) {
      _index++;
    }
  }

  _Token _number(int start) {
    var seenDot = false;
    while (_index < _source.length) {
      final char = _source[_index];
      if (_isDigit(char)) {
        _index++;
      } else if (char == '.' && !seenDot) {
        seenDot = true;
        _index++;
      } else {
        break;
      }
    }

    // Scientific notation: 1e3, 2.5E-4. Only consume when digits follow.
    if (_index < _source.length &&
        (_source[_index] == 'e' || _source[_index] == 'E')) {
      var lookahead = _index + 1;
      if (lookahead < _source.length &&
          (_source[lookahead] == '+' || _source[lookahead] == '-')) {
        lookahead++;
      }
      if (lookahead < _source.length && _isDigit(_source[lookahead])) {
        _index = lookahead;
        while (_index < _source.length && _isDigit(_source[_index])) {
          _index++;
        }
      }
    }

    final lexeme = _source.substring(start, _index);
    final value = double.tryParse(lexeme);
    if (value == null) {
      throw MathException('Invalid number "$lexeme"', start);
    }
    return _Token(_TokenType.number, lexeme, start, value);
  }

  _Token _identifier(int start) {
    while (_index < _source.length && _isIdentifierPart(_source[_index])) {
      _index++;
    }
    return _Token(
      _TokenType.identifier,
      _source.substring(start, _index),
      start,
    );
  }

  static bool _isDigit(String char) {
    final code = char.codeUnitAt(0);
    return code >= 48 && code <= 57;
  }

  static bool _isIdentifierStart(String char) {
    final code = char.codeUnitAt(0);
    return (code >= 65 && code <= 90) ||
        (code >= 97 && code <= 122) ||
        char == '_';
  }

  static bool _isIdentifierPart(String char) {
    return _isIdentifierStart(char) || _isDigit(char);
  }
}

// ---------------------------------------------------------------------------
// Expression tree
// ---------------------------------------------------------------------------

/// Immutable expression node evaluated against an [EvalContext].
abstract class Expr {
  const Expr();

  double eval(EvalContext context);
}

class NumberExpr extends Expr {
  const NumberExpr(this.value);

  final double value;

  @override
  double eval(EvalContext context) => value;
}

class VariableExpr extends Expr {
  const VariableExpr(this.name);

  final String name;

  @override
  double eval(EvalContext context) {
    final value = context.variables[name];
    if (value != null) return value;
    switch (name) {
      case 'pi':
        return math.pi;
      case 'e':
        return math.e;
      case 'tau':
        return math.pi * 2;
      case 'phi':
        return (1 + math.sqrt(5)) / 2;
      case 'inf':
      case 'infinity':
        return double.infinity;
    }
    throw MathException('Unknown variable "$name"');
  }
}

class UnaryExpr extends Expr {
  const UnaryExpr(this.operator, this.operand);

  final String operator;
  final Expr operand;

  @override
  double eval(EvalContext context) {
    final value = operand.eval(context);
    return operator == '-' ? -value : value;
  }
}

class BinaryExpr extends Expr {
  const BinaryExpr(this.operator, this.left, this.right);

  final String operator;
  final Expr left;
  final Expr right;

  @override
  double eval(EvalContext context) {
    switch (operator) {
      case '+':
        return left.eval(context) + right.eval(context);
      case '-':
        return left.eval(context) - right.eval(context);
      case '*':
        return left.eval(context) * right.eval(context);
      case '/':
        return left.eval(context) / right.eval(context);
      case '%':
        final a = left.eval(context);
        final b = right.eval(context);
        return a - b * (a / b).floorToDouble();
      case '^':
        return math.pow(left.eval(context), right.eval(context)).toDouble();
    }
    throw MathException('Unknown operator "$operator"');
  }
}

class CallExpr extends Expr {
  const CallExpr(this.name, this.arguments);

  final String name;
  final List<Expr> arguments;

  @override
  double eval(EvalContext context) {
    final args = arguments.map((argument) => argument.eval(context)).toList();
    return _Functions.call(name, args, context.angleMode);
  }
}

/// Values available while evaluating an expression.
class EvalContext {
  const EvalContext({
    this.variables = const {},
    this.angleMode = AngleMode.radians,
  });

  final Map<String, double> variables;
  final AngleMode angleMode;

  EvalContext withVariable(String name, double value) {
    return EvalContext(
      variables: {...variables, name: value},
      angleMode: angleMode,
    );
  }
}

// ---------------------------------------------------------------------------
// Function library
// ---------------------------------------------------------------------------

class _Functions {
  const _Functions._();

  static const arities = <String, List<int>>{
    'sin': [1],
    'cos': [1],
    'tan': [1],
    'sec': [1],
    'csc': [1],
    'cot': [1],
    'asin': [1],
    'acos': [1],
    'atan': [1],
    'asec': [1],
    'acsc': [1],
    'acot': [1],
    'sinh': [1],
    'cosh': [1],
    'tanh': [1],
    'asinh': [1],
    'acosh': [1],
    'atanh': [1],
    'ln': [1],
    'log': [1, 2],
    'log10': [1],
    'log2': [1],
    'sqrt': [1],
    'cbrt': [1],
    'abs': [1],
    'exp': [1],
    'floor': [1],
    'ceil': [1],
    'round': [1],
    'sign': [1],
    'min': [1, 2, 3, 4, 5],
    'max': [1, 2, 3, 4, 5],
    'pow': [2],
    'atan2': [2],
    'mod': [2],
    'gcd': [2],
    'lcm': [2],
    'ncr': [2],
    'npr': [2],
    'gamma': [1],
    'fact': [1],
  };

  static bool isFunction(String name) => arities.containsKey(name);

  static bool isValidArity(String name, int count) {
    final allowed = arities[name];
    if (allowed == null) return false;
    return allowed.contains(count) ||
        (allowed.isNotEmpty && allowed.last >= 5 && count >= allowed.first);
  }

  static double call(String name, List<double> args, AngleMode mode) {
    if (!isValidArity(name, args.length)) {
      throw MathException('"$name" received ${args.length} argument(s)');
    }
    final a = args[0];
    switch (name) {
      case 'sin':
        return _sin(_toRadians(a, mode));
      case 'cos':
        return _cos(_toRadians(a, mode));
      case 'tan':
        return _tan(_toRadians(a, mode));
      case 'sec':
        return 1 / _cos(_toRadians(a, mode));
      case 'csc':
        return 1 / _sin(_toRadians(a, mode));
      case 'cot':
        return 1 / _tan(_toRadians(a, mode));
      case 'asin':
        return _fromRadians(math.asin(_clampUnit(a)), mode);
      case 'acos':
        return _fromRadians(math.acos(_clampUnit(a)), mode);
      case 'atan':
        return _fromRadians(math.atan(a), mode);
      case 'asec':
        return _fromRadians(math.acos(_clampUnit(1 / a)), mode);
      case 'acsc':
        return _fromRadians(math.asin(_clampUnit(1 / a)), mode);
      case 'acot':
        final value = math.atan(1 / a);
        return _fromRadians(a < 0 ? value + math.pi : value, mode);
      case 'sinh':
        return (math.exp(a) - math.exp(-a)) / 2;
      case 'cosh':
        return (math.exp(a) + math.exp(-a)) / 2;
      case 'tanh':
        final ea = math.exp(a);
        final eb = math.exp(-a);
        return (ea - eb) / (ea + eb);
      case 'asinh':
        return math.log(a + math.sqrt(a * a + 1));
      case 'acosh':
        return math.log(a + math.sqrt(a * a - 1));
      case 'atanh':
        return 0.5 * math.log((1 + a) / (1 - a));
      case 'ln':
        return math.log(a);
      case 'log':
        if (args.length == 1) return math.log(a) / math.ln10;
        return math.log(a) / math.log(args[1]);
      case 'log10':
        return math.log(a) / math.ln10;
      case 'log2':
        return math.log(a) / math.ln2;
      case 'sqrt':
        return math.sqrt(a);
      case 'cbrt':
        return a < 0
            ? -math.pow(-a, 1 / 3).toDouble()
            : math.pow(a, 1 / 3).toDouble();
      case 'abs':
        return a.abs();
      case 'exp':
        return math.exp(a);
      case 'floor':
        return a.floorToDouble();
      case 'ceil':
        return a.ceilToDouble();
      case 'round':
        return a.roundToDouble();
      case 'sign':
        return a.sign;
      case 'min':
        return args.reduce(math.min);
      case 'max':
        return args.reduce(math.max);
      case 'pow':
        return math.pow(a, args[1]).toDouble();
      case 'atan2':
        return _fromRadians(math.atan2(a, args[1]), mode);
      case 'mod':
        return a - args[1] * (a / args[1]).floorToDouble();
      case 'gcd':
        return _gcd(a.round(), args[1].round()).toDouble();
      case 'lcm':
        final x = a.round();
        final y = args[1].round();
        if (x == 0 || y == 0) return 0;
        return (x ~/ _gcd(x, y) * y).absToDouble();
      case 'ncr':
        return _factorial(a.round()) /
            (_factorial(args[1].round()) *
                _factorial(a.round() - args[1].round()));
      case 'npr':
        return _factorial(a.round()) / _factorial(a.round() - args[1].round());
      case 'gamma':
        return _gamma(a);
      case 'fact':
        return _factorial(a.round());
    }
    throw MathException('Unknown function "$name"');
  }

  static double _toRadians(double value, AngleMode mode) =>
      mode == AngleMode.degrees ? value * math.pi / 180 : value;

  static double _fromRadians(double value, AngleMode mode) =>
      mode == AngleMode.degrees ? value * 180 / math.pi : value;

  static double _clampUnit(double value) {
    if (value.isNaN) return value;
    return value.clamp(-1.0, 1.0).toDouble();
  }

  static double _sin(double value) => math.sin(value);
  static double _cos(double value) => math.cos(value);
  static double _tan(double value) => math.tan(value);

  static int _gcd(int a, int b) {
    var x = a.abs();
    var y = b.abs();
    while (y != 0) {
      final temp = y;
      y = x % y;
      x = temp;
    }
    return x;
  }

  static double _factorial(int n) {
    if (n < 0) {
      throw const MathException('Factorial needs a non-negative integer');
    }
    if (n > 170) return double.infinity;
    var result = 1.0;
    for (var i = 2; i <= n; i++) {
      result *= i;
    }
    return result;
  }

  // Lanczos approximation, used for non-integer factorial input.
  static double _gamma(double z) {
    if (z < 0.5) {
      return math.pi / (math.sin(math.pi * z) * _gamma(1 - z));
    }
    const coefficients = <double>[
      0.99999999999980993,
      676.5203681218851,
      -1259.1392167224028,
      771.32342877765313,
      -176.61502916214059,
      12.507343278686905,
      -0.13857109526572012,
      9.9843695780195716e-6,
      1.5056327351493116e-7,
    ];
    final zz = z - 1;
    var x = coefficients[0];
    for (var i = 1; i < coefficients.length; i++) {
      x += coefficients[i] / (zz + i);
    }
    final t = zz + coefficients.length - 1.5;
    return math.sqrt(2 * math.pi) * math.pow(t, zz + 0.5) * math.exp(-t) * x;
  }
}

extension on int {
  double absToDouble() => abs().toDouble();
}

// ---------------------------------------------------------------------------
// Parser
// ---------------------------------------------------------------------------

class _Parser {
  _Parser(this._tokens);

  final List<_Token> _tokens;
  int _position = 0;

  _Token get _current => _tokens[_position];

  Expr parse() {
    if (_current.type == _TokenType.eof) {
      throw const MathException('Enter an expression');
    }
    final expression = _parseSum();
    if (_current.type != _TokenType.eof) {
      throw MathException('Unexpected "${_current.lexeme}"', _current.start);
    }
    return expression;
  }

  Expr _parseSum() {
    var left = _parseProduct();
    while (_current.type == _TokenType.plus ||
        _current.type == _TokenType.minus) {
      final operator = _current.type == _TokenType.plus ? '+' : '-';
      _position++;
      final right = _parseProduct();
      left = BinaryExpr(operator, left, right);
    }
    return left;
  }

  Expr _parseProduct() {
    var left = _parseUnary();
    while (true) {
      final type = _current.type;
      if (type == _TokenType.star ||
          type == _TokenType.slash ||
          type == _TokenType.percent) {
        final operator = switch (type) {
          _TokenType.star => '*',
          _TokenType.slash => '/',
          _ => '%',
        };
        _position++;
        left = BinaryExpr(operator, left, _parseUnary());
      } else if (_startsFactor(type)) {
        // Implicit multiplication: 2x, 3(x+1), (x+1)(x-1), 2sin(x).
        left = BinaryExpr('*', left, _parseUnary());
      } else {
        break;
      }
    }
    return left;
  }

  Expr _parseUnary() {
    if (_current.type == _TokenType.plus) {
      _position++;
      return _parseUnary();
    }
    if (_current.type == _TokenType.minus) {
      _position++;
      return UnaryExpr('-', _parseUnary());
    }
    return _parsePower();
  }

  Expr _parsePower() {
    final base = _parsePostfix();
    if (_current.type == _TokenType.caret) {
      _position++;
      final exponent = _parseUnary();
      return BinaryExpr('^', base, exponent);
    }
    return base;
  }

  Expr _parsePostfix() {
    var expression = _parsePrimary();
    while (_current.type == _TokenType.bang) {
      _position++;
      expression = CallExpr('fact', [expression]);
    }
    return expression;
  }

  Expr _parsePrimary() {
    final token = _current;
    switch (token.type) {
      case _TokenType.number:
        _position++;
        return NumberExpr(token.value!);
      case _TokenType.identifier:
        _position++;
        final name = token.lexeme.toLowerCase();
        if (_current.type == _TokenType.lparen && _Functions.isFunction(name)) {
          return _parseCall(name);
        }
        return VariableExpr(name);
      case _TokenType.lparen:
        _position++;
        final expression = _parseSum();
        if (_current.type != _TokenType.rparen) {
          throw MathException('Missing ")"', _current.start);
        }
        _position++;
        return expression;
      case _TokenType.eof:
        throw MathException('Unexpected end of expression', token.start);
      default:
        throw MathException('Unexpected "${token.lexeme}"', token.start);
    }
  }

  CallExpr _parseCall(String name) {
    _position++; // consume "("
    final arguments = <Expr>[];
    if (_current.type != _TokenType.rparen) {
      arguments.add(_parseSum());
      while (_current.type == _TokenType.comma) {
        _position++;
        arguments.add(_parseSum());
      }
    }
    if (_current.type != _TokenType.rparen) {
      throw MathException('Missing ")"', _current.start);
    }
    _position++;
    if (!_Functions.isValidArity(name, arguments.length)) {
      throw MathException(
        '"$name" received ${arguments.length} argument(s)',
        _current.start,
      );
    }
    return CallExpr(name, arguments);
  }

  static bool _startsFactor(_TokenType type) {
    return type == _TokenType.number ||
        type == _TokenType.identifier ||
        type == _TokenType.lparen;
  }
}

// ---------------------------------------------------------------------------
// Public engine
// ---------------------------------------------------------------------------

/// Parses and evaluates plain-text math expressions.
class MathEngine {
  const MathEngine._();

  static final Map<String, Expr> _cache = <String, Expr>{};

  /// Parses [source] into an [Expr], caching the result.
  static Expr parse(String source) {
    final key = source.trim();
    final cached = _cache[key];
    if (cached != null) return cached;
    final tokens = _Lexer(source).tokenize();
    final expression = _Parser(tokens).parse();
    if (_cache.length > 512) _cache.clear();
    _cache[key] = expression;
    return expression;
  }

  /// Evaluates [source]. Throws [MathException] on failure.
  static double evaluate(
    String source, {
    Map<String, double> variables = const {},
    AngleMode angleMode = AngleMode.radians,
  }) {
    final expression = parse(source);
    return expression.eval(
      EvalContext(variables: variables, angleMode: angleMode),
    );
  }

  /// Returns the error message for [source], or null if it parses.
  static String? validate(String source) {
    try {
      parse(source);
      return null;
    } on MathException catch (error) {
      return error.message;
    }
  }
}
