package __PACKAGE__

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "emu_compagnon/widgets")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "refresh" -> {
                        refreshWidgets()
                        result.success(null)
                    }
                    // How many widget types this build contains.
                    "count" -> result.success(EmuWidgetRegistry.providers.size)
                    // Asks the launcher to place a widget on the home screen.
                    "pin" -> result.success(pinWidget(call.argument<String>("key")))
                    else -> result.notImplemented()
                }
            }
    }

    private fun pinWidget(key: String?): Boolean {
        val provider = key?.let { EmuWidgetRegistry.byKey[it] } ?: return false
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return false
        val manager = AppWidgetManager.getInstance(this)
        if (!manager.isRequestPinAppWidgetSupported) return false
        return manager.requestPinAppWidget(ComponentName(this, provider), null, null)
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
