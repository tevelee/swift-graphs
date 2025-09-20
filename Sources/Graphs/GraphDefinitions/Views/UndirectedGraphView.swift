import Collections

struct UndirectedGraphView<
    Base: BidirectionalGraph
>: Graph where
    Base.EdgeDescriptor: Hashable
{
    typealias VertexDescriptor = Base.VertexDescriptor
    struct EdgeDescriptor: Hashable {
        let base: Base.EdgeDescriptor
        let flipped: Bool
    }

    let base: Base
}

extension UndirectedGraphView: VertexListGraph where Base: VertexListGraph {
    typealias Vertices = Base.Vertices
    func vertices() -> Vertices { base.vertices() }
    var vertexCount: Int { base.vertexCount }
}

extension UndirectedGraphView: EdgeListGraph where Base: EdgeListGraph {
    struct Edges: Sequence {
        let baseEdges: Base.Edges
        func makeIterator() -> Iterator { Iterator(baseIterator: baseEdges.makeIterator()) }
        struct Iterator: IteratorProtocol {
            var baseIterator: Base.Edges.Iterator
            mutating func next() -> EdgeDescriptor? {
                baseIterator.next().map { EdgeDescriptor(base: $0, flipped: false) }
            }
        }
    }
    func edges() -> Edges { .init(baseEdges: base.edges()) }
    var edgeCount: Int { base.edgeCount }
}

extension UndirectedGraphView: IncidenceGraph {
    struct OutgoingEdges: Sequence {
        let base: Base
        let vertex: Base.VertexDescriptor
        func makeIterator() -> Iterator { Iterator(base: base, vertex: vertex, outIt: base.outgoingEdges(of: vertex).makeIterator(), inIt: base.incomingEdges(of: vertex).makeIterator()) }
        struct Iterator: IteratorProtocol {
            let base: Base
            let vertex: Base.VertexDescriptor
            var outIt: Base.OutgoingEdges.Iterator
            var inIt: Base.IncomingEdges.Iterator
            mutating func next() -> EdgeDescriptor? {
                if let e = outIt.next() { return EdgeDescriptor(base: e, flipped: false) }
                if let e = inIt.next() { return EdgeDescriptor(base: e, flipped: true) }
                return nil
            }
        }
    }

    func outgoingEdges(of vertex: VertexDescriptor) -> OutgoingEdges {
        .init(base: base, vertex: vertex)
    }

    func source(of edge: EdgeDescriptor) -> VertexDescriptor? {
        edge.flipped ? base.destination(of: edge.base) : base.source(of: edge.base)
    }

    func destination(of edge: EdgeDescriptor) -> VertexDescriptor? {
        edge.flipped ? base.source(of: edge.base) : base.destination(of: edge.base)
    }

    func outDegree(of vertex: VertexDescriptor) -> Int {
        base.outDegree(of: vertex) + base.inDegree(of: vertex)
    }
}

extension UndirectedGraphView: BidirectionalGraph {
    typealias IncomingEdges = OutgoingEdges
    func incomingEdges(of vertex: VertexDescriptor) -> IncomingEdges { outgoingEdges(of: vertex) }
    func inDegree(of vertex: VertexDescriptor) -> Int { outDegree(of: vertex) }
}

// MARK: - Convenience Methods for Creating UndirectedGraphView

extension BidirectionalGraph where EdgeDescriptor: Hashable {
    /// Returns an undirected view of this bidirectional graph.
    /// 
    /// In the undirected view, each edge can be traversed in both directions,
    /// effectively treating the graph as undirected.
    /// - Returns: An `UndirectedGraphView` that represents the undirected graph
    @inlinable
    func undirected() -> UndirectedGraphView<Self> {
        UndirectedGraphView(base: self)
    }
}

// MARK: - Chaining Support for UndirectedGraphView

extension UndirectedGraphView {
    /// Returns a directed view of this undirected graph.
    /// 
    /// - Returns: The original bidirectional graph
    @inlinable
    func directed() -> Base {
        base
    }
}

