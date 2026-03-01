#if !GRAPHS_USES_TRAITS || GRAPHS_PATHFINDING
/// Dijkstra's algorithm for finding shortest paths from a source vertex.
///
/// Dijkstra's algorithm is a greedy algorithm that finds the shortest paths from a source
/// vertex to all other vertices in a weighted graph with non-negative edge weights.
///
/// - Complexity: O((V + E) log V) where V is the number of vertices and E is the number of edges
public struct Dijkstra<
    Graph: IncidenceGraph,
    Weight: Numeric & Comparable
> where
    Graph.VertexDescriptor: Hashable,
    Weight.Magnitude == Weight
{
    /// The vertex type of the graph.
    public typealias Vertex = Graph.VertexDescriptor
    /// The edge type of the graph.
    public typealias Edge = Graph.EdgeDescriptor

    /// A visitor that can be used to observe Dijkstra's algorithm progress.
    /// A visitor that can be used to observe Dijkstra's algorithm progress.
    public struct Visitor {
        /// Called when examining a vertex.
        public var examineVertex: ((Vertex) -> Void)?
        /// Called when examining an edge.
        public var examineEdge: ((Edge) -> Void)?
        /// Called when an edge is relaxed (distance updated).
        public var edgeRelaxed: ((Edge) -> Void)?
        /// Called when an edge is not relaxed (no distance improvement).
        public var edgeNotRelaxed: ((Edge) -> Void)?
        /// Called when a vertex is finished (all outgoing edges processed).
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

    /// The result of Dijkstra's algorithm execution.
    public struct Result {
        /// The vertex type of the graph.
        public typealias Vertex = Graph.VertexDescriptor
        /// The edge type of the graph.
        public typealias Edge = Graph.EdgeDescriptor
        /// The source vertex from which shortest paths were computed.
        public let source: Vertex
        /// The current vertex being processed.
        public let currentVertex: Vertex
        /// The distance property type for storing shortest distances.
        public let distanceProperty: any VertexProperty<Cost<Weight>>.Type
        /// The predecessor edge property type for storing path information.
        public let predecessorEdgeProperty: any VertexProperty<Edge?>.Type
        @usableFromInline
        let propertyMap: any PropertyMap<Vertex, VertexPropertyValues>
        
        /// Creates a new result.
        @inlinable
        public init(source: Vertex, currentVertex: Vertex, distanceProperty: any VertexProperty<Cost<Weight>>.Type, predecessorEdgeProperty: any VertexProperty<Edge?>.Type, propertyMap: any PropertyMap<Vertex, VertexPropertyValues>) {
            self.source = source
            self.currentVertex = currentVertex
            self.distanceProperty = distanceProperty
            self.predecessorEdgeProperty = predecessorEdgeProperty
            self.propertyMap = propertyMap
        }
    }

    private enum DistanceProperty: VertexProperty {
        static var defaultValue: Cost<Weight> { .infinite }
    }

    private enum PredecessorEdgeProperty: VertexProperty {
        static var defaultValue: Edge? { nil }
    }

    public struct PriorityItem {
        public typealias Vertex = Graph.VertexDescriptor
        public let vertex: Vertex
        public let cost: Cost<Weight>
        
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

            propertyMap[source][distanceProperty] = .finite(.zero)
            self.queue.enqueue(PriorityItem(vertex: source, cost: .finite(.zero)))
        }

    }
    
}

extension Dijkstra.Iterator: IteratorProtocol {
    @inlinable
    public mutating func next() -> Dijkstra.Result? {
        guard let currentVertex = queue.dequeue() else { return nil }
        
        if visited.contains(currentVertex.vertex) {
            return next()
        }
        
        let currentDistance = currentVertex.cost
        propertyMap[currentVertex.vertex][distanceProperty] = currentDistance
        
        visitor?.examineVertex?(currentVertex.vertex)
        
        for edge in graph.outgoingEdges(of: currentVertex.vertex) {
            guard let destination = graph.destination(of: edge) else { continue }
            let edgeWeight = self.edgeWeight.costToExplore(edge, graph)
            let newDistance = currentDistance + edgeWeight
            
            if newDistance < propertyMap[destination][distanceProperty] {
                propertyMap[destination][distanceProperty] = newDistance
                propertyMap[destination][predecessorEdgeProperty] = edge
                queue.enqueue(Dijkstra.PriorityItem(vertex: destination, cost: newDistance))
            }
        }
        
        visited.insert(currentVertex.vertex)
        visitor?.finishVertex?(currentVertex.vertex)
        
        return Dijkstra.Result(
            source: source,
            currentVertex: currentVertex.vertex,
            distanceProperty: distanceProperty,
            predecessorEdgeProperty: predecessorEdgeProperty,
            propertyMap: propertyMap
        )
    }
}

extension Dijkstra: Sequence {
    @inlinable
    public func makeIterator() -> Iterator {
        makeIterator(visitor: nil)
    }
}

extension Dijkstra.PriorityItem: Equatable {
    @inlinable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.vertex == rhs.vertex
    }
}

extension Dijkstra.PriorityItem: Comparable {
    @inlinable
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.cost < rhs.cost
    }
}

extension Dijkstra.Result {
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

    @inlinable
    public func predecessor(in graph: some IncidenceGraph<Vertex, Edge>) -> Vertex {
        predecessor(of: currentVertex, in: graph).unwrap(
            orReport: "The currently examined vertex should always have a predecessor"
        )
    }

    @inlinable
    public func predecessorEdge() -> Edge {
        predecessorEdge(of: currentVertex).unwrap(
            orReport: "The currently examined vertex should always have a predecessor edge"
        )
    }

    @inlinable
    public func vertices(in graph: some IncidenceGraph<Vertex, Edge>) -> [Vertex] {
        vertices(to: currentVertex, in: graph)
    }

    @inlinable
    public func edges(in graph: some IncidenceGraph<Vertex, Edge>) -> [Edge] {
        edges(to: currentVertex, in: graph)
    }

    @inlinable
    public func path(in graph: some IncidenceGraph<Vertex, Edge>) -> [(vertex: Vertex, edge: Edge)] {
        path(to: currentVertex, in: graph)
    }

    @inlinable
    public func distance(of vertex: Vertex) -> Cost<Weight> {
        propertyMap[vertex][distanceProperty]
    }

    @inlinable
    public func predecessor(of vertex: Vertex, in graph: some IncidenceGraph<Vertex, Edge>) -> Vertex? {
        predecessorEdge(of: vertex).flatMap(graph.source)
    }

    @inlinable
    public func predecessorEdge(of vertex: Vertex) -> Edge? {
        propertyMap[vertex][predecessorEdgeProperty]
    }

    @inlinable
    public func vertices(to destination: Vertex, in graph: some IncidenceGraph<Vertex, Edge>) -> [Vertex] {
        [source] + path(to: destination, in: graph).map(\.vertex)
    }

    @inlinable
    public func edges(to destination: Vertex, in graph: some IncidenceGraph<Vertex, Edge>) -> [Edge] {
        path(to: destination, in: graph).map(\.edge)
    }

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

    @inlinable
    public func hasPath(to vertex: Vertex) -> Bool {
        propertyMap[vertex][distanceProperty] != .infinite
    }
}

extension Dijkstra: VisitorSupportingSequence {}
#endif
