//
//  NHLTeams.swift
//  stat-tracker
//
//  Created by Rkos on 29.1.2025.
//

import Foundation

enum HockeyTeam: Identifiable, Hashable, Codable {
    case nhl(NHL)
    case smLiiga(SMLiiga)
    case shl(SHL)
    case allsvenskan(Allsvenskan)
    case nationalLeague(NationalLeague)
    case del(DEL)
    case extraliga(Extraliga)

    // MARK: - Nested League Enums

    enum NHL: String, CaseIterable, Codable {
        case anaheimDucks = "Anaheim Ducks"
        case bostonBruins = "Boston Bruins"
        case buffaloSabres = "Buffalo Sabres"
        case calgaryFlames = "Calgary Flames"
        case carolinaHurricanes = "Carolina Hurricanes"
        case chicagoBlackhawks = "Chicago Blackhawks"
        case coloradoAvalanche = "Colorado Avalanche"
        case columbusBlueJackets = "Columbus Blue Jackets"
        case dallasStars = "Dallas Stars"
        case detroitRedWings = "Detroit Red Wings"
        case edmontonOilers = "Edmonton Oilers"
        case floridaPanthers = "Florida Panthers"
        case losAngelesKings = "Los Angeles Kings"
        case minnesotaWild = "Minnesota Wild"
        case montrealCanadiens = "Montreal Canadiens"
        case nashvillePredators = "Nashville Predators"
        case newJerseyDevils = "New Jersey Devils"
        case newYorkIslanders = "New York Islanders"
        case newYorkRangers = "New York Rangers"
        case ottawaSenators = "Ottawa Senators"
        case philadelphiaFlyers = "Philadelphia Flyers"
        case pittsburghPenguins = "Pittsburgh Penguins"
        case sanJoseSharks = "San Jose Sharks"
        case seattleKraken = "Seattle Kraken"
        case stLouisBlues = "St. Louis Blues"
        case tampaBayLightning = "Tampa Bay Lightning"
        case torontoMapleLeafs = "Toronto Maple Leafs"
        case utahHC = "Utah Hockey Club"
        case vancouverCanucks = "Vancouver Canucks"
        case vegasGoldenKnights = "Vegas Golden Knights"
        case washingtonCapitals = "Washington Capitals"
        case winnipegJets = "Winnipeg Jets"
    }

    enum SMLiiga: String, CaseIterable, Codable {
        case hifk = "HIFK"
        case hpk = "HPK"
        case ilves = "Ilves"
        case jukurit = "Jukurit"
        case jyp = "JYP"
        case kalpa = "KalPa"
        case kiekkoEspoo = "Kiekko-Espoo"
        case kookoo = "KooKoo"
        case karpat = "Kärpät"
        case lukko = "Lukko"
        case pelicans = "Pelicans"
        case saipa = "SaiPa"
        case sport = "Sport"
        case tappara = "Tappara"
        case tps = "TPS"
        case assat = "Ässät"
    }

    enum SHL: String, CaseIterable, Codable {
        case brynasIF = "Brynäs IF"
        case frolundaHC = "Frölunda HC"
        case farjestadBK = "Färjestad BK"
        case hv71 = "HV71"
        case leksandsIF = "Leksands IF"
        case linkopingHC = "Linköping HC"
        case luleaHF = "Luleå HF"
        case malmoRedhawks = "Malmö Redhawks"
        case modoHockey = "MoDo Hockey"
        case orebroHK = "Örebro HK"
        case rogleBK = "Rögle BK"
        case skellefteaAIK = "Skellefteå AIK"
        case timraIK = "Timrå IK"
        case vaxjoLakers = "Växjö Lakers"
    }

    enum Allsvenskan: String, CaseIterable, Codable {
        case aik = "AIK"
        case almtunaIS = "Almtuna IS"
        case bikKarlskoga = "BIK Karlskoga"
        case djurgardensIF = "Djurgårdens IF"
        case ifBjorkloven = "IF Björklöven"
        case ikOskarshamn = "IK Oskarshamn"
        case kalmarHC = "Kalmar HC"
        case moraIK = "Mora IK"
        case nybroVikings = "Nybro Vikings IF"
        case sodertaljeSK = "Södertälje SK"
        case tingsrydsAIF = "Tingsryds AIF"
        case vimmerbyHC = "Vimmerby HC"
        case vasterasIK = "Västerås IK"
        case ostersundsIK = "Östersunds IK"
    }

    enum NationalLeague: String, CaseIterable, Codable {
        case hcAjoie = "HC Ajoie"
        case hcAmbriPiotta = "HC Ambrì-Piotta"
        case scBern = "SC Bern"
        case ehcBielBienne = "EHC Biel-Bienne"
        case hcDavos = "HC Davos"
        case fribourgGotteron = "Fribourg-Gottéron"
        case geneveServette = "Genève-Servette HC"
        case ehcKloten = "EHC Kloten"
        case sclTigers = "SCL Tigers"
        case lausanneHC = "Lausanne HC"
        case hcLugano = "HC Lugano"
        case scrjLakers = "SC Rapperswil-Jona Lakers"
        case zscLions = "ZSC Lions"
        case evZug = "EV Zug"
    }

    enum DEL: String, CaseIterable, Codable {
        case augsburgerPanther = "Augsburger Panther"
        case eisbarenBerlin = "Eisbären Berlin"
        case fischtownPinguins = "Fischtown Pinguins"
        case dusseldorferEG = "Düsseldorfer EG"
        case lowenFrankfurt = "Löwen Frankfurt"
        case ercIngolstadt = "ERC Ingolstadt"
        case iserlohnRoosters = "Iserlohn Roosters"
        case kolnerHaie = "Kölner Haie"
        case adlerMannheim = "Adler Mannheim"
        case redBullMunchen = "EHC Red Bull München"
        case nurnbergIceTigers = "Nürnberg Ice Tigers"
        case schwenningerWildWings = "Schwenninger Wild Wings"
        case straubingTigers = "Straubing Tigers"
        case grizzlysWolfsburg = "Grizzlys Wolfsburg"
    }

    enum Extraliga: String, CaseIterable, Codable {
        case hcKometaBrno = "HC Kometa Brno"
        case hcOlomouc = "HC Olomouc"
        case mountfieldHK = "Mountfield HK"
        case hcEnergieKarlovyVary = "HC Energie Karlovy Vary"
        case bkMladaBoleslav = "BK Mladá Boleslav"
        case biliTygriLiberec = "Bílí Tygři Liberec"
        case hcVervaLitvinov = "HC Verva Litvínov"
        case hcDynamoPardubice = "HC Dynamo Pardubice"
        case hcSkodaPlzen = "HC Škoda Plzeň"
        case rytiriKladno = "Rytíři Kladno"
        case hcSpartaPraha = "HC Sparta Praha"
        case hcOcelariTrinec = "HC Oceláři Třinec"
        case hcVitkoviceRidera = "HC Vítkovice Ridera"
        case motorCeskeBudejovice = "Banes Motor České Budějovice"
    }

    // MARK: - 3. Unified Properties

    var id: String {
        switch self {
        case let .nhl(team): return "NHL_\(team.rawValue)"
        case let .smLiiga(team): return "LIIGA_\(team.rawValue)"
        case let .shl(team): return "SHL_\(team.rawValue)"
        case let .allsvenskan(team): return "ALLS_\(team.rawValue)"
        case let .nationalLeague(team): return "NL_\(team.rawValue)"
        case let .del(team): return "DEL_\(team.rawValue)"
        case let .extraliga(team): return "CZE_\(team.rawValue)"
        }
    }

    var displayName: String {
        switch self {
        case let .nhl(team): return team.rawValue
        case let .smLiiga(team): return team.rawValue
        case let .shl(team): return team.rawValue
        case let .allsvenskan(team): return team.rawValue
        case let .nationalLeague(team): return team.rawValue
        case let .del(team): return team.rawValue
        case let .extraliga(team): return team.rawValue
        }
    }

    var leagueName: String {
        switch self {
        case .nhl: return "NHL"
        case .smLiiga: return "SM-Liiga"
        case .shl: return "SHL"
        case .allsvenskan: return "HockeyAllsvenskan"
        case .nationalLeague: return "National League"
        case .del: return "DEL"
        case .extraliga: return "Tipsport Extraliga"
        }
    }
}

// MARK: HockeyTeam + CaseIterable

extension HockeyTeam: CaseIterable {
    static var allCases: [HockeyTeam] {
        let nhl = NHL.allCases.map { HockeyTeam.nhl($0) }
        let liiga = SMLiiga.allCases.map { HockeyTeam.smLiiga($0) }
        let shl = SHL.allCases.map { HockeyTeam.shl($0) }
        let allsvenskan = Allsvenskan.allCases.map { HockeyTeam.allsvenskan($0) }
        let nl = NationalLeague.allCases.map { HockeyTeam.nationalLeague($0) }
        let del = DEL.allCases.map { HockeyTeam.del($0) }
        let extraliga = Extraliga.allCases.map { HockeyTeam.extraliga($0) }

        return nhl + liiga + shl + allsvenskan + nl + del + extraliga
    }
}

extension HockeyTeam {
    static func teams(inLeague league: String) -> [HockeyTeam] {
        return allCases.filter { $0.leagueName == league }
    }

    static let leagueOrder = [
        "NHL",
        "SM-Liiga",
        "SHL",
        "HockeyAllsvenskan",
        "National League",
        "DEL",
        "Tipsport Extraliga",
    ]
}
