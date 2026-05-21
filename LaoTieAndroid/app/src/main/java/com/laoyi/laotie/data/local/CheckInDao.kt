package com.laoyi.laotie.data.local

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import kotlinx.coroutines.flow.Flow

@Dao
interface CheckInDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(record: CheckInEntity)

    @Query("SELECT * FROM check_in_records ORDER BY submittedAt DESC")
    fun observeAll(): Flow<List<CheckInEntity>>

    @Query("SELECT COUNT(*) FROM check_in_records")
    fun observeCount(): Flow<Int>
}
