/// A protocol for property maps that provide read-only access to values by key.
///
/// Property maps are used to associate additional data with graph elements
/// (vertices or edges) without modifying the graph structure itself.
public protocol PropertyMap<Key, Value> {
    /// The type of keys used to access values.
    associatedtype Key
    
    /// The type of values stored in the map.
    associatedtype Value

    /// Accesses the value associated with the given key.
    ///
    /// - Parameter key: The key to look up
    /// - Returns: The value associated with the key
    subscript(key: Key) -> Value { get }
}

/// A protocol for property maps that provide read-write access to values by key.
///
/// Mutable property maps allow both reading and writing values associated
/// with graph elements.
public protocol MutablePropertyMap<Key, Value>: PropertyMap {
    /// Accesses the value associated with the given key for reading and writing.
    ///
    /// - Parameter key: The key to look up or set
    /// - Returns: The value associated with the key
    subscript(key: Key) -> Value { get set }
}
