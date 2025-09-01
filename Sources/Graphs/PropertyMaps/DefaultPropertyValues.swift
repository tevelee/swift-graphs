protocol PropertyValues<Component> {
    associatedtype Component: GraphComponent

    subscript<P: GraphProperty<Component>>(property: P.Type) -> P.Value { get }
}

protocol MutablePropertyValues<Component>: PropertyValues {
    subscript<P: GraphProperty<Component>>(property: P.Type) -> P.Value { get set }
}

struct DefaultPropertyValues<Component: GraphComponent>: MutablePropertyValues {
    private var storage: [ObjectIdentifier: Any] = [:]

    subscript<P: GraphProperty<Component>>(property: P.Type) -> P.Value {
        get { storage[ObjectIdentifier(property)] as? P.Value ?? P.defaultValue }
        set { storage[ObjectIdentifier(property)] = newValue }
    }
}
