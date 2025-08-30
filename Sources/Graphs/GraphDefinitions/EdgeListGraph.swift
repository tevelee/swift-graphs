protocol EdgeListGraph: Graph {
    associatedtype Edges: Sequence<EdgeDescriptor>

    func edges() -> Edges
    var numberOfEdges: Int { get }
}
