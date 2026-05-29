/// A property map implementation using a dictionary for storage.
///
/// This implementation provides efficient key-value storage with a default value
/// for keys that haven't been explicitly set. It's commonly used for storing
/// vertex and edge properties in graphs.
public struct DictionaryPropertyMap<Key: Hashable, Value> {
    @usableFromInline
    var values: [Key: Value] = [:]
    public let defaultValue: Value

    /// Creates a new dictionary property map.
    ///
    /// - Parameter defaultValue: The value to return for keys that haven't been set
    @inlinable
    public init(defaultValue: Value) {
        self.defaultValue = defaultValue
    }
}

extension DictionaryPropertyMap: MutablePropertyMap {
    @inlinable
    public subscript(key: Key) -> Value {
        set { values[key] = newValue }
        _read {
            yield values[key] ?? defaultValue
        }
        _modify {
            var value = values[key] ?? defaultValue
            defer { values[key] = value }
            yield &value
        }
    }
}

extension DictionaryPropertyMap: Sendable where Key: Sendable, Value: Sendable {}

extension Graph where VertexDescriptor: Hashable {
    @inlinable
    public func makeVertexPropertyMap() -> DictionaryPropertyMap<VertexDescriptor, VertexPropertyValues> {
        .init(defaultValue: .init())
    }
}

extension Graph where EdgeDescriptor: Hashable {
    @inlinable
    public func makeEdgePropertyMap() -> DictionaryPropertyMap<EdgeDescriptor, EdgePropertyValues> {
        .init(defaultValue: .init())
    }
}
