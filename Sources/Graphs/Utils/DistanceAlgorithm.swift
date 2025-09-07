import Foundation
import simd

struct DistanceAlgorithm<Coordinate, Distance> {
    let calculateDistance: (Coordinate, Coordinate) -> Distance
}

extension DistanceAlgorithm {
    static func euclidean<Vertex>(_ coordinate: (Vertex) -> Coordinate) -> Self {
        .init { a, b in
            simd_distance(coordinate(a), coordinate(b))
        }
    }

    static var manhattan: Self {
        .init { a, b in
            let d = abs(a - b)
            return d.x + d.y
        }
    }
}
