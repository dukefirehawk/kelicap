import {bootstrapApplication} from '@angular/platform-browser';

import {BenchAppComponent} from './app/bench';

// Angular 22 runs without zone.js by default. The benchmark runs change
// detection itself, with ApplicationRef.tick().
const app = await bootstrapApplication(BenchAppComponent);

// Runs the benchmark while the page loads, so that it is done when the page
// has loaded, such as for `chrome --headless --dump-dom`.
if (location.search.includes('autorun')) {
  app.components[0].instance.run();
}
