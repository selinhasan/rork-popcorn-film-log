import Foundation

enum MockDataService {
    static let popularFilms: [Film] = [
        Film(id: "1", title: "The Shawshank Redemption", year: "1994", genre: ["Drama"], director: "Frank Darabont", cast: ["Tim Robbins", "Morgan Freeman"], synopsis: "A banker convicted of uxoricide forms a friendship over a quarter century with a hardened convict, while maintaining his innocence and trying to remain hopeful through simple compassion.", posterURL: "https://image.tmdb.org/t/p/w500/9cjIGRQL0ohUhGkbQ25z6lsinT5.jpg", runtime: "2h 22m", averageRating: 4.7),
        Film(id: "2", title: "The Godfather", year: "1972", genre: ["Crime", "Drama"], director: "Francis Ford Coppola", cast: ["Marlon Brando", "Al Pacino"], synopsis: "The aging patriarch of an organized crime dynasty transfers control of his clandestine empire to his reluctant youngest son.", posterURL: "https://image.tmdb.org/t/p/w500/3bhkrj58Vtu7enYsRolD1fZdja1.jpg", runtime: "2h 55m", averageRating: 4.6),
        Film(id: "3", title: "The Dark Knight", year: "2008", genre: ["Action", "Crime", "Drama"], director: "Christopher Nolan", cast: ["Christian Bale", "Heath Ledger"], synopsis: "When the menace known as the Joker wreaks havoc and chaos on the people of Gotham, Batman must accept one of the greatest psychological and physical tests of his ability to fight injustice.", posterURL: "https://image.tmdb.org/t/p/w500/qJ2tW6WMUDux911BTUgMe1bqxD.jpg", runtime: "2h 32m", averageRating: 4.5),
        Film(id: "4", title: "Pulp Fiction", year: "1994", genre: ["Crime", "Drama"], director: "Quentin Tarantino", cast: ["John Travolta", "Uma Thurman", "Samuel L. Jackson"], synopsis: "The lives of two mob hitmen, a boxer, a gangster and his wife, and a pair of diner bandits intertwine in four tales of violence and redemption.", posterURL: "https://image.tmdb.org/t/p/w500/d5iIlFn5s0ImszYzBPb8JPIfbXD.jpg", runtime: "2h 34m", averageRating: 4.4),
        Film(id: "5", title: "Inception", year: "2010", genre: ["Action", "Sci-Fi"], director: "Christopher Nolan", cast: ["Leonardo DiCaprio", "Joseph Gordon-Levitt"], synopsis: "A thief who steals corporate secrets through the use of dream-sharing technology is given the inverse task of planting an idea into the mind of a C.E.O.", posterURL: "https://image.tmdb.org/t/p/w500/edv5CZvWj09upOsy2Y6IwDhK8bt.jpg", runtime: "2h 28m", averageRating: 4.3),
        Film(id: "6", title: "Forrest Gump", year: "1994", genre: ["Drama", "Romance"], director: "Robert Zemeckis", cast: ["Tom Hanks", "Robin Wright"], synopsis: "The presidencies of Kennedy and Johnson, the Vietnam War, the Watergate scandal and other historical events unfold from the perspective of an Alabama man with an IQ of 75.", posterURL: "https://image.tmdb.org/t/p/w500/arw2vcBveWOVZr6pxd9XTd1TdQa.jpg", runtime: "2h 22m", averageRating: 4.4),
        Film(id: "7", title: "Parasite", year: "2019", genre: ["Comedy", "Drama", "Thriller"], director: "Bong Joon-ho", cast: ["Song Kang-ho", "Choi Woo-shik"], synopsis: "Greed and class discrimination threaten the newly formed symbiotic relationship between the wealthy Park family and the destitute Kim clan.", posterURL: "https://image.tmdb.org/t/p/w500/7IiTTgloJzvGI1TAYymCfbfl3vT.jpg", runtime: "2h 12m", averageRating: 4.5),
        Film(id: "8", title: "Interstellar", year: "2014", genre: ["Adventure", "Drama", "Sci-Fi"], director: "Christopher Nolan", cast: ["Matthew McConaughey", "Anne Hathaway"], synopsis: "When Earth becomes uninhabitable in the future, a farmer and ex-NASA pilot is tasked with piloting a spacecraft along with a team of researchers to find a new planet for humans.", posterURL: "https://image.tmdb.org/t/p/w500/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg", runtime: "2h 49m", averageRating: 4.4),
        Film(id: "9", title: "The Grand Budapest Hotel", year: "2014", genre: ["Adventure", "Comedy", "Crime"], director: "Wes Anderson", cast: ["Ralph Fiennes", "Tony Revolori"], synopsis: "A writer encounters the owner of an aging high-class hotel, who tells him of his early years serving as a lobby boy in the hotel's glorious years under an exceptional concierge.", posterURL: "https://image.tmdb.org/t/p/w500/eWdyYQreja6JGCzqHWXpWHDrrPo.jpg", runtime: "1h 39m", averageRating: 4.2),
        Film(id: "10", title: "Whiplash", year: "2014", genre: ["Drama", "Music"], director: "Damien Chazelle", cast: ["Miles Teller", "J.K. Simmons"], synopsis: "A promising young drummer enrolls at a cut-throat music conservatory where his dreams of greatness are mentored by an instructor who will stop at nothing to realize a student's potential.", posterURL: "https://image.tmdb.org/t/p/w500/7fn624j5lj3xTme2SgiLCeuedmO.jpg", runtime: "1h 46m", averageRating: 4.4),
        Film(id: "11", title: "Everything Everywhere All at Once", year: "2022", genre: ["Action", "Adventure", "Comedy"], director: "Daniel Kwan, Daniel Scheinert", cast: ["Michelle Yeoh", "Ke Huy Quan"], synopsis: "A middle-aged Chinese immigrant is swept up into an insane adventure in which she alone can save existence by exploring other universes and connecting with the lives she could have led.", posterURL: "https://image.tmdb.org/t/p/w500/w3LxiVYdWWRvEVdn5RYq6jIqkb1.jpg", runtime: "2h 19m", averageRating: 4.3),
        Film(id: "12", title: "Oppenheimer", year: "2023", genre: ["Biography", "Drama", "History"], director: "Christopher Nolan", cast: ["Cillian Murphy", "Emily Blunt", "Robert Downey Jr."], synopsis: "The story of American scientist J. Robert Oppenheimer and his role in the development of the atomic bomb.", posterURL: "https://image.tmdb.org/t/p/w500/8Gxv8gSFCU0XGDykEGv7zR1n2ua.jpg", runtime: "3h", averageRating: 4.5),
        Film(id: "13", title: "Dune: Part Two", year: "2024", genre: ["Action", "Adventure", "Drama"], director: "Denis Villeneuve", cast: ["Timothée Chalamet", "Zendaya"], synopsis: "Paul Atreides unites with Chani and the Fremen while on a warpath of revenge against the conspirators who destroyed his family.", posterURL: "https://image.tmdb.org/t/p/w500/8b8R8l88Qje9dn9OE8PY05Nez7.jpg", runtime: "2h 46m", averageRating: 4.4),
        Film(id: "14", title: "Poor Things", year: "2023", genre: ["Comedy", "Drama", "Romance"], director: "Yorgos Lanthimos", cast: ["Emma Stone", "Mark Ruffalo", "Willem Dafoe"], synopsis: "The incredible tale about the fantastical evolution of Bella Baxter, a young woman brought back to life by the brilliant and unorthodox scientist Dr. Godwin Baxter.", posterURL: "https://image.tmdb.org/t/p/w500/kCGlIMHnOm8JPXq3rXM6c5wMxcT.jpg", runtime: "2h 21m", averageRating: 3.9),
        Film(id: "15", title: "The Brutalist", year: "2025", genre: ["Drama"], director: "Brady Corbet", cast: ["Adrien Brody", "Felicity Jones"], synopsis: "A visionary architect escapes post-war Europe and arrives in America to rebuild his life.", posterURL: "https://image.tmdb.org/t/p/w500/zp5AEZmGOsCtelKeFmRtiPaWbPP.jpg", runtime: "3h 35m", averageRating: 4.1),
    ]

    static let tvShows: [Film] = [
        Film(id: "tv1", title: "Breaking Bad", year: "2008", genre: ["Crime", "Drama", "Thriller"], director: "Vince Gilligan", cast: ["Bryan Cranston", "Aaron Paul"], synopsis: "A chemistry teacher diagnosed with inoperable lung cancer turns to manufacturing and selling methamphetamine with a former student to secure his family's future.", posterURL: "https://image.tmdb.org/t/p/w500/ggFHVNu6YYI5L9pCfOacjizRGt.jpg", runtime: "49m", isTV: true, averageRating: 4.8),
        Film(id: "tv2", title: "The Bear", year: "2022", genre: ["Comedy", "Drama"], director: "Christopher Storer", cast: ["Jeremy Allen White", "Ayo Edebiri"], synopsis: "A young chef from the fine dining world returns to Chicago to run his family's sandwich shop.", posterURL: "https://image.tmdb.org/t/p/w500/sHFlZTDMrL85mAJHqIbMj9HnKgo.jpg", runtime: "30m", isTV: true, averageRating: 4.3),
        Film(id: "tv3", title: "Severance", year: "2022", genre: ["Drama", "Mystery", "Sci-Fi"], director: "Dan Erickson", cast: ["Adam Scott", "Britt Lower"], synopsis: "Mark leads a team of office workers whose memories have been surgically divided between their work and personal lives.", posterURL: "https://image.tmdb.org/t/p/w500/lFf6LLrQjYZEMBsGCsbWMPHBxGo.jpg", runtime: "55m", isTV: true, averageRating: 4.4),
    ]

    static let allContent: [Film] = popularFilms + tvShows

    static let genres = ["Action", "Adventure", "Animation", "Biography", "Comedy", "Crime", "Drama", "Horror", "Music", "Mystery", "Romance", "Sci-Fi", "Thriller"]

    static let defaultAvatars = [
        "avatar_1", "avatar_2", "avatar_3", "avatar_4", "avatar_5",
        "avatar_6", "avatar_7", "avatar_8", "avatar_9", "avatar_10"
    ]

    static let sampleBuddies: [UserProfile] = [
        UserProfile(id: "buddy1", username: "filmfanatic42", email: "film@example.com", profileImageName: "avatar_2", topFiveFilms: Array(popularFilms.prefix(5)), buddyIds: ["currentUser"]),
        UserProfile(id: "buddy2", username: "cinemaqueen", email: "cinema@example.com", profileImageName: "avatar_7", topFiveFilms: Array(popularFilms.suffix(5)), buddyIds: ["currentUser"]),
        UserProfile(id: "buddy3", username: "reelwatcher", email: "reel@example.com", profileImageName: "avatar_9", topFiveFilms: [popularFilms[2], popularFilms[4], popularFilms[6], popularFilms[8], popularFilms[10]], buddyIds: ["currentUser"]),
    ]

    static let sampleBuddyLogs: [LogEntry] = [
        LogEntry(id: "bl1", film: popularFilms[12], rating: 4.5, review: "Absolutely stunning sequel. The visuals and scale are breathtaking.", dateWatched: Date().addingTimeInterval(-3600), userId: "buddy1", username: "filmfanatic42"),
        LogEntry(id: "bl2", film: popularFilms[11], rating: 5.0, review: "A masterpiece. Nolan at his absolute best.", dateWatched: Date().addingTimeInterval(-7200), userId: "buddy2", username: "cinemaqueen"),
        LogEntry(id: "bl3", film: popularFilms[6], rating: 4.0, review: "Brilliant social commentary. The twist is unforgettable.", dateWatched: Date().addingTimeInterval(-86400), userId: "buddy3", username: "reelwatcher"),
        LogEntry(id: "bl4", film: popularFilms[9], rating: 5.0, review: "J.K. Simmons is absolutely terrifying. Pure tension.", dateWatched: Date().addingTimeInterval(-172800), userId: "buddy1", username: "filmfanatic42"),
        LogEntry(id: "bl5", film: popularFilms[13], rating: 3.5, review: "Visually creative but not for everyone.", dateWatched: Date().addingTimeInterval(-259200), userId: "buddy2", username: "cinemaqueen"),
    ]

    static let samplePosts: [BuddyPost] = [
        BuddyPost(id: "p1", userId: "buddy1", username: "filmfanatic42", profileImageName: "avatar_2", text: "Just finished a Nolan marathon! Dark Knight is still the GOAT. What's your favourite Nolan film?", likeCount: 12, comments: [
            PostComment(userId: "buddy2", username: "cinemaqueen", text: "Interstellar for me, always!"),
            PostComment(userId: "buddy3", username: "reelwatcher", text: "Inception. No contest."),
        ], date: Date().addingTimeInterval(-1800)),
        BuddyPost(id: "p2", userId: "buddy2", username: "cinemaqueen", profileImageName: "avatar_7", text: "The Brutalist is a must-watch this year. Brady Corbet has created something truly special.", likeCount: 8, date: Date().addingTimeInterval(-43200)),
        BuddyPost(id: "p3", userId: "buddy3", username: "reelwatcher", profileImageName: "avatar_9", text: "Started rewatching Breaking Bad for the third time. It somehow gets better every time.", likeCount: 24, comments: [
            PostComment(userId: "buddy1", username: "filmfanatic42", text: "The best show ever made, hands down."),
        ], date: Date().addingTimeInterval(-86400)),
    ]

    static let articles: [ArticleItem] = [
        ArticleItem(title: "The Rise of A24: How an Independent Studio Changed Hollywood", source: "Film Quarterly", timeAgo: "2h ago"),
        ArticleItem(title: "Why Practical Effects Are Making a Comeback", source: "Cinephile Magazine", timeAgo: "5h ago"),
        ArticleItem(title: "2025 Oscar Predictions: Our Early Picks", source: "Screen Daily", timeAgo: "1d ago"),
        ArticleItem(title: "The Art of the Long Take: Cinema's Most Ambitious Shots", source: "Film Comment", timeAgo: "2d ago"),
        ArticleItem(title: "How Streaming Changed the Way We Watch Films", source: "The Reel Review", timeAgo: "3d ago"),
    ]
}

nonisolated struct ArticleItem: Identifiable, Hashable, Sendable {
    let id = UUID().uuidString
    let title: String
    let source: String
    let timeAgo: String
}
