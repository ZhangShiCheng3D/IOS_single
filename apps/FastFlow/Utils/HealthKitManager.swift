//
//  HealthKitManager.swift
//  FastFlow
//
//  HealthKit 读写封装：体重读取/写入、饮水写入。全部为可选增强，未授权时降级。
//

import Foundation
import HealthKit

/// 体重数据点。
struct WeightSample: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    /// 体重（千克）。
    let kilograms: Double
}

/// HealthKit 管理器（单例）。
@Observable
@MainActor
final class HealthKitManager {
    static let shared = HealthKitManager()

    private let store = HKHealthStore()

    /// 设备是否支持 HealthKit。
    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    /// 最近一次授权后是否已可读写（用于 UI 状态展示）。
    private(set) var isAuthorized = false

    private init() {}

    // 关注的数据类型。
    private var bodyMassType: HKQuantityType { HKQuantityType(.bodyMass) }
    private var waterType: HKQuantityType { HKQuantityType(.dietaryWater) }

    /// 请求 HealthKit 读写授权。
    @discardableResult
    func requestAuthorization() async -> Bool {
        guard isAvailable else { return false }
        let types: Set<HKSampleType> = [bodyMassType, waterType]
        do {
            try await store.requestAuthorization(toShare: types, read: types)
            isAuthorized = true
            return true
        } catch {
            isAuthorized = false
            return false
        }
    }

    // MARK: - 体重

    /// 读取最近 `days` 天的体重样本，按时间升序返回。
    func fetchWeightSamples(days: Int = 90) async -> [WeightSample] {
        guard isAvailable else { return [] }

        let start = Date().dayOffset(-days)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: .now)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: bodyMassType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sort]
            ) { _, samples, _ in
                let result: [WeightSample] = (samples as? [HKQuantitySample] ?? []).map {
                    WeightSample(
                        date: $0.startDate,
                        kilograms: $0.quantity.doubleValue(for: .gramUnit(with: .kilo))
                    )
                }
                continuation.resume(returning: result)
            }
            store.execute(query)
        }
    }

    /// 写入一条体重记录。
    func saveWeight(kilograms: Double, date: Date = .now) async -> Bool {
        guard isAvailable, kilograms > 0 else { return false }
        let quantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: kilograms)
        let sample = HKQuantitySample(
            type: bodyMassType,
            quantity: quantity,
            start: date,
            end: date
        )
        do {
            try await store.save(sample)
            return true
        } catch {
            return false
        }
    }

    // MARK: - 饮水（同步至「健康」）

    /// 将饮水量写入 HealthKit，便于与系统数据汇总。
    func saveWater(milliliters: Int, date: Date = .now) async -> Bool {
        guard isAvailable, milliliters > 0 else { return false }
        let quantity = HKQuantity(unit: .literUnit(with: .milli), doubleValue: Double(milliliters))
        let sample = HKQuantitySample(
            type: waterType,
            quantity: quantity,
            start: date,
            end: date
        )
        do {
            try await store.save(sample)
            return true
        } catch {
            return false
        }
    }
}
