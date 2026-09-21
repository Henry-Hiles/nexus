import "dart:io";

import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:xdg_desktop_portal/xdg_desktop_portal.dart";

class PortalController extends AsyncNotifier<XdgDesktopPortalClient> {
  @override
  Future<XdgDesktopPortalClient> build() async {
    final portal = XdgDesktopPortalClient();
    if (!await File("/.flatpak-info").exists()) {
      await portal.registerApplication("nexus.federated.nexus");
    }

    ref.onDispose(portal.close);
    return portal;
  }

  static final provider =
      AsyncNotifierProvider<PortalController, XdgDesktopPortalClient>(
        PortalController.new,
      );
}
