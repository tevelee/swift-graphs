import Collections

struct FilteredGraphView<Base: IncidenceGraph>: Graph {
    typealias VertexDescriptor = Base.VertexDescriptor
    typealias EdgeDescriptor = Base.EdgeDescriptor

    let base: Base
    let includeVertex: (VertexDescriptor) -> Bool
    let includeEdge: (EdgeDescriptor) -> Bool
}

extension FilteredGraphView: VertexListGraph where Base: VertexListGraph {
    struct Vertices: Sequence {
        let baseVertices: Base.Vertices
        let predicate: (Base.VertexDescriptor) -> Bool
        func makeIterator() -> Iterator { Iterator(baseIterator: baseVertices.makeIterator(), predicate: predicate) }
        struct Iterator: IteratorProtocol {
            var baseIterator: Base.Vertices.Iterator
            let predicate: (Base.VertexDescriptor) -> Bool
            mutating func next() -> Base.VertexDescriptor? {
                while let v = baseIterator.next() {
                    if predicate(v) { return v }
                }
                return nil
            }
        }
    }
    func vertices() -> Vertices { .init(baseVertices: base.vertices(), predicate: includeVertex) }
    var vertexCount: Int { vertices().reduce(0) { acc, _ in acc + 1 } }
}

extension FilteredGraphView: EdgeListGraph where Base: EdgeListGraph {
    struct Edges: Sequence {
        let baseEdges: Base.Edges
        let predicate: (Base.EdgeDescriptor) -> Bool
        func makeIterator() -> Iterator { Iterator(baseIterator: baseEdges.makeIterator(), predicate: predicate) }
        struct Iterator: IteratorProtocol {
            var baseIterator: Base.Edges.Iterator
            let predicate: (Base.EdgeDescriptor) -> Bool
            mutating func next() -> Base.EdgeDescriptor? {
                while let e = baseIterator.next() {
                    if predicate(e) { return e }
                }
                return nil
            }
        }
    }
    func edges() -> Edges { .init(baseEdges: base.edges(), predicate: includeEdge) }
    var edgeCount: Int { edges().reduce(0) { acc, _ in acc + 1 } }
}

extension FilteredGraphView: IncidenceGraph {
    struct OutgoingEdges: Sequence {
        let base: Base
        let vertex: Base.VertexDescriptor
        let vertexOk: (Base.VertexDescriptor) -> Bool
        let edgeOk: (Base.EdgeDescriptor) -> Bool
        func makeIterator() -> Iterator { Iterator(baseIterator: base.outgoingEdges(of: vertex).makeIterator(), base: base, edgeOk: edgeOk, vertexOk: vertexOk) }
        struct Iterator: IteratorProtocol {
            var baseIterator: Base.OutgoingEdges.Iterator
            let base: Base
            let edgeOk: (Base.EdgeDescriptor) -> Bool
            let vertexOk: (Base.VertexDescriptor) -> Bool
            mutating func next() -> Base.EdgeDescriptor? {
                while let e = baseIterator.next() {
                    guard edgeOk(e), let d = base.destination(of: e), vertexOk(d) else { continue }
                    return e
                }
                return nil
            }
        }
    }
    func outgoingEdges(of vertex: VertexDescriptor) -> OutgoingEdges {
        guard includeVertex(vertex) else { return .init(base: base, vertex: vertex, vertexOk: { _ in false }, edgeOk: { _ in false }) }
        return .init(base: base, vertex: vertex, vertexOk: includeVertex, edgeOk: includeEdge)
    }
    func source(of edge: EdgeDescriptor) -> VertexDescriptor? {
        guard includeEdge(edge), let s = base.source(of: edge), includeVertex(s) else { return nil }
        return s
    }
    func destination(of edge: EdgeDescriptor) -> VertexDescriptor? {
        guard includeEdge(edge), let d = base.destination(of: edge), includeVertex(d) else { return nil }
        return d
    }
    func outDegree(of vertex: VertexDescriptor) -> Int {
        outgoingEdges(of: vertex).count { _ in true }
    }
}

// MARK: - Convenience Methods for Creating FilteredGraphView

extension IncidenceGraph {
    /// Returns a filtered view of this graph based on vertex and edge predicates.
    /// 
    /// - Parameters:
    ///   - includeVertex: Predicate to determine which vertices to include
    ///   - includeEdge: Predicate to determine which edges to include
    /// - Returns: A `FilteredGraphView` with the specified filtering applied
    @inlinable
    func filtered(
        includeVertex: @escaping (VertexDescriptor) -> Bool = { _ in true },
        includeEdge: @escaping (EdgeDescriptor) -> Bool = { _ in true }
    ) -> FilteredGraphView<Self> {
        FilteredGraphView(base: self, includeVertex: includeVertex, includeEdge: includeEdge)
    }
    
    /// Returns a view containing only vertices that satisfy the given predicate.
    /// 
    /// - Parameter predicate: The condition that vertices must satisfy
    /// - Returns: A `FilteredGraphView` with only the specified vertices
    @inlinable
    func filterVertices(where predicate: @escaping (VertexDescriptor) -> Bool) -> FilteredGraphView<Self> {
        filtered(includeVertex: predicate)
    }
    
    /// Returns a view containing only edges that satisfy the given predicate.
    /// 
    /// - Parameter predicate: The condition that edges must satisfy
    /// - Returns: A `FilteredGraphView` with only the specified edges
    @inlinable
    func filterEdges(where predicate: @escaping (EdgeDescriptor) -> Bool) -> FilteredGraphView<Self> {
        filtered(includeEdge: predicate)
    }
}

// MARK: - Chaining Support for FilteredGraphView

extension FilteredGraphView {
    /// Returns a further filtered view of this filtered graph.
    /// 
    /// - Parameters:
    ///   - includeVertex: Additional vertex predicate (combined with existing)
    ///   - includeEdge: Additional edge predicate (combined with existing)
    /// - Returns: A `FilteredGraphView` with combined filtering
    @inlinable
    func filtered(
        includeVertex: @escaping (VertexDescriptor) -> Bool = { _ in true },
        includeEdge: @escaping (EdgeDescriptor) -> Bool = { _ in true }
    ) -> FilteredGraphView<Base> {
        FilteredGraphView(
            base: base,
            includeVertex: { self.includeVertex($0) && includeVertex($0) },
            includeEdge: { self.includeEdge($0) && includeEdge($0) }
        )
    }
}

