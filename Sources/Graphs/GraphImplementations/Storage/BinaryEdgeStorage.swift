import Collections

/// A storage implementation for binary tree edge structures.
///
/// BinaryEdgeStore provides efficient storage for binary tree graphs where each vertex
/// can have at most two children (left and right). This is optimized for binary tree
/// algorithms and provides O(1) access to left and right edges.
public struct BinaryEdgeStore<Vertex: Hashable> {
    /// An edge descriptor for binary tree edges.
    public struct Edge: Identifiable, Hashable {
        public let id: Int
        
        @inlinable
        public init(id: Int) {
            self.id = id
        }
    }
    
    @usableFromInline
    var leftEdgeMap: [Vertex: Edge] = [:]
    @usableFromInline
    var rightEdgeMap: [Vertex: Edge] = [:]
    @usableFromInline
    var edgesStore: OrderedDictionary<Edge, (source: Vertex, destination: Vertex)> = [:]
    @usableFromInline
    var nextEdgeId: Int = 0
}

extension BinaryEdgeStore: EdgeStorage {
    @inlinable
    public func edges() -> OrderedSet<Edge> { edgesStore.keys }
    
    @inlinable
    public var edgeCount: Int { edgesStore.count }
    
    @inlinable
    public func endpoints(of edge: Edge) -> (source: Vertex, destination: Vertex)? {
        edgesStore[edge]
    }
    
    @inlinable
    public func outgoingEdges(of vertex: Vertex) -> OrderedSet<Edge> {
        var result: OrderedSet<Edge> = []
        if let e = leftEdgeMap[vertex] { result.updateOrAppend(e) }
        if let e = rightEdgeMap[vertex] { result.updateOrAppend(e) }
        return result
    }
    
    @inlinable
    public func outDegree(of vertex: Vertex) -> Int {
        (leftEdgeMap[vertex] != nil ? 1 : 0) + (rightEdgeMap[vertex] != nil ? 1 : 0)
    }
    
    @inlinable
    public func incomingEdges(of vertex: Vertex) -> OrderedSet<Edge> {
        var result: OrderedSet<Edge> = []
        for (edge, endpoints) in edgesStore where endpoints.destination == vertex {
            result.updateOrAppend(edge)
        }
        return result
    }
    
    @inlinable
    public func inDegree(of vertex: Vertex) -> Int {
        incomingEdges(of: vertex).count
    }
    
    @discardableResult
    @inlinable
    public mutating func addEdge(from source: Vertex, to destination: Vertex) -> Edge {
        if leftEdgeMap[source] == nil {
            let e = Edge(id: nextEdgeId)
            nextEdgeId &+= 1
            leftEdgeMap[source] = e
            edgesStore[e] = (source, destination)
            return e
        } else if rightEdgeMap[source] == nil {
            let e = Edge(id: nextEdgeId)
            nextEdgeId &+= 1
            rightEdgeMap[source] = e
            edgesStore[e] = (source, destination)
            return e
        } else {
            // Third child: replace right by policy; adjust as needed
            let e = Edge(id: nextEdgeId)
            nextEdgeId &+= 1
            if let old = rightEdgeMap[source] {
                edgesStore.removeValue(forKey: old)
            }
            rightEdgeMap[source] = e
            edgesStore[e] = (source, destination)
            return e
        }
    }
    
    @inlinable
    public mutating func remove(edge: consuming Edge) {
        guard let endpoints = edgesStore.removeValue(forKey: edge) else { return }
        let parent = endpoints.source
        if leftEdgeMap[parent] == edge {
            leftEdgeMap.removeValue(forKey: parent)
        }
        if rightEdgeMap[parent] == edge {
            rightEdgeMap.removeValue(forKey: parent)
        }
    }
}

extension BinaryEdgeStore: BinaryEdgeStorage {
    @inlinable
    public func leftEdge(of v: Vertex) -> Edge? {
        leftEdgeMap[v]
    }
    
    @inlinable
    public func rightEdge(of v: Vertex) -> Edge? {
        rightEdgeMap[v]
    }
}


