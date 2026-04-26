//
//  FIFATeams.swift
//  stat-tracker
//
//  Created by Roni Koskinen on 26.4.2026.
//

import Foundation

enum FifaTeam: Identifiable, Hashable, Codable {
    case premierLeague(PremierLeague)
    case laLiga(LaLiga)
    case serieA(SerieA)
    case bundesliga(Bundesliga)
    case ligue1(Ligue1)
    case nationalTeams(NationalTeams)

    // MARK: - Nested League Enums

    enum PremierLeague: String, CaseIterable, Codable {
        case arsenal = "Arsenal"
        case astonVilla = "Aston Villa"
        case chelsea = "Chelsea"
        case everton = "Everton"
        case liverpool = "Liverpool"
        case manCity = "Manchester City"
        case manUnited = "Manchester United"
        case newcastle = "Newcastle United"
        case tottenham = "Tottenham Hotspur"
        case westHam = "West Ham United"
    }

    enum LaLiga: String, CaseIterable, Codable {
        case athleticClub = "Athletic Club"
        case atleticoMadrid = "Atlético Madrid"
        case barcelona = "FC Barcelona"
        case realBetis = "Real Betis"
        case realMadrid = "Real Madrid"
        case realSociedad = "Real Sociedad"
        case sevilla = "Sevilla"
        case valencia = "Valencia CF"
    }

    enum SerieA: String, CaseIterable, Codable {
        case acMilan = "AC Milan"
        case atalanta = "Atalanta"
        case fiorentina = "Fiorentina"
        case interMilan = "Inter Milan"
        case juventus = "Juventus"
        case lazio = "Lazio"
        case napoli = "Napoli"
        case roma = "AS Roma"
    }

    enum Bundesliga: String, CaseIterable, Codable {
        case bayerLeverkusen = "Bayer Leverkusen"
        case bayernMunich = "Bayern Munich"
        case bvb = "Borussia Dortmund"
        case eintrachtFrankfurt = "Eintracht Frankfurt"
        case rbLeipzig = "RB Leipzig"
        case stuttgart = "VfB Stuttgart"
    }

    enum Ligue1: String, CaseIterable, Codable {
        case asMonaco = "AS Monaco"
        case lille = "LOSC Lille"
        case lyon = "Olympique Lyonnais"
        case marseille = "Olympique de Marseille"
        case psg = "Paris Saint-Germain"
    }

    enum NationalTeams: String, CaseIterable, Codable {
        case argentina = "Argentina"
        case belgium = "Belgium"
        case brazil = "Brazil"
        case croatia = "Croatia"
        case england = "England"
        case france = "France"
        case germany = "Germany"
        case italy = "Italy"
        case netherlands = "Netherlands"
        case portugal = "Portugal"
        case spain = "Spain"
        case usa = "United States"
    }

    // MARK: - Unified Properties

    var id: String {
        switch self {
        case let .premierLeague(team): return "PL_\(team.rawValue)"
        case let .laLiga(team): return "LALIGA_\(team.rawValue)"
        case let .serieA(team): return "SERIEA_\(team.rawValue)"
        case let .bundesliga(team): return "BUNDES_\(team.rawValue)"
        case let .ligue1(team): return "LIGUE1_\(team.rawValue)"
        case let .nationalTeams(team): return "INT_\(team.rawValue)"
        }
    }

    var displayName: String {
        switch self {
        case let .premierLeague(team): return team.rawValue
        case let .laLiga(team): return team.rawValue
        case let .serieA(team): return team.rawValue
        case let .bundesliga(team): return team.rawValue
        case let .ligue1(team): return team.rawValue
        case let .nationalTeams(team): return team.rawValue
        }
    }

    var leagueName: String {
        switch self {
        case .premierLeague: return "Premier League"
        case .laLiga: return "La Liga"
        case .serieA: return "Serie A"
        case .bundesliga: return "Bundesliga"
        case .ligue1: return "Ligue 1"
        case .nationalTeams: return "National Teams"
        }
    }
}

// MARK: FifaTeam + CaseIterable

extension FifaTeam: CaseIterable {
    static var allCases: [FifaTeam] {
        let pl = PremierLeague.allCases.map { FifaTeam.premierLeague($0) }
        let laLiga = LaLiga.allCases.map { FifaTeam.laLiga($0) }
        let serieA = SerieA.allCases.map { FifaTeam.serieA($0) }
        let bundesliga = Bundesliga.allCases.map { FifaTeam.bundesliga($0) }
        let ligue1 = Ligue1.allCases.map { FifaTeam.ligue1($0) }
        let national = NationalTeams.allCases.map { FifaTeam.nationalTeams($0) }

        return pl + laLiga + serieA + bundesliga + ligue1 + national
    }
}

extension FifaTeam {
    static func teams(inLeague league: String) -> [FifaTeam] {
        return allCases.filter { $0.leagueName == league }
    }

    static let leagueOrder = [
        "Premier League",
        "La Liga",
        "Serie A",
        "Bundesliga",
        "Ligue 1",
        "National Teams",
    ]
}
