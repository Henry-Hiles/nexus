import "package:nexus/models/event.dart";

extension SendFailed on Event {
  /// gomuks marks events that are still sending as "not sent" (and often forgets to clear it at all)
  bool get sendFailed => sendError != null && sendError != "not sent";
}
