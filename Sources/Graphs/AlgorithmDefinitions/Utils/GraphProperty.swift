/// A protocol for defining property types that can be associated with graph elements.
///
/// Conforming types must provide a default value that is used when a property has not been explicitly set.
/// Use ``VertexProperty`` for vertex properties and ``EdgeProperty`` for edge properties.
public protocol GraphProperty<Value> {
    associatedtype Value

    /// The default value for this property.
    static var defaultValue: Value { get }
}

/// A protocol for property types that can be associated with graph vertices.
public protocol VertexProperty<Value>: GraphProperty {}

/// A protocol for property types that can be associated with graph edges.
public protocol EdgeProperty<Value>: GraphProperty {}

extension Optional: GraphProperty where Wrapped: GraphProperty {
    @inlinable
    public static var defaultValue: Self { nil }
}
extension Optional: VertexProperty where Wrapped: VertexProperty {}
extension Optional: EdgeProperty where Wrapped: EdgeProperty {}
