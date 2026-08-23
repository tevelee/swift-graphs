/// Composite algorithm for checking if a graph is a tree using separate connected and cyclic algorithms.
public struct CompositeTreePropertyAlgorithm<Graph: IncidenceGraph & VertexListGraph & EdgeListGraph> where Graph.VertexDescriptor: Hashable {
    public struct EdgeCount {
        public let expected: Int
        public let actual: Int

        public init(expected: Int, actual: Int) {
            self.expected = expected
            self.actual = actual
        }
    }

    public enum Event {
        case edgeCountChecked(EdgeCount)
        case edgeCountMismatchDetected(EdgeCount)
        case connectivityCheckStarted
        case connectivityDetermined(Bool)
        case acyclicityCheckStarted
        case acyclicityDetermined(Bool)
    }

    public enum EventCases {
        public static var edgeCountChecked: AlgorithmEventCase<Event, EdgeCount> {
            .init {
                guard case .edgeCountChecked(let value) = $0 else { return nil }
                return value
            }
        }
        public static var edgeCountMismatchDetected: AlgorithmEventCase<Event, EdgeCount> {
            .init {
                guard case .edgeCountMismatchDetected(let value) = $0 else { return nil }
                return value
            }
        }
        public static var connectivityCheckStarted: AlgorithmEventCase<Event, Void> {
            .init {
                guard case .connectivityCheckStarted = $0 else { return nil }
                return ()
            }
        }
        public static var connectivityDetermined: AlgorithmEventCase<Event, Bool> {
            .init {
                guard case .connectivityDetermined(let value) = $0 else { return nil }
                return value
            }
        }
        public static var acyclicityCheckStarted: AlgorithmEventCase<Event, Void> {
            .init {
                guard case .acyclicityCheckStarted = $0 else { return nil }
                return ()
            }
        }
        public static var acyclicityDetermined: AlgorithmEventCase<Event, Bool> {
            .init {
                guard case .acyclicityDetermined(let value) = $0 else { return nil }
                return value
            }
        }
    }

    @usableFromInline
    let connectedAlgorithm: any ConnectedPropertyAlgorithm<Graph>
    @usableFromInline
    let cyclicAlgorithm: any CyclicPropertyAlgorithm<Graph>

    /// Creates a new composite tree property algorithm.
    ///
    /// - Parameters:
    ///   - connectedAlgorithm: The connected property algorithm to use
    ///   - cyclicAlgorithm: The cyclic property algorithm to use
    @inlinable
    public init(
        connectedAlgorithm: any ConnectedPropertyAlgorithm<Graph>,
        cyclicAlgorithm: any CyclicPropertyAlgorithm<Graph>
    ) {
        self.connectedAlgorithm = connectedAlgorithm
        self.cyclicAlgorithm = cyclicAlgorithm
    }

    /// Checks if the graph is a tree using composite algorithms.
    ///
    /// - Parameters:
    ///   - graph: The graph to check
    ///   - observation: An optional observation of the algorithm progress
    /// - Returns: `true` if the graph is a tree, `false` otherwise
    @inlinable
    public func isTree(
        in graph: Graph,
        observation: AlgorithmObservation<Event>?
    ) -> Bool {
        // Handle empty graphs
        guard graph.vertexCount > 0 else {
            return true
        }

        // Handle single vertex graphs (they are trees)
        guard graph.vertexCount > 1 else {
            return true
        }

        // A tree must have exactly V-1 edges
        let expectedEdges = graph.vertexCount - 1
        let actualEdges = graph.edgeCount

        let edgeCount = EdgeCount(expected: expectedEdges, actual: actualEdges)
        observation?.receive(.edgeCountChecked(edgeCount))

        if actualEdges != expectedEdges {
            observation?.receive(.edgeCountMismatchDetected(edgeCount))
            return false
        }

        // Check if graph is connected
        observation?.receive(.connectivityCheckStarted)
        let isConnected = checkConnectivity(graph)
        observation?.receive(.connectivityDetermined(isConnected))

        if !isConnected {
            return false
        }

        // Check if graph is acyclic
        observation?.receive(.acyclicityCheckStarted)
        let isCyclic = checkAcyclicity(graph)
        observation?.receive(.acyclicityDetermined(isCyclic))

        // A tree is connected and acyclic
        return !isCyclic
    }

    @usableFromInline
    func checkConnectivity(_ graph: Graph) -> Bool {
        // Use DFS to check connectivity
        var visitedVertices = Set<Graph.VertexDescriptor>()

        guard let firstVertex = graph.vertices().first(where: { _ in true }) else {
            return true
        }

        var iterator = DepthFirstSearch(on: graph, from: firstVertex)
            .makeIterator(
                observation: .init { event in
                    if case .vertexDiscovered(let vertex) = event { visitedVertices.insert(vertex) }
                }
            )
        while iterator.next() != nil {}

        return visitedVertices.count == graph.vertexCount
    }

    @usableFromInline
    func checkAcyclicity(_ graph: Graph) -> Bool {
        // Use DFS to check for cycles
        var hasCycle = false

        var visitedVertices = Set<Graph.VertexDescriptor>()

        for vertex in graph.vertices() where !hasCycle && !visitedVertices.contains(vertex) {
            var iterator = DepthFirstSearch(on: graph, from: vertex)
                .makeIterator(
                    observation: .init { event in
                        switch event {
                            case .vertexDiscovered(let vertex): visitedVertices.insert(vertex)
                            case .backEdgeTraversed: hasCycle = true
                            default: break
                        }
                    }
                )
            while iterator.next() != nil {}
        }

        return hasCycle
    }
}
