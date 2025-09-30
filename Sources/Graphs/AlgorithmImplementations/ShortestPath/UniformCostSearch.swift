/// Uniform Cost Search algorithm for finding shortest paths from a source vertex.
///
/// Uniform Cost Search is a search algorithm that explores vertices in order of their
/// cost from the source. It guarantees finding the shortest path in weighted graphs.
///
/// - Complexity: O(E + V log V) where E is the number of edges and V is the number of vertices
public struct UniformCostSearch<
    Graph: IncidenceGraph & EdgePropertyGraph,
    Weight: Numeric & Comparable
> where
    Graph.VertexDescriptor: Hashable,
    Weight.Magnitude == Weight
{
    /// The vertex type of the graph.
    public typealias Vertex = Graph.VertexDescriptor
    /// The edge type of the graph.
    public typealias Edge = Graph.EdgeDescriptor

    /// A visitor that can be used to observe the uniform cost search algorithm's progress.
    public struct Visitor {
        /// Called when examining a vertex.
        public var examineVertex: ((Vertex) -> Void)?
        /// Called when examining an edge.
        public var examineEdge: ((Edge) -> Void)?
        /// Called when an edge is relaxed.
        public var edgeRelaxed: ((Edge) -> Void)?
        /// Called when an edge is not relaxed.
        public var edgeNotRelaxed: ((Edge) -> Void)?
        /// Called when finishing a vertex.
        public var finishVertex: ((Vertex) -> Void)?
        
        /// Creates a new visitor.
        @inlinable
        public init(
            examineVertex: ((Vertex) -> Void)? = nil,
            examineEdge: ((Edge) -> Void)? = nil,
            edgeRelaxed: ((Edge) -> Void)? = nil,
            edgeNotRelaxed: ((Edge) -> Void)? = nil,
            finishVertex: ((Vertex) -> Void)? = nil
        ) {
            self.examineVertex = examineVertex
            self.examineEdge = examineEdge
            self.edgeRelaxed = edgeRelaxed
            self.edgeNotRelaxed = edgeNotRelaxed
            self.finishVertex = finishVertex
        }
    }

    /// The result of a uniform cost search iteration.
    public struct Result {
        /// The vertex type of the graph.
        public typealias Vertex = Graph.VertexDescriptor
        /// The edge type of the graph.
        public typealias Edge = Graph.EdgeDescriptor
        @usableFromInline
        let source: Vertex
        /// The current vertex being examined.
        public let currentVertex: Vertex
        /// The distance property type.
        public let distanceProperty: any VertexProperty<Cost<Weight>>.Type
        /// The predecessor edge property type.
        public let predecessorEdgeProperty: any VertexProperty<Edge?>.Type
        /// The property map containing distances and predecessors.
        public let propertyMap: any PropertyMap<Vertex, VertexPropertyValues>
        
        /// Creates a new result.
        @inlinable
        public init(
            source: Vertex,
            currentVertex: Vertex,
            distanceProperty: any VertexProperty<Cost<Weight>>.Type,
            predecessorEdgeProperty: any VertexProperty<Edge?>.Type,
            propertyMap: any PropertyMap<Vertex, VertexPropertyValues>
        ) {
            self.source = source
            self.currentVertex = currentVertex
            self.distanceProperty = distanceProperty
            self.predecessorEdgeProperty = predecessorEdgeProperty
            self.propertyMap = propertyMap
        }
    }

    @usableFromInline
    enum DistanceProperty: VertexProperty {
        @usableFromInline
        static var defaultValue: Cost<Weight> { .infinite }
    }

    @usableFromInline
    enum PredecessorEdgeProperty: VertexProperty {
        @usableFromInline
        static var defaultValue: Edge? { nil }
    }

    /// A priority queue item for uniform cost search.
    public struct PriorityItem {
        /// The vertex type of the graph.
        public typealias Vertex = Graph.VertexDescriptor
        /// The vertex.
        public let vertex: Vertex
        /// The cost to reach this vertex.
        public let cost: Cost<Weight>
        
        /// Creates a new priority item.
        @inlinable
        public init(vertex: Vertex, cost: Cost<Weight>) {
            self.vertex = vertex
            self.cost = cost
        }
    }

    @usableFromInline
    let graph: Graph
    @usableFromInline
    let source: Vertex
    @usableFromInline
    let edgeWeight: CostDefinition<Graph, Weight>
    @usableFromInline
    let makePriorityQueue: () -> any QueueProtocol<PriorityItem>

    /// Creates a new uniform cost search algorithm instance.
    ///
    /// - Parameters:
    ///   - graph: The graph to search in.
    ///   - source: The source vertex.
    ///   - edgeWeight: The cost definition for edge weights.
    ///   - makePriorityQueue: A factory for creating priority queues.
    @inlinable
    public init(
        on graph: Graph,
        from source: Vertex,
        edgeWeight: CostDefinition<Graph, Weight>,
        makePriorityQueue: @escaping () -> any QueueProtocol<PriorityItem> = {
            PriorityQueue()
        }
    ) {
        self.graph = graph
        self.source = source
        self.edgeWeight = edgeWeight
        self.makePriorityQueue = makePriorityQueue
    }

    /// Creates an iterator for the uniform cost search.
    ///
    /// - Parameter visitor: An optional visitor to observe the algorithm's progress.
    /// - Returns: An iterator for the search.
    @inlinable
    public func makeIterator(visitor: Visitor?) -> Iterator {
        Iterator(
            graph: graph,
            source: source,
            edgeWeight: edgeWeight,
            visitor: visitor,
            queue: makePriorityQueue()
        )
    }

    /// An iterator for uniform cost search.
    public struct Iterator {
        @usableFromInline
        let graph: Graph
        @usableFromInline
        let source: Vertex
        @usableFromInline
        let edgeWeight: CostDefinition<Graph, Weight>
        @usableFromInline
        let visitor: Visitor?
        @usableFromInline
        var queue: any QueueProtocol<PriorityItem>
        @usableFromInline
        var visited: Set<Vertex> = []

        @usableFromInline
        var propertyMap: any MutablePropertyMap<Vertex, VertexPropertyValues>
        @usableFromInline
        let distanceProperty: any VertexProperty<Cost>.Type = DistanceProperty.self
        @usableFromInline
        let predecessorEdgeProperty: any VertexProperty<Edge?>.Type = PredecessorEdgeProperty.self

        /// Creates a new iterator.
        ///
        /// - Parameters:
        ///   - graph: The graph to search in.
        ///   - source: The source vertex.
        ///   - edgeWeight: The cost definition for edge weights.
        ///   - visitor: An optional visitor.
        ///   - queue: The priority queue to use.
        @inlinable
        public init(
            graph: Graph,
            source: Vertex,
            edgeWeight: CostDefinition<Graph, Weight>,
            visitor: Visitor?,
            queue: any QueueProtocol<PriorityItem>
        ) {
            self.graph = graph
            self.source = source
            self.edgeWeight = edgeWeight
            self.visitor = visitor
            self.queue = queue
            self.propertyMap = graph.makeVertexPropertyMap()

            // UCS only initializes the source node, not all nodes
            propertyMap[source][distanceProperty] = .finite(.zero)
            self.queue.enqueue(.init(vertex: source, cost: .finite(.zero)))
        }

        /// Gets the next result from the search.
        ///
        /// - Returns: The next result, or `nil` if the search is complete.
        @inlinable
        public mutating func next() -> Result? {
            var currentVertex: Vertex?
            while let popped = queue.dequeue() {
                if visited.contains(popped.vertex) { continue }
                let stored = propertyMap[popped.vertex][distanceProperty]
                if popped.cost != stored { continue }
                currentVertex = popped.vertex
                break
            }

            guard let currentVertex else { return nil }

            visitor?.examineVertex?(currentVertex)

            let currentCost = propertyMap[currentVertex][distanceProperty]
            for edge in graph.outgoingEdges(of: currentVertex) {
                visitor?.examineEdge?(edge)

                guard let destination = graph.destination(of: edge) else { continue }
                if visited.contains(destination) { continue }

                let weight = edgeWeight.costToExplore(edge, graph)
                let newCost = currentCost + weight

                // UCS: Only add to queue if we haven't seen this vertex before or found a better path
                let destinationCost = propertyMap[destination][distanceProperty]
                if newCost < destinationCost {
                    propertyMap[destination][distanceProperty] = newCost
                    propertyMap[destination][predecessorEdgeProperty] = edge
                    queue.enqueue(.init(vertex: destination, cost: newCost))
                    visitor?.edgeRelaxed?(edge)
                } else {
                    visitor?.edgeNotRelaxed?(edge)
                }
            }

            visited.insert(currentVertex)
            visitor?.finishVertex?(currentVertex)

            return Result(
                source: source,
                currentVertex: currentVertex,
                distanceProperty: distanceProperty,
                predecessorEdgeProperty: predecessorEdgeProperty,
                propertyMap: propertyMap
            )
        }
    }
    
}

extension UniformCostSearch.Iterator: IteratorProtocol {}

extension UniformCostSearch: Sequence {
    @inlinable
    public func makeIterator() -> Iterator {
        makeIterator(visitor: nil)
    }
}

extension UniformCostSearch.PriorityItem: Equatable {
    @inlinable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.vertex == rhs.vertex
    }
}

extension UniformCostSearch.PriorityItem: Comparable {
    @inlinable
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.cost < rhs.cost
    }
}

extension UniformCostSearch.Result {
    /// Gets the current distance.
    ///
    /// - Returns: The current distance.
    @inlinable
    public func currentDistance() -> Weight {
        switch distance(of: currentVertex) {
            case .finite(let value):
                return value
            case .infinite:
                assertionFailure("The currently examined vertex should always be reachable")
                return .zero
        }
    }

    /// Gets the predecessor vertex.
    ///
    /// - Parameter graph: The graph.
    /// - Returns: The predecessor vertex.
    @inlinable
    public func predecessor(in graph: some IncidenceGraph<Vertex, Edge>) -> Vertex {
        predecessor(of: currentVertex, in: graph).unwrap(
            orReport: "The currently examined vertex should always have a predecessor"
        )
    }

    /// Gets the predecessor edge.
    ///
    /// - Returns: The predecessor edge.
    @inlinable
    public func predecessorEdge() -> Edge {
        predecessorEdge(of: currentVertex).unwrap(
            orReport: "The currently examined vertex should always have a predecessor edge"
        )
    }

    /// Gets the vertices in the current path.
    ///
    /// - Parameter graph: The graph.
    /// - Returns: The vertices in the current path.
    @inlinable
    public func vertices(in graph: some IncidenceGraph<Vertex, Edge>) -> [Vertex] {
        vertices(to: currentVertex, in: graph)
    }

    /// Gets the edges in the current path.
    ///
    /// - Parameter graph: The graph.
    /// - Returns: The edges in the current path.
    @inlinable
    public func edges(in graph: some IncidenceGraph<Vertex, Edge>) -> [Edge] {
        edges(to: currentVertex, in: graph)
    }

    /// Gets the current path.
    ///
    /// - Parameter graph: The graph.
    /// - Returns: The current path.
    @inlinable
    public func path(in graph: some IncidenceGraph<Vertex, Edge>) -> [(vertex: Vertex, edge: Edge)] {
        path(to: currentVertex, in: graph)
    }

    /// Gets the distance to a vertex.
    ///
    /// - Parameter vertex: The vertex.
    /// - Returns: The distance to the vertex.
    @inlinable
    public func distance(of vertex: Vertex) -> Cost<Weight> {
        propertyMap[vertex][distanceProperty]
    }

    /// Gets the predecessor of a vertex.
    ///
    /// - Parameters:
    ///   - vertex: The vertex.
    ///   - graph: The graph.
    /// - Returns: The predecessor vertex, if one exists.
    @inlinable
    public func predecessor(of vertex: Vertex, in graph: some IncidenceGraph<Vertex, Edge>) -> Vertex? {
        predecessorEdge(of: vertex).flatMap(graph.source)
    }

    /// Gets the predecessor edge of a vertex.
    ///
    /// - Parameter vertex: The vertex.
    /// - Returns: The predecessor edge, if one exists.
    @inlinable
    public func predecessorEdge(of vertex: Vertex) -> Edge? {
        propertyMap[vertex][predecessorEdgeProperty]
    }

    /// Gets the vertices to a destination.
    ///
    /// - Parameters:
    ///   - destination: The destination vertex.
    ///   - graph: The graph.
    /// - Returns: The vertices to the destination.
    @inlinable
    public func vertices(to destination: Vertex, in graph: some IncidenceGraph<Vertex, Edge>) -> [Vertex] {
        [source] + path(to: destination, in: graph).map(\.vertex)
    }

    /// Gets the edges to a destination.
    ///
    /// - Parameters:
    ///   - destination: The destination vertex.
    ///   - graph: The graph.
    /// - Returns: The edges to the destination.
    @inlinable
    public func edges(to destination: Vertex, in graph: some IncidenceGraph<Vertex, Edge>) -> [Edge] {
        path(to: destination, in: graph).map(\.edge)
    }

    /// Gets the path to a destination.
    ///
    /// - Parameters:
    ///   - destination: The destination vertex.
    ///   - graph: The graph.
    /// - Returns: The path to the destination.
    @inlinable
    public func path(to destination: Vertex, in graph: some IncidenceGraph<Vertex, Edge>) -> [(vertex: Vertex, edge: Edge)] {
        var currentVertex = destination
        var result: [(Vertex, Edge)] = []
        while let predecessorEdge = predecessorEdge(of: currentVertex) {
            result.insert((currentVertex, predecessorEdge), at: 0)
            guard let predecessor = graph.source(of: predecessorEdge) else { break }
            currentVertex = predecessor
        }
        return result
    }

    /// Checks if there is a path to a vertex.
    ///
    /// - Parameter vertex: The vertex.
    /// - Returns: `true` if there is a path, `false` otherwise.
    @inlinable
    public func hasPath(to vertex: Vertex) -> Bool {
        propertyMap[vertex][distanceProperty] != .infinite
    }
}

extension UniformCostSearch: VisitorSupportingSequence {}
