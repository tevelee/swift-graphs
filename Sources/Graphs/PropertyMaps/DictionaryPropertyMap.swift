struct DictionaryPropertyMap<Key: Hashable, Property: GraphProperty> {
    private var values: [Key: Property.Value] = [:]
}

extension DictionaryPropertyMap: MutablePropertyMap {
    subscript(key: Key) -> Property.Value {
        get { values[key] ?? Property.defaultValue }
        set { values[key] = newValue }
    }
}
