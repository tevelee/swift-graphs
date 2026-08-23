/// BFS-based algorithm for checking if a graph is bipartite.
public struct BFSBipartitePropertyAlgorithm<Graph: IncidenceGraph & VertexListGraph> where Graph.VertexDescriptor: Hashable {
    public typealias Vertex = Graph.VertexDescriptor
    public typealias Edge = Graph.EdgeDescriptor

    public struct ColorAssignment {
        public let vertex: Vertex
        public let color: Int

        public init(vertex: Vertex, color: Int) {
            self.vertex = vertex
            self.color = color
        }
    }

    public struct ColorConflict {
        public let first: Vertex
        public let second: Vertex
        public let color: Int

        public init(first: Vertex, second: Vertex, color: Int) {
            self.first = first
            self.second = second
            self.color = color
        }
    }

    public enum Event {
        case colorAssigned(ColorAssignment)
        case vertexExamined(Vertex)
        case edgeExamined(Edge)
        case colorConflictDetected(ColorConflict)
    }

    public enum EventCases {
        public static var colorAssigned: AlgorithmEventCase<Event, ColorAssignment> {
            .init {
                guard case .colorAssigned(let value) = $0 else { return nil }
                return value
            }
        }
        public static var vertexExamined: AlgorithmEventCase<Event, Vertex> {
            .init {
                guard case .vertexExamined(let value) = $0 else { return nil }
                return value
            }
        }
        public static var edgeExamined: AlgorithmEventCase<Event, Edge> {
            .init {
                guard case .edgeExamined(let value) = $0 else { return nil }
                return value
            }
        }
        public static var colorConflictDetected: AlgorithmEventCase<Event, ColorConflict> {
            .init {
                guard case .colorConflictDetected(let value) = $0 else { return nil }
                return value
            }
        }
    }

    /// Creates a new BFS-based bipartite property algorithm.
    @inlinable
    public init() {}

    /// Checks if the graph is bipartite using BFS.
    ///
    /// - Parameters:
    ///   - graph: The graph to check
    ///   - observation: An optional observation of the algorithm progress
    /// - Returns: `true` if the graph is bipartite, `false` otherwise
    @inlinable
    public func isBipartite(
        in graph: Graph,
        observation: AlgorithmObservation<Event>?
    ) -> Bool {
        // Handle empty graphs and single vertex graphs
        guard graph.vertexCount > 0 else {
            return true  // Empty graph is considered bipartite
        }

        guard graph.vertexCount > 1 else {
            return true  // Single vertex graph is bipartite
        }

        // Color map: 0 = uncolored, 1 = color A, 2 = color B
        var color = [Graph.VertexDescriptor: Int]()
        var isBipartite = true

        // Process each connected component
        for vertex in graph.vertices() where color[vertex] == nil && isBipartite {
            // Start BFS from this unvisited vertex
            var queue: [Graph.VertexDescriptor] = [vertex]
            color[vertex] = 1  // Assign first color
            observation?.receive(.colorAssigned(.init(vertex: vertex, color: 1)))

            while !queue.isEmpty && isBipartite {
                let currentVertex = queue.removeFirst()
                guard let currentColor = color[currentVertex] else { continue }
                let nextColor = currentColor == 1 ? 2 : 1

                observation?.receive(.vertexExamined(currentVertex))

                // Check all neighbors
                for edge in graph.outgoingEdges(of: currentVertex) {
                    guard let neighbor = graph.destination(of: edge) else { continue }

                    observation?.receive(.edgeExamined(edge))

                    if color[neighbor] == nil {
                        // Neighbor is uncolored, assign opposite color
                        color[neighbor] = nextColor
                        observation?.receive(.colorAssigned(.init(vertex: neighbor, color: nextColor)))
                        queue.append(neighbor)
                    } else if color[neighbor] == currentColor {
                        // Neighbor has same color as current vertex
                        // This violates bipartite property
                        isBipartite = false
                        observation?.receive(.colorConflictDetected(.init(first: currentVertex, second: neighbor, color: currentColor)))
                        break
                    }
                }
            }
        }

        return isBipartite
    }
}

extension BFSBipartitePropertyAlgorithm.Event: VertexExaminedEvent, EdgeExaminedEvent {
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
