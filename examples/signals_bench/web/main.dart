import 'package:kelicap/kelicap.dart';
import 'package:web/web.dart';

import 'package:signals_bench/bench.dart';
import 'package:signals_bench/bench.template.dart' as ng;

void main() {
  final app = runApp<BenchAppComponent>(ng.BenchAppComponentNgFactory);
  // Runs the benchmark while the page loads, so that it is done when the page
  // has loaded, such as for `chrome --headless --dump-dom`.
  if (window.location.search.contains('autorun')) {
    app.instance.run();
  }
}
