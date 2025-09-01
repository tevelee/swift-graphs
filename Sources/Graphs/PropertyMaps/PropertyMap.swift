protocol PropertyMap<Key, Value> {
    associatedtype Key
    associatedtype Value

    subscript(key: Key) -> Value { get }
}

protocol MutablePropertyMap<Key, Value>: PropertyMap {
    subscript(key: Key) -> Value { get set }
}
