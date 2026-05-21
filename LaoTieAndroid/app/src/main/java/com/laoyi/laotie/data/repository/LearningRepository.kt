package com.laoyi.laotie.data.repository

import com.laoyi.laotie.data.model.Dialogue
import com.laoyi.laotie.data.model.Meme
import com.laoyi.laotie.data.model.QuizLevel
import com.laoyi.laotie.data.model.Scenic
import com.laoyi.laotie.data.model.TongueTwister
import com.laoyi.laotie.data.model.Vocabulary
import com.laoyi.laotie.data.seed.SeedDataLoader
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

interface LearningRepository {
    suspend fun vocabularies(): List<Vocabulary>
    suspend fun dialogues(): List<Dialogue>
    suspend fun quizzes(): List<QuizLevel>
    suspend fun memes(): List<Meme>
    suspend fun tongueTwisters(): List<TongueTwister>
    suspend fun scenics(): List<Scenic>
}

@Singleton
class LearningRepositoryImpl @Inject constructor(
    private val seedDataLoader: SeedDataLoader
) : LearningRepository {

    override suspend fun vocabularies(): List<Vocabulary> = withContext(Dispatchers.IO) {
        seedDataLoader.loadArray("vocabularies.json")
    }

    override suspend fun dialogues(): List<Dialogue> = withContext(Dispatchers.IO) {
        seedDataLoader.loadArray("dialogues.json")
    }

    override suspend fun quizzes(): List<QuizLevel> = withContext(Dispatchers.IO) {
        seedDataLoader.loadArray("quizzes.json")
    }

    override suspend fun memes(): List<Meme> = withContext(Dispatchers.IO) {
        seedDataLoader.loadArray("memes.json")
    }

    override suspend fun tongueTwisters(): List<TongueTwister> = withContext(Dispatchers.IO) {
        seedDataLoader.loadArray("tongue_twisters.json")
    }

    override suspend fun scenics(): List<Scenic> = withContext(Dispatchers.IO) {
        seedDataLoader.loadArray("scenics.json")
    }
}
