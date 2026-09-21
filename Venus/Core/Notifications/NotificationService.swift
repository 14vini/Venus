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
        content.title = "Lembrete da Venus ⏰"
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
}
