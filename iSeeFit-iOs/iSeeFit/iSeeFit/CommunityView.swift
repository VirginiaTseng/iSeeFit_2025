//
//  CommunityView.swift
//  iSeeFit
//
//  Created by Virginia Zheng on 2025-02-18.
//
import SwiftUI

struct CommunityView: View {
    @State private var selectedInterests = Set<String>()
    
    let interests = [
        "Yoga", "Art", "Reading", "Cooking", "Photography", "Music"
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // 愿望瓶部分
                    WishBottleSection()
                    
                    // 发现兴趣部分
                    DiscoverSection()
                    
                    // 兴趣标签部分
                    InterestsSection(selectedInterests: $selectedInterests, interests: interests)
                    
                    // 即将举办的活动
                    UpcomingEventsSection()
                    
                    // 添加新的组件
                    ForEach(events) { event in
                        EventListItem(event: event)
                    }
                    
                    DailyWellnessTip()
                }
                .padding()
            }
            //.navigationTitle("iSeeFit")
            .commonToolbar()
//            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    HStack(spacing: 15) {
//                        Button(action: {}) {
//                            Image(systemName: "bell.fill")
//                                .foregroundColor(.purple)
//                        }
//                        Button(action: {}) {
//                            Image(systemName: "moon.fill")
//                                .foregroundColor(.purple)
//                        }
//                        Button(action: {}) {
//                            Image(systemName: "mic.fill")
//                                .foregroundColor(.purple)
//                        }
//                    }
//                }
//            }
        }
    }
}

// 愿望瓶部分
struct WishBottleSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Wish Bottle")
                .font(.title)
                .bold()
            Text("Share your wishes or read others'")
                .foregroundColor(.gray)
            
            ZStack {
                // 渐变背景
                LinearGradient(
                    gradient: Gradient(colors: [.purple.opacity(0.6), .purple.opacity(0.3)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // 愿望瓶网格
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 15) {
                    ForEach(0..<6) { _ in
                        WishBottleItem()
                    }
                    
                    // 添加按钮
                    Button(action: {}) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.purple.opacity(0.3))
                            .clipShape(Circle())
                    }
                }
                .padding()
            }
            .frame(height: 200)
            .cornerRadius(15)
        }
    }
}

// 单个愿望瓶项目
struct WishBottleItem: View {
    var body: some View {
        VStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.3))
                .frame(width: 60, height: 80)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                )
        }
    }
}

// 发现部分
struct DiscoverSection: View {
    var body: some View {
        Button(action: {}) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Discover Your Interests")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Join local activities and meet like-minded people")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                Spacer()
            }
            .padding()
            .background(Color.purple)
            .cornerRadius(15)
        }
    }
}

// 兴趣标签部分
struct InterestsSection: View {
    @Binding var selectedInterests: Set<String>
    var interests: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Your Interests")
                .font(.headline)
            
            FlowLayout(spacing: 10) {
                ForEach(interests, id: \.self) { interest in
                    InterestTag(
                        title: interest,
                        isSelected: selectedInterests.contains(interest),
                        action: {
                            if selectedInterests.contains(interest) {
                                selectedInterests.remove(interest)
                            } else {
                                selectedInterests.insert(interest)
                            }
                        }
                    )
                }
            }
        }
    }
}

// 兴趣标签
struct InterestTag: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.purple : Color.gray.opacity(0.1))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

// 即将举办的活动部分
struct UpcomingEventsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Upcoming Events")
                    .font(.headline)
                Spacer()
                Button("View All") {
                    // 查看所有事件的操作
                }
                .foregroundColor(.purple)
            }
            
            EventCard(
                image: "yoga",
                title: "Yoga in the Park",
                date: "2025-02-20 at 09:00 AM",
                location: "Central Park",
                category: "Wellness"
            )
        }
    }
}

// 活动卡片
struct EventCard: View {
    var image: String
    var title: String
    var date: String
    var location: String
    var category: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 使用占位图像
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 150)
                .cornerRadius(10)
                .overlay(
                    Text("Yoga Image")
                        .foregroundColor(.gray)
                )
            
            Text(title)
                .font(.headline)
            
            HStack {
                Image(systemName: "calendar")
                Text(date)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            HStack {
                Image(systemName: "location")
                Text(location)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Text(category)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.purple.opacity(0.1))
                .foregroundColor(.purple)
                .cornerRadius(15)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 2)
    }
}

// 流式布局助手
struct FlowLayout: Layout {
    var spacing: CGFloat
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(at: frame.origin, proposal: ProposedViewSize(frame.size))
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var frames: [CGRect] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            var maxWidth: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if currentX + size.width > maxWidth {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
                maxWidth = max(maxWidth, currentX)
            }
            
            self.size = CGSize(
                width: maxWidth,
                height: currentY + lineHeight
            )
        }
    }
}

// 活动数据模型
struct Event: Identifiable {
    let id = UUID()
    let title: String
    let datetime: String
    let location: String
    let category: String
    let joinedCount: Int
    let image: String
}

// 示例数据
let events = [
    Event(
        title: "Yoga in the Park",
        datetime: "2025-02-20 at 09:00 AM",
        location: "Central Park",
        category: "Wellness",
        joinedCount: 15,
        image: "yoga"
    ),
    Event(
        title: "Art & Craft Workshop",
        datetime: "2025-02-22 at 02:00 PM",
        location: "Community Center",
        category: "Creative",
        joinedCount: 8,
        image: "art"
    ),
    Event(
        title: "Book Club Meeting",
        datetime: "2025-02-24 at 06:30 PM",
        location: "Local Library",
        category: "Education",
        joinedCount: 12,
        image: "book"
    )
]

// 活动列表项
struct EventListItem: View {
    let event: Event
    
    var body: some View {
        HStack(spacing: 15) {
            // 活动图片
            Image(event.image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 80, height: 80)
                .cornerRadius(10)
                .clipped()
            
            // 活动信息
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.headline)
                
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.gray)
                    Text(event.datetime)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                HStack {
                    Image(systemName: "location")
                        .foregroundColor(.gray)
                    Text(event.location)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                HStack {
                    Image(systemName: "person.2")
                        .foregroundColor(.gray)
                    Text("\(event.joinedCount) joined")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            VStack(spacing: 8) {
                // 分类标签
                Text(event.category)
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(categoryColor(for: event.category).opacity(0.1))
                    .foregroundColor(categoryColor(for: event.category))
                    .cornerRadius(12)
                
                // 加入按钮
                Button(action: {}) {
                    Text("Join")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.purple)
                        .cornerRadius(20)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 2)
    }
    
    // 根据分类返回对应的颜色
    func categoryColor(for category: String) -> Color {
        switch category {
        case "Wellness":
            return .blue
        case "Creative":
            return .purple
        case "Education":
            return .indigo
        default:
            return .gray
        }
    }
}

// 每日健康提示
struct DailyWellnessTip: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Daily Wellness Tips")
                .font(.headline)
            
            HStack(spacing: 15) {
                Image(systemName: "brain.head.profile")
                    .font(.title)
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Practice Mindfulness")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Take 5 minutes today to focus on your breath and be present in the moment.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.purple)
            .cornerRadius(15)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 2)
    }
} 
