package com.laoyi.laotie.core.map

import android.content.Context
import android.content.Intent
import android.net.Uri
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class AmapNavigator @Inject constructor(
    @ApplicationContext private val context: Context
) {
    fun openRoute(toLat: Double, toLng: Double, poiName: String) {
        val uri = Uri.parse(
            "androidamap://route?sourceApplication=laotie" +
                "&dlat=$toLat&dlon=$toLng&dname=$poiName&dev=0&t=0"
        )
        val intent = Intent(Intent.ACTION_VIEW, uri).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        if (intent.resolveActivity(context.packageManager) != null) {
            context.startActivity(intent)
        }
    }
}
