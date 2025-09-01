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
    }
}
