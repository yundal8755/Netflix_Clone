//
//  TMDBMapper.swift
//  Netflix_Clone
//
//  Created by mac on 4/14/26.
//

import Foundation

protocol TMDBMapperType: Sendable {
    func map(_ dtos: [MovieResponseDTO]) -> [TMDBMovieEntity]
    func map(_ dto: MovieResponseDTO) -> TMDBMovieEntity
}

struct TMDBMapper: TMDBMapperType {
    
    func map(_ dtos: [MovieResponseDTO]) -> [TMDBMovieEntity] {
        dtos.map(map)
    }

    func map(_ dto: MovieResponseDTO) -> TMDBMovieEntity {
        TMDBMovieEntity(
            id: dto.id,
            title: dto.title,
            name: dto.name,
            posterPath: dto.posterPath,
            overview: dto.overview
        )
    }
}
