//
//  TMDBEntity.swift
//  Netflix_Clone
//
//  Created by mac on 4/14/26.
//

import Foundation

struct TMDBMovieEntity: Entity {
    let id: Int
    let title: String?
    let name: String?
    let posterPath: String?
    let overview: String?
}
