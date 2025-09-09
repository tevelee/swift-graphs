struct DictionaryPropertyMap<Key: Hashable, Value> {
    private var values: [Key: Value] = [:]
    let defaultValue: Value

    init(defaultValue: Value) {
        self.defaultValue = defaultValue
    }
}

extension DictionaryPropertyMap: MutablePropertyMap {
    subscript(key: Key) -> Value {
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

extension Graph where VertexDescriptor: Hashable {
    func makeVertexPropertyMap() -> some MutablePropertyMap<VertexDescriptor, VertexPropertyValues> {
        .init(defaultValue: .init()) as DictionaryPropertyMap
    }
}

extension Graph where EdgeDescriptor: Hashable {
    func makeEdgePropertyMap() -> some MutablePropertyMap<EdgeDescriptor, EdgePropertyValues> {
        .init(defaultValue: .init()) as DictionaryPropertyMap
    }
}
