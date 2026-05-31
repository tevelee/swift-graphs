/// A container for vertex property values.
///
/// This type provides type-safe storage for vertex properties using a dynamic
/// property system. It allows storing different types of properties associated
/// with vertices in a single container.
public struct VertexPropertyValues: VertexProperties {
    private var storage = PropertyValues()

    /// Accesses the value of a specific vertex property.
    ///
    /// - Parameter property: The type of property to access
    /// - Returns: The current value of the property
    // Swift 5.9/6.0 SIL bug: see DictionaryPropertyMap for details.
    #if compiler(>=6.1)
    public subscript<P: VertexProperty>(property: P.Type) -> P.Value {
        set { storage[property] = newValue }
        _read { yield storage[property] }
        _modify {
            var value: P.Value = storage[property]
            defer { storage[property] = value }
            yield &value
        }
    }
    #else
    public subscript<P: VertexProperty>(property: P.Type) -> P.Value {
        get { storage[property] }
        set { storage[property] = newValue }
    }
    #endif

    /// Creates a new empty vertex property values container.
    @inlinable
    public init() {}
}

/// A container for edge property values.
///
/// This type provides type-safe storage for edge properties using a dynamic
/// property system. It allows storing different types of properties associated
/// with edges in a single container.
public struct EdgePropertyValues: EdgeProperties {
    private var storage = PropertyValues()

    /// Accesses the value of a specific edge property.
    ///
    /// - Parameter property: The type of property to access
    /// - Returns: The current value of the property
    // Swift 5.9/6.0 SIL bug: see DictionaryPropertyMap for details.
    #if compiler(>=6.1)
    public subscript<P: EdgeProperty>(property: P.Type) -> P.Value {
        set { storage[property] = newValue }
        _read { yield storage[property] }
        _modify {
            var value: P.Value = storage[property]
            defer { storage[property] = value }
            yield &value
        }
    }
    #else
    public subscript<P: EdgeProperty>(property: P.Type) -> P.Value {
        get { storage[property] }
        set { storage[property] = newValue }
    }
    #endif

    /// Creates a new empty edge property values container.
    @inlinable
    public init() {}
}

#if compiler(>=6.1)
private struct PropertyValues: Sendable {
    private var storage: [ObjectIdentifier: any Sendable] = [:]

    subscript<P: GraphProperty>(property: P.Type) -> P.Value {
        set { storage[ObjectIdentifier(property)] = newValue }
        _read {
            let key = ObjectIdentifier(property)
            if let value = storage[key] as? P.Value {
                yield value
            } else {
                yield P.defaultValue
            }
        }
        _modify {
            let key = ObjectIdentifier(property)
            var value = (storage[key] as? P.Value) ?? P.defaultValue
            defer { storage[key] = value }
            yield &value
        }
    }
}
extension VertexPropertyValues: Sendable {}
extension EdgePropertyValues: Sendable {}
#else
private struct PropertyValues {
    private var storage: [ObjectIdentifier: Any] = [:]

    subscript<P: GraphProperty>(property: P.Type) -> P.Value {
        get {
            let key = ObjectIdentifier(property)
            return (storage[key] as? P.Value) ?? P.defaultValue
        }
        set {
            storage[ObjectIdentifier(property)] = newValue
        }
    }
}
#endif
