//
//  TodayView.swift
//  iSeeFit
//
//  Created by Virginia Zheng on 2025-09-19.
//

import SwiftUI

struct TodayEntry: Identifiable {
    enum Kind { case meal, workout }
    let id = UUID()
    let time: String
    let title: String
    let calories: Int
    let kind: Kind
    let image: Image?
    let note: String?
}

struct TodayView: View {
    // Demo data; 后续可替换成真实数据源
    @State private var entries: [TodayEntry] = [
        TodayEntry(time: "08:12", title: "Breakfast", calories: 320, kind: .meal, image: nil, note: "Yogurt & fruits"),
        TodayEntry(time: "12:48", title: "Lunch", calories: 640, kind: .meal, image: nil, note: "Chicken salad"),
        TodayEntry(time: "18:30", title: "Workout", calories: 420, kind: .workout, image: nil, note: "Treadmill 40min"),
        TodayEntry(time: "20:05", title: "Dinner", calories: 510, kind: .meal, image: nil, note: "Shrimp & veggies")
    ]

    private var intake: Int { entries.filter { $0.kind == .meal }.map { $0.calories }.reduce(0, +) }
    private var burn: Int { entries.filter { $0.kind == .workout }.map { $0.calories }.reduce(0, +) }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    header
                    
                    timeline

                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .navigationBarTitleDisplayMode(.inline)
//            .toolbar { ToolbarItem(placement: .principal) { Text("Today's Memory").font(.headline) } }
            .background(LinearGradient(colors: [Color.black.opacity(0.04), Color.clear], startPoint: .top, endPoint: .bottom))
        }
    }

    private var header: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 20)
                .fill(LinearGradient(colors: [Color.yellow.opacity(0.35), Color.orange.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(height: 120)
            VStack(alignment: .leading, spacing: 8) {
                //Text("Today's Memory").font(.title3).bold()
                Text("Track your meals and workouts today")
                    .font(.caption)
                    .foregroundColor(.secondary)
                summary
            }
            .padding(16)
        }
    }

    private var timeline: some View {
        VStack(spacing: 24) {
            ForEach(entries) { item in
                HStack(alignment: .top, spacing: 12) {
                    // 左列（餐饮）
                    Group {
                        if item.kind == .meal {
                            entryCard(item)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        } else {
                            Spacer(minLength: 0)
                                .frame(maxWidth: .infinity)
                        }
                    }

                    // 中线与时间
                    VStack(spacing: 6) {
                        Text(item.time)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Circle().fill(item.kind == .meal ? Color.orange : Color.green)
                            .frame(width: 10, height: 10)
                        Rectangle()
                            .fill(Color.secondary.opacity(0.25))
                            .frame(width: 2, height: 90)
                    }

                    // 右列（健身）
                    Group {
                        if item.kind == .workout {
                            entryCard(item)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            Spacer(minLength: 0)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
        }
    }

    private func entryCard(_ item: TodayEntry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.title).font(.headline)
                Spacer()
                HStack(spacing: 6) {
                    Image(systemName: item.kind == .meal ? "flame.fill" : "bolt.heart.fill")
                        .foregroundColor(item.kind == .meal ? .orange : .green)
                    Text("\(item.calories) kcal").font(.subheadline).bold()
                }
            }
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
                .frame(height: 110)
                .overlay(
                    ZStack {
                        if let img = item.image { img.resizable().scaledToFill().clipped() }
                        if let note = item.note {
                            Text(note).font(.caption).foregroundColor(.secondary)
                                .padding(8).frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                )
        }
    }

    private var summary: some View {
        VStack(spacing: 2) {
            HStack {
                Label("Intake", systemImage: "fork.knife").foregroundColor(.orange)
                Spacer()
                Text("\(intake) kcal").bold()
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))

            HStack {
                Label("Burned", systemImage: "figure.run").foregroundColor(.green)
                Spacer()
                Text("\(burn) kcal").bold()
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))

            HStack {
                Label("Net", systemImage: "scalemass").foregroundColor(.blue)
                Spacer()
                Text("\(intake - burn) kcal").bold()
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
        }
    }
}

struct TodayView_Previews: PreviewProvider {
    static var previews: some View { TodayView() }
}


