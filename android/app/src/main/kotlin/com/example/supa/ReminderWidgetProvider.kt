package com.example.supa

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class ReminderWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.reminder_widget).apply {
                val carModel = widgetData.getString("car_model", "Toyota Corolla")
                val serviceInfo = widgetData.getString("service_info", "Next Service: 45,000 km")
                val status = widgetData.getString("status", "Healthy")

                setTextViewText(R.id.widget_car_model, carModel)
                setTextViewText(R.id.widget_service_info, serviceInfo)
                setTextViewText(R.id.widget_status, status)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
