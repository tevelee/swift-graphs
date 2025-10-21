import Collections

/// An adjacency list implementation of a bipartite graph.
///
/// This implementation maintains separate storage for left and right partitions,
/// ensuring that edges only connect vertices from different partitions.
public struct BipartiteAdjacencyList<
    VertexStore: VertexStorage,
    EdgeStore: EdgeStorage,
    VertexPropertyMap: MutablePropertyMap,
    EdgePropertyMap: MutablePropertyMap
> where
    EdgeStore.Vertex == VertexStore.Vertex,
    VertexPropertyMap.Key == VertexStore.Vertex,
    VertexPropertyMap.Value == VertexPropertyValues,
    EdgePropertyMap.Key == EdgeStore.Edge,
    EdgePropertyMap.Value == EdgePropertyValues
{
    public var vertexStore: VertexStore
    public var edgeStore: EdgeStore
    public var vertexPropertyMap: VertexPropertyMap
    public var edgePropertyMap: EdgePropertyMap
    
    /// Maps vertices to their partition.
    @usableFromInline
    var vertexPartitions: [VertexStore.Vertex: BipartitePartition] = [:]
    
    /// Creates a new bipartite adjacency list with the specified storage components.
    ///
    /// - Parameters:
    ///   - vertexStore: The storage for vertices
    ///   - edgeStore: The storage for edges
    ///   - vertexPropertyMap: The property map for vertex properties
    ///   - edgePropertyMap: The property map for edge properties
    @inlinable
    public init(
        vertexStore: VertexStore,
        edgeStore: EdgeStore,
        vertexPropertyMap: VertexPropertyMap,
        edgePropertyMap: EdgePropertyMap
    ) {
        self.vertexStore = vertexStore
        self.edgeStore = edgeStore
        self.vertexPropertyMap = vertexPropertyMap
        self.edgePropertyMap = edgePropertyMap
    }
}

// MARK: - Convenience Initializers

extension BipartiteAdjacencyList where
    VertexStore == OrderedVertexStorage,
    EdgeStore == OrderedEdgeStorage<OrderedVertexStorage.Vertex>,
    VertexPropertyMap == DictionaryPropertyMap<OrderedVertexStorage.Vertex, VertexPropertyValues>,
    EdgePropertyMap == DictionaryPropertyMap<OrderedEdgeStorage<OrderedVertexStorage.Vertex>.Edge, EdgePropertyValues>
{
    /// Creates a new empty bipartite adjacency list with default storage types.
    ///
    /// - Returns: A new empty bipartite adjacency list
    @inlinable
    public init() where Self == BipartiteAdjacencyList<
        OrderedVertexStorage,
        OrderedEdgeStorage<OrderedVertexStorage.Vertex>,
        DictionaryPropertyMap<OrderedVertexStorage.Vertex, VertexPropertyValues>,
        DictionaryPropertyMap<OrderedEdgeStorage<OrderedVertexStorage.Vertex>.Edge, EdgePropertyValues>
    > {
        self.init(
            vertexStore: OrderedVertexStorage(),
            edgeStore: OrderedEdgeStorage<OrderedVertexStorage.Vertex>(),
            vertexPropertyMap: DictionaryPropertyMap<OrderedVertexStorage.Vertex, VertexPropertyValues>(defaultValue: .init()),
            edgePropertyMap: DictionaryPropertyMap<OrderedEdgeStorage<OrderedVertexStorage.Vertex>.Edge, EdgePropertyValues>(defaultValue: .init())
        )
    }
}

// MARK: - Protocol Conformances

extension BipartiteAdjacencyList: Graph {
    public typealias VertexDescriptor = VertexStore.Vertex
    public typealias EdgeDescriptor = EdgeStore.Edge
}

extension BipartiteAdjacencyList: VertexStorageBackedGraph, EdgeStorageBackedGraph {}

extension BipartiteAdjacencyList: IncidenceGraph {
    public typealias OutgoingEdges = EdgeStore.Edges
}

extension BipartiteAdjacencyList: BidirectionalGraph {
    public typealias IncomingEdges = EdgeStore.Edges
}

extension BipartiteAdjacencyList: VertexListGraph {}

extension BipartiteAdjacencyList: EdgeListGraph {}

extension BipartiteAdjacencyList: AdjacencyGraph {}

extension BipartiteAdjacencyList: MutableGraph {}

extension BipartiteAdjacencyList: PropertyGraph {
    public typealias VertexProperties = VertexPropertyValues
    public typealias EdgeProperties = EdgePropertyValues
    public typealias VertexPropertyMap = VertexPropertyMap
    public typealias EdgePropertyMap = EdgePropertyMap
}

extension BipartiteAdjacencyList: MutablePropertyGraph {}

extension BipartiteAdjacencyList: BipartiteGraph {
    public typealias PartitionVertices = [VertexDescriptor]
    
    @inlinable
    public func leftPartition() -> PartitionVertices {
        vertexPartitions.compactMap { (vertex, partition) in
            partition == .left ? vertex : nil
        }
    }
    
    @inlinable
    public func rightPartition() -> PartitionVertices {
        vertexPartitions.compactMap { (vertex, partition) in
            partition == .right ? vertex : nil
        }
    }
    
    @inlinable
    public func partition(of vertex: VertexDescriptor) -> BipartitePartition? {
        vertexPartitions[vertex]
    }
}

extension BipartiteAdjacencyList: MutableBipartiteGraph {
    
    @inlinable
    public mutating func addVertex(to partition: BipartitePartition) -> VertexDescriptor {
        let vertex = vertexStore.addVertex()
        vertexPartitions[vertex] = partition
        return vertex
    }
    
    @inlinable
    public mutating func move(vertex: VertexDescriptor, to newPartition: BipartitePartition) {
        vertexPartitions[vertex] = newPartition
    }
    
    @inlinable
    public mutating func addVertex() -> VertexDescriptor {
        // Default to left partition for backward compatibility
        addVertex(to: .left)
    }
    
    #if swift(>=6.2)
    @inlinable
    public mutating func remove(vertex: consuming VertexDescriptor) {
        // Remove all edges connected to this vertex
        for edge in outgoingEdges(of: vertex) {
            remove(edge: edge)
        }
        for edge in incomingEdges(of: vertex) {
            remove(edge: edge)
        }
        
        vertexPartitions.removeValue(forKey: vertex)
        vertexStore.remove(vertex: vertex)
    }
    #else
    @inlinable
    public mutating func remove(vertex: VertexDescriptor) {
        // Remove all edges connected to this vertex
        for edge in outgoingEdges(of: vertex) {
            remove(edge: edge)
        }
        for edge in incomingEdges(of: vertex) {
            remove(edge: edge)
        }
        
        vertexPartitions.removeValue(forKey: vertex)
        vertexStore.remove(vertex: vertex)
    }
    #endif
    
    @discardableResult
    @inlinable
    public mutating func addEdge(from source: VertexDescriptor, to destination: VertexDescriptor) -> EdgeDescriptor? {
        // Ensure vertices exist and are in different partitions
        guard vertexStore.contains(source),
              vertexStore.contains(destination),
              let sourcePartition = vertexPartitions[source],
              let destPartition = vertexPartitions[destination],
              sourcePartition != destPartition else {
            return nil
        }
        
        return edgeStore.addEdge(from: source, to: destination)
    }
}
