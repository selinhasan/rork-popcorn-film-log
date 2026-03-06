import Foundation

nonisolated struct ActorStat: Identifiable, Sendable {
    let id: String
    let name: String
    let count: Int
}

nonisolated struct DirectorStat: Identifiable, Sendable {
    let id: String
    let name: String
    let count: Int
}

nonisolated struct GenreStat: Identifiable, Sendable {
    let id: String
    let name: String
    let count: Int
}

struct UserStats {
    let filmsWatched: Int
    let totalMinutes: Int
    let topActors: [ActorStat]
    let topDirectors: [DirectorStat]
    let topGenres: [GenreStat]

    var totalHours: Int { totalMinutes / 60 }
    var totalDays: Int { totalMinutes / 1440 }

    var formattedWatchTime: String {
        if totalMinutes < 60 {
            return "\(totalMinutes)m"
        } else if totalMinutes < 1440 {
            let h = totalMinutes / 60
            let m = totalMinutes % 60
            return m > 0 ? "\(h)h \(m)m" : "\(h)h"
        } else {
            let d = totalMinutes / 1440
            let h = (totalMinutes % 1440) / 60
            return h > 0 ? "\(d)d \(h)h" : "\(d)d"
        }
    }

    static let empty = UserStats(filmsWatched: 0, totalMinutes: 0, topActors: [], topDirectors: [], topGenres: [])
}
