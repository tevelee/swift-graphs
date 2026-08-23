#if !GRAPHS_USES_TRAITS || GRAPHS_BIPARTITE_GRAPH
    import OrderedCollections

    /// A bipartite adjacency-list graph with caller-selected storage adapters.
    ///
    /// This implementation maintains separate storage for left and right partitions,
    /// ensuring that edges only connect vertices from different partitions.
    public struct StorageBackedBipartiteAdjacencyList<
        VertexStore: VertexStorage,
        EdgeStore: EdgeStorage,
        VertexPropertyStore: MutablePropertyMap,
        EdgePropertyStore: MutablePropertyMap
    >
    where
        EdgeStore.Vertex == VertexStore.Vertex,
        VertexPropertyStore.Key == VertexStore.Vertex,
        VertexPropertyStore.Value == VertexPropertyValues,
        EdgePropertyStore.Key == EdgeStore.Edge,
        EdgePropertyStore.Value == EdgePropertyValues
    {
        @usableFromInline
        var vertexStorage: VertexStore
        @usableFromInline
        var edgeStorage: EdgeStore
        @usableFromInline
        var vertexPropertyStorage: VertexPropertyStore
        @usableFromInline
        var edgePropertyStorage: EdgePropertyStore

        /// Maps vertices to their partition.
        @usableFromInline
        var vertexPartitions: [VertexStore.Vertex: BipartitePartition] = [:]

        /// Creates a new bipartite adjacency list with the specified storage components.
        ///
        /// - Parameters:
        ///   - vertexStorage: The storage for vertices.
        ///   - edgeStorage: The storage for edges.
        ///   - vertexPropertyStorage: The property storage for vertices.
        ///   - edgePropertyStorage: The property storage for edges.
        @inlinable
        public init(
            vertexStorage: VertexStore,
            edgeStorage: EdgeStore,
            vertexPropertyStorage: VertexPropertyStore,
            edgePropertyStorage: EdgePropertyStore
        ) {
            self.vertexStorage = vertexStorage
            self.edgeStorage = edgeStorage
            self.vertexPropertyStorage = vertexPropertyStorage
            self.edgePropertyStorage = edgePropertyStorage
        }
    }

    /// The general-purpose bipartite adjacency-list graph.
    public typealias BipartiteAdjacencyList = StorageBackedBipartiteAdjacencyList<
        OrderedVertexStorage,
        OrderedEdgeStorage<OrderedVertexStorage.Vertex>,
        DictionaryPropertyMap<OrderedVertexStorage.Vertex, VertexPropertyValues>,
        DictionaryPropertyMap<OrderedEdgeStorage<OrderedVertexStorage.Vertex>.Edge, EdgePropertyValues>
    >

    // MARK: - Convenience Initializers

    extension StorageBackedBipartiteAdjacencyList
    where
        VertexStore == OrderedVertexStorage,
        EdgeStore == OrderedEdgeStorage<OrderedVertexStorage.Vertex>,
        VertexPropertyStore == DictionaryPropertyMap<OrderedVertexStorage.Vertex, VertexPropertyValues>,
        EdgePropertyStore == DictionaryPropertyMap<OrderedEdgeStorage<OrderedVertexStorage.Vertex>.Edge, EdgePropertyValues>
    {
        /// Creates a new empty bipartite adjacency list with default storage types.
        ///
        /// - Returns: A new empty bipartite adjacency list
        @inlinable
        public init()
        where
            Self == StorageBackedBipartiteAdjacencyList<
                OrderedVertexStorage,
                OrderedEdgeStorage<OrderedVertexStorage.Vertex>,
                DictionaryPropertyMap<OrderedVertexStorage.Vertex, VertexPropertyValues>,
                DictionaryPropertyMap<OrderedEdgeStorage<OrderedVertexStorage.Vertex>.Edge, EdgePropertyValues>
            >
        {
            self.init(
                vertexStorage: OrderedVertexStorage(),
                edgeStorage: OrderedEdgeStorage<OrderedVertexStorage.Vertex>(),
                vertexPropertyStorage: DictionaryPropertyMap<OrderedVertexStorage.Vertex, VertexPropertyValues>(defaultValue: .init()),
                edgePropertyStorage: DictionaryPropertyMap<OrderedEdgeStorage<OrderedVertexStorage.Vertex>.Edge, EdgePropertyValues>(defaultValue: .init())
            )
        }
    }

    // MARK: - Protocol Conformances

    extension StorageBackedBipartiteAdjacencyList: Graph {
        public typealias VertexDescriptor = VertexStore.Vertex
        public typealias EdgeDescriptor = EdgeStore.Edge
    }

    extension StorageBackedBipartiteAdjacencyList: IncidenceGraph {
        public typealias OutgoingEdges = EdgeStore.Edges

        @inlinable
        public func outgoingEdges(of vertex: VertexDescriptor) -> OutgoingEdges {
            edgeStorage.outgoingEdges(of: vertex)
        }

        @inlinable
        public func source(of edge: EdgeDescriptor) -> VertexDescriptor? {
            edgeStorage.endpoints(of: edge)?.source
        }

        @inlinable
        public func destination(of edge: EdgeDescriptor) -> VertexDescriptor? {
            edgeStorage.endpoints(of: edge)?.destination
        }

        @inlinable
        public func outDegree(of vertex: VertexDescriptor) -> Int {
            edgeStorage.outDegree(of: vertex)
        }
    }

    extension StorageBackedBipartiteAdjacencyList: BidirectionalGraph {
        public typealias IncomingEdges = EdgeStore.Edges

        @inlinable
        public func incomingEdges(of vertex: VertexDescriptor) -> IncomingEdges {
            edgeStorage.incomingEdges(of: vertex)
        }

        @inlinable
        public func inDegree(of vertex: VertexDescriptor) -> Int {
            edgeStorage.inDegree(of: vertex)
        }
    }

    extension StorageBackedBipartiteAdjacencyList: VertexListGraph {
        public typealias Vertices = VertexStore.Vertices

        @inlinable
        public func vertices() -> Vertices {
            vertexStorage.vertices()
        }

        @inlinable
        public var vertexCount: Int {
            vertexStorage.vertexCount
        }
    }

    extension StorageBackedBipartiteAdjacencyList: EdgeListGraph {
        public typealias Edges = EdgeStore.Edges

        @inlinable
        public func edges() -> Edges {
            edgeStorage.edges()
        }

        @inlinable
        public var edgeCount: Int {
            edgeStorage.edgeCount
        }
    }

    extension StorageBackedBipartiteAdjacencyList: AdjacencyGraph {}

    extension StorageBackedBipartiteAdjacencyList: PropertyGraph {
        public typealias VertexProperties = VertexPropertyValues
        public typealias EdgeProperties = EdgePropertyValues

        @inlinable
        public subscript(vertex: VertexDescriptor) -> VertexProperties {
            get { vertexPropertyStorage[vertex] }
            set { vertexPropertyStorage[vertex] = newValue }
        }

        @inlinable
        public subscript(edge: EdgeDescriptor) -> EdgeProperties {
            get { edgePropertyStorage[edge] }
            set { edgePropertyStorage[edge] = newValue }
        }
    }

    extension StorageBackedBipartiteAdjacencyList: MutablePropertyGraph {}

    extension StorageBackedBipartiteAdjacencyList: BipartiteGraph {
        public typealias PartitionVertices = [VertexDescriptor]

        @inlinable
        public func leftPartition() -> PartitionVertices {
            vertexPartitions.compactMap { vertex, partition in
                partition == .left ? vertex : nil
            }
        }

        @inlinable
        public func rightPartition() -> PartitionVertices {
            vertexPartitions.compactMap { vertex, partition in
                partition == .right ? vertex : nil
            }
        }

        @inlinable
        public func partition(of vertex: VertexDescriptor) -> BipartitePartition? {
            vertexPartitions[vertex]
        }
    }

    extension StorageBackedBipartiteAdjacencyList: MutableBipartiteGraph {

        @inlinable
        public mutating func addVertex(to partition: BipartitePartition) -> VertexDescriptor {
            let vertex = vertexStorage.addVertex()
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
                vertexStorage.remove(vertex: vertex)
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
                vertexStorage.remove(vertex: vertex)
            }
        #endif

        @discardableResult
        @inlinable
        public mutating func addEdge(from source: VertexDescriptor, to destination: VertexDescriptor) -> EdgeDescriptor? {
            // Ensure vertices exist and are in different partitions
            guard vertexStorage.contains(source),
                vertexStorage.contains(destination),
                let sourcePartition = vertexPartitions[source],
                let destPartition = vertexPartitions[destination],
                sourcePartition != destPartition
            else {
                return nil
            }

            return edgeStorage.addEdge(from: source, to: destination)
        }

        #if swift(>=6.2)
            @inlinable
            public mutating func remove(edge: consuming EdgeDescriptor) {
                edgeStorage.remove(edge: edge)
            }
        #else
            @inlinable
            public mutating func remove(edge: EdgeDescriptor) {
                edgeStorage.remove(edge: edge)
            }
        #endif
    }

    extension StorageBackedBipartiteAdjacencyList: MutableGraph {}
#endif
