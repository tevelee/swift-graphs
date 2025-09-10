protocol VertexProperties {
    subscript<P: VertexProperty>(property: P.Type) -> P.Value { get set }
}

struct VertexPropertyValues: VertexProperties {
    private var storage = PropertyValues()

    subscript<P: VertexProperty>(property: P.Type) -> P.Value {
        set { storage[property] = newValue }
        _read {
            yield storage[property]
        }
        _modify {
            var value: P.Value = storage[property]
            defer { storage[property] = value }
            yield &value
        }
    }
}

protocol EdgeProperties {
    subscript<P: EdgeProperty>(property: P.Type) -> P.Value { get set }
}

struct EdgePropertyValues: EdgeProperties {
    private var storage = PropertyValues()

    subscript<P: EdgeProperty>(property: P.Type) -> P.Value {
        set { storage[property] = newValue }
        _read {
            yield storage[property]
        }
        _modify {
            var value: P.Value = storage[property]
            defer { storage[property] = value }
            yield &value
        }
    }
}

private struct PropertyValues {
    private var storage: [ObjectIdentifier: Any] = [:]

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

