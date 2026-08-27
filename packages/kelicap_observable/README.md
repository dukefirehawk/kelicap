# Kelicap Observable

![Pub Version (including pre-releases)](https://img.shields.io/pub/v/kelicap_observable?include_prereleases)
[![Null Safety](https://img.shields.io/badge/null-safety-brightgreen)](https://dart.dev/null-safety)
[![License](https://img.shields.io/github/license/dukefirehawk/kelicap)](https://github.com/dukefirehawk/kelicap/blob/master/LICENSE)

Support for detecting and being notified when an object is mutated.

An observable is a way to be notified of a continuous stream of events over time.

Some suggested uses for this library:

* Observe objects for changes, and log when a change occurs
* Optimize for observable collections in your own APIs and libraries instead of diffing
* Implement simple data-binding by listening to streams

## Usage

There are two general ways to detect changes:

* Listen to `Observable.changes` and be notified when an object changes
* Use `Differ.diff` to determine changes between two objects
