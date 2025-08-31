struct NoProperty<Key>: PropertyMap {
    typealias Property = Empty

    subscript(key: Key) -> Empty {
        Empty()
    }
}
