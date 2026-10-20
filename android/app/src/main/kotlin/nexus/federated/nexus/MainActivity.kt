package nexus.federated.nexus

import android.os.Build
import android.os.Bundle
import android.view.View
import android.view.WindowInsets
import android.view.WindowInsetsAnimation
import io.flutter.embedding.android.FlutterActivity

// TODO: Revert this commit once https://github.com/flutter/flutter/issues/191156 is fixed
class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) return

        window.decorView.setWindowInsetsAnimationCallback(
            object : WindowInsetsAnimation.Callback(DISPATCH_MODE_CONTINUE_ON_SUBTREE) {
                override fun onProgress(
                    insets: WindowInsets,
                    runningAnimations: List<WindowInsetsAnimation>,
                ) = insets

                override fun onEnd(animation: WindowInsetsAnimation) {
                    if ((animation.typeMask and WindowInsets.Type.ime()) != 0) reapplyInsets()
                }
            },
        )
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus && Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) reapplyInsets()
    }

    // Posted so it runs after Flutter has applied any insets it deferred.
    private fun reapplyInsets() {
        val view = findViewById<View>(FLUTTER_VIEW_ID) ?: return
        view.post { view.rootWindowInsets?.let(view::onApplyWindowInsets) }
    }
}
