import OrderedCollections

/// Depth-First Search algorithm for traversing graphs.
///
/// Depth-First Search explores vertices by going as deep as possible along each branch
/// before backtracking. It can be used to detect cycles, find connected components,
/// and perform topological sorting.
///
/// - Complexity: O(V + E) where V is the number of vertices and E is the number of edges
public struct DepthFirstSearch<Graph: IncidenceGraph> where Graph.VertexDescriptor: Hashable {
    /// The vertex type of the graph.
    public typealias Vertex = Graph.VertexDescriptor
    /// The edge type of the graph.
    public typealias Edge = Graph.EdgeDescriptor

    /// The discovery and finish time of a vertex in DFS.
    public enum Time: Sendable {
        /// The vertex has not been discovered yet.
        case undiscovered
        /// The vertex was discovered at the given time.
        case discovered(UInt)
        /// The vertex was finished at the given time.
        case finished(UInt)
    }

    /// An event emitted synchronously while depth-first search advances.
    public enum Event {
        case vertexDiscovered(Vertex)
        case vertexExamined(Vertex)
        case edgeExamined(Edge)
        case treeEdgeTraversed(Edge)
        case backEdgeTraversed(Edge)
        case forwardEdgeTraversed(Edge)
        case crossEdgeTraversed(Edge)
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

    /// The color of a vertex in DFS (used for cycle detection).
    public enum Color: Sendable {
        /// Undiscovered vertex.
        case white
        /// Discovered but not fully processed vertex.
        case gray
        /// Fully processed vertex.
        case black
    }

    /// The result of a depth-first search iteration.
    public struct Result {
        public typealias Vertex = Graph.VertexDescriptor
        public typealias Edge = Graph.EdgeDescriptor
        @usableFromInline
        let source: Vertex
        public let currentVertex: Vertex
        @usableFromInline
        let discoveryTimeProperty: any VertexProperty<Time>.Type
        @usableFromInline
        let finishTimeProperty: any VertexProperty<Time>.Type
        @usableFromInline
        let predecessorEdgeProperty: any VertexProperty<Edge?>.Type
        @usableFromInline
        let depthProperty: any VertexProperty<UInt?>.Type
        @usableFromInline
        let propertyMap: any PropertyMap<Vertex, VertexPropertyValues>

        /// Creates a new result.
        ///
        /// - Parameters:
        ///   - source: The source vertex.
        ///   - currentVertex: The current vertex being examined.
        ///   - discoveryTimeProperty: The discovery time property type.
        ///   - finishTimeProperty: The finish time property type.
        ///   - predecessorEdgeProperty: The predecessor edge property type.
        ///   - depthProperty: The depth property type.
        ///   - propertyMap: The property map containing vertex data.
        @inlinable
        public init(
            source: Vertex,
            currentVertex: Vertex,
            discoveryTimeProperty: any VertexProperty<Time>.Type,
            finishTimeProperty: any VertexProperty<Time>.Type,
            predecessorEdgeProperty: any VertexProperty<Edge?>.Type,
            depthProperty: any VertexProperty<UInt?>.Type,
            propertyMap: any PropertyMap<Vertex, VertexPropertyValues>
        ) {
            self.source = source
            self.currentVertex = currentVertex
            self.discoveryTimeProperty = discoveryTimeProperty
            self.finishTimeProperty = finishTimeProperty
            self.predecessorEdgeProperty = predecessorEdgeProperty
            self.depthProperty = depthProperty
            self.propertyMap = propertyMap
        }
    }

    private enum ColorProperty: VertexProperty {
        static var defaultValue: Color { .white }
    }

    private enum DiscoveryTimeProperty: VertexProperty {
        static var defaultValue: Time { .undiscovered }
    }

    private enum FinishTimeProperty: VertexProperty {
        static var defaultValue: Time { .undiscovered }
    }

    private enum DepthProperty: VertexProperty {
        static var defaultValue: UInt? { nil }
    }

    /// A frame in the DFS stack.
    public struct DFSFrame {
        /// The vertex in this frame.
        @usableFromInline
        let vertex: Vertex
        /// Whether this is the first visit to the vertex.
        @usableFromInline
        let isFirstVisit: Bool
        /// The depth of the vertex in the DFS tree.
        @usableFromInline
        let depth: UInt

        @inlinable
        public init(vertex: Vertex, isFirstVisit: Bool, depth: UInt) {
            self.vertex = vertex
            self.isFirstVisit = isFirstVisit
            self.depth = depth
        }
    }

    /// The graph to search in.
    @usableFromInline
    let graph: Graph
    /// The source vertex.
    @usableFromInline
    let source: Vertex
    @usableFromInline
    let observation: AlgorithmObservation<Event>?
    @usableFromInline
    let shouldTraverse: ((TraversalCandidate) -> Bool)?

    /// Creates a new depth-first search algorithm instance.
    ///
    /// - Parameters:
    ///   - graph: The graph to search in.
    ///   - source: The source vertex.
    @inlinable
    public init(
        on graph: Graph,
        from source: Vertex
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
    @inlinable
    public func allowingTraversal(_ predicate: @escaping (TraversalCandidate) -> Bool) -> Self {
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

    /// Creates an iterator for the depth-first search.
    ///
    /// - Parameter observation: An optional observation of the algorithm's progress.
    /// - Returns: An iterator for the search.
    @inlinable
    public func makeIterator(observation: AlgorithmObservation<Event>?) -> Iterator {
        let combined = self.observation.map { $0.followed(by: observation) } ?? observation
        return Iterator(graph: graph, source: source, observation: combined, shouldTraverse: shouldTraverse)
    }

    /// An iterator for depth-first search.
    public struct Iterator {
        /// The graph to search in.
        @usableFromInline
        let graph: Graph
        /// The source vertex.
        @usableFromInline
        let source: Vertex
        /// An optional observation.
        @usableFromInline
        let observation: AlgorithmObservation<Event>?
        @usableFromInline
        let shouldTraverse: ((TraversalCandidate) -> Bool)?
        // The DFS stack
        @usableFromInline
        var stack: [DFSFrame] = []
        /// The current time counter.
        @usableFromInline
        var time: UInt = 0

        @usableFromInline
        var propertyMap: DictionaryPropertyMap<Vertex, VertexPropertyValues>
        @usableFromInline
        let colorProperty: any VertexProperty<Color>.Type = ColorProperty.self
        @usableFromInline
        let discoveryTimeProperty: any VertexProperty<Time>.Type = DiscoveryTimeProperty.self
        @usableFromInline
        let finishTimeProperty: any VertexProperty<Time>.Type = FinishTimeProperty.self
        @usableFromInline
        let predecessorEdgeProperty: any VertexProperty<Edge?>.Type = PredecessorEdgeProperty<Edge>.self
        @usableFromInline
        let depthProperty: any VertexProperty<UInt?>.Type = DepthProperty.self

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

            self.stack.push(DFSFrame(vertex: source, isFirstVisit: true, depth: 0))
        }

        /// Gets the next result from the search.
        ///
        /// - Returns: The next result, or `nil` if the search is complete.
        @inlinable
        public mutating func next() -> Result? {
            while !stack.isEmpty {
                guard let frame = stack.pop() else { break }
                let vertex = frame.vertex

                guard frame.isFirstVisit else {
                    time += 1
                    propertyMap[vertex][colorProperty] = .black
                    propertyMap[vertex][finishTimeProperty] = .finished(time)
                    observation?.receive(.vertexFinished(vertex))

                    return Result(
                        source: source,
                        currentVertex: vertex,
                        discoveryTimeProperty: discoveryTimeProperty,
                        finishTimeProperty: finishTimeProperty,
                        predecessorEdgeProperty: predecessorEdgeProperty,
                        depthProperty: depthProperty,
                        propertyMap: propertyMap
                    )
                }
                // Guard against duplicate stack entries that can arise from parallel edges:
                // if the vertex was already discovered via a sibling parallel edge, skip it.
                guard propertyMap[vertex][colorProperty] == .white else { continue }

                time += 1
                propertyMap[vertex][colorProperty] = .gray
                propertyMap[vertex][discoveryTimeProperty] = .discovered(time)
                propertyMap[vertex][depthProperty] = frame.depth

                observation?.receive(.vertexDiscovered(vertex))
                observation?.receive(.vertexExamined(vertex))

                stack.push(DFSFrame(vertex: vertex, isFirstVisit: false, depth: frame.depth))

                var whiteNeighbors: [Vertex] = []
                // Tracks white destinations already claimed in this batch so that
                // parallel edges to the same vertex don't fire treeEdge multiple times.
                var pendingWhite: Set<Vertex> = []
                for edge in graph.outgoingEdges(of: vertex) {
                    observation?.receive(.edgeExamined(edge))

                    guard let destination = graph.destination(of: edge) else { continue }

                    let destinationColor = propertyMap[destination][colorProperty]

                    switch destinationColor {
                        case .white:
                            // Only build the (expensive) Result context if a traversal
                            // policy is attached. The Result captures
                            // the existential property map, costing a retain on every
                            // edge — was happening for *all* edges of *every* vertex.
                            if let shouldTraverse {
                                let context = Result(
                                    source: source,
                                    currentVertex: vertex,
                                    discoveryTimeProperty: discoveryTimeProperty,
                                    finishTimeProperty: finishTimeProperty,
                                    predecessorEdgeProperty: predecessorEdgeProperty,
                                    depthProperty: depthProperty,
                                    propertyMap: propertyMap
                                )
                                if !shouldTraverse(.init(from: vertex, to: destination, via: edge, context: context)) { continue }
                            }
                            // Skip parallel edges to a destination already claimed this batch.
                            // Checked after the veto so a vetoed first parallel edge doesn't
                            // block subsequent parallel edges from being presented to shouldTraverse.
                            guard pendingWhite.insert(destination).inserted else { continue }
                            propertyMap[destination][predecessorEdgeProperty] = edge
                            observation?.receive(.treeEdgeTraversed(edge))
                            whiteNeighbors.append(destination)
                        case .gray:
                            observation?.receive(.backEdgeTraversed(edge))
                        case .black:
                            let sourceDiscoveryTime = propertyMap[vertex][discoveryTimeProperty]
                            let destinationDiscoveryTime = propertyMap[destination][discoveryTimeProperty]

                            if case .discovered(let sourceTime) = sourceDiscoveryTime,
                                case .discovered(let destTime) = destinationDiscoveryTime,
                                sourceTime < destTime
                            {
                                observation?.receive(.forwardEdgeTraversed(edge))
                            } else {
                                observation?.receive(.crossEdgeTraversed(edge))
                            }
                    }
                }

                for neighbor in whiteNeighbors.reversed() {
                    stack.push(DFSFrame(vertex: neighbor, isFirstVisit: true, depth: frame.depth + 1))
                }
            }

            return nil
        }
    }
}

extension DepthFirstSearch.Event: VertexDiscoveredEvent, VertexExaminedEvent, EdgeExaminedEvent {
    @inlinable
    public static func discoveredVertex(from event: Self) -> Graph.VertexDescriptor? {
        guard case .vertexDiscovered(let vertex) = event else { return nil }
        return vertex
    }

    @inlinable
    public static func examinedVertex(from event: Self) -> Graph.VertexDescriptor? {
        guard case .vertexExamined(let vertex) = event else { return nil }
        return vertex
    }

    @inlinable
    public static func examinedEdge(from event: Self) -> Graph.EdgeDescriptor? {
        guard case .edgeExamined(let edge) = event else { return nil }
        return edge
    }
}

extension DepthFirstSearch.Iterator: IteratorProtocol {}

extension DepthFirstSearch: Sequence {
    @inlinable
    public func makeIterator() -> Iterator {
        makeIterator(observation: nil)
    }
}

extension DepthFirstSearch.Result {
    /// Gets the discovery time of a vertex.
    ///
    /// - Parameter vertex: The vertex.
    /// - Returns: The discovery time of the vertex.
    @inlinable
    public func discoveryTime(of vertex: Vertex) -> DepthFirstSearch<Graph>.Time {
        propertyMap[vertex][discoveryTimeProperty]
    }

    /// Gets the finish time of a vertex.
    ///
    /// - Parameter vertex: The vertex.
    /// - Returns: The finish time of the vertex.
    @inlinable
    public func finishTime(of vertex: Vertex) -> DepthFirstSearch<Graph>.Time {
        propertyMap[vertex][finishTimeProperty]
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
        var current = destination
        var result: [(Vertex, Edge)] = []
        while let predecessorEdge = predecessorEdge(of: current) {
            result.insert((current, predecessorEdge), at: 0)
            guard let predecessor = graph.source(of: predecessorEdge) else { break }
            current = predecessor
        }
        return result
    }

    /// Gets the current depth.
    ///
    /// - Returns: The current depth.
    @inlinable
    public func depth() -> UInt {
        propertyMap[currentVertex][depthProperty] ?? 0
    }

    /// Gets the depth of a vertex.
    ///
    /// - Parameter vertex: The vertex.
    /// - Returns: The depth of the vertex, if it has been visited.
    @inlinable
    public func depth(of vertex: Vertex) -> UInt? {
        propertyMap[vertex][depthProperty]
    }
}

extension DepthFirstSearch.Time: Equatable {}

extension DepthFirstSearch.Time: Comparable {
    @inlinable
    public static func < (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
            case (_, .undiscovered): false
            case (.undiscovered, _): true
            case (.discovered(let lhsValue), .discovered(let rhsValue)): lhsValue < rhsValue
            case (.finished(let lhsValue), .finished(let rhsValue)): lhsValue < rhsValue
            case (.discovered(let lhsValue), .finished(let rhsValue)): lhsValue < rhsValue
            case (.finished(let lhsValue), .discovered(let rhsValue)): lhsValue < rhsValue
        }
    }
}

extension DepthFirstSearch.Time: ExpressibleByIntegerLiteral {
    public typealias IntegerLiteralType = UInt

    @inlinable
    public init(integerLiteral value: UInt) {
        self = .discovered(value)
    }
}

extension DepthFirstSearch.Time: ExpressibleByNilLiteral {
    @inlinable
    public init(nilLiteral: ()) {
        self = .undiscovered
    }
}

extension DepthFirstSearch: AlgorithmObservationSequence {}

extension DepthFirstSearch {
    /// Named selectors for depth-first-search events.
    public enum EventCases {
        public static var vertexDiscovered: AlgorithmEventCase<Event, Vertex> { .init { if case .vertexDiscovered(let value) = $0 { value } else { nil } } }
        public static var vertexExamined: AlgorithmEventCase<Event, Vertex> { .init { if case .vertexExamined(let value) = $0 { value } else { nil } } }
        public static var edgeExamined: AlgorithmEventCase<Event, Edge> { .init { if case .edgeExamined(let value) = $0 { value } else { nil } } }
        public static var treeEdgeTraversed: AlgorithmEventCase<Event, Edge> { .init { if case .treeEdgeTraversed(let value) = $0 { value } else { nil } } }
        public static var backEdgeTraversed: AlgorithmEventCase<Event, Edge> { .init { if case .backEdgeTraversed(let value) = $0 { value } else { nil } } }
        public static var forwardEdgeTraversed: AlgorithmEventCase<Event, Edge> {
            .init { if case .forwardEdgeTraversed(let value) = $0 { value } else { nil } }
        }
        public static var crossEdgeTraversed: AlgorithmEventCase<Event, Edge> { .init { if case .crossEdgeTraversed(let value) = $0 { value } else { nil } } }
        public static var vertexFinished: AlgorithmEventCase<Event, Vertex> { .init { if case .vertexFinished(let value) = $0 { value } else { nil } } }
    }
}
