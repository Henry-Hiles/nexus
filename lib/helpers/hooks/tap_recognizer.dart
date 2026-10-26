import "package:flutter/gestures.dart";
import "package:flutter_hooks/flutter_hooks.dart";

/// A recognizer for a tappable span in text, like a name, disposed with the
/// widget.
TapGestureRecognizer useTapRecognizer() {
  final recognizer = useMemoized(TapGestureRecognizer.new);
  useEffect(() => recognizer.dispose, [recognizer]);

  return recognizer;
}
