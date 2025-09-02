protocol Graph<VertexDescriptor, EdgeDescriptor> {
    associatedtype VertexDescriptor
    associatedtype EdgeDescriptor
}

extension Graph {
    func makeVertexCollection<T: Collection<VertexDescriptor>>(_ factory: () -> T) -> T {
        factory()
    }

    func makeEdgeCollection<T: Collection<EdgeDescriptor>>(_ factory: () -> T) -> T {
        factory()
    }
}
