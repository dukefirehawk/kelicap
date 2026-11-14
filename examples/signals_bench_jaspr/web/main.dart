import 'package:web/web.dart';

import 'package:signals_bench_jaspr/bench.dart';

void main() {
  final binding = BenchBinding();
  binding.attachRootComponent(BenchApp(binding), attachTo: 'bench-app');
  // Runs the benchmark while the page loads, so that it is done when the page
  // has loaded, such as for `chrome --headless --dump-dom`.
  if (window.location.search.contains('autorun')) {
    BenchApp.instance!.run();
  }
}
