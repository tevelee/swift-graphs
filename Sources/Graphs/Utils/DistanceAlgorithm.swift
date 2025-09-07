import Foundation
import simd

struct DistanceAlgorithm<Coordinate, Distance> {
    let calculateDistance: (Coordinate, Coordinate) -> Distance
}

extension DistanceAlgorithm {
    static func euclidean<Vector: SIMD>(_ coordinate: @escaping (Coordinate) -> Vector) -> Self where Vector.Scalar: FloatingPoint, Distance == Vector.Scalar {
        .init { a, b in
            (coordinate(a) - coordinate(b)).squared().sum().squareRoot()
        }
    }
    
    static func manhattan<Vector: SIMD>(_ coordinate: @escaping (Coordinate) -> Vector) -> Self where Vector.Scalar: FloatingPoint, Distance == Vector.Scalar {
        .init { a, b in
            (coordinate(a) - coordinate(b)).sum()
        }
    }
}

extension DistanceAlgorithm where Distance == Double {
    static func euclidean(_ coordinate: @escaping (Coordinate) -> SIMD2<Double>) -> Self {
        .init { a, b in
            simd_distance(coordinate(a), coordinate(b))
        }
    }

    static func manhattan(_ coordinate: @escaping (Coordinate) -> SIMD2<Double>) -> Self {
        .init { a, b in
            let d = abs(coordinate(a) - coordinate(b))
            return d.x + d.y
        }
    }
}

private extension SIMD where Scalar: FloatingPoint {
    func squared() -> Self {
        self * self
    }
}
