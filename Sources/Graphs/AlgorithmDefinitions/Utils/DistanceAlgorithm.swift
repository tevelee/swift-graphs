import Foundation
import simd

/// A distance calculation algorithm for geometric coordinates.
///
/// DistanceAlgorithm provides various distance calculation methods for coordinates,
/// supporting both Euclidean and Manhattan distance calculations.
public struct DistanceAlgorithm<Coordinate, Distance> {
    public let calculateDistance: (Coordinate, Coordinate) -> Distance
    
    @inlinable
    public init(calculateDistance: @escaping (Coordinate, Coordinate) -> Distance) {
        self.calculateDistance = calculateDistance
    }
}

extension DistanceAlgorithm {
    /// Creates a Euclidean distance calculator for SIMD vectors.
    ///
    /// - Parameter coordinate: A function that extracts SIMD coordinates from a coordinate
    /// - Returns: A distance algorithm that calculates Euclidean distance
    @inlinable
    public static func euclidean<Vector: SIMD>(_ coordinate: @escaping (Coordinate) -> Vector) -> Self where Vector.Scalar: FloatingPoint, Distance == Vector.Scalar {
        .init { a, b in
            (coordinate(a) - coordinate(b)).squared().sum().squareRoot()
        }
    }
    
    /// Creates a Manhattan distance calculator for SIMD vectors.
    ///
    /// - Parameter coordinate: A function that extracts SIMD coordinates from a coordinate
    /// - Returns: A distance algorithm that calculates Manhattan distance
    @inlinable
    public static func manhattan<Vector: SIMD>(_ coordinate: @escaping (Coordinate) -> Vector) -> Self where Vector.Scalar: FloatingPoint, Distance == Vector.Scalar {
        .init { a, b in
            (coordinate(a) - coordinate(b)).sum()
        }
    }
}

extension DistanceAlgorithm where Distance == Double {
    /// Creates a Euclidean distance calculator for 2D double coordinates.
    ///
    /// - Parameter coordinate: A function that extracts 2D coordinates from a coordinate
    /// - Returns: A distance algorithm that calculates Euclidean distance
    @inlinable
    public static func euclidean(_ coordinate: @escaping (Coordinate) -> SIMD2<Double>) -> Self {
        .init { a, b in
            simd_distance(coordinate(a), coordinate(b))
        }
    }

    /// Creates a Manhattan distance calculator for 2D double coordinates.
    ///
    /// - Parameter coordinate: A function that extracts 2D coordinates from a coordinate
    /// - Returns: A distance algorithm that calculates Manhattan distance
    @inlinable
    public static func manhattan(_ coordinate: @escaping (Coordinate) -> SIMD2<Double>) -> Self {
        .init { a, b in
            let d = abs(coordinate(a) - coordinate(b))
            return d.x + d.y
        }
    }
}

extension SIMD where Scalar: FloatingPoint {
    @usableFromInline
    func squared() -> Self {
        self * self
    }
}
