/// Change detection enables data binding in Kelicap.
library;

export 'change_detection/change_detection.dart'
    show
        ChangeDetectorRef,
        DeprecatedChangeDetectorRef,
        DeprecatedDetectChanges;
export 'change_detection/differs/default_iterable_differ.dart' show TrackByFn;
