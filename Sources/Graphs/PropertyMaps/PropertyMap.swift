protocol PropertyMap<Key, Property> {
    associatedtype Key
    associatedtype Property: GraphProperty

    subscript(key: Key) -> Property.Value { get }
}

protocol MutablePropertyMap<Key, Property>: PropertyMap {
    subscript(key: Key) -> Property.Value { get set }
}
