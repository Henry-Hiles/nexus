import "dart:async";

import "package:flutter_hooks/flutter_hooks.dart";

final class Saving({
  required final bool active,
  required final Future<void> Function(FutureOr<void> Function() action) run,
}) {
  factory use() {
    final context = useContext();
    final active = useState(false);

    return .new(
      active: active.value,
      run: (action) async {
        active.value = true;
        try {
          await action();
        } finally {
          if (context.mounted) active.value = false;
        }
      },
    );
  }
}
