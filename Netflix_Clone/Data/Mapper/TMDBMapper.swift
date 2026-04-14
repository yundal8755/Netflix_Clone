//
//  TMDBMapper.swift
//  Netflix_Clone
//
//  Created by mac on 4/14/26.
//

import Foundation

protocol TMDBMapperType: Sendable {
    func map(_ dtos: [TMDBMovieDTO]) -> [TMDBMovieEntity]
    func map(_ dto: TMDBMovieDTO) -> TMDBMovieEntity
}

struct TMDBMapper: TMDBMapperType {
    
    func map(_ dtos: [TMDBMovieDTO]) -> [TMDBMovieEntity] {
        dtos.map(map)
    }

    func map(_ dto: TMDBMovieDTO) -> TMDBMovieEntity {
        TMDBMovieEntity(
            id: dto.id,
            title: dto.title,
            name: dto.name,
            posterPath: dto.posterPath,
            overview: dto.overview
        )
    }
}
