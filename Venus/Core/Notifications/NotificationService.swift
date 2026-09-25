//
//  NotificationService.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import Foundation
import UserNotifications

protocol NotificationServiceProtocol {
    func requestAuthorization() async -> Bool
    func scheduleReminder(text: String, inSeconds timeInterval: TimeInterval) async -> Bool
    func scheduleMorningReadiness(score: Double, stateTitle: String) async
    func scheduleEveningReflection() async
    func scheduleCriticalWindowAlert(window: String) async
    func cancelReadinessReminders()
}

final class NotificationService: NotificationServiceProtocol {
    private let center = UNUserNotificationCenter.current()

    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func scheduleReminder(text: String, inSeconds timeInterval: TimeInterval = 3600) async -> Bool {
        let authorized = await requestAuthorization()
        guard authorized else { return false }

        let content = UNMutableNotificationContent()
        content.title = "Lembrete da Venus \u{23F0}"
        content.body = text
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(timeInterval, 5), repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        do {
            try await center.add(request)
            return true
        } catch {
            return false
        }
    }

    // MARK: - Readiness Proativa

    func scheduleMorningReadiness(score: Double, stateTitle: String) async {
        guard await requestAuthorization() else { return }
        cancelReadinessReminders(prefix: "venus.morning")
        let content = UNMutableNotificationContent()
        content.title = "Sua prontid\u{E3}o de hoje \u{1FA90}"
        let pct = Int((max(0, min(10, score)) / 10 * 100).rounded())
        content.body = "\(pct)% \u{00B7} \(stateTitle). Toque para ver seu ritual ideal."
        content.sound = .default
        content.userInfo = ["kind": "morning-readiness"]
        var comps = DateComponents()
        comps.hour = 8
        comps.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let req = UNNotificationRequest(identifier: "venus.morning.readiness", content: content, trigger: trigger)
        try? await center.add(req)
    }

    func scheduleEveningReflection() async {
        guard await requestAuthorization() else { return }
        cancelReadinessReminders(prefix: "venus.evening")
        let content = UNMutableNotificationContent()
        content.title = "Como foi sua energia hoje? \u{1F319}"
        content.body = "1 minutinho de check-in ajuda a calibrar seu amanh\u{E3}."
        content.sound = .default
        content.userInfo = ["kind": "evening-reflection"]
        var comps = DateComponents()
        comps.hour = 21
        comps.minute = 30
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let req = UNNotificationRequest(identifier: "venus.evening.reflection", content: content, trigger: trigger)
        try? await center.add(req)
    }

    func scheduleCriticalWindowAlert(window: String) async {
        guard await requestAuthorization() else { return }
        cancelReadinessReminders(prefix: "venus.critical")
        let content = UNMutableNotificationContent()
        content.title = "Janela de queda \u{26A1}"
        content.body = "Sua energia costuma cair \(window). Que tal uma pausa de 5 min?"
        content.sound = .default
        content.userInfo = ["kind": "critical-window"]
        // Agenda para daqui 2h como nudge (evita spam diário fixo)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2 * 3600, repeats: false)
        let req = UNNotificationRequest(identifier: "venus.critical.\(UUID().uuidString)", content: content, trigger: trigger)
        try? await center.add(req)
    }

    func cancelReadinessReminders(prefix: String = "venus.") {
        center.getPendingNotificationRequests { reqs in
            let ids = reqs.map(\.identifier).filter { $0.hasPrefix(prefix) }
            self.center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    func cancelReadinessReminders() { cancelReadinessReminders(prefix: "venus.") }
}
