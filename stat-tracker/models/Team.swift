//
//  Team.swift
//  stat-tracker
//
//  Created by Rkos on 29.1.2025.
//

enum NHLTeam: String, CaseIterable, Identifiable, Codable {
    case anaheimDucks = "Anaheim Ducks"
    case arizonaCoyotes = "Arizona Coyotes"
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
    case vancouverCanucks = "Vancouver Canucks"
    case vegasGoldenKnights = "Vegas Golden Knights"
    case washingtonCapitals = "Washington Capitals"
    case winnipegJets = "Winnipeg Jets"
    
    var id: Self { self }
}
