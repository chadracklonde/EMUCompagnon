package __PACKAGE__

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "emu_compagnon/widgets")
            .setMethodCallHandler { call, result ->
                if (call.method == "refresh") {
                    refreshWidgets()
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }

    /** Asks every placed widget to redraw with the data the app has just written. */
    private fun refreshWidgets() {
        val manager = AppWidgetManager.getInstance(this)
        for (provider in EmuWidgetRegistry.providers) {
            val ids = manager.getAppWidgetIds(ComponentName(this, provider))
            if (ids.isEmpty()) continue
            val intent = Intent(this, provider)
                .setAction(AppWidgetManager.ACTION_APPWIDGET_UPDATE)
                .putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
            sendBroadcast(intent)
        }
    }
}
