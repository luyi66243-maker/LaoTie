package com.laoyi.laotie.data.model

import kotlinx.serialization.Serializable

@Serializable
data class Vocabulary(
    val id: String,
    val dongbeiWord: String,
    val standardWord: String,
    val pinyin: String,
    val dongbeiPinyin: String,
    val meaning: String,
    val exampleSentence: String,
    val exampleTranslation: String,
    val audioFileName: String? = null,
    val standardAudioFileName: String? = null,
    val category: String,
    val difficulty: String,
    val usageNote: String? = null,
    val funFact: String? = null
)

@Serializable
data class DialogueRole(
    val id: String,
    val name: String,
    val avatarName: String,
    val description: String
)

@Serializable
data class DialogueLine(
    val id: String,
    val speakerRoleId: String,
    val dongbeiText: String,
    val standardText: String,
    val audioFileName: String? = null,
    val standardAudioFileName: String? = null,
    val isUserLine: Boolean
)

@Serializable
data class Dialogue(
    val id: String,
    val scenarioTitle: String,
    val scenarioDescription: String,
    val backgroundImageName: String,
    val difficulty: String,
    val roles: List<DialogueRole>,
    val lines: List<DialogueLine>
)

@Serializable
data class QuizQuestion(
    val id: String,
    val type: String,
    val prompt: String,
    val audioFileName: String? = null,
    val options: List<String>? = null,
    val matchingPairs: List<MatchingPair>? = null,
    val correctAnswer: String,
    val explanation: String
) {
    @Serializable
    data class MatchingPair(
        val dongbei: String,
        val standard: String
    )
}

@Serializable
data class QuizLevel(
    val id: String,
    val levelNumber: Int,
    val title: String,
    val subtitle: String,
    val province: String,
    val city: String,
    val questions: List<QuizQuestion>,
    val passingScore: Int,
    val rewardXP: Int,
    val rewardTitle: String? = null
)

@Serializable
data class Meme(
    val id: String,
    val phrase: String,
    val meaning: String,
    val usage: String,
    val origin: String? = null
)

@Serializable
data class TongueTwister(
    val id: String,
    val title: String,
    val content: String,
    val pinyin: String? = null,
    val audioFileName: String? = null
)

@Serializable
data class Scenic(
    val id: String,
    val name: String,
    val province: String,
    val city: String,
    val description: String,
    val location: String,
    val category: String,
    val highlight: String,
    val imageName: String? = null,
    val imageMatchType: String = "pending",
    val latitude: Double? = null,
    val longitude: Double? = null
)

@Serializable
data class Place(
    val id: String,
    val province: String,
    val city: String,
    val district: String? = null,
    val scenicId: String? = null
)
