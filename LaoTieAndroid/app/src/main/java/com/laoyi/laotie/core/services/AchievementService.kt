package com.laoyi.laotie.core.services

import com.laoyi.laotie.domain.checkin.Achievement
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class AchievementService @Inject constructor() {
    private val definitions = listOf(
        Definition("ach_first", "初次打卡", "完成第一次风景打卡", 1, 50),
        Definition("ach_3", "小小探险家", "累计打卡 3 个风景", 3, 100),
        Definition("ach_10", "风景猎人", "累计打卡 10 个风景", 10, 300),
        Definition("ach_30", "三省通行证", "累计打卡 30 个风景", 30, 800),
        Definition("ach_100", "东北全景大师", "打卡全部 100 个风景", 100, 5000)
    )

    fun evaluate(checkInCount: Int): List<Achievement> {
        return definitions.map { item ->
            Achievement(
                id = item.id,
                title = item.title,
                description = item.description,
                requirement = item.requirement,
                rewardXp = item.rewardXp,
                unlocked = checkInCount >= item.requirement
            )
        }
    }

    private data class Definition(
        val id: String,
        val title: String,
        val description: String,
        val requirement: Int,
        val rewardXp: Int
    )
}
