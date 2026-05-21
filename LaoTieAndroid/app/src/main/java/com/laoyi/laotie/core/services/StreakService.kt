package com.laoyi.laotie.core.services

import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class StreakService @Inject constructor() {
    fun calculateStreak(checkInTimestamps: List<Long>): Int {
        if (checkInTimestamps.isEmpty()) return 0
        val days = checkInTimestamps
            .map { Instant.ofEpochMilli(it).atZone(ZoneId.systemDefault()).toLocalDate() }
            .distinct()
            .sortedDescending()

        var streak = 0
        var cursor = LocalDate.now()
        for (day in days) {
            if (day == cursor) {
                streak++
                cursor = cursor.minusDays(1)
            } else if (day.isBefore(cursor)) {
                break
            }
        }
        return streak
    }
}
