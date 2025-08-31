struct NoProperty<Key>: MutablePropertyMap {
    typealias Property = Empty

    subscript(key: Key) -> Empty {
        get { Empty() }
        set {}
    }
}
