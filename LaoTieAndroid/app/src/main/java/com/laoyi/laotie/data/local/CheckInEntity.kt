package com.laoyi.laotie.data.local

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "check_in_records")
data class CheckInEntity(
    @PrimaryKey val id: String,
    val scenicId: String,
    val scenicName: String,
    val province: String,
    val submittedAt: Long,
    val latitude: Double?,
    val longitude: Double?,
    val photoFileName: String?,
    val distanceMeters: Double?,
    val rewardXp: Int
)
