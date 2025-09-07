import Foundation
import simd

struct DistanceAlgorithm<Coordinate, Distance> {
    let calculateDistance: (Coordinate, Coordinate) -> Distance
}

extension DistanceAlgorithm where Coordinate == SIMD2<Double>, Distance == Double {
    static var euclidean: Self {
        .init { a, b in simd_distance(a, b) }
    }

    static var manhattan: Self {
        .init { a, b in
            let d = abs(a - b)
            return d.x + d.y
        }
    }
}
