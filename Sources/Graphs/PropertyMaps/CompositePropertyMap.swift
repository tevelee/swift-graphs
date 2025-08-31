struct CompositePropertyMap<First: PropertyMap, Second: PropertyMap>: PropertyMap {
    var first: First
    var second: Second

    struct Key {
        let first: First.Key
        let second: Second.Key
    }

    struct Property: GraphProperty {
        struct Value {
            let first: First.Property.Value
            let second: Second.Property.Value
        }

        static var defaultValue: Value {
            Value(
                first: First.Property.defaultValue,
                second: Second.Property.defaultValue
            )
        }
    }

    subscript(_ key: Key) -> Property.Value {
        Property.Value(
            first: first[key.first],
            second: second[key.second]
        )
    }
}

extension CompositePropertyMap: MutablePropertyMap where First: MutablePropertyMap, Second: MutablePropertyMap {
    subscript(_ key: Key) -> Property.Value {
        get {
            Property.Value(
                first: first[key.first],
                second: second[key.second]
            )
        }
        set {
            first[key.first] = newValue.first
            second[key.second] = newValue.second
        }
    }
}

@available(macOS 14.0.0, *)
struct Composite<each Element> {
    var element: (repeat each Element)
}

@available(macOS 14.0.0, *)
extension Composite: PropertyMap where repeat each Element: PropertyMap {
    struct Key {
        let element: (repeat (each Element).Key)
    }

    struct Property: GraphProperty {
        typealias Value = (repeat (each Element).Property.Value)

        static var defaultValue: (repeat (each Element).Property.Value) {
            (repeat (each Element).Property.defaultValue)
        }
    }

    subscript(key: Key) -> (repeat (each Element).Property.Value) {
        (repeat (each element)[each key.element])
    }
}

// https://github.com/swiftlang/swift/issues/84037
//@available(macOS 14.0.0, *)
//extension Composite: MutablePropertyMap where repeat each Element: MutablePropertyMap {
//    subscript(key: Key) -> (repeat (each Element).Property.Value) {
//        get {
//            (repeat (each element)[each key.element])
//        }
//        set {
//            // https://github.com/swiftlang/swift/issues/69231
//            repeat (each element)[each key.element] = each newValue
//        }
//    }
//}
