import Collections

/// A view of a graph that represents its complement.
///
/// The complement graph contains all edges that are not present in the original graph.
/// This is useful for algorithms that need to work with the complement of a graph.
public struct ComplementGraphView<
    Base: EdgeLookupGraph & VertexListGraph
>: Graph where
    Base.VertexDescriptor: Hashable
{
    public typealias VertexDescriptor = Base.VertexDescriptor
    
    /// An edge descriptor in the complement graph view.
    public struct EdgeDescriptor: Hashable {
        /// The source vertex of the edge.
        public let source: VertexDescriptor
        /// The destination vertex of the edge.
        public let destination: VertexDescriptor
        
        @inlinable
        public init(source: VertexDescriptor, destination: VertexDescriptor) {
            self.source = source
            self.destination = destination
        }
    }
    
    /// The underlying graph.
    public let base: Base
    
    /// Creates a new complement graph view.
    ///
    /// - Parameter base: The underlying graph to create the complement of
    @inlinable
    public init(base: Base) {
        self.base = base
    }
}

extension ComplementGraphView: VertexListGraph {
    public typealias Vertices = Base.Vertices
    
    @inlinable
    public func vertices() -> Vertices { base.vertices() }
    
    @inlinable
    public var vertexCount: Int { base.vertexCount }
}

extension ComplementGraphView: EdgeListGraph {
    public struct Edges: Sequence {
        @usableFromInline
        let base: Base
        
        @inlinable
        public init(base: Base) {
            self.base = base
        }
        
        @inlinable
        public func makeIterator() -> Iterator { Iterator(base: base, outer: base.vertices().makeIterator(), inner: nil, currentSource: nil) }
        
        public struct Iterator: IteratorProtocol {
            @usableFromInline
            let base: Base
            @usableFromInline
            var outer: Base.Vertices.Iterator
            @usableFromInline
            var inner: Base.Vertices.Iterator?
            @usableFromInline
            var currentSource: Base.VertexDescriptor?
            
            @inlinable
            public init(base: Base, outer: Base.Vertices.Iterator, inner: Base.Vertices.Iterator?, currentSource: Base.VertexDescriptor?) {
                self.base = base
                self.outer = outer
                self.inner = inner
                self.currentSource = currentSource
            }
            
            @inlinable
            public mutating func next() -> EdgeDescriptor? {
                while true {
                    if var innerIt = inner, let s = currentSource {
                        while let d = innerIt.next() {
                            if s == d { continue }
                            if base.edge(from: s, to: d) == nil { inner = innerIt; return EdgeDescriptor(source: s, destination: d) }
                        }
                        inner = nil
                    }
                    guard let s = outer.next() else { return nil }
                    currentSource = s
                    inner = base.vertices().makeIterator()
                }
            }
        }
    }
    
    @inlinable
    public func edges() -> Edges { .init(base: base) }
    
    @inlinable
    public var edgeCount: Int {
        // Count complement edges by iteration to avoid existential casts
        edges().reduce(0) { acc, _ in acc + 1 }
    }
}

extension ComplementGraphView: IncidenceGraph {
    public struct OutgoingEdges: Sequence {
        @usableFromInline
        let base: Base
        @usableFromInline
        let source: Base.VertexDescriptor
        
        @inlinable
        public init(base: Base, source: Base.VertexDescriptor) {
            self.base = base
            self.source = source
        }
        
        @inlinable
        public func makeIterator() -> Iterator { Iterator(base: base, source: source, it: base.vertices().makeIterator()) }
        
        public struct Iterator: IteratorProtocol {
            @usableFromInline
            let base: Base
            @usableFromInline
            let source: Base.VertexDescriptor
            @usableFromInline
            var it: Base.Vertices.Iterator
            
            @inlinable
            public init(base: Base, source: Base.VertexDescriptor, it: Base.Vertices.Iterator) {
                self.base = base
                self.source = source
                self.it = it
            }
            
            @inlinable
            public mutating func next() -> EdgeDescriptor? {
                while let d = it.next() {
                    if d == source { continue }
                    if base.edge(from: source, to: d) == nil { return EdgeDescriptor(source: source, destination: d) }
                }
                return nil
            }
        }
    }
    
    @inlinable
    public func outgoingEdges(of vertex: VertexDescriptor) -> OutgoingEdges { .init(base: base, source: vertex) }
    
    @inlinable
    public func source(of edge: EdgeDescriptor) -> VertexDescriptor? { edge.source }
    
    @inlinable
    public func destination(of edge: EdgeDescriptor) -> VertexDescriptor? { edge.destination }
    
    @inlinable
    public func outDegree(of vertex: VertexDescriptor) -> Int {
        var count = 0
        for d in base.vertices() {
            if d == vertex { continue }
            if base.edge(from: vertex, to: d) == nil { count &+= 1 }
        }
        return count
    }
}

// MARK: - Convenience Methods for Creating ComplementGraphView

extension EdgeLookupGraph where Self: VertexListGraph, VertexDescriptor: Hashable {
    /// Returns a view of this graph representing its complement.
    /// 
    /// The complement graph contains all possible edges that are not present in the original graph.
    /// - Returns: A `ComplementGraphView` that represents the complement graph
    @inlinable
    func complement() -> ComplementGraphView<Self> {
        ComplementGraphView(base: self)
    }
}

// MARK: - Chaining Support for ComplementGraphView

extension ComplementGraphView {
    /// Returns the complement of this complement graph (back to original).
    /// 
    /// - Returns: The original graph
    @inlinable
    func complement() -> Base {
        base
    }
}

