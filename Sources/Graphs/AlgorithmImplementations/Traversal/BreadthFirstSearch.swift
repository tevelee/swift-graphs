import DequeModule

/// Breadth-First Search algorithm for traversing graphs.
///
/// Breadth-First Search explores vertices level by level, visiting all vertices
/// at distance k before visiting vertices at distance k+1.
///
/// - Complexity: O(V + E) where V is the number of vertices and E is the number of edges
public struct BreadthFirstSearch<Graph: IncidenceGraph> where Graph.VertexDescriptor: Hashable {
    /// The vertex type of the graph.
    public typealias Vertex = Graph.VertexDescriptor
    /// The edge type of the graph.
    public typealias Edge = Graph.EdgeDescriptor

    /// The distance from the source vertex.
    public enum Distance: Sendable {
        /// The vertex is unreachable.
        case unreachable
        /// The vertex is reachable at the given depth.
        case reachable(depth: UInt)
    }

    /// An event emitted synchronously while breadth-first search advances.
    public enum Event {
        case vertexDiscovered(Vertex)
        case vertexExamined(Vertex)
        case edgeExamined(Edge)
        case treeEdgeTraversed(Edge)
        case nonTreeEdgeTraversed(Edge)
        case grayTargetEdgeTraversed(Edge)
        case blackTargetEdgeTraversed(Edge)
        case vertexFinished(Vertex)
    }

    /// A candidate tree edge presented to a traversal policy.
    public struct TraversalCandidate {
        public let from: Vertex
        public let to: Vertex
        public let via: Edge
        public let context: Result

        @inlinable
        public init(from: Vertex, to: Vertex, via: Edge, context: Result) {
            self.from = from
            self.to = to
            self.via = via
            self.context = context
        }
    }

    @usableFromInline
    enum Color: Equatable, Sendable {
        case white  // Undiscovered
        case gray  // Discovered but not fully processed
        case black  // Fully processed
    }

    /// The result of a breadth-first search iteration.
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
        public let distanceProperty: any VertexProperty<Distance>.Type
        /// The predecessor edge property type.
        public let predecessorEdgeProperty: any VertexProperty<Edge?>.Type
        /// The property map containing distances and predecessors.
        public let propertyMap: any PropertyMap<Vertex, VertexPropertyValues>

        /// Creates a new result.
        @inlinable
        public init(
            source: Vertex,
            currentVertex: Vertex,
            distanceProperty: any VertexProperty<Distance>.Type,
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
    enum ColorProperty: VertexProperty {
        @usableFromInline
        static var defaultValue: Color { .white }
    }

    @usableFromInline
    enum DistanceProperty: VertexProperty {
        @usableFromInline
        static var defaultValue: Distance { .unreachable }
    }

    @usableFromInline
    let graph: Graph
    @usableFromInline
    let source: Vertex
    @usableFromInline
    let observation: AlgorithmObservation<Event>?
    @usableFromInline
    let shouldTraverse: ((TraversalCandidate) -> Bool)?

    /// Creates a new breadth-first search algorithm instance.
    ///
    /// - Parameters:
    ///   - graph: The graph to search in.
    ///   - source: The source vertex.
    @inlinable
    public init(
        on graph: Graph,
        from source: Vertex  // TODO: multi source with a set/sequence of vertices
    ) {
        self.graph = graph
        self.source = source
        self.observation = nil
        self.shouldTraverse = nil
    }

    @inlinable
    init(
        on graph: Graph,
        from source: Vertex,
        observation: AlgorithmObservation<Event>? = nil,
        shouldTraverse: ((TraversalCandidate) -> Bool)? = nil
    ) {
        self.graph = graph
        self.source = source
        self.observation = observation
        self.shouldTraverse = shouldTraverse
    }

    /// Adds a policy that decides whether candidate tree edges may be traversed.
    ///
    /// Repeated policies are evaluated in attachment order and short-circuit on
    /// the first rejection.
    @inlinable
    public func allowingTraversal(
        _ predicate: @escaping (TraversalCandidate) -> Bool
    ) -> Self {
        let earlier = shouldTraverse
        return .init(
            on: graph,
            from: source,
            observation: observation,
            shouldTraverse: { candidate in
                (earlier?(candidate) ?? true) && predicate(candidate)
            }
        )
    }

    /// Creates an iterator for the breadth-first search.
    ///
    /// - Parameter observation: An optional observation of the algorithm's progress.
    /// - Returns: An iterator for the search.
    @inlinable
    public func makeIterator(observation: AlgorithmObservation<Event>?) -> Iterator {
        let combined = self.observation.map { $0.followed(by: observation) } ?? observation
        return Iterator(graph: graph, source: source, observation: combined, shouldTraverse: shouldTraverse)
    }

    /// An iterator for breadth-first search.
    public struct Iterator {
        @usableFromInline
        let graph: Graph
        @usableFromInline
        let source: Vertex
        @usableFromInline
        let observation: AlgorithmObservation<Event>?
        @usableFromInline
        let shouldTraverse: ((TraversalCandidate) -> Bool)?
        @usableFromInline
        var queue: Deque<Vertex> = []

        @usableFromInline
        var propertyMap: DictionaryPropertyMap<Vertex, VertexPropertyValues>
        @usableFromInline
        let colorProperty: any VertexProperty<Color>.Type = ColorProperty.self
        @usableFromInline
        let distanceProperty: any VertexProperty<Distance>.Type = DistanceProperty.self
        @usableFromInline
        let predecessorEdgeProperty: any VertexProperty<Edge?>.Type = PredecessorEdgeProperty<Edge>.self

        /// Creates a new iterator.
        ///
        /// - Parameters:
        ///   - graph: The graph to search in.
        ///   - source: The source vertex.
        ///   - observation: An optional observation.
        ///   - shouldTraverse: An optional policy for candidate tree edges.
        @inlinable
        public init(
            graph: Graph,
            source: Vertex,
            observation: AlgorithmObservation<Event>? = nil,
            shouldTraverse: ((TraversalCandidate) -> Bool)? = nil
        ) {
            self.graph = graph
            self.source = source
            self.observation = observation
            self.shouldTraverse = shouldTraverse
            self.propertyMap = graph.makeVertexPropertyMap()

            propertyMap[source][colorProperty] = .gray
            propertyMap[source][distanceProperty] = .reachable(depth: 0)
            self.queue.enqueue(source)
            observation?.receive(.vertexDiscovered(source))
        }

        /// Gets the next result from the search.
        ///
        /// - Returns: The next result, or `nil` if the search is complete.
        @inlinable
        public mutating func next() -> Result? {
            guard let current = queue.dequeue() else {
                return nil
            }

            observation?.receive(.vertexExamined(current))

            for edge in graph.outgoingEdges(of: current) {
                observation?.receive(.edgeExamined(edge))

                guard let destination = graph.destination(of: edge) else { continue }

                let destinationColor = propertyMap[destination][colorProperty]

                switch destinationColor {
                    case .white:
                        // Tree edge - first time discovering this vertex
                        let context = Result(
                            source: source,
                            currentVertex: current,
                            distanceProperty: distanceProperty,
                            predecessorEdgeProperty: predecessorEdgeProperty,
                            propertyMap: propertyMap
                        )
                        if let shouldTraverse,
                            !shouldTraverse(.init(from: current, to: destination, via: edge, context: context))
                        {
                            continue
                        }
                        propertyMap[destination][colorProperty] = .gray
                        propertyMap[destination][distanceProperty] = propertyMap[current][distanceProperty] + 1
                        propertyMap[destination][predecessorEdgeProperty] = edge
                        observation?.receive(.vertexDiscovered(destination))
                        queue.enqueue(destination)
                        observation?.receive(.treeEdgeTraversed(edge))
                    case .gray:
                        // Non-tree edge to an in-progress vertex
                        observation?.receive(.grayTargetEdgeTraversed(edge))
                        observation?.receive(.nonTreeEdgeTraversed(edge))
                    case .black:
                        // Non-tree edge to a finished vertex
                        observation?.receive(.blackTargetEdgeTraversed(edge))
                        observation?.receive(.nonTreeEdgeTraversed(edge))
                }
            }

            propertyMap[current][colorProperty] = .black
            observation?.receive(.vertexFinished(current))

            return Result(
                source: source,
                currentVertex: current,
                distanceProperty: distanceProperty,
                predecessorEdgeProperty: predecessorEdgeProperty,
                propertyMap: propertyMap
            )
        }
    }
}

extension BreadthFirstSearch.Iterator: IteratorProtocol {}

extension BreadthFirstSearch: Sequence {
    @inlinable
    public func makeIterator() -> Iterator {
        makeIterator(observation: nil)
    }
}

extension BreadthFirstSearch.Result {
    /// Gets the current depth.
    ///
    /// - Returns: The current depth.
    @inlinable
    public func depth() -> UInt {
        switch depth(of: currentVertex) {
            case .reachable(let distance):
                return distance
            case .unreachable:
                assertionFailure("The currently examined vertex should always be reachable")
                return 0
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

    /// Gets the depth of a vertex.
    ///
    /// - Parameter vertex: The vertex.
    /// - Returns: The depth of the vertex.
    @inlinable
    public func depth(of vertex: Vertex) -> BreadthFirstSearch.Distance {
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

    /// Checks if there is a path to a vertex.
    ///
    /// - Parameter vertex: The vertex.
    /// - Returns: `true` if there is a path, `false` otherwise.
    @inlinable
    public func hasPath(to vertex: Vertex) -> Bool {
        propertyMap[vertex][distanceProperty] != .unreachable
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
        var current = destination
        var result: [(Vertex, Edge)] = []
        while let predecessorEdge = predecessorEdge(of: current) {
            result.insert((current, predecessorEdge), at: 0)
            guard let predecessor = graph.source(of: predecessorEdge) else { break }
            current = predecessor
        }
        return result
    }
}

extension BreadthFirstSearch.Distance: Equatable {
    @inlinable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
            case (.unreachable, .unreachable):
                return true
            case (.reachable(let lhsDepth), .reachable(let rhsDepth)):
                return lhsDepth == rhsDepth
            default:
                return false
        }
    }
}

extension BreadthFirstSearch.Distance: Comparable {
    @inlinable
    public static func < (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
            case (.unreachable, _): false
            case (_, .unreachable): true
            case (.reachable(let lhsValue), .reachable(let rhsValue)): lhsValue < rhsValue
        }
    }
}

extension BreadthFirstSearch.Distance {
    /// Adds an amount to a distance.
    ///
    /// - Parameters:
    ///   - distance: The distance.
    ///   - amount: The amount to add.
    /// - Returns: The new distance.
    @inlinable
    public static func + (distance: Self, amount: UInt) -> Self {
        switch distance {
            case .unreachable: .unreachable
            case .reachable(let depth): .reachable(depth: depth + amount)
        }
    }
}

extension BreadthFirstSearch.Distance: ExpressibleByIntegerLiteral {
    @inlinable
    public init(integerLiteral value: UInt) {
        self = .reachable(depth: value)
    }
}

extension BreadthFirstSearch.Distance: ExpressibleByNilLiteral {
    @inlinable
    public init(nilLiteral: ()) {
        self = .unreachable
    }
}

extension BreadthFirstSearch: AlgorithmObservationSequence {}

extension BreadthFirstSearch.Event: VertexDiscoveredEvent, VertexExaminedEvent, EdgeExaminedEvent {
    /// Returns a discovered vertex carried by the event.
    @inlinable
    public static func discoveredVertex(from event: Self) -> Graph.VertexDescriptor? {
        guard case .vertexDiscovered(let vertex) = event else { return nil }
        return vertex
    }

    /// Returns an examined vertex carried by the event.
    @inlinable
    public static func examinedVertex(from event: Self) -> Graph.VertexDescriptor? {
        guard case .vertexExamined(let vertex) = event else { return nil }
        return vertex
    }

    /// Returns an examined edge carried by the event.
    @inlinable
    public static func examinedEdge(from event: Self) -> Graph.EdgeDescriptor? {
        guard case .edgeExamined(let edge) = event else { return nil }
        return edge
    }
}

extension BreadthFirstSearch {
    /// Named selectors for breadth-first-search events.
    public enum EventCases {
        public static var vertexDiscovered: AlgorithmEventCase<Event, Vertex> { .init { if case .vertexDiscovered(let value) = $0 { value } else { nil } } }
        public static var vertexExamined: AlgorithmEventCase<Event, Vertex> { .init { if case .vertexExamined(let value) = $0 { value } else { nil } } }
        public static var edgeExamined: AlgorithmEventCase<Event, Edge> { .init { if case .edgeExamined(let value) = $0 { value } else { nil } } }
        public static var treeEdgeTraversed: AlgorithmEventCase<Event, Edge> { .init { if case .treeEdgeTraversed(let value) = $0 { value } else { nil } } }
        public static var nonTreeEdgeTraversed: AlgorithmEventCase<Event, Edge> {
            .init { if case .nonTreeEdgeTraversed(let value) = $0 { value } else { nil } }
        }
        public static var grayTargetEdgeTraversed: AlgorithmEventCase<Event, Edge> {
            .init { if case .grayTargetEdgeTraversed(let value) = $0 { value } else { nil } }
        }
        public static var blackTargetEdgeTraversed: AlgorithmEventCase<Event, Edge> {
            .init { if case .blackTargetEdgeTraversed(let value) = $0 { value } else { nil } }
        }
        public static var vertexFinished: AlgorithmEventCase<Event, Vertex> { .init { if case .vertexFinished(let value) = $0 { value } else { nil } } }
    }
}
