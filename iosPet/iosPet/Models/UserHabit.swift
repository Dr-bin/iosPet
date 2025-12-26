//
//  UserHabit.swift
//  iosPet
//

import Foundation

struct UserHabitProfile: Codable {
    var usualSleepHour: Int?
    var usualWakeHour: Int?
    var dailyScreenTimeMinutes: Int?
    var preferredExerciseTime: [String]? // "18:00-19:00"
    var notes: String?
}

