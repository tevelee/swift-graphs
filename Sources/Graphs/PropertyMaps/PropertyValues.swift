struct VertexPropertyValues {
    private var storage = PropertyValues()

    subscript<P: VertexProperty>(property: P.Type) -> P.Value {
        get { storage[property] }
        set { storage[property] = newValue }
        // TODO: modify accessor
    }
}

struct EdgePropertyValues {
    private var storage = PropertyValues()

    subscript<P: EdgeProperty>(property: P.Type) -> P.Value {
        get { storage[property] }
        set { storage[property] = newValue }
        // TODO: modify accessor
    }
}

private struct PropertyValues {
    private var storage: [ObjectIdentifier: Any] = [:]

    subscript<P: GraphProperty>(property: P.Type) -> P.Value {
        get { storage[ObjectIdentifier(property)] as? P.Value ?? P.defaultValue }
        set { storage[ObjectIdentifier(property)] = newValue }
        // TODO: modify accessor
    }
}

