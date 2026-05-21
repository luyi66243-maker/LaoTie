import Foundation

// MARK: - Dialogue

struct DialogueRole: Codable, Identifiable, Sendable {
    var id: String
    var name: String
    var avatarName: String
    var description: String
}

struct DialogueLine: Codable, Identifiable, Sendable {
    var id: String
    var speakerRoleId: String
    var dongbeiText: String
    var standardText: String
    var audioFileName: String?
    var standardAudioFileName: String?
    var isUserLine: Bool
}

struct Dialogue: Codable, Identifiable, Sendable {
    var id: String
    var scenarioTitle: String
    var scenarioDescription: String
    var backgroundImageName: String
    var difficulty: Difficulty
    var roles: [DialogueRole]
    var lines: [DialogueLine]

    static let preview = Dialogue(
        id: "1",
        scenarioTitle: "烧烤摊点餐",
        scenarioDescription: "在东北的路边烧烤摊，你要学会怎么地道地点几串烤串",
        backgroundImageName: "scenario_bbq",
        difficulty: .beginner,
        roles: [
            DialogueRole(id: "boss", name: "烧烤老板", avatarName: "avatar_boss", description: "热情的烧烤摊老板"),
            DialogueRole(id: "you", name: "你", avatarName: "avatar_user", description: "初到东北的南方小土豆")
        ],
        lines: [
            DialogueLine(id: "l1", speakerRoleId: "boss", dongbeiText: "哎呀妈呀，来啦！想吃点啥？", standardText: "来了！想吃点什么？", audioFileName: "bbq_l1", isUserLine: false),
            DialogueLine(id: "l2", speakerRoleId: "you", dongbeiText: "老板，整几串大腰子！", standardText: "老板，来几串烤腰子！", audioFileName: "bbq_l2", isUserLine: true),
            DialogueLine(id: "l3", speakerRoleId: "boss", dongbeiText: "行嘞！再整点啥不？蒜蚕蛆要不？", standardText: "好的！还要点别的吗？蒜蓉茄子要不要？", audioFileName: "bbq_l3", isUserLine: false),
            DialogueLine(id: "l4", speakerRoleId: "you", dongbeiText: "来一个！再整瓶大绿棒子！", standardText: "来一个！再来瓶雪花啤酒！", audioFileName: "bbq_l4", isUserLine: true)
        ]
    )
}
