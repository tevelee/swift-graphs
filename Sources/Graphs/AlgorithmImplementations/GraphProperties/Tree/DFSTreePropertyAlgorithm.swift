/// Single-pass DFS-based algorithm for checking if a graph is a tree.
public struct DFSTreePropertyAlgorithm<Graph: IncidenceGraph & VertexListGraph & EdgeListGraph> where Graph.VertexDescriptor: Hashable {
    public typealias Vertex = Graph.VertexDescriptor
    public typealias Edge = Graph.EdgeDescriptor

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
        case vertexDiscovered(Vertex)
        case edgeExamined(Edge)
        case backEdgeTraversed(Edge)
        case connectivityDetermined(Bool)
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
        public static var vertexDiscovered: AlgorithmEventCase<Event, Vertex> {
            .init {
                guard case .vertexDiscovered(let value) = $0 else { return nil }
                return value
            }
        }
        public static var edgeExamined: AlgorithmEventCase<Event, Edge> {
            .init {
                guard case .edgeExamined(let value) = $0 else { return nil }
                return value
            }
        }
        public static var backEdgeTraversed: AlgorithmEventCase<Event, Edge> {
            .init {
                guard case .backEdgeTraversed(let value) = $0 else { return nil }
                return value
            }
        }
        public static var connectivityDetermined: AlgorithmEventCase<Event, Bool> {
            .init {
                guard case .connectivityDetermined(let value) = $0 else { return nil }
                return value
            }
        }
        public static var acyclicityDetermined: AlgorithmEventCase<Event, Bool> {
            .init {
                guard case .acyclicityDetermined(let value) = $0 else { return nil }
                return value
            }
        }
    }

    /// Creates a new single-pass DFS-based tree property algorithm.
    @inlinable
    public init() {}

    /// Checks if the graph is a tree using a single DFS pass.
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

        // Single DFS pass to check both connectivity and acyclicity
        var visitedVertices = Set<Graph.VertexDescriptor>()
        var hasCycle = false
        var verticesVisited = 0

        let treeObservation = AlgorithmObservation<DepthFirstSearch<Graph>.Event> { event in
            switch event {
                case .vertexDiscovered(let vertex):
                    visitedVertices.insert(vertex)
                    verticesVisited += 1
                    observation?.receive(.vertexDiscovered(vertex))
                case .edgeExamined(let edge):
                    observation?.receive(.edgeExamined(edge))
                case .backEdgeTraversed(let edge):
                    hasCycle = true
                    observation?.receive(.backEdgeTraversed(edge))
                default:
                    break
            }
        }

        // Start DFS from the first vertex
        guard let firstVertex = graph.vertices().first(where: { _ in true }) else {
            return true
        }

        var iterator = DepthFirstSearch(on: graph, from: firstVertex)
            .makeIterator(observation: treeObservation)
        while iterator.next() != nil {}

        observation?.receive(.connectivityDetermined(verticesVisited == graph.vertexCount))
        observation?.receive(.acyclicityDetermined(!hasCycle))

        // A tree is connected and acyclic
        return verticesVisited == graph.vertexCount && !hasCycle
    }
}

extension DFSTreePropertyAlgorithm.Event: VertexDiscoveredEvent, EdgeExaminedEvent {
    @inlinable
    public static func discoveredVertex(from event: Self) -> Graph.VertexDescriptor? {
        guard case .vertexDiscovered(let vertex) = event else { return nil }
        return vertex
    }

    @inlinable
    public static func examinedEdge(from event: Self) -> Graph.EdgeDescriptor? {
        guard case .edgeExamined(let edge) = event else { return nil }
        return edge
    }
}
