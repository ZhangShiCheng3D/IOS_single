//
//  NotificationManager.swift
//  OneWord
//
//  Schedules an optional daily local reminder to capture one's word. Like the
//  rest of OneWord this touches no network — the reminder is a local
//  UNCalendarNotificationTrigger scheduled entirely on-device.
//

import Foundation
import UserNotifications
import Observation

@MainActor
@Observable
final class NotificationManager {

    private enum Key {
        static let enabled = "reminder.enabled"
        static let hour = "reminder.hour"
        static let minute = "reminder.minute"
    }
    private let requestID = "oneword.daily.reminder"
    private let center = UNUserNotificationCenter.current()

    /// Whether a daily reminder is currently scheduled.
    private(set) var isEnabled: Bool
    /// Set when the user toggled the reminder on but notifications are denied
    /// at the system level — Settings surfaces a one-shot alert for this.
    var permissionDenied = false

    private var hour: Int
    private var minute: Int

    init() {
        let d = UserDefaults.standard
        isEnabled = d.bool(forKey: Key.enabled)
        hour = d.object(forKey: Key.hour) as? Int ?? 21      // default 9:00 PM
        minute = d.object(forKey: Key.minute) as? Int ?? 0
    }

    /// The reminder fire time, exposed as a `Date` for `DatePicker`.
    var time: Date {
        get { Calendar.current.date(from: DateComponents(hour: hour, minute: minute)) ?? Date() }
        set {
            let c = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            hour = c.hour ?? 21
            minute = c.minute ?? 0
            let d = UserDefaults.standard
            d.set(hour, forKey: Key.hour)
            d.set(minute, forKey: Key.minute)
            if isEnabled { schedule() }
        }
    }

    /// Requests authorization (if needed) and schedules the reminder. On denial
    /// the toggle reverts and `permissionDenied` is set for the UI to react to.
    @MainActor
    func enable() async {
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        if granted {
            setEnabled(true)
            schedule()
            permissionDenied = false
        } else {
            setEnabled(false)
            permissionDenied = true
        }
    }

    /// Cancels the reminder.
    func disable() {
        setEnabled(false)
        center.removePendingNotificationRequests(withIdentifiers: [requestID])
    }

    /// Re-syncs on launch: if the user revoked permission in Settings, reflect
    /// that; otherwise re-arm the schedule (pending requests don't survive some
    /// system events).
    func refresh() async {
        let settings = await center.notificationSettings()
        if isEnabled {
            if settings.authorizationStatus == .denied {
                disable()
            } else {
                schedule()
            }
        }
    }

    // MARK: - Private

    private func setEnabled(_ value: Bool) {
        isEnabled = value
        UserDefaults.standard.set(value, forKey: Key.enabled)
    }

    private func schedule() {
        center.removePendingNotificationRequests(withIdentifiers: [requestID])

        let content = UNMutableNotificationContent()
        content.title = String(localized: "notification.title")
        content.body = String(localized: "notification.body")
        content.sound = .default

        var comps = DateComponents()
        comps.hour = hour
        comps.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)

        let request = UNNotificationRequest(identifier: requestID, content: content, trigger: trigger)
        center.add(request)
    }
}
