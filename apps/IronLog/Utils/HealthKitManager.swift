//
//  HealthKitManager.swift
//  IronLog
//
//  HealthKit 集成：将完成的力量训练写入「健身记录」(workout)，
//  并可选读取体重用于相对力量展示。全程可选，未授权也不影响核心功能。
//

import Foundation
import HealthKit

@MainActor
final class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()

    private let store = HKHealthStore()

    /// 设备是否支持 HealthKit。
    @Published private(set) var isAvailable = HKHealthStore.isHealthDataAvailable()
    /// 是否已获得写入授权（乐观标记，真实状态以系统为准）。
    @Published var isAuthorized = false

    private init() {}

    private var typesToShare: Set<HKSampleType> {
        var set = Set<HKSampleType>()
        set.insert(HKObjectType.workoutType())
        if let energy = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
            set.insert(energy)
        }
        return set
    }

    private var typesToRead: Set<HKObjectType> {
        var set = Set<HKObjectType>()
        if let bodyMass = HKObjectType.quantityType(forIdentifier: .bodyMass) {
            set.insert(bodyMass)
        }
        return set
    }

    /// 请求 HealthKit 授权。
    func requestAuthorization() async {
        guard isAvailable else { return }
        do {
            try await store.requestAuthorization(toShare: typesToShare, read: typesToRead)
            isAuthorized = true
        } catch {
            isAuthorized = false
        }
    }

    /// 将一次训练写入 HealthKit。
    func save(session: WorkoutSession) async {
        guard isAvailable, isAuthorized else { return }
        let end = session.endDate ?? .now

        let config = HKWorkoutConfiguration()
        config.activityType = .traditionalStrengthTraining

        let builder = HKWorkoutBuilder(healthStore: store, configuration: config, device: .local())
        do {
            try await builder.beginCollection(at: session.date)
            try await builder.endCollection(at: end)
            try await builder.finishWorkout()
        } catch {
            // 静默失败：HealthKit 写入不应阻塞用户主流程。
        }
    }

    /// 读取最近一次体重（kg）。用于相对力量等高级展示。
    func latestBodyMassKg() async -> Double? {
        guard isAvailable,
              let type = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { return nil }

        return await withCheckedContinuation { continuation in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let query = HKSampleQuery(
                sampleType: type,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sort]
            ) { _, samples, _ in
                let kg = (samples?.first as? HKQuantitySample)?
                    .quantity.doubleValue(for: .gramUnit(with: .kilo))
                continuation.resume(returning: kg)
            }
            store.execute(query)
        }
    }
}
