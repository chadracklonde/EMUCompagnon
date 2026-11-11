package __PACKAGE__

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.util.TypedValue
import android.view.View
import android.widget.RemoteViews
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Shared base of the home-screen widgets. Each widget is a tiny subclass
 * (generated from native/android/widgets.json) choosing a layout "kind":
 * card, week, list or shortcuts. The app writes what each one shows into
 * its preferences (WidgetSyncService); a tap opens the app on a route.
 */
abstract class EmuWidgetProvider(
    private val key: String,
    private val kind: String,
    private val dark: Boolean,
    private val defaults: String,
) : AppWidgetProvider() {

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        val data = EmuWidgetData.load(context, key, defaults)
        for (id in ids) {
            val views = when (kind) {
                "week" -> EmuWidgetRenderer.week(context, key, data)
                "list" -> EmuWidgetRenderer.list(context, key, data)
                "shortcuts" -> EmuWidgetRenderer.shortcuts(context, key)
                else -> EmuWidgetRenderer.card(context, key, dark, data)
            }
            manager.updateAppWidget(id, views)
        }
    }
}

object EmuWidgetData {
    /** Defaults of the widget, overlaid with what the app wrote for it (today's entry for daily ones). */
    fun load(context: Context, key: String, defaults: String): JSONObject {
        val result = JSONObject(defaults)
        try {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val raw = prefs.getString("flutter.widget.data", null) ?: return result
            val node = JSONObject(raw).optJSONObject(key) ?: return result
            val days = node.optJSONObject("days")
            val source = if (days != null) pickDay(days) else node
            if (source != null) {
                val names = source.keys()
                while (names.hasNext()) {
                    val name = names.next()
                    result.put(name, source.get(name))
                }
            }
        } catch (e: Exception) {
            // Keep the defaults.
        }
        return result
    }

    /** Today's entry; failing that the latest past one, then the earliest. */
    private fun pickDay(days: JSONObject): JSONObject? {
        val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
        if (days.has(today)) return days.optJSONObject(today)
        var past: String? = null
        var first: String? = null
        val names = days.keys()
        while (names.hasNext()) {
            val name = names.next()
            if (first == null || name < first) first = name
            if (name < today && (past == null || name > past)) past = name
        }
        val chosen = past ?: first ?: return null
        return days.optJSONObject(chosen)
    }
}

object EmuWidgetRenderer {
    private const val ACTION_KEY = "some unique action key" // read by the quick_actions plugin

    private const val WHITE = 0xFFFFFFFF.toInt()
    private const val DARK_TEXT = 0xFF1C1B1A.toInt()
    private const val ROSE = 0xFFF3C9CC.toInt()
    private const val BURGUNDY = 0xFF7A2426.toInt()
    private const val GREY = 0xFF6B6560.toInt()

    private fun setText(views: RemoteViews, id: Int, text: String, color: Int) {
        if (text.isEmpty()) {
            views.setViewVisibility(id, View.GONE)
        } else {
            views.setViewVisibility(id, View.VISIBLE)
            views.setTextViewText(id, text)
            views.setTextColor(id, color)
        }
    }

    /** A tap opens the app, on [route] when there is one. */
    private fun link(context: Context, views: RemoteViews, viewId: Int, key: String, route: String) {
        val launch = context.packageManager.getLaunchIntentForPackage(context.packageName) ?: return
        if (route.isNotEmpty() && route != "home") launch.putExtra(ACTION_KEY, route)
        val pending = PendingIntent.getActivity(
            context,
            (key + route).hashCode(),
            launch,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        views.setOnClickPendingIntent(viewId, pending)
    }

    fun card(context: Context, key: String, dark: Boolean, data: JSONObject): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.tpl_card)
        views.setInt(
            R.id.w_root,
            "setBackgroundResource",
            if (dark) R.drawable.widget_bg_burgundy else R.drawable.widget_bg_light,
        )
        val main = if (dark) WHITE else DARK_TEXT
        val muted = if (dark) ROSE else GREY
        val accent = if (dark) ROSE else BURGUNDY
        setText(views, R.id.w_label, data.optString("l"), accent)
        setText(views, R.id.w_title, data.optString("t"), main)
        setText(views, R.id.w_body, data.optString("b"), main)
        setText(views, R.id.w_footer, data.optString("f"), muted)
        if (data.has("ts")) {
            views.setTextViewTextSize(R.id.w_title, TypedValue.COMPLEX_UNIT_SP, data.optDouble("ts", 18.0).toFloat())
        }
        val progress = data.optInt("p", -1)
        if (progress >= 0) {
            views.setViewVisibility(R.id.w_progress, View.VISIBLE)
            views.setProgressBar(R.id.w_progress, 100, progress.coerceIn(0, 100), false)
        } else {
            views.setViewVisibility(R.id.w_progress, View.GONE)
        }
        if (data.has("c")) {
            views.setViewVisibility(R.id.w_stripe, View.VISIBLE)
            views.setInt(R.id.w_stripe, "setBackgroundColor", data.optLong("c").toInt())
        } else {
            views.setViewVisibility(R.id.w_stripe, View.GONE)
        }
        link(context, views, R.id.w_root, key, data.optString("r"))
        return views
    }

    fun week(context: Context, key: String, data: JSONObject): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.tpl_week)
        setText(views, R.id.w_label, data.optString("l"), BURGUNDY)
        setText(views, R.id.w_title, data.optString("t"), DARK_TEXT)
        setText(views, R.id.w_footer, data.optString("f"), GREY)
        val dots = data.optJSONArray("d")
        val ids = intArrayOf(
            R.id.w_d0, R.id.w_d1, R.id.w_d2, R.id.w_d3, R.id.w_d4, R.id.w_d5, R.id.w_d6,
        )
        for (i in ids.indices) {
            val on = dots != null && dots.optInt(i, 0) == 1
            views.setInt(
                ids[i],
                "setBackgroundResource",
                if (on) R.drawable.widget_dot_on else R.drawable.widget_dot_off,
            )
            views.setTextColor(ids[i], if (on) WHITE else GREY)
        }
        link(context, views, R.id.w_root, key, data.optString("r"))
        return views
    }

    fun list(context: Context, key: String, data: JSONObject): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.tpl_list)
        setText(views, R.id.w_label, data.optString("l"), BURGUNDY)
        setText(views, R.id.w_footer, data.optString("f"), GREY)
        val items = data.optJSONArray("items")
        val ids = intArrayOf(R.id.w_r0, R.id.w_r1, R.id.w_r2, R.id.w_r3, R.id.w_r4)
        for (i in ids.indices) {
            val text = if (items != null && i < items.length()) items.optString(i) else ""
            setText(views, ids[i], text, DARK_TEXT)
        }
        link(context, views, R.id.w_root, key, data.optString("r"))
        return views
    }

    private val SHORTCUTS = listOf(
        Pair("Rechercher", "search"),
        Pair("Bible", "bible"),
        Pair("Cantiques", "hymns"),
        Pair("Culte", "worship"),
    )

    fun shortcuts(context: Context, key: String): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.tpl_shortcuts)
        val ids = intArrayOf(R.id.w_s0, R.id.w_s1, R.id.w_s2, R.id.w_s3)
        for (i in ids.indices) {
            views.setTextViewText(ids[i], SHORTCUTS[i].first)
            link(context, views, ids[i], key, SHORTCUTS[i].second)
        }
        return views
    }
}
