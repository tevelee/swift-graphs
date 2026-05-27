/// A marker protocol for edge storage backends that can be default-constructed.
///
/// Used by ``CacheInOutEdges`` to provide a no-argument ``init()`` overload when its
/// underlying `Base` supports default construction — the mechanism that lets
/// `OrderedEdgeStorage()` (a typealias for `CacheInOutEdges<LinearOrderedEdgeStorage<V>>`)
/// be called without manually constructing the wrapped base.
///
/// Conform internal storage types to this protocol when they have an `init()`.
public protocol DefaultEdgeStorageInitializable {
    init()
}
