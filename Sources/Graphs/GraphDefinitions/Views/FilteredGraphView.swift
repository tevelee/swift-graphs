import Collections

/// A view of a graph that filters vertices and edges based on predicates.
///
/// This view provides a filtered perspective of the underlying graph by
/// including only vertices and edges that satisfy the given predicates.
/// This is useful for creating subgraphs or focusing on specific parts of a graph.
public struct FilteredGraphView<Base: IncidenceGraph>: Graph {
    public typealias VertexDescriptor = Base.VertexDescriptor
    public typealias EdgeDescriptor = Base.EdgeDescriptor

    public let base: Base
    public let includeVertex: (VertexDescriptor) -> Bool
    public let includeEdge: (EdgeDescriptor) -> Bool
    
    /// Creates a new filtered graph view.
    ///
    /// - Parameters:
    ///   - base: The underlying graph to filter
    ///   - includeVertex: A predicate that determines which vertices to include
    ///   - includeEdge: A predicate that determines which edges to include
    @inlinable
    public init(
        base: Base,
        includeVertex: @escaping (VertexDescriptor) -> Bool,
        includeEdge: @escaping (EdgeDescriptor) -> Bool
    ) {
        self.base = base
        self.includeVertex = includeVertex
        self.includeEdge = includeEdge
    }
}

extension FilteredGraphView: VertexListGraph where Base: VertexListGraph {
    public struct Vertices: Sequence {
        @usableFromInline
        let baseVertices: Base.Vertices
        @usableFromInline
        let predicate: (Base.VertexDescriptor) -> Bool
        
        @inlinable
        public init(baseVertices: Base.Vertices, predicate: @escaping (Base.VertexDescriptor) -> Bool) {
            self.baseVertices = baseVertices
            self.predicate = predicate
        }
        public func makeIterator() -> Iterator { Iterator(baseIterator: baseVertices.makeIterator(), predicate: predicate) }
        public struct Iterator: IteratorProtocol {
            var baseIterator: Base.Vertices.Iterator
            let predicate: (Base.VertexDescriptor) -> Bool
            public mutating func next() -> Base.VertexDescriptor? {
                while let v = baseIterator.next() {
                    if predicate(v) { return v }
                }
                return nil
            }
        }
    }
    @inlinable
    public func vertices() -> Vertices { .init(baseVertices: base.vertices(), predicate: includeVertex) }
    
    @inlinable
    public var vertexCount: Int { vertices().reduce(0) { acc, _ in acc + 1 } }
}

extension FilteredGraphView: EdgeListGraph where Base: EdgeListGraph {
    public struct Edges: Sequence {
        @usableFromInline
        let baseEdges: Base.Edges
        @usableFromInline
        let predicate: (Base.EdgeDescriptor) -> Bool
        
        @inlinable
        public init(baseEdges: Base.Edges, predicate: @escaping (Base.EdgeDescriptor) -> Bool) {
            self.baseEdges = baseEdges
            self.predicate = predicate
        }
        public func makeIterator() -> Iterator { Iterator(baseIterator: baseEdges.makeIterator(), predicate: predicate) }
        public struct Iterator: IteratorProtocol {
            var baseIterator: Base.Edges.Iterator
            let predicate: (Base.EdgeDescriptor) -> Bool
            public mutating func next() -> Base.EdgeDescriptor? {
                while let e = baseIterator.next() {
                    if predicate(e) { return e }
                }
                return nil
            }
        }
    }
    @inlinable
    public func edges() -> Edges { .init(baseEdges: base.edges(), predicate: includeEdge) }
    @inlinable
    public var edgeCount: Int { edges().reduce(0) { acc, _ in acc + 1 } }
}

extension FilteredGraphView: IncidenceGraph {
    public struct OutgoingEdges: Sequence {
        @usableFromInline
        let base: Base
        @usableFromInline
        let vertex: Base.VertexDescriptor
        @usableFromInline
        let vertexOk: (Base.VertexDescriptor) -> Bool
        @usableFromInline
        let edgeOk: (Base.EdgeDescriptor) -> Bool
        
        @inlinable
        public init(base: Base, vertex: Base.VertexDescriptor, vertexOk: @escaping (Base.VertexDescriptor) -> Bool, edgeOk: @escaping (Base.EdgeDescriptor) -> Bool) {
            self.base = base
            self.vertex = vertex
            self.vertexOk = vertexOk
            self.edgeOk = edgeOk
        }
        public func makeIterator() -> Iterator { Iterator(baseIterator: base.outgoingEdges(of: vertex).makeIterator(), base: base, edgeOk: edgeOk, vertexOk: vertexOk) }
        public struct Iterator: IteratorProtocol {
            var baseIterator: Base.OutgoingEdges.Iterator
            let base: Base
            let edgeOk: (Base.EdgeDescriptor) -> Bool
            let vertexOk: (Base.VertexDescriptor) -> Bool
            public mutating func next() -> Base.EdgeDescriptor? {
                while let e = baseIterator.next() {
                    guard edgeOk(e), let d = base.destination(of: e), vertexOk(d) else { continue }
                    return e
                }
                return nil
            }
        }
    }
    @inlinable
    public func outgoingEdges(of vertex: VertexDescriptor) -> OutgoingEdges {
        guard includeVertex(vertex) else { return .init(base: base, vertex: vertex, vertexOk: { _ in false }, edgeOk: { _ in false }) }
        return .init(base: base, vertex: vertex, vertexOk: includeVertex, edgeOk: includeEdge)
    }
    @inlinable
    public func source(of edge: EdgeDescriptor) -> VertexDescriptor? {
        guard includeEdge(edge), let s = base.source(of: edge), includeVertex(s) else { return nil }
        return s
    }
    @inlinable
    public func destination(of edge: EdgeDescriptor) -> VertexDescriptor? {
        guard includeEdge(edge), let d = base.destination(of: edge), includeVertex(d) else { return nil }
        return d
    }
    @inlinable
    public func outDegree(of vertex: VertexDescriptor) -> Int {
        outgoingEdges(of: vertex).count
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
    public func filtered(
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
    public func filterVertices(where predicate: @escaping (VertexDescriptor) -> Bool) -> FilteredGraphView<Self> {
        filtered(includeVertex: predicate)
    }
    
    /// Returns a view containing only edges that satisfy the given predicate.
    /// 
    /// - Parameter predicate: The condition that edges must satisfy
    /// - Returns: A `FilteredGraphView` with only the specified edges
    @inlinable
    public func filterEdges(where predicate: @escaping (EdgeDescriptor) -> Bool) -> FilteredGraphView<Self> {
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
    public func filtered(
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

extension Sequence {
    @usableFromInline
    var count: Int {
        var result = 0
        for _ in self {
            result += 1
        }
        return result
    }
}
