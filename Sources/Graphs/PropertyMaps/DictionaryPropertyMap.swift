struct DictionaryPropertyMap<Key: Hashable, Value> {
    private var values: [Key: Value] = [:]
    let defaultValue: Value

    init(defaultValue: Value) {
        self.defaultValue = defaultValue
    }
}

extension DictionaryPropertyMap: MutablePropertyMap {
    subscript(key: Key) -> Value {
        get { values[key] ?? defaultValue }
        set { values[key] = newValue }
        // TODO: modify accessor
    }
}

extension PropertyGraph where VertexDescriptor: Hashable {
    func makeVertexPropertyMap() -> some MutablePropertyMap<VertexDescriptor, VertexPropertyValues> {
        .init(defaultValue: .init()) as DictionaryPropertyMap
    }
}

extension PropertyGraph where EdgeDescriptor: Hashable {
    func makeEdgePropertyMap() -> some MutablePropertyMap<EdgeDescriptor, EdgePropertyValues> {
        .init(defaultValue: .init()) as DictionaryPropertyMap
    }
}
