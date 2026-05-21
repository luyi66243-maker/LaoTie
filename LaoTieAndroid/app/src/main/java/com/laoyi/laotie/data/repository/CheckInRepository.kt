package com.laoyi.laotie.data.repository

import com.laoyi.laotie.data.local.CheckInDao
import com.laoyi.laotie.data.local.CheckInEntity
import com.laoyi.laotie.domain.checkin.ScenicCheckIn
import java.util.UUID
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

@Singleton
class CheckInRepository @Inject constructor(
    private val checkInDao: CheckInDao
) {
    fun observeAll(): Flow<List<ScenicCheckIn>> {
        return checkInDao.observeAll().map { list ->
            list.map {
                ScenicCheckIn(
                    id = it.id,
                    scenicId = it.scenicId,
                    scenicName = it.scenicName,
                    province = it.province,
                    submittedAt = it.submittedAt,
                    distanceMeters = it.distanceMeters,
                    rewardXp = it.rewardXp
                )
            }
        }
    }

    fun observeCount(): Flow<Int> = checkInDao.observeCount()

    suspend fun addCheckIn(
        scenicId: String,
        scenicName: String,
        province: String,
        latitude: Double?,
        longitude: Double?,
        distanceMeters: Double?,
        rewardXp: Int = 30
    ) {
        val entity = CheckInEntity(
            id = UUID.randomUUID().toString(),
            scenicId = scenicId,
            scenicName = scenicName,
            province = province,
            submittedAt = System.currentTimeMillis(),
            latitude = latitude,
            longitude = longitude,
            photoFileName = null,
            distanceMeters = distanceMeters,
            rewardXp = rewardXp
        )
        checkInDao.upsert(entity)
    }
}
