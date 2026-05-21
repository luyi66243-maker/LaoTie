package com.laoyi.laotie.data.local

import androidx.room.Database
import androidx.room.RoomDatabase

@Database(
    entities = [CheckInEntity::class],
    version = 1,
    exportSchema = false
)
abstract class LaoTieDatabase : RoomDatabase() {
    abstract fun checkInDao(): CheckInDao
}
