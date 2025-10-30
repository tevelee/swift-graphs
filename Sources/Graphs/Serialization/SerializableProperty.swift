/// A protocol for graph properties that can be serialized.
///
/// Conforming types must have a `Codable` value type, enabling them to be
/// serialized to various graph file formats like DOT, JSON, and GraphML.
public protocol SerializableProperty<Value>: GraphProperty where Value: Codable {
    /// The name of the property used during serialization.
    ///
    /// Defaults to the type name of the property.
    static var name: String { get }
}

extension SerializableProperty {
    /// Default implementation returns the type name.
    @inlinable
    public static var name: String {
        "\(self)"
    }
}
