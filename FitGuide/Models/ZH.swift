import Foundation

enum ZH {
    static let bodyPart: [String: String] = [
        "back": "背部", "cardio": "有氧", "chest": "胸部",
        "lower arms": "前臂", "lower legs": "小腿", "neck": "颈部",
        "shoulders": "肩部", "upper arms": "上臂",
        "upper legs": "大腿", "waist": "腰腹"
    ]

    /// 中文训练惯例排序：胸 → 背 → 肩 → 上臂 → 大腿 → 小腿 → 腰腹 → 前臂 → 有氧 → 颈
    static let bodyPartOrder: [String] = [
        "chest", "back", "shoulders", "upper arms",
        "upper legs", "lower legs", "waist", "lower arms",
        "cardio", "neck"
    ]

    static let target: [String: String] = [
        "abs": "腹肌", "pectoralis": "胸肌", "pectorals": "胸肌",
        "biceps": "肱二头肌", "glutes": "臀肌", "delts": "三角肌",
        "triceps": "肱三头肌", "upper back": "上背", "lats": "背阔肌",
        "calves": "小腿肌", "quads": "股四头肌", "forearms": "前臂肌",
        "cardiovascular system": "心血管系统", "hamstrings": "腘绳肌",
        "spine": "脊柱", "traps": "斜方肌", "adductors": "内收肌",
        "serratus anterior": "前锯肌", "abductors": "外展肌",
        "levator scapulae": "肩胛提肌"
    ]

    static let muscleGroup: [String: String] = [
        "shoulders": "肩部", "forearms": "前臂", "biceps": "肱二头肌",
        "triceps": "肱三头肌", "hamstrings": "腘绳肌", "quadriceps": "股四头肌",
        "glutes": "臀肌", "obliques": "腹斜肌", "hip flexors": "髋屈肌",
        "chest": "胸部", "trapezius": "斜方肌", "traps": "斜方肌",
        "deltoids": "三角肌", "calves": "小腿肌", "ankles": "脚踝",
        "core": "核心", "lower back": "下背", "rotator cuff": "肩袖",
        "soleus": "比目鱼肌", "rhomboids": "菱形肌",
        "wrist flexors": "腕屈肌", "latissimus dorsi": "背阔肌",
        "abdominals": "腹肌", "ankle stabilizers": "踝稳定肌",
        "upper back": "上背", "wrist extensors": "腕伸肌",
        "lats": "背阔肌", "wrists": "腕部", "hands": "手部"
    ]

    static let equipment: [String: String] = [
        "body weight": "自重", "dumbbell": "哑铃", "cable": "拉力器",
        "barbell": "杠铃", "leverage machine": "杠杆机", "band": "弹力带",
        "smith machine": "史密斯机", "kettlebell": "壶铃", "weighted": "负重",
        "stability ball": "稳定球", "ez barbell": "EZ 杠铃", "assisted": "辅助",
        "sled machine": "推雪橇机", "medicine ball": "药球", "rope": "绳索",
        "roller": "滚轮", "resistance band": "阻力带", "bosu ball": "半球",
        "olympic barbell": "奥运杠铃", "wheel roller": "腹肌轮",
        "upper body ergometer": "上肢测功计", "skierg machine": "滑雪机",
        "hammer": "锤", "stationary bike": "动感单车", "tire": "轮胎",
        "trap bar": "菱形杠铃", "elliptical machine": "椭圆机",
        "stepmill machine": "阶梯机"
    ]

    /// 常用动作中英对照表（-known compound/iso lifts）
    static let nameMap: [String: String] = [
        "barbell bench press": "杠铃卧推",
        "barbell full squat": "杠铃深蹲",
        "barbell deadlift": "杠铃硬拉",
        "dumbbell biceps curl": "哑铃二头弯举",
        "dumbbell lateral raise": "哑铃侧平举",
        "pull-up": "引体向上",
        "chin-up": "反握引体向上",
        "push-up": "俯卧撑",
        "barbell row": "杠铃划船",
        "dumbbell row": "哑铃划船",
        "dumbbell shoulder press": "哑铃肩推",
        "barbell shoulder press": "杠铃肩推",
        "barbell curl": "杠铃弯举",
        "barbell front squat": "杠铃前蹲",
        "dumbbell triceps extension": "哑铃三头屈伸",
        "triceps pushdown": "三头下压",
        "hammer curl": "锤式弯举",
        "leg press": "腿举",
        "leg curl": "腿弯举",
        "leg extension": "腿屈伸",
        "romanian deadlift": "罗马尼亚硬拉",
        "sumo deadlift": "相扑硬拉",
        "front raise": "前平举",
        "lat pulldown": "高位下拉",
        "cable row": "绳索划船",
        "plank": "平板支撑",
        "side plank": "侧平板支撑",
        "russian twist": "俄罗斯转体",
        "crunches": "卷腹",
        "sit-up": "仰卧起坐",
        "hanging leg raise": "悬垂举腿",
        "calf raise": "提踵",
        "walking lunge": "行走弓步",
        "split squat": "分腿蹲",
        "bulgarian split squat": "保加利亚分腿蹲",
        "hip thrust": "臀桥",
        "barbell hip thrust": "杠铃臀桥",
        "glute bridge": "臀桥",
        "dumbbell fly": "哑铃飞鸟",
        "incline bench press": "上斜卧推",
        "decline bench press": "下斜卧推",
        "lat pulldown wide grip": "宽握高位下拉",
        "ez bar curl": "EZ 杠弯举",
        "preacher curl": "牧师凳弯举",
        "concentration curl": "集中弯举",
        "skull crusher": "仰卧三头屈伸",
        "french press": "法式推举",
        "dips": "双杠臂屈伸",
        "hyperextensions": "背伸展",
        "back extension": "背伸展",
        "good mornings": "早安动作",
        "farmer's walk": "农夫走",
        "dead hang": "悬垂",
        "burpee": "波比跳",
        "mountain climber": "登山者",
        "jumping jacks": "开合跳",
        "high knees": "高抬腿",
        "sprint": "冲刺跑",
        "jump rope": "跳绳"
    ]
}

extension Exercise {
    /// 中文名称：优先命中常用对照表，否则按"部位 · 器械 · 目标肌群"合成描述
    var nameZH: String {
        let key = name.lowercased()
        if let zh = ZH.nameMap[key] { return zh }
        let bp = ZH.bodyPart[bodyPart.lowercased()] ?? bodyPart
        let eq = ZH.equipment[equipment.lowercased()] ?? equipment
        let tg = ZH.target[target.lowercased()] ?? target
        return "\(bp) · \(eq) · \(tg)"
    }

    var targetZH: String { ZH.target[target.lowercased()] ?? target }
    var muscleGroupZH: String { ZH.muscleGroup[muscleGroup.lowercased()] ?? muscleGroup }
    var equipmentZH: String { ZH.equipment[equipment.lowercased()] ?? equipment }
    var bodyPartZH: String { ZH.bodyPart[bodyPart.lowercased()] ?? bodyPart }
}