struct CompositePropertyMap<First: PropertyMap, Second: PropertyMap>: PropertyMap where First.Key == Second.Key {
    var first: First
    var second: Second

    struct Property: GraphProperty {
        typealias Value = (
            First.Property.Value,
            Second.Property.Value
        )

        static var defaultValue: Value {
            Value(
                First.Property.defaultValue,
                Second.Property.defaultValue
            )
        }
    }

    subscript(_ key: First.Key) -> Property.Value {
        Property.Value(
            first[key],
            second[key]
        )
    }
}

extension NoProperty {
    func combined<P: PropertyMap>(with other: P) -> P {
        other
    }
}

extension PropertyMap {
    func combined<P: PropertyMap>(with other: P) -> CompositePropertyMap<Self, P> {
        .init(first: self, second: other)
    }
}

extension CompositePropertyMap {
    func combined<P: PropertyMap>(with other: P) -> CompositePropertyMap<Self, P> {
        .init(first: self, second: other)
    }
}

extension CompositePropertyMap: MutablePropertyMap where First: MutablePropertyMap, Second: MutablePropertyMap {
    subscript(_ key: First.Key) -> Property.Value {
        get {
            Property.Value(
                first[key],
                second[key]
            )
        }
        set {
            first[key] = newValue.0
            second[key] = newValue.1
        }
    }
}
