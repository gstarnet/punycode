class PunycodeException {
  String message;
  static const BAD_INPUT = 'BAD INPUT';
  static const OVERFLOW = 'OVERFLOW';
  PunycodeException(this.message);

  @override
  String toString() {
    return 'PunicodeException{message: $message}';
  }
}

final me = new _Punycode();

String decode(String value) => me.decode(value);
String encode(String value) => me.encode(value);

class _Punycode {
  /* Punycode parameters */
  static const int TMIN = 1;
  static const int TMAX = 26;
  static const int BASE = 36;
  static const int INITIAL_N = 128;
  static const int INITIAL_BIAS = 72;
  static const int DAMP = 700;
  static const int SKEW = 38;
  static const DELIMITER = '-';
  static const maxInt = 2147483647;

  /**
   * Punycodes a unicode string.
   *
   * @param input Unicode string.
   * @return Punycoded string.
   */
  String encode(String input) {
    int n = INITIAL_N;
    int delta = 0;
    int bias = INITIAL_BIAS;
    List<int> output = [];

    // Copy all basic code points to the output
    int b = 0;
    for (int i = 0; i < input.length; i++) {
      int c = input.codeUnitAt(i);
      if (isBasic(c)) {
        output.add(c);
        b++;
      }
    }

    // Append delimiter
    if (b > 0) {
      output.add(DELIMITER.codeUnitAt(0));
    }

    int h = b;
    while (h < input.length) {
      int m = maxInt;

      // Find the minimum code point >= n
      for (int i = 0; i < input.length; i++) {
        int c = input.codeUnitAt(i);
        if (c >= n && c < m) {
          m = c;
        }
      }

      if (m - n > (maxInt - delta) / (h + 1)) {
        throw new PunycodeException(PunycodeException.OVERFLOW);
      }
      delta = delta + (m - n) * (h + 1);
      n = m;

      for (int j = 0; j < input.length; j++) {
        int c = input.codeUnitAt(j);
        if (c < n) {
          delta++;
          if (0 == delta) {
            throw new PunycodeException(PunycodeException.OVERFLOW);
          }
        }
        if (c == n) {
          int q = delta;

          for (int k = BASE;; k += BASE) {
            int t;
            if (k <= bias) {
              t = TMIN;
            } else if (k >= bias + TMAX) {
              t = TMAX;
            } else {
              t = k - bias;
            }
            if (q < t) {
              break;
            }
            output.add((digit2codepoint(t + (q - t) % (BASE - t))));
            q = ((q - t) / (BASE - t)).floor();
          }

          output.add(digit2codepoint(q));
          bias = adapt(delta, h + 1, h == b);
          delta = 0;
          h++;
        }
      }

      delta++;
      n++;
    }

    return new String.fromCharCodes(output);
  }

  /**
   * Decode a punycoded string.
   *
   * @param input Punycode string
   * @return Unicode string.
   */
  String decode(String input) {
    int n = INITIAL_N;
    int i = 0;
    int bias = INITIAL_BIAS;
    List<int> output = [];

    int d = input.lastIndexOf(DELIMITER);
    if (d > 0) {
      for (int j = 0; j < d; j++) {
        int c = input.codeUnitAt(j);
        if (!isBasic(c)) {
          throw new PunycodeException(PunycodeException.BAD_INPUT);
        }
        output.add(c);
      }
      d++;
    } else {
      d = 0;
    }

    while (d < input.length) {
      int oldi = i;
      int w = 1;

      for (int k = BASE;; k += BASE) {
        if (d == input.length) {
          throw new PunycodeException(PunycodeException.BAD_INPUT);
        }
        int c = input.codeUnitAt(d++);
        int digit = codepoint2digit(c);
        if (digit > (maxInt - i) / w) {
          throw new PunycodeException(PunycodeException.OVERFLOW);
        }

        i = i + digit * w;

        int t;
        if (k <= bias) {
          t = TMIN;
        } else if (k >= bias + TMAX) {
          t = TMAX;
        } else {
          t = k - bias;
        }
        if (digit < t) {
          break;
        }
        w = w * (BASE - t);
      }

      bias = adapt(i - oldi, output.length + 1, oldi == 0);

      if (i / (output.length + 1) > maxInt - n) {
        throw new PunycodeException(PunycodeException.OVERFLOW);
      }

      n = (n + i / (output.length + 1)).floor();
      i = i % (output.length + 1);
      output.insert(i, n);
      i++;
    }

    return new String.fromCharCodes(output);
  }

  int adapt(int delta, int numpoints, bool first) {
    if (first) {
      delta = (delta / DAMP).floor();
    } else {
      delta = (delta / 2).floor();
    }

    delta = delta + (delta / numpoints).floor();

    int k = 0;
    while (delta > ((BASE - TMIN) * TMAX) / 2) {
      delta = (delta / (BASE - TMIN)).floor();
      k = k + BASE;
    }

    return (k + ((BASE - TMIN + 1) * delta) / (delta + SKEW)).floor();
  }

  bool isBasic(int c) {
    return c < 0x80;
  }

  int digit2codepoint(int d) {
    if (d < 26) {
      // 0..25 : 'a'..'z'
      return d + 'a'.codeUnitAt(0);
    } else if (d < 36) {
      // 26..35 : '0'..'9';
      return d - 26 + '0'.codeUnitAt(0);
    } else {
      throw new PunycodeException(PunycodeException.BAD_INPUT);
    }
  }

  int codepoint2digit(int c) {
    if (c - '0'.codeUnitAt(0) < 10) {
      // '0'..'9' : 26..35
      return c - '0'.codeUnitAt(0) + 26;
    } else if (c - 'a'.codeUnitAt(0) < 26) {
      // 'a'..'z' : 0..25
      return c - 'a'.codeUnitAt(0);
    } else {
      throw new PunycodeException(PunycodeException.BAD_INPUT);
    }
  }
}
