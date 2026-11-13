package __PACKAGE__

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * "Verset du jour" widget of the home screen.
 *
 * The app writes the verses of the coming days into its preferences
 * (WidgetSyncService); this reads today's one, so the widget changes every
 * day without the app being opened.
 */
class VerseWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        val (text, reference) = todaysVerse(context)
        val launch = context.packageManager.getLaunchIntentForPackage(context.packageName)
        val tap = launch?.let {
            PendingIntent.getActivity(context, 0, it, PendingIntent.FLAG_IMMUTABLE)
        }
        for (id in ids) {
            val views = RemoteViews(context.packageName, R.layout.verse_widget)
            views.setTextViewText(R.id.verse_text, text)
            views.setTextViewText(R.id.verse_reference, reference)
            if (tap != null) views.setOnClickPendingIntent(R.id.verse_root, tap)
            manager.updateAppWidget(id, views)
        }
    }

    private fun todaysVerse(context: Context): Pair<String, String> {
        val placeholder = Pair("Ouvrez ÉMU Compagnon pour afficher le verset du jour.", "")
        try {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val raw = prefs.getString("flutter.widget.verses", null) ?: return placeholder
            val verses = JSONObject(raw)
            val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
            // Today's verse; failing that the latest one known (better than an empty widget).
            val key = if (verses.has(today)) today else verses.keys().asSequence().maxOrNull() ?: return placeholder
            val verse = verses.getJSONObject(key)
            return Pair(verse.getString("t"), verse.getString("r"))
        } catch (e: Exception) {
            return placeholder
        }
    }
}
