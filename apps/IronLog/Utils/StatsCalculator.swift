//
//  StatsCalculator.swift
//  IronLog
//
//  容量、1RM、趋势聚合等纯函数计算。无副作用，便于测试与复用。
//

import Foundation

/// 趋势图中的一个数据点。
struct TrendPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

enum StatsCalculator {

    /// 按天聚合容量趋势（用于历史图表）。
    static func volumeTrend(sessions: [WorkoutSession]) -> [TrendPoint] {
        let cal = Calendar.current
        var byDay: [Date: Double] = [:]
        for session in sessions {
            let day = cal.startOfDay(for: session.date)
            byDay[day, default: 0] += session.totalVolume
        }
        return byDay
            .map { TrendPoint(date: $0.key, value: $0.value) }
            .sorted { $0.date < $1.date }
    }

    /// 某动作的估算 1RM 趋势（每次训练取该动作当日最佳 1RM）。
    static func oneRMTrend(exerciseID: String, sessions: [WorkoutSession]) -> [TrendPoint] {
        let cal = Calendar.current
        var byDay: [Date: Double] = [:]
        for session in sessions {
            let day = cal.startOfDay(for: session.date)
            let best = session.sets
                .filter { $0.exercise?.id == exerciseID && $0.isCompleted && !$0.isWarmup }
                .map(\.estimatedOneRepMax)
                .max() ?? 0
            if best > 0 {
                byDay[day] = max(byDay[day] ?? 0, best)
            }
        }
        return byDay
            .map { TrendPoint(date: $0.key, value: $0.value) }
            .sorted { $0.date < $1.date }
    }

    /// 每周训练频次（最近 N 周）。
    static func weeklyFrequency(sessions: [WorkoutSession], weeks: Int = 8) -> [TrendPoint] {
        let cal = Calendar.current
        var byWeek: [Date: Double] = [:]
        for session in sessions {
            guard let weekStart = cal.dateInterval(of: .weekOfYear, for: session.date)?.start else { continue }
            byWeek[weekStart, default: 0] += 1
        }
        return byWeek
            .map { TrendPoint(date: $0.key, value: $0.value) }
            .sorted { $0.date < $1.date }
            .suffix(weeks)
            .map { $0 }
    }
}
