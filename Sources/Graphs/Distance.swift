/// A structure representing a distance algorithm between coordinates.
public struct DistanceAlgorithm<Coordinate, Distance> where Distance: Numeric, Distance.Magnitude == Distance {
    /// A closure that calculates the distance between two coordinates.
    public let distance: (Coordinate, Coordinate) -> Distance

    /// Initializes a new distance algorithm with the given distance closure.
    /// - Parameter distance: A closure that takes two coordinates and returns the distance between them.
    @inlinable public init(distance: @escaping (Coordinate, Coordinate) -> Distance) {
        self.distance = distance
    }
}

/// A type alias for a geometric distance algorithm where the distance is a scalar value of a SIMD type.
public typealias GeometricDistanceAlgorithm<Coordinate, Value: SIMD> = DistanceAlgorithm<Coordinate, Value.Scalar>
where Value.Scalar: FloatingPoint

extension DistanceAlgorithm {
    /// Creates a geometric distance algorithm that calculates the Euclidean distance between coordinates.
    /// - Parameter value: A closure that takes a coordinate and returns its SIMD value.
    /// - Returns: A `GeometricDistanceAlgorithm` instance that calculates the Euclidean distance.
    @inlinable public static func euclideanDistance<Value>(of value: @escaping (Coordinate) -> Value) -> Self
    where Self == GeometricDistanceAlgorithm<Coordinate, Value> {
        .init { source, destination in
            (value(source).squared() - value(destination).squared()).sum().squareRoot()
        }
    }

    /// Creates a geometric distance algorithm that calculates the Manhattan distance between coordinates.
    /// - Parameter value: A closure that takes a coordinate and returns its SIMD value.
    /// - Returns: A `GeometricDistanceAlgorithm` instance that calculates the Manhattan distance.
    @inlinable public static func manhattanDistance<Value>(of value: @escaping (Coordinate) -> Value) -> Self
    where Self == GeometricDistanceAlgorithm<Coordinate, Value> {
        .init { source, destination in
            (value(source) - value(destination)).absoluteValue().sum()
        }
    }
}

extension SIMD where Scalar: FloatingPoint {
    /// Returns the element-wise absolute value of the SIMD vector.
    /// - Returns: A SIMD vector where each element is the absolute value of the corresponding element in the original vector.
    @usableFromInline func absoluteValue() -> Self {
        pointwiseMax(.zero, self)
    }

    /// Returns the element-wise square of the SIMD vector.
    /// - Returns: A SIMD vector where each element is the square of the corresponding element in the original vector.
    @usableFromInline func squared() -> Self {
        self * self
    }
}
