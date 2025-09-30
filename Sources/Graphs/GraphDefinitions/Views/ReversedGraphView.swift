/// A view of a graph with all edges reversed (transposed).
///
/// This view provides a reversed perspective of the underlying graph by swapping
/// the source and destination of all edges. This is useful for algorithms that
/// need to traverse the graph in the opposite direction.
public struct ReversedGraphView<Base: IncidenceGraph>: Graph {
    public typealias VertexDescriptor = Base.VertexDescriptor
    public typealias EdgeDescriptor = Base.EdgeDescriptor
    public let base: Base
    
    /// Creates a new reversed graph view.
    ///
    /// - Parameter base: The underlying graph to reverse
    @inlinable
    public init(base: Base) {
        self.base = base
    }
}

extension ReversedGraphView: VertexListGraph where Base: VertexListGraph {
    public typealias Vertices = Base.Vertices
    @inlinable
    public func vertices() -> Vertices { base.vertices() }
    
    @inlinable
    public var vertexCount: Int { base.vertexCount }
}

extension ReversedGraphView: EdgeListGraph where Base: EdgeListGraph {
    public typealias Edges = Base.Edges
    @inlinable
    public func edges() -> Edges { base.edges() }
    
    @inlinable
    public var edgeCount: Int { base.edgeCount }
}

extension ReversedGraphView: IncidenceGraph where Base: BidirectionalGraph {
    public typealias OutgoingEdges = Base.IncomingEdges
    @inlinable
    public func outgoingEdges(of vertex: VertexDescriptor) -> OutgoingEdges { base.incomingEdges(of: vertex) }
    
    @inlinable
    public func source(of edge: EdgeDescriptor) -> VertexDescriptor? { base.destination(of: edge) }
    
    @inlinable
    public func destination(of edge: EdgeDescriptor) -> VertexDescriptor? { base.source(of: edge) }
    
    @inlinable
    public func outDegree(of vertex: VertexDescriptor) -> Int { base.inDegree(of: vertex) }
}

extension ReversedGraphView: BidirectionalGraph where Base: BidirectionalGraph {
    public typealias IncomingEdges = Base.OutgoingEdges
    @inlinable
    public func incomingEdges(of vertex: VertexDescriptor) -> IncomingEdges { base.outgoingEdges(of: vertex) }
    
    @inlinable
    public func inDegree(of vertex: VertexDescriptor) -> Int { base.outDegree(of: vertex) }
}

// MARK: - Convenience Methods for Creating ReversedGraphView

extension IncidenceGraph where Self: BidirectionalGraph {
    /// Returns a view of this graph with all edges reversed (transposed).
    /// 
    /// This is equivalent to the transpose of the graph's adjacency matrix.
    /// - Returns: A `ReversedGraphView` that represents the transposed graph
    @inlinable
    public func reversed() -> ReversedGraphView<Self> {
        ReversedGraphView(base: self)
    }
    
    /// Returns a view of this graph with all edges reversed (transposed).
    /// 
    /// This is an alias for `reversed()` that uses the more common "transpose" terminology.
    /// - Returns: A `ReversedGraphView` that represents the transposed graph
    @inlinable
    public func transpose() -> ReversedGraphView<Self> {
        ReversedGraphView(base: self)
    }
}

// MARK: - Chaining Support for ReversedGraphView

extension ReversedGraphView {
    /// Returns a view of this reversed graph with all edges reversed again (back to original).
    /// 
    /// - Returns: The original graph
    @inlinable
    func reversed() -> Base {
        base
    }
    
    /// Returns a view of this reversed graph with all edges reversed again (back to original).
    /// 
    /// - Returns: The original graph
    @inlinable
    func transpose() -> Base {
        base
    }
}

