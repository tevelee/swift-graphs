import Collections

/// A view of a bidirectional graph that treats it as undirected.
///
/// This view provides an undirected perspective of a bidirectional graph by
/// treating each pair of directed edges (u,v) and (v,u) as a single undirected edge.
/// This is useful for algorithms that work on undirected graphs.
public struct UndirectedGraphView<
    Base: BidirectionalGraph
>: Graph where
    Base.EdgeDescriptor: Hashable
{
    public typealias VertexDescriptor = Base.VertexDescriptor
    
    /// An edge descriptor in the undirected graph view.
    public struct EdgeDescriptor: Hashable {
        /// The underlying edge from the base graph.
        public let base: Base.EdgeDescriptor
        
        /// Whether this edge is flipped (represents the reverse direction).
        public let flipped: Bool
        
        /// Creates a new undirected edge descriptor.
        ///
        /// - Parameters:
        ///   - base: The underlying edge
        ///   - flipped: Whether this edge is flipped
        @inlinable
        public init(base: Base.EdgeDescriptor, flipped: Bool) {
            self.base = base
            self.flipped = flipped
        }
    }

    public let base: Base
    
    /// Creates a new undirected graph view.
    ///
    /// - Parameter base: The underlying bidirectional graph
    @inlinable
    public init(base: Base) {
        self.base = base
    }
}

extension UndirectedGraphView: VertexListGraph where Base: VertexListGraph {
    public typealias Vertices = Base.Vertices
    @inlinable
    public func vertices() -> Vertices { base.vertices() }
    
    @inlinable
    public var vertexCount: Int { base.vertexCount }
}

extension UndirectedGraphView: EdgeListGraph where Base: EdgeListGraph {
    public struct Edges: Sequence {
        @usableFromInline
        let baseEdges: Base.Edges
        
        @inlinable
        public init(baseEdges: Base.Edges) {
            self.baseEdges = baseEdges
        }
        
        @inlinable
        public func makeIterator() -> Iterator { Iterator(baseIterator: baseEdges.makeIterator()) }
        public struct Iterator: IteratorProtocol {
            @usableFromInline
            var baseIterator: Base.Edges.Iterator
            
            @inlinable
            public init(baseIterator: Base.Edges.Iterator) {
                self.baseIterator = baseIterator
            }
            
            @inlinable
            public mutating func next() -> EdgeDescriptor? {
                baseIterator.next().map { EdgeDescriptor(base: $0, flipped: false) }
            }
        }
    }
    @inlinable
    public func edges() -> Edges { .init(baseEdges: base.edges()) }
    @inlinable
    public var edgeCount: Int { base.edgeCount }
}

extension UndirectedGraphView: IncidenceGraph {
    public struct OutgoingEdges: Sequence {
        @usableFromInline
        let base: Base
        @usableFromInline
        let vertex: Base.VertexDescriptor
        
        @inlinable
        public init(base: Base, vertex: Base.VertexDescriptor) {
            self.base = base
            self.vertex = vertex
        }
        
        @inlinable
        public func makeIterator() -> Iterator { Iterator(base: base, vertex: vertex, outIt: base.outgoingEdges(of: vertex).makeIterator(), inIt: base.incomingEdges(of: vertex).makeIterator()) }
        public struct Iterator: IteratorProtocol {
            @usableFromInline
            let base: Base
            @usableFromInline
            let vertex: Base.VertexDescriptor
            @usableFromInline
            var outIt: Base.OutgoingEdges.Iterator
            @usableFromInline
            var inIt: Base.IncomingEdges.Iterator
            
            @inlinable
            public init(base: Base, vertex: Base.VertexDescriptor, outIt: Base.OutgoingEdges.Iterator, inIt: Base.IncomingEdges.Iterator) {
                self.base = base
                self.vertex = vertex
                self.outIt = outIt
                self.inIt = inIt
            }
            public mutating func next() -> EdgeDescriptor? {
                if let e = outIt.next() { return EdgeDescriptor(base: e, flipped: false) }
                if let e = inIt.next() { return EdgeDescriptor(base: e, flipped: true) }
                return nil
            }
        }
    }

    @inlinable
    public func outgoingEdges(of vertex: VertexDescriptor) -> OutgoingEdges {
        .init(base: base, vertex: vertex)
    }

    @inlinable
    public func source(of edge: EdgeDescriptor) -> VertexDescriptor? {
        edge.flipped ? base.destination(of: edge.base) : base.source(of: edge.base)
    }

    @inlinable
    public func destination(of edge: EdgeDescriptor) -> VertexDescriptor? {
        edge.flipped ? base.source(of: edge.base) : base.destination(of: edge.base)
    }

    @inlinable
    public func outDegree(of vertex: VertexDescriptor) -> Int {
        base.outDegree(of: vertex) + base.inDegree(of: vertex)
    }
}

extension UndirectedGraphView: BidirectionalGraph {
    public typealias IncomingEdges = OutgoingEdges
    @inlinable
    public func incomingEdges(of vertex: VertexDescriptor) -> IncomingEdges { outgoingEdges(of: vertex) }
    @inlinable
    public func inDegree(of vertex: VertexDescriptor) -> Int { outDegree(of: vertex) }
}

// MARK: - Convenience Methods for Creating UndirectedGraphView

extension BidirectionalGraph where EdgeDescriptor: Hashable {
    /// Returns an undirected view of this bidirectional graph.
    /// 
    /// In the undirected view, each edge can be traversed in both directions,
    /// effectively treating the graph as undirected.
    /// - Returns: An `UndirectedGraphView` that represents the undirected graph
    @inlinable
    public func undirected() -> UndirectedGraphView<Self> {
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

