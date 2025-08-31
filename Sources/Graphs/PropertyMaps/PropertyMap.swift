protocol PropertyMap {
    associatedtype Key
    associatedtype Property: GraphProperty

    subscript(key: Key) -> Property.Value { get }
}

protocol MutablePropertyMap: PropertyMap {
    subscript(key: Key) -> Property.Value { get set }
}
