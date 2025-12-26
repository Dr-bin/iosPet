//
//  SyncState.swift
//  iosPet
//

import Foundation

struct CarrierSyncState: Identifiable, Codable {
    let id: UUID
    let carrier: PetCarrier
    var lastState: PetState
    var lastUpdated: Date
    var lastSuccess: Bool
}

