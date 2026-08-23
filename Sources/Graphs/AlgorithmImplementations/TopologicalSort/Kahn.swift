#if !GRAPHS_USES_TRAITS || GRAPHS_CONNECTIVITY
    import OrderedCollections
    import DequeModule

    /// Kahn's algorithm for topological sorting.
    ///
    /// This algorithm works by repeatedly removing vertices with no incoming edges.
    /// If all vertices are processed, the graph is acyclic and the order is a valid topological sort.
    /// If some vertices remain, the graph contains a cycle.
    ///
    /// - Complexity: O(V + E) where V is the number of vertices and E is the number of edges
    public struct Kahn<Graph: IncidenceGraph & VertexListGraph>: TopologicalSortAlgorithm where Graph.VertexDescriptor: Hashable {
        /// The vertex type of the graph.
        public typealias Vertex = Graph.VertexDescriptor
        /// The edge type of the graph.
        public typealias Edge = Graph.EdgeDescriptor

        public enum Event {
            case vertexDiscovered(Vertex)
            case edgeExamined(Edge)
            case vertexFinished(Vertex)
            case cycleDetected([Vertex])
        }

        public enum EventCases {
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
            public static var vertexFinished: AlgorithmEventCase<Event, Vertex> {
                .init {
                    guard case .vertexFinished(let value) = $0 else { return nil }
                    return value
                }
            }
            public static var cycleDetected: AlgorithmEventCase<Event, [Vertex]> {
                .init {
                    guard case .cycleDetected(let value) = $0 else { return nil }
                    return value
                }
            }
        }

        /// Creates a new Kahn's algorithm instance.
        @inlinable
        public init() {}

        /// Performs topological sort using Kahn's algorithm.
        ///
        /// - Parameters:
        ///   - graph: The graph to sort topologically.
        ///   - observation: An optional observation of the algorithm progress.
        /// - Returns: The topological sort result.
        @inlinable
        public func topologicalSort(
            in graph: Graph,
            observation: AlgorithmObservation<Event>?
        ) -> TopologicalSortResult<Graph.VertexDescriptor> {
            var inDegree: OrderedDictionary<Vertex, Int> = [:]
            var sortedVertices: [Vertex] = []
            var queue: Deque<Vertex> = []

            // Calculate in-degrees for all vertices
            for vertex in graph.vertices() {
                inDegree[vertex] = 0
            }

            for vertex in graph.vertices() {
                for edge in graph.outgoingEdges(of: vertex) {
                    observation?.receive(.edgeExamined(edge))
                    guard let destination = graph.destination(of: edge) else { continue }
                    inDegree[destination, default: 0] += 1
                }
            }

            // Find all vertices with no incoming edges
            for (vertex, degree) in inDegree where degree == 0 {
                queue.enqueue(vertex)
            }

            // Process vertices
            while !queue.isEmpty {
                guard let current = queue.dequeue() else { break }

                observation?.receive(.vertexDiscovered(current))
                sortedVertices.append(current)
                observation?.receive(.vertexFinished(current))

                // Remove this vertex and update in-degrees of its neighbors
                for edge in graph.outgoingEdges(of: current) {
                    observation?.receive(.edgeExamined(edge))
                    guard let destination = graph.destination(of: edge) else { continue }

                    inDegree[destination, default: 0] -= 1
                    if inDegree[destination, default: 0] == 0 {
                        queue.enqueue(destination)
                    }
                }
            }

            // Check if all vertices were processed
            let hasCycle = sortedVertices.count != graph.vertexCount
            let cycleVertices = hasCycle ? Array(inDegree.keys.filter { inDegree[$0, default: 0] > 0 }) : []

            if hasCycle {
                observation?.receive(.cycleDetected(cycleVertices))
            }

            return TopologicalSortResult(
                sortedVertices: sortedVertices,
                hasCycle: hasCycle,
                cycleVertices: cycleVertices
            )
        }
    }

#endif

#if !GRAPHS_USES_TRAITS || GRAPHS_CONNECTIVITY
    extension Kahn.Event: VertexDiscoveredEvent, EdgeExaminedEvent {
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
#endif
