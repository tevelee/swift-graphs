/// A protocol for types that can store vertex properties.
///
/// This protocol defines the interface for storing and retrieving properties
/// associated with vertices in a type-safe manner.
public protocol VertexProperties {
    /// Accesses the value of a specific vertex property.
    ///
    /// - Parameter property: The type of property to access
    /// - Returns: The current value of the property
    subscript<P: VertexProperty>(property: P.Type) -> P.Value { get set }
}
