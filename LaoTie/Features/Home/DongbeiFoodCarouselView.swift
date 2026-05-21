import SwiftUI

// MARK: - Data Model

struct DongbeiFoodItem: Identifiable {
    let id: Int
    let name: String
    let region: String
    let city: String
    let emoji: String
    let imageName: String
    let colorDesc: String
    let aromaDesc: String
    let tasteDesc: String
    let description: String
    let dongbeiComment: String
}

// MARK: - Food Database

let dongbeiFoods: [DongbeiFoodItem] = [
    DongbeiFoodItem(
        id: 1, name: "锅包肉", region: "黑龙江", city: "哈尔滨", emoji: "🥩",
        imageName: "food_guobaorou",
        colorDesc: "金黄酥脆，外皮如琥珀般透亮",
        aromaDesc: "酸甜酱汁裹着肉香，闻着就流口水",
        tasteDesc: "外酥里嫩，酸甜适口，一口一个嘎嘣脆",
        description: "哈尔滨名菜，猪里脊挂糊油炸后浇酸甜汁，东北人的硬菜担当。",
        dongbeiComment: "这菜杠杠的！没吃过锅包肉等于没来过东北！"
    ),
    DongbeiFoodItem(
        id: 2, name: "小鸡炖蘑菇", region: "黑龙江", city: "牡丹江", emoji: "🍗",
        imageName: "food_xiaojidunmoggu",
        colorDesc: "汤色金黄浓郁，鸡肉泛着油光",
        aromaDesc: "榛蘑的山野清香混着鸡汤的鲜美",
        tasteDesc: "鸡肉软烂入味，蘑菇吸满汤汁，越炖越香",
        description: "东北四大炖之首，小笨鸡配野生榛蘑，铁锅慢炖出灵魂。",
        dongbeiComment: "姑爷进门，小鸡断魂！这是东北待客最高规格！"
    ),
    DongbeiFoodItem(
        id: 3, name: "猪肉炖粉条", region: "辽宁", city: "沈阳", emoji: "🍖",
        imageName: "food_zhuroudunfentiao",
        colorDesc: "红烧酱色油亮，粉条晶莹剔透",
        aromaDesc: "五花肉炖出的浓香，隔着屏幕都能闻到",
        tasteDesc: "五花肉肥而不腻，粉条滑溜筋道",
        description: "东北四大炖之一，五花肉配红薯粉条，冬天吃一碗浑身暖和。",
        dongbeiComment: "造一大碗粉条子，这日子过得有滋有味儿！"
    ),
    DongbeiFoodItem(
        id: 4, name: "东北烧烤", region: "辽宁", city: "锦州", emoji: "🍢",
        imageName: "food_dongbeishaokao",
        colorDesc: "炭火炙烤金黄焦香，辣椒面红彤彤",
        aromaDesc: "孜然辣椒混着炭火香，整条街都是味儿",
        tasteDesc: "外焦里嫩，咸香微辣，配上大绿棒子绝了",
        description: "锦州烧烤全国闻名，万物皆可烤，配大绿棒子是标配。",
        dongbeiComment: "撸串不喝大绿棒子，那跟咸鱼有啥区别！"
    ),
    DongbeiFoodItem(
        id: 5, name: "铁锅炖大鹅", region: "黑龙江", city: "齐齐哈尔", emoji: "🦢",
        imageName: "food_tieguodundae",
        colorDesc: "酱红色浓汤翻滚，鹅肉色泽诱人",
        aromaDesc: "铁锅里飘出的鹅肉香，配上玉米饼的麦香",
        tasteDesc: "鹅肉紧实有嚼劲，汤汁浓郁鲜美",
        description: "铁锅灶台炖大鹅，锅边贴玉米饼子，东北最有烟火气的菜。",
        dongbeiComment: "铁锅炖大鹅，吃的就是那个氛围！贼带劲！"
    ),
    DongbeiFoodItem(
        id: 6, name: "地三鲜", region: "吉林", city: "长春", emoji: "🍆",
        imageName: "food_disanxian",
        colorDesc: "茄子紫亮，土豆金黄，青椒翠绿",
        aromaDesc: "蒜香酱香混合着蔬菜的清甜",
        tasteDesc: "茄子绵软，土豆酥面，青椒脆嫩，三味合一",
        description: "茄子、土豆、青椒——地里三样宝贝炒一盘，家常至极。",
        dongbeiComment: "这道菜整起来贼简单，但没有东北人不爱的！"
    ),
    DongbeiFoodItem(
        id: 7, name: "酸菜白肉血肠", region: "吉林", city: "吉林市", emoji: "🥬",
        imageName: "food_suancaibairouxuechang",
        colorDesc: "酸菜泛着微黄，白肉晶莹，血肠深红",
        aromaDesc: "酸菜的发酵酸香配上猪肉的鲜美",
        tasteDesc: "酸菜开胃解腻，白肉肥嫩，血肠鲜香Q弹",
        description: "满族传统菜，酸菜配白肉和血肠，杀猪菜的经典版本。",
        dongbeiComment: "杀猪菜一上桌，年味儿就来了！嘎嘎香！"
    ),
    DongbeiFoodItem(
        id: 8, name: "哈尔滨红肠", region: "黑龙江", city: "哈尔滨", emoji: "🌭",
        imageName: "food_haerbinhongchang",
        colorDesc: "枣红色外皮微皱，横切面粉嫩细腻",
        aromaDesc: "果木熏制的烟熏香气，浓郁持久",
        tasteDesc: "蒜香浓郁，肉质紧实弹牙，越嚼越香",
        description: "百年秋林红肠，果木炭熏工艺，哈尔滨的城市名片。",
        dongbeiComment: "去哈尔滨不整根红肠？那你算白去了！"
    ),
    DongbeiFoodItem(
        id: 9, name: "东北大拉皮", region: "吉林", city: "延边", emoji: "🥗",
        imageName: "food_dalapi",
        colorDesc: "拉皮透明如玉，配菜五彩缤纷",
        aromaDesc: "芝麻酱和蒜汁的浓香扑鼻",
        tasteDesc: "拉皮滑爽弹牙，麻酱浓香，酸辣开胃",
        description: "绿豆淀粉制成的大拉皮，拌上麻酱蒜汁，夏天必吃凉菜。",
        dongbeiComment: "大热天来一盘大拉皮，凉快！贼得劲！"
    ),
    DongbeiFoodItem(
        id: 10, name: "东北饺子", region: "辽宁", city: "大连", emoji: "🥟",
        imageName: "food_dongbeijiaozi",
        colorDesc: "皮薄馅大，白胖饱满如元宝",
        aromaDesc: "猪肉白菜馅的鲜香从蒸汽中飘出",
        tasteDesc: "皮薄馅足汤汁鲜，蘸上醋蒜汁更美",
        description: "东北饺子以大馅著称，过年必吃，蘸醋蒜酱油是标配。",
        dongbeiComment: "好吃不过饺子！东北的饺子比你脸还大！"
    ),
    DongbeiFoodItem(
        id: 11, name: "溜肉段", region: "辽宁", city: "鞍山", emoji: "🥘",
        imageName: "food_liurouduan",
        colorDesc: "金红酱色油亮，肉段外挂薄芡",
        aromaDesc: "酱香蒜香交融，热气腾腾",
        tasteDesc: "外酥内嫩，咸鲜微甜，裹汁入味",
        description: "猪里脊挂糊炸至金黄，再勾芡翻炒，东北硬菜之一。",
        dongbeiComment: "溜肉段配米饭，能造三大碗！"
    ),
    DongbeiFoodItem(
        id: 12, name: "冷面", region: "吉林", city: "延吉", emoji: "🍜",
        imageName: "food_lengmian",
        colorDesc: "面条深褐色，汤汁清亮如冰",
        aromaDesc: "冰爽酸甜的汤底带着梨的清香",
        tasteDesc: "面条筋道弹滑，汤汁酸甜冰爽",
        description: "延吉冷面，荞麦面配冰镇酸甜汤，夏天的灵魂美食。",
        dongbeiComment: "大夏天嗦一碗冷面，从头凉到脚！嘎嘎爽！"
    ),
    DongbeiFoodItem(
        id: 13, name: "烤冷面", region: "黑龙江", city: "鸡西", emoji: "🫓",
        imageName: "food_kaolengmian",
        colorDesc: "面皮煎至微焦金黄，酱料红亮诱人",
        aromaDesc: "甜面酱和醋的混合香气，配上鸡蛋的焦香",
        tasteDesc: "软糯Q弹，酸甜咸辣一口全有",
        description: "东北街头小吃之王，铁板煎冷面加蛋刷酱卷起来吃。",
        dongbeiComment: "两块钱一份的烤冷面，承包了我整个青春！"
    ),
    DongbeiFoodItem(
        id: 14, name: "排骨炖豆角", region: "辽宁", city: "抚顺", emoji: "🫘",
        imageName: "food_paigudundoujiao",
        colorDesc: "排骨酱红油亮，豆角翠绿饱满",
        aromaDesc: "排骨的肉香混着豆角的清甜",
        tasteDesc: "排骨酥烂脱骨，豆角绵软入味",
        description: "东北四大炖之一，排骨炖豆角再贴上玉米饼，灶台炖菜经典。",
        dongbeiComment: "再贴上一圈大饼子，这才叫整活儿！"
    ),
    DongbeiFoodItem(
        id: 15, name: "杀猪菜", region: "黑龙江", city: "绥化", emoji: "🐷",
        imageName: "food_shazhucai",
        colorDesc: "大铁锅里热气翻滚，荤素搭配色彩丰富",
        aromaDesc: "新鲜猪肉配酸菜的浓郁香气弥漫整个院子",
        tasteDesc: "大块猪肉鲜嫩多汁，酸菜爽口解腻",
        description: "年末杀年猪时做的大铁锅菜，是东北农村过年的仪式感。",
        dongbeiComment: "杀猪菜一吃，过年的味儿就全有了！"
    ),
    DongbeiFoodItem(
        id: 16, name: "鲅鱼饺子", region: "辽宁", city: "大连", emoji: "🐟",
        imageName: "food_bayujiaozi",
        colorDesc: "饺子皮白润饱满，透着淡淡的鱼肉粉色",
        aromaDesc: "新鲜鲅鱼肉的海鲜清香",
        tasteDesc: "鱼肉鲜嫩多汁，一口爆浆，鲜到眉毛掉下来",
        description: "大连特色，用新鲜鲅鱼肉做馅，海边人家的待客之道。",
        dongbeiComment: "这饺子一口下去，鲜得你直拍大腿！"
    ),
    DongbeiFoodItem(
        id: 17, name: "粘豆包", region: "黑龙江", city: "佳木斯", emoji: "🟡",
        imageName: "food_niandoubao",
        colorDesc: "金黄色的外皮，小巧圆润像金元宝",
        aromaDesc: "黄米面的谷物清香，夹着红豆沙的甜香",
        tasteDesc: "外皮糯软黏牙，内馅甜蜜绵密",
        description: "冬天冻在室外保存，吃时上锅蒸，越蒸越黏糊。",
        dongbeiComment: "冬天啃冻豆包，那才叫正宗东北味儿！"
    ),
    DongbeiFoodItem(
        id: 18, name: "马迭尔冰棍", region: "黑龙江", city: "哈尔滨", emoji: "🍦",
        imageName: "food_madier",
        colorDesc: "奶白色冰棍，简约朴素不花哨",
        aromaDesc: "浓浓的鲜奶香气，甜而不腻",
        tasteDesc: "奶味醇厚绵密，入口即化，清甜爽口",
        description: "中央大街百年老字号，零下三十度也要排队买的冰棍。",
        dongbeiComment: "零下三十度吃冰棍，这才是东北人的尿性！"
    ),
]

// MARK: - Carousel View

struct DongbeiFoodCarouselView: View {
    @State private var currentIndex = 0
    @State private var timer: Timer?

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingMD) {
            // Header
            HStack {
                Image(systemName: "fork.knife")
                    .font(.headline)
                    .foregroundStyle(DongbeiColors.dahong)
                Text("东北三省美食")
                    .font(Theme.headlineFont)
                    .foregroundStyle(DongbeiColors.meihei)
                Spacer()
                // Province tag
                Text(dongbeiFoods[currentIndex].region)
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(provinceColor(dongbeiFoods[currentIndex].region))
                    .clipShape(Capsule())
            }

            // Food card carousel
            TabView(selection: $currentIndex) {
                ForEach(Array(dongbeiFoods.enumerated()), id: \.element.id) { index, food in
                    FoodCardView(food: food)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 380)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusLG))

            // Page indicator dots
            HStack(spacing: 6) {
                ForEach(0..<dongbeiFoods.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentIndex ? DongbeiColors.dahong : DongbeiColors.dahong.opacity(0.2))
                        .frame(width: index == currentIndex ? 8 : 6, height: index == currentIndex ? 8 : 6)
                        .animation(.easeInOut(duration: 0.2), value: currentIndex)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .onAppear { startAutoScroll() }
        .onDisappear { stopAutoScroll() }
        .onChange(of: currentIndex) { _ in
            // Reset timer on manual swipe
            stopAutoScroll()
            startAutoScroll()
        }
    }

    private func startAutoScroll() {
        timer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { _ in
            Task { @MainActor in
                withAnimation(.easeInOut(duration: 0.5)) {
                    self.currentIndex = (self.currentIndex + 1) % dongbeiFoods.count
                }
            }
        }
    }

    private func stopAutoScroll() {
        timer?.invalidate()
        timer = nil
    }

    private func provinceColor(_ region: String) -> Color {
        switch region {
        case "辽宁": return DongbeiColors.dahong
        case "吉林": return DongbeiColors.cuilu
        case "黑龙江": return DongbeiColors.binglan
        default: return DongbeiColors.jinhuang
        }
    }
}

// MARK: - Individual Food Card

struct FoodCardView: View {
    let food: DongbeiFoodItem

    var body: some View {
        VStack(spacing: 0) {
            // Food image
            Image(food.imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 160)
                .clipped()
                .overlay(alignment: .bottomLeading) {
                    // Name + city overlay on image
                    HStack(spacing: 6) {
                        Text(food.emoji)
                            .font(.title2)
                        Text(food.name)
                            .font(Theme.headlineFont)
                            .foregroundStyle(.white)
                        Text("· \(food.city)")
                            .font(.caption.bold())
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .padding(.horizontal, Theme.spacingMD)
                    .padding(.vertical, Theme.spacingSM)
                    .background(
                        LinearGradient(
                            colors: [.black.opacity(0.6), .clear],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

            // Color / Aroma / Taste
            VStack(alignment: .leading, spacing: 5) {
                flavorRow(icon: "paintpalette.fill", label: "色", text: food.colorDesc, color: DongbeiColors.dahong)
                flavorRow(icon: "wind", label: "香", text: food.aromaDesc, color: DongbeiColors.jinhuang)
                flavorRow(icon: "mouth.fill", label: "味", text: food.tasteDesc, color: DongbeiColors.cuilu)
            }
            .padding(.horizontal, Theme.spacingMD)
            .padding(.top, Theme.spacingSM)

            Spacer(minLength: 4)

            // Dongbei comment
            HStack(spacing: 4) {
                Image(systemName: "quote.opening")
                    .font(Theme.tinyFont)
                Text(food.dongbeiComment)
                    .font(.caption.bold())
                Image(systemName: "quote.closing")
                    .font(Theme.tinyFont)
            }
            .foregroundStyle(DongbeiColors.dahong)
            .padding(.horizontal, Theme.spacingMD)
            .padding(.bottom, Theme.spacingMD)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.white, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusLG))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
        .padding(.horizontal, 2)
    }

    private func flavorRow(icon: String, label: String, text: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 6) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(Theme.badgeFont)
                Text(label)
                    .font(Theme.smallLabelFont.weight(.heavy))
            }
            .foregroundStyle(color)
            .frame(width: 32, alignment: .leading)

            Text(text)
                .font(Theme.labelFont)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
    }
}
