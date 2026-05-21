package com.laoyi.laotie.core.di

import android.content.Context
import androidx.room.Room
import com.laoyi.laotie.data.local.CheckInDao
import com.laoyi.laotie.data.local.LaoTieDatabase
import com.laoyi.laotie.data.repository.LearningRepository
import com.laoyi.laotie.data.repository.LearningRepositoryImpl
import dagger.Binds
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton
import okhttp3.OkHttpClient

@Module
@InstallIn(SingletonComponent::class)
object AppProvidesModule {
    @Provides
    @Singleton
    fun provideOkHttpClient(): OkHttpClient = OkHttpClient.Builder().build()

    @Provides
    @Singleton
    fun provideDatabase(@ApplicationContext context: Context): LaoTieDatabase {
        return Room.databaseBuilder(
            context,
            LaoTieDatabase::class.java,
            "laotie.db"
        ).build()
    }

    @Provides
    fun provideCheckInDao(database: LaoTieDatabase): CheckInDao = database.checkInDao()
}

@Module
@InstallIn(SingletonComponent::class)
abstract class AppBindModule {
    @Binds
    @Singleton
    abstract fun bindLearningRepository(
        impl: LearningRepositoryImpl
    ): LearningRepository
}
