/// A protocol for types that can store edge properties.
///
/// This protocol defines the interface for storing and retrieving properties
/// associated with edges in a type-safe manner.
public protocol EdgeProperties {
    /// Accesses the value of a specific edge property.
    ///
    /// - Parameter property: The type of property to access
    /// - Returns: The current value of the property
    subscript<P: EdgeProperty>(property: P.Type) -> P.Value { get set }
}
