/// Union-Find-based algorithm for checking if a graph is cyclic.
public struct UnionFindCyclicPropertyAlgorithm<Graph: IncidenceGraph & VertexListGraph & EdgeListGraph> where Graph.VertexDescriptor: Hashable {
    public typealias Vertex = Graph.VertexDescriptor
    public typealias Edge = Graph.EdgeDescriptor

    public struct RootPair {
        public let first: Vertex
        public let second: Vertex

        public init(first: Vertex, second: Vertex) {
            self.first = first
            self.second = second
        }
    }

    public enum Event {
        case edgeExamined(Edge)
        case rootsFound(RootPair)
        case verticesUnioned(RootPair)
        case cycleDetected(Edge)
    }

    public enum EventCases {
        public static var edgeExamined: AlgorithmEventCase<Event, Edge> {
            .init {
                guard case .edgeExamined(let value) = $0 else { return nil }
                return value
            }
        }
        public static var rootsFound: AlgorithmEventCase<Event, RootPair> {
            .init {
                guard case .rootsFound(let value) = $0 else { return nil }
                return value
            }
        }
        public static var verticesUnioned: AlgorithmEventCase<Event, RootPair> {
            .init {
                guard case .verticesUnioned(let value) = $0 else { return nil }
                return value
            }
        }
        public static var cycleDetected: AlgorithmEventCase<Event, Edge> {
            .init {
                guard case .cycleDetected(let value) = $0 else { return nil }
                return value
            }
        }
    }

    /// Creates a new Union-Find-based cyclic property algorithm.
    @inlinable
    public init() {}

    /// Checks if the graph is cyclic using Union-Find.
    ///
    /// - Parameters:
    ///   - graph: The graph to check
    ///   - observation: An optional observation of the algorithm progress
    /// - Returns: `true` if the graph is cyclic, `false` otherwise
    @inlinable
    public func isCyclic(
        in graph: Graph,
        observation: AlgorithmObservation<Event>?
    ) -> Bool {
        // Handle empty graphs and single vertex graphs
        guard graph.vertexCount > 1 else {
            return false
        }

        // Union-Find only works for undirected graphs
        // For directed graphs, we need to convert to undirected first
        // by treating each directed edge as an undirected edge

        var parent = [Graph.VertexDescriptor: Graph.VertexDescriptor]()
        var rank = [Graph.VertexDescriptor: Int]()

        // Initialize each vertex as its own parent
        for vertex in graph.vertices() {
            parent[vertex] = vertex
            rank[vertex] = 0
        }

        // Find root with path compression
        func findRoot(_ vertex: Graph.VertexDescriptor) -> Graph.VertexDescriptor {
            guard var currentParent = parent[vertex] else { return vertex }
            if currentParent != vertex {
                currentParent = findRoot(currentParent)
                parent[vertex] = currentParent
            }
            return currentParent
        }

        // Union two sets by rank
        func union(_ x: Graph.VertexDescriptor, _ y: Graph.VertexDescriptor) {
            let rootX = findRoot(x)
            let rootY = findRoot(y)

            if rootX == rootY {
                return  // Already in the same set
            }

            // Union by rank
            guard let rankX = rank[rootX], let rankY = rank[rootY] else { return }

            if rankX < rankY {
                parent[rootX] = rootY
            } else if rankX > rankY {
                parent[rootY] = rootX
            } else {
                parent[rootY] = rootX
                rank[rootX] = rankX + 1
            }
        }

        // Process all edges
        for edge in graph.edges() {
            guard let source = graph.source(of: edge),
                let destination = graph.destination(of: edge)
            else { continue }

            observation?.receive(.edgeExamined(edge))

            let rootSource = findRoot(source)
            let rootDestination = findRoot(destination)
            observation?.receive(.rootsFound(.init(first: rootSource, second: rootDestination)))

            if rootSource == rootDestination {
                // Cycle detected - both vertices are already in the same set
                observation?.receive(.cycleDetected(edge))
                return true
            }

            union(source, destination)
            observation?.receive(.verticesUnioned(.init(first: rootSource, second: rootDestination)))
        }

        return false
    }
}

extension UnionFindCyclicPropertyAlgorithm.Event: EdgeExaminedEvent {
    @inlinable
    public static func examinedEdge(from event: Self) -> Graph.EdgeDescriptor? {
        guard case .edgeExamined(let edge) = event else { return nil }
        return edge
    }
}
