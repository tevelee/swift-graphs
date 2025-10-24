/// An A* search algorithm implementation.
///
/// A* is an informed search algorithm that uses a heuristic function to estimate
/// the cost from the current vertex to the goal, making it more efficient than
/// Dijkstra's algorithm for finding shortest paths in many cases.
public struct AStar<
    Graph: IncidenceGraph,
    Weight: AdditiveArithmetic & Comparable,
    HScore: AdditiveArithmetic,
    FScore: Comparable
> where
    Graph.VertexDescriptor: Hashable
{
    public typealias Vertex = Graph.VertexDescriptor
    public typealias Edge = Graph.EdgeDescriptor
    public typealias GScore = Cost<Weight>

    /// A visitor for A* algorithm events.
    ///
    /// Visitors can be used to observe and react to different events during
    /// the A* search process, such as vertex examination and edge relaxation.
    public struct Visitor {
        public var examineVertex: ((Vertex) -> Void)?
        public var examineEdge: ((Edge) -> Void)?
        public var edgeRelaxed: ((Edge) -> Void)?
        public var edgeNotRelaxed: ((Edge) -> Void)?
        public var finishVertex: ((Vertex) -> Void)?
        
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

    /// A result from the A* search algorithm.
    ///
    /// Contains information about the current state of the search, including
    /// the current vertex, distance properties, and path reconstruction data.
    public struct Result {
        public typealias Vertex = Graph.VertexDescriptor
        public typealias Edge = Graph.EdgeDescriptor
        public typealias GScore = AStar.GScore
        
        @usableFromInline
        let source: Vertex
        public let currentVertex: Vertex
        public let gScoreProperty: any VertexProperty<GScore>.Type
        public let predecessorEdgeProperty: any VertexProperty<Edge?>.Type
        @usableFromInline
        let propertyMap: any PropertyMap<Vertex, VertexPropertyValues>
        
        @inlinable
        public init(
            source: Vertex,
            currentVertex: Vertex,
            gScoreProperty: any VertexProperty<GScore>.Type,
            predecessorEdgeProperty: any VertexProperty<Edge?>.Type,
            propertyMap: any PropertyMap<Vertex, VertexPropertyValues>
        ) {
            self.source = source
            self.currentVertex = currentVertex
            self.gScoreProperty = gScoreProperty
            self.predecessorEdgeProperty = predecessorEdgeProperty
            self.propertyMap = propertyMap
        }
    }

    private enum GScoreProperty: VertexProperty {
        static var defaultValue: GScore { .infinite }
    }

    private enum PredecessorEdgeProperty: VertexProperty {
        static var defaultValue: Edge? { nil }
    }

    /// A priority queue item for A* search.
    ///
    /// Contains a vertex and its total cost (g + h) for priority queue ordering.
    public struct PriorityItem {
        public typealias Vertex = Graph.VertexDescriptor
        public let vertex: Vertex
        public let totalCost: FScore
        
        @inlinable
        public init(vertex: Vertex, totalCost: FScore) {
            self.vertex = vertex
            self.totalCost = totalCost
        }
    }

    @usableFromInline
    let graph: Graph
    @usableFromInline
    let source: Vertex
    @usableFromInline
    let edgeWeight: CostDefinition<Graph, Weight>
    @usableFromInline
    let heuristic: Heuristic<Graph, HScore>
    @usableFromInline
    let calculateTotalCost: (GScore, HScore) -> FScore
    @usableFromInline
    let makePriorityQueue: () -> any QueueProtocol<PriorityItem>

    @inlinable
    public init(
        on graph: Graph,
        from source: Vertex,
        edgeWeight: CostDefinition<Graph, Weight>,
        heuristic: Heuristic<Graph, HScore>,
        calculateTotalCost: @escaping (Weight, HScore) -> FScore,
        makePriorityQueue: @escaping () -> any QueueProtocol<PriorityItem> = {
            PriorityQueue()
        }
    ) {
        self.graph = graph
        self.source = source
        self.edgeWeight = edgeWeight
        self.heuristic = heuristic
        self.calculateTotalCost = { gScore, hScore in
            switch gScore {
                case .infinite:
                    assertionFailure(".infinite means unreachable, but if it's being examined it should be reachable")
                    return calculateTotalCost(.zero, hScore)
                case .finite(let weight):
                    return calculateTotalCost(weight, hScore)
            }
        }
        self.makePriorityQueue = makePriorityQueue
    }

    @inlinable
    public func makeIterator(visitor: Visitor?) -> Iterator {
        Iterator(
            graph: graph,
            source: source,
            edgeWeight: edgeWeight,
            heuristic: heuristic,
            calculateTotalCost: calculateTotalCost,
            visitor: visitor,
            queue: makePriorityQueue()
        )
    }

    /// An iterator for A* search results.
    ///
    /// Provides sequential access to A* search results, yielding one vertex
    /// at a time in the order they are processed by the algorithm.
    public struct Iterator {
        @usableFromInline
        let graph: Graph
        @usableFromInline
        let source: Vertex
        @usableFromInline
        let edgeWeight: CostDefinition<Graph, Weight>
        @usableFromInline
        let heuristic: Heuristic<Graph, HScore>
        @usableFromInline
        let calculateTotalCost: (GScore, HScore) -> FScore
        @usableFromInline
        let visitor: Visitor?
        @usableFromInline
        var queue: any QueueProtocol<PriorityItem>
        @usableFromInline
        var visited: Set<Vertex> = []

        @usableFromInline
        var propertyMap: any MutablePropertyMap<Vertex, VertexPropertyValues>
        @usableFromInline
        let gScoreProperty: any VertexProperty<GScore>.Type = GScoreProperty.self
        @usableFromInline
        let predecessorEdgeProperty: any VertexProperty<Edge?>.Type = PredecessorEdgeProperty.self

        @inlinable
        public init(
            graph: Graph,
            source: Vertex,
            edgeWeight: CostDefinition<Graph, Weight>,
            heuristic: Heuristic<Graph, HScore>,
            calculateTotalCost: @escaping (GScore, HScore) -> FScore,
            visitor: Visitor?,
            queue: any QueueProtocol<PriorityItem>
        ) {
            self.graph = graph
            self.source = source
            self.edgeWeight = edgeWeight
            self.heuristic = heuristic
            self.calculateTotalCost = calculateTotalCost
            self.visitor = visitor
            self.queue = queue
            self.propertyMap = graph.makeVertexPropertyMap()

            let gScore: GScore = .finite(.zero)
            propertyMap[source][gScoreProperty] = gScore
            let hScore: HScore = heuristic.estimatedCost(source, graph)
            let fScore: FScore = calculateTotalCost(gScore, hScore)
            self.queue.enqueue(.init(vertex: source, totalCost: fScore))
        }

        @inlinable
        public mutating func next() -> Result? {
            // Find next valid vertex to process
            var current: Vertex?
            while let popped = queue.dequeue() {
                if visited.contains(popped.vertex) { continue }
                let storedG = propertyMap[popped.vertex][gScoreProperty]
                // Recompute f from current best g to ensure consistency
                let currentF = calculateTotalCost(storedG, heuristic.estimatedCost(popped.vertex, graph))
                if popped.totalCost != currentF { continue }
                current = popped.vertex
                break
            }

            guard let current else { return nil }

            visitor?.examineVertex?(current)

            let currentG = propertyMap[current][gScoreProperty]
            for edge in graph.outgoingEdges(of: current) {
                visitor?.examineEdge?(edge)

                guard let neighbor = graph.destination(of: edge) else { continue }
                if visited.contains(neighbor) { continue }

                let weight = edgeWeight.costToExplore(edge, graph)
                let tentativeG = currentG + weight

                let neighborG = propertyMap[neighbor][gScoreProperty]
                if tentativeG < neighborG {
                    propertyMap[neighbor][gScoreProperty] = tentativeG
                    propertyMap[neighbor][predecessorEdgeProperty] = edge
                    let fScore = calculateTotalCost(tentativeG, heuristic.estimatedCost(neighbor, graph))
                    queue.enqueue(.init(vertex: neighbor, totalCost: fScore))
                    visitor?.edgeRelaxed?(edge)
                } else {
                    visitor?.edgeNotRelaxed?(edge)
                }
            }

            visited.insert(current)
            visitor?.finishVertex?(current)

            return Result(
                source: source,
                currentVertex: current,
                gScoreProperty: gScoreProperty,
                predecessorEdgeProperty: predecessorEdgeProperty,
                propertyMap: propertyMap
            )
        }
    }
}

extension AStar.Iterator: IteratorProtocol {}

extension AStar: Sequence {
    @inlinable
    public func makeIterator() -> Iterator {
        makeIterator(visitor: nil)
    }
}

extension AStar: VisitorSupporting {}

extension AStar.PriorityItem: Equatable {
    @inlinable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.vertex == rhs.vertex
    }
}

extension AStar.PriorityItem: Comparable {
    @inlinable
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.totalCost < rhs.totalCost
    }
}

extension AStar.Result {
    @inlinable
    public func currentDistance() -> Weight {
        switch gScore(of: currentVertex) {
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
    public func gScore(of vertex: Vertex) -> GScore {
        propertyMap[vertex][gScoreProperty]
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
        var current = destination
        var result: [(Vertex, Edge)] = []
        while let predecessorEdge = predecessorEdge(of: current) {
            result.insert((current, predecessorEdge), at: 0)
            guard let predecessor = graph.source(of: predecessorEdge) else { break }
            current = predecessor
        }
        return result
    }

    @inlinable
    public func hasPath(to vertex: Vertex) -> Bool {
        propertyMap[vertex][gScoreProperty] != .infinite
    }
}

/// A heuristic function for A* search.
///
/// Heuristics provide estimates of the cost from a given vertex to the goal,
/// helping A* find optimal paths more efficiently than uninformed search algorithms.
public struct Heuristic<Graph: Graphs.Graph, EstimatedCost> {
    public let estimatedCost: (Graph.VertexDescriptor, Graph) -> EstimatedCost
    
    @inlinable
    public init(estimatedCost: @escaping (Graph.VertexDescriptor, Graph) -> EstimatedCost) {
        self.estimatedCost = estimatedCost
    }
}

extension Heuristic {
    /// Creates a uniform heuristic that returns the same value for all vertices.
    ///
    /// - Parameter value: The constant value to return for all vertices
    /// - Returns: A uniform heuristic
    @inlinable
    public static func uniform(_ value: EstimatedCost) -> Self {
        .init { _, _ in
            value
        }
    }
    
    /// Creates a distance-based heuristic using a distance algorithm.
    ///
    /// - Parameters:
    ///   - destination: The target vertex
    ///   - distance: The distance algorithm to use
    /// - Returns: A distance-based heuristic
    @inlinable
    public static func distance(
        to destination: Graph.VertexDescriptor,
        using distance: DistanceAlgorithm<Graph.VertexDescriptor, EstimatedCost>
    ) -> Self {
        .init { vertex, _ in
            distance.calculateDistance(vertex, destination)
        }
    }
}

#if canImport(simd)
import simd

extension Heuristic where Graph: PropertyGraph {
    /// Creates a Euclidean distance heuristic for vertices with coordinate properties.
    ///
    /// - Parameters:
    ///   - destination: The target vertex
    ///   - coordinates: A function that extracts coordinates from vertex properties
    /// - Returns: A Euclidean distance heuristic
    @inlinable
    public static func euclideanDistance<Coordinate: SIMD>(
        to destination: Graph.VertexDescriptor,
        of coordinates: @escaping (VertexProperties) -> Coordinate
    ) -> Self where EstimatedCost == Coordinate.Scalar, Coordinate.Scalar: FloatingPoint {
        .init { vertex, graph in
            DistanceAlgorithm.euclidean { coordinates(graph[$0]) }.calculateDistance(vertex, destination)
        }
    }
    
    /// Creates a Manhattan distance heuristic for vertices with coordinate properties.
    ///
    /// - Parameters:
    ///   - destination: The target vertex
    ///   - coordinates: A function that extracts coordinates from vertex properties
    /// - Returns: A Manhattan distance heuristic
    @inlinable
    public static func manhattanDistance<Coordinate: SIMD>(
        to destination: Graph.VertexDescriptor,
        of coordinates: @escaping (VertexProperties) -> Coordinate
    ) -> Self where EstimatedCost == Coordinate.Scalar, Coordinate.Scalar: FloatingPoint {
        .init { vertex, graph in
            DistanceAlgorithm.manhattan { coordinates(graph[$0]) }.calculateDistance(vertex, destination)
        }
    }
}
#endif

extension AStar: VisitorSupportingSequence {}
