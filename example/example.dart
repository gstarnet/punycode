// Copyright (c) 2016, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:punycode/punycode.dart' as punycode;

main() {
 var original =  '\u5B89\u5BA4\u5948\u7F8E\u6075-with-SUPER-MONKEYS';

 print('Original string: $original');

 var encoded = punycode.encode(original);
 print('Encoded string: $encoded');

 var decoded = punycode.decode(encoded);
 print('Decoded string: $decoded');


}
