package com.laoyi.laotie.domain.checkin

data class ScenicCheckIn(
    val id: String,
    val scenicId: String,
    val scenicName: String,
    val province: String,
    val submittedAt: Long,
    val distanceMeters: Double?,
    val rewardXp: Int
)

data class Achievement(
    val id: String,
    val title: String,
    val description: String,
    val requirement: Int,
    val rewardXp: Int,
    val unlocked: Boolean
)
