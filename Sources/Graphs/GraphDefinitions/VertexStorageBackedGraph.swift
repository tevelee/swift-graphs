/// A protocol for graphs that use vertex storage for their vertex management.
///
/// This protocol allows graphs to delegate vertex management to a separate
/// storage component, enabling different storage strategies and implementations.
public protocol VertexStorageBackedGraph: Graph {
    /// The type of vertex storage used by this graph.
    associatedtype VertexStore: VertexStorage where VertexStore.Vertex == VertexDescriptor
    
    /// The vertex storage component.
    var vertexStore: VertexStore { get set }
}

extension VertexListGraph where Self: VertexStorageBackedGraph {
    @inlinable
    public func vertices() -> VertexStore.Vertices { vertexStore.vertices() }
    
    @inlinable
    public var vertexCount: Int { vertexStore.vertexCount }
}

extension MutableGraph where Self: VertexStorageBackedGraph & EdgeStorageBackedGraph {
    @discardableResult
    @inlinable
    public mutating func addVertex() -> VertexDescriptor { vertexStore.addVertex() }

    #if swift(>=6.2)
    @inlinable
    public mutating func remove(edge: consuming EdgeDescriptor) { edgeStore.remove(edge: edge) }
    #else
    @inlinable
    public mutating func remove(edge: EdgeDescriptor) { edgeStore.remove(edge: edge) }
    #endif
}

extension MutableGraph where Self: VertexStorageBackedGraph & EdgeStorageBackedGraph & IncidenceGraph {
    @discardableResult
    @inlinable
    public mutating func addEdge(from source: VertexDescriptor, to destination: VertexDescriptor) -> EdgeDescriptor? {
        guard vertexStore.contains(source), vertexStore.contains(destination) else { return nil }
        return edgeStore.addEdge(from: source, to: destination)
    }

    #if swift(>=6.2)
    @inlinable
    public mutating func remove(vertex: consuming VertexDescriptor) {
        for edge in outgoingEdges(of: vertex) { remove(edge: edge) }
        vertexStore.remove(vertex: vertex)
    }
    #else
    @inlinable
    public mutating func remove(vertex: VertexDescriptor) {
        for edge in outgoingEdges(of: vertex) { remove(edge: edge) }
        vertexStore.remove(vertex: vertex)
    }
    #endif
}

extension MutableGraph where Self: VertexStorageBackedGraph & EdgeStorageBackedGraph & BidirectionalGraph {
    #if swift(>=6.2)
    @inlinable
    public mutating func remove(vertex: consuming VertexDescriptor) {
        for edge in outgoingEdges(of: vertex) { remove(edge: edge) }
        for edge in incomingEdges(of: vertex) { remove(edge: edge) }
        vertexStore.remove(vertex: vertex)
    }
    #else
    @inlinable
    public mutating func remove(vertex: VertexDescriptor) {
        for edge in outgoingEdges(of: vertex) { remove(edge: edge) }
        for edge in incomingEdges(of: vertex) { remove(edge: edge) }
        vertexStore.remove(vertex: vertex)
    }
    #endif
}


