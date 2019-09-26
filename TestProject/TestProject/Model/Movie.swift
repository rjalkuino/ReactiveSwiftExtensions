//
//  Movie.swift
//  TestProject
//
//  Created by robert john alkuino on 25/09/2019.
//  Copyright © 2019 robert john alkuino. All rights reserved.
//

import UIKit

public struct Movie: Codable {
    let id: Int
    let title: String
    let overview: String
    let releaseDate: Date
    let voteAverage: Double
    let voteCount: Int
    let adult: Bool
    let posterPath:String
    let popularity:Double
    let originalLanguage:String
}
