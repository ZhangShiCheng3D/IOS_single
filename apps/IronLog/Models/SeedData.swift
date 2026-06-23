//
//  SeedData.swift
//  IronLog
//
//  首次启动时写入的内置动作库（100+）与训练模板。
//  通过稳定 ID 去重，保证升级时不重复插入。
//

import Foundation
import SwiftData

enum SeedData {

    // MARK: - 动作库

    /// 内置动作定义元组：(id, 中文, 英文, 肌群, 器械)
    /// id 使用 "ex.<slug>" 形式，稳定且可读。
    static let exercises: [(String, String, String, MuscleGroup, Equipment)] = [
        // —— 胸 ——
        ("ex.bench_press", "杠铃卧推", "Barbell Bench Press", .chest, .barbell),
        ("ex.incline_bench", "上斜杠铃卧推", "Incline Barbell Bench Press", .chest, .barbell),
        ("ex.decline_bench", "下斜杠铃卧推", "Decline Barbell Bench Press", .chest, .barbell),
        ("ex.db_bench", "哑铃卧推", "Dumbbell Bench Press", .chest, .dumbbell),
        ("ex.incline_db_bench", "上斜哑铃卧推", "Incline Dumbbell Press", .chest, .dumbbell),
        ("ex.db_fly", "哑铃飞鸟", "Dumbbell Fly", .chest, .dumbbell),
        ("ex.cable_fly", "龙门夹胸", "Cable Fly", .chest, .cable),
        ("ex.pec_deck", "蝴蝶机夹胸", "Pec Deck", .chest, .machine),
        ("ex.pushup", "俯卧撑", "Push-Up", .chest, .bodyweight),
        ("ex.dips_chest", "双杠臂屈伸(胸)", "Chest Dip", .chest, .bodyweight),
        ("ex.machine_press", "坐姿推胸机", "Machine Chest Press", .chest, .machine),

        // —— 背 ——
        ("ex.deadlift", "硬拉", "Deadlift", .back, .barbell),
        ("ex.barbell_row", "杠铃划船", "Barbell Row", .back, .barbell),
        ("ex.pendlay_row", "Pendlay划船", "Pendlay Row", .back, .barbell),
        ("ex.tbar_row", "T杠划船", "T-Bar Row", .back, .barbell),
        ("ex.pullup", "引体向上", "Pull-Up", .back, .bodyweight),
        ("ex.chinup", "反握引体", "Chin-Up", .back, .bodyweight),
        ("ex.lat_pulldown", "高位下拉", "Lat Pulldown", .back, .cable),
        ("ex.seated_row", "坐姿划船", "Seated Cable Row", .back, .cable),
        ("ex.db_row", "单臂哑铃划船", "Dumbbell Row", .back, .dumbbell),
        ("ex.machine_row", "器械划船", "Machine Row", .back, .machine),
        ("ex.straight_pulldown", "直臂下拉", "Straight-Arm Pulldown", .back, .cable),
        ("ex.rack_pull", "架上拉", "Rack Pull", .back, .barbell),
        ("ex.shrug", "耸肩", "Barbell Shrug", .back, .barbell),

        // —— 肩 ——
        ("ex.ohp", "站姿杠铃推举", "Overhead Press", .shoulders, .barbell),
        ("ex.seated_ohp", "坐姿杠铃推举", "Seated Overhead Press", .shoulders, .barbell),
        ("ex.db_shoulder_press", "哑铃肩推", "Dumbbell Shoulder Press", .shoulders, .dumbbell),
        ("ex.arnold_press", "阿诺德推举", "Arnold Press", .shoulders, .dumbbell),
        ("ex.lateral_raise", "哑铃侧平举", "Lateral Raise", .shoulders, .dumbbell),
        ("ex.cable_lateral", "龙门侧平举", "Cable Lateral Raise", .shoulders, .cable),
        ("ex.front_raise", "前平举", "Front Raise", .shoulders, .dumbbell),
        ("ex.rear_delt_fly", "反向飞鸟", "Rear Delt Fly", .shoulders, .dumbbell),
        ("ex.face_pull", "面拉", "Face Pull", .shoulders, .cable),
        ("ex.upright_row", "直立划船", "Upright Row", .shoulders, .barbell),
        ("ex.machine_shoulder_press", "器械肩推", "Machine Shoulder Press", .shoulders, .machine),

        // —— 肱二头 ——
        ("ex.barbell_curl", "杠铃弯举", "Barbell Curl", .biceps, .barbell),
        ("ex.db_curl", "哑铃弯举", "Dumbbell Curl", .biceps, .dumbbell),
        ("ex.hammer_curl", "锤式弯举", "Hammer Curl", .biceps, .dumbbell),
        ("ex.preacher_curl", "牧师凳弯举", "Preacher Curl", .biceps, .barbell),
        ("ex.incline_db_curl", "上斜哑铃弯举", "Incline Dumbbell Curl", .biceps, .dumbbell),
        ("ex.cable_curl", "龙门弯举", "Cable Curl", .biceps, .cable),
        ("ex.concentration_curl", "集中弯举", "Concentration Curl", .biceps, .dumbbell),
        ("ex.ez_bar_curl", "EZ杠弯举", "EZ-Bar Curl", .biceps, .barbell),

        // —— 肱三头 ——
        ("ex.close_grip_bench", "窄距卧推", "Close-Grip Bench Press", .triceps, .barbell),
        ("ex.tricep_pushdown", "绳索下压", "Triceps Pushdown", .triceps, .cable),
        ("ex.rope_pushdown", "绳索分推", "Rope Pushdown", .triceps, .cable),
        ("ex.skullcrusher", "仰卧臂屈伸", "Skullcrusher", .triceps, .barbell),
        ("ex.overhead_ext", "过顶臂屈伸", "Overhead Triceps Extension", .triceps, .dumbbell),
        ("ex.dips_triceps", "双杠臂屈伸(三头)", "Triceps Dip", .triceps, .bodyweight),
        ("ex.kickback", "哑铃后撑", "Triceps Kickback", .triceps, .dumbbell),

        // —— 腿（股四头） ——
        ("ex.squat", "杠铃深蹲", "Back Squat", .quads, .barbell),
        ("ex.front_squat", "颈前深蹲", "Front Squat", .quads, .barbell),
        ("ex.leg_press", "腿举", "Leg Press", .quads, .machine),
        ("ex.hack_squat", "哈克深蹲", "Hack Squat", .quads, .machine),
        ("ex.leg_extension", "腿屈伸", "Leg Extension", .quads, .machine),
        ("ex.goblet_squat", "高脚杯深蹲", "Goblet Squat", .quads, .dumbbell),
        ("ex.bulgarian_split", "保加利亚分腿蹲", "Bulgarian Split Squat", .quads, .dumbbell),
        ("ex.lunge", "箭步蹲", "Walking Lunge", .quads, .dumbbell),

        // —— 腘绳肌 / 臀 ——
        ("ex.romanian_dl", "罗马尼亚硬拉", "Romanian Deadlift", .hamstrings, .barbell),
        ("ex.leg_curl", "俯卧腿弯举", "Lying Leg Curl", .hamstrings, .machine),
        ("ex.seated_leg_curl", "坐姿腿弯举", "Seated Leg Curl", .hamstrings, .machine),
        ("ex.good_morning", "早安式", "Good Morning", .hamstrings, .barbell),
        ("ex.hip_thrust", "臀冲", "Hip Thrust", .glutes, .barbell),
        ("ex.glute_bridge", "臀桥", "Glute Bridge", .glutes, .barbell),
        ("ex.cable_kickback", "龙门后踢腿", "Cable Glute Kickback", .glutes, .cable),

        // —— 小腿 ——
        ("ex.standing_calf", "站姿提踵", "Standing Calf Raise", .calves, .machine),
        ("ex.seated_calf", "坐姿提踵", "Seated Calf Raise", .calves, .machine),
        ("ex.leg_press_calf", "腿举提踵", "Leg Press Calf Raise", .calves, .machine),

        // —— 核心 / 腹 ——
        ("ex.plank", "平板支撑", "Plank", .abs, .bodyweight),
        ("ex.hanging_leg_raise", "悬垂举腿", "Hanging Leg Raise", .abs, .bodyweight),
        ("ex.cable_crunch", "绳索卷腹", "Cable Crunch", .abs, .cable),
        ("ex.crunch", "卷腹", "Crunch", .abs, .bodyweight),
        ("ex.russian_twist", "俄罗斯转体", "Russian Twist", .abs, .bodyweight),
        ("ex.ab_wheel", "腹肌轮", "Ab Wheel Rollout", .abs, .other),
        ("ex.leg_raise", "仰卧举腿", "Lying Leg Raise", .abs, .bodyweight),

        // —— 前臂 ——
        ("ex.wrist_curl", "腕弯举", "Wrist Curl", .forearms, .dumbbell),
        ("ex.reverse_curl", "反握弯举", "Reverse Curl", .forearms, .barbell),
        ("ex.farmers_walk", "农夫行走", "Farmer's Walk", .forearms, .dumbbell),

        // —— 全身 / 功能 ——
        ("ex.clean", "翻站", "Power Clean", .fullBody, .barbell),
        ("ex.clean_and_jerk", "挺举", "Clean and Jerk", .fullBody, .barbell),
        ("ex.snatch", "抓举", "Snatch", .fullBody, .barbell),
        ("ex.kb_swing", "壶铃摆荡", "Kettlebell Swing", .fullBody, .kettlebell),
        ("ex.thruster", "推举深蹲", "Thruster", .fullBody, .barbell),
        ("ex.burpee", "波比跳", "Burpee", .fullBody, .bodyweight),
        ("ex.turkish_getup", "土耳其起立", "Turkish Get-Up", .fullBody, .kettlebell),

        // —— 有氧 ——
        ("ex.run", "跑步", "Running", .cardio, .bodyweight),
        ("ex.row_erg", "划船机", "Rowing Machine", .cardio, .machine),
        ("ex.cycling", "动感单车", "Cycling", .cardio, .machine),
        ("ex.jump_rope", "跳绳", "Jump Rope", .cardio, .other),
        ("ex.incline_walk", "坡度快走", "Incline Walk", .cardio, .machine),

        // —— 其他常见 ——
        ("ex.zercher_squat", "Zercher深蹲", "Zercher Squat", .quads, .barbell),
        ("ex.pendulum_squat", "钟摆深蹲", "Pendulum Squat", .quads, .machine),
        ("ex.smith_squat", "史密斯深蹲", "Smith Machine Squat", .quads, .machine),
        ("ex.smith_bench", "史密斯卧推", "Smith Machine Bench", .chest, .machine),
        ("ex.landmine_press", "杠铃单端推举", "Landmine Press", .shoulders, .barbell),
        ("ex.meadows_row", "Meadows划船", "Meadows Row", .back, .barbell),
        ("ex.cable_crossover", "龙门交叉", "Cable Crossover", .chest, .cable),
        ("ex.spider_curl", "蜘蛛弯举", "Spider Curl", .biceps, .dumbbell),
        ("ex.jm_press", "JM推举", "JM Press", .triceps, .barbell),
        ("ex.sissy_squat", "西西里深蹲", "Sissy Squat", .quads, .bodyweight),
        ("ex.nordic_curl", "北欧挺", "Nordic Hamstring Curl", .hamstrings, .bodyweight),
        ("ex.reverse_fly_machine", "反向飞鸟机", "Reverse Pec Deck", .shoulders, .machine),
        ("ex.band_pull_apart", "弹力带分肩", "Band Pull-Apart", .shoulders, .bands),
        ("ex.pullover", "哑铃曲臂上拉", "Dumbbell Pullover", .chest, .dumbbell),
    ]

    // MARK: - 内置模板

    /// 模板定义：(名称, 描述, [(动作id, 组, 次, 处方)])
    static let templates: [(String, String, [(String, Int, Int, String)])] = [
        (
            "5/3/1 — 主项日",
            "Wendler 5/3/1：四大项渐进超负荷。围绕训练最大重量(TM)安排。",
            [
                ("ex.squat", 3, 5, "65/75/85% TM，末组AMRAP"),
                ("ex.bench_press", 3, 5, "辅助主项"),
                ("ex.leg_press", 5, 10, "BBB 辅助"),
                ("ex.ab_wheel", 3, 12, "核心收尾"),
            ]
        ),
        (
            "PPL — 推 (Push)",
            "Push/Pull/Legs 之推日：胸、肩、三头。",
            [
                ("ex.bench_press", 4, 6, "主项"),
                ("ex.ohp", 3, 8, ""),
                ("ex.incline_db_bench", 3, 10, ""),
                ("ex.lateral_raise", 4, 15, ""),
                ("ex.tricep_pushdown", 3, 12, ""),
                ("ex.overhead_ext", 3, 12, ""),
            ]
        ),
        (
            "PPL — 拉 (Pull)",
            "Push/Pull/Legs 之拉日：背、二头、后束。",
            [
                ("ex.deadlift", 3, 5, "主项"),
                ("ex.pullup", 4, 8, ""),
                ("ex.barbell_row", 3, 8, ""),
                ("ex.seated_row", 3, 12, ""),
                ("ex.face_pull", 3, 15, ""),
                ("ex.barbell_curl", 3, 10, ""),
                ("ex.hammer_curl", 3, 12, ""),
            ]
        ),
        (
            "PPL — 腿 (Legs)",
            "Push/Pull/Legs 之腿日：股四头、腘绳、臀、小腿。",
            [
                ("ex.squat", 4, 6, "主项"),
                ("ex.romanian_dl", 3, 8, ""),
                ("ex.leg_press", 3, 12, ""),
                ("ex.leg_curl", 3, 12, ""),
                ("ex.leg_extension", 3, 15, ""),
                ("ex.standing_calf", 4, 15, ""),
            ]
        ),
        (
            "上肢日 (Upper)",
            "上下分化之上肢日，适合每周四练。",
            [
                ("ex.bench_press", 4, 6, ""),
                ("ex.barbell_row", 4, 6, ""),
                ("ex.db_shoulder_press", 3, 10, ""),
                ("ex.lat_pulldown", 3, 10, ""),
                ("ex.db_curl", 3, 12, ""),
                ("ex.tricep_pushdown", 3, 12, ""),
            ]
        ),
        (
            "下肢日 (Lower)",
            "上下分化之下肢日。",
            [
                ("ex.squat", 4, 6, ""),
                ("ex.romanian_dl", 3, 8, ""),
                ("ex.bulgarian_split", 3, 10, ""),
                ("ex.leg_curl", 3, 12, ""),
                ("ex.standing_calf", 4, 15, ""),
                ("ex.hanging_leg_raise", 3, 12, ""),
            ]
        ),
        (
            "全身 (Full Body) A",
            "适合初学者或时间紧张者的全身计划。",
            [
                ("ex.squat", 3, 5, ""),
                ("ex.bench_press", 3, 5, ""),
                ("ex.barbell_row", 3, 8, ""),
                ("ex.ohp", 3, 8, ""),
                ("ex.plank", 3, 60, "秒"),
            ]
        ),
    ]

    // MARK: - 写入逻辑

    /// 若数据库尚无内置数据则写入。基于稳定 ID 去重。
    @MainActor
    static func seedIfNeeded(_ context: ModelContext) {
        seedExercises(context)
        seedTemplates(context)
    }

    @MainActor
    private static func seedExercises(_ context: ModelContext) {
        // 查询已存在的内置动作 ID。
        let existing = (try? context.fetch(FetchDescriptor<Exercise>())) ?? []
        let existingIDs = Set(existing.map(\.id))

        for (id, name, nameEN, group, equip) in exercises where !existingIDs.contains(id) {
            let ex = Exercise(
                id: id,
                name: name,
                nameEN: nameEN,
                muscleGroup: group,
                equipment: equip,
                isCustom: false
            )
            context.insert(ex)
        }
        try? context.save()
    }

    @MainActor
    private static func seedTemplates(_ context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<WorkoutTemplate>())) ?? []
        let existingNames = Set(existing.filter { $0.isBuiltIn }.map(\.name))

        // 建立动作名映射，便于写入快照名。
        let allExercises = (try? context.fetch(FetchDescriptor<Exercise>())) ?? []
        let nameByID = Dictionary(uniqueKeysWithValues: allExercises.map { ($0.id, $0.name) })

        for (name, detail, items) in templates where !existingNames.contains(name) {
            let template = WorkoutTemplate(name: name, detail: detail, isBuiltIn: true)
            context.insert(template)
            for (index, item) in items.enumerated() {
                let (exID, sets, reps, rx) = item
                let te = TemplateExercise(
                    exerciseID: exID,
                    exerciseName: nameByID[exID] ?? exID,
                    order: index,
                    targetSets: sets,
                    targetReps: reps,
                    prescription: rx
                )
                te.template = template
                context.insert(te)
            }
        }
        try? context.save()
    }
}
