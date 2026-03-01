#if !GRAPHS_USES_TRAITS || GRAPHS_PATHFINDING
import Collections

/// The Shortest Path Faster Algorithm (SPFA) for finding shortest paths in graphs with negative edge weights.
///
/// SPFA is a queue-based optimization of Bellman-Ford. Instead of iterating over all edges V-1 times,
/// it maintains a FIFO queue of vertices whose distances were updated, relaxing only their outgoing edges.
/// Average case O(E), worst case O(VE). Handles negative weights and detects negative cycles.
public struct SPFA<
    Graph: IncidenceGraph & VertexListGraph,
    Weight: AdditiveArithmetic & Comparable
> where
    Graph.VertexDescriptor: Hashable
{
    public typealias Vertex = Graph.VertexDescriptor
    public typealias Edge = Graph.EdgeDescriptor

    /// A visitor for SPFA algorithm events.
    ///
    /// Visitors can observe the algorithm's progress including edge relaxations
    /// and negative cycle detection. Unlike Bellman-Ford, negative cycles are detected
    /// per-vertex (when a vertex is enqueued more than V times).
    public struct Visitor {
        public var examineVertex: ((Vertex) -> Void)?
        public var examineEdge: ((Edge) -> Void)?
        public var edgeRelaxed: ((Edge) -> Void)?
        public var edgeNotRelaxed: ((Edge) -> Void)?
        public var detectNegativeCycle: ((Vertex) -> Void)?

        @inlinable
        public init(
            examineVertex: ((Vertex) -> Void)? = nil,
            examineEdge: ((Edge) -> Void)? = nil,
            edgeRelaxed: ((Edge) -> Void)? = nil,
            edgeNotRelaxed: ((Edge) -> Void)? = nil,
            detectNegativeCycle: ((Vertex) -> Void)? = nil
        ) {
            self.examineVertex = examineVertex
            self.examineEdge = examineEdge
            self.edgeRelaxed = edgeRelaxed
            self.edgeNotRelaxed = edgeNotRelaxed
            self.detectNegativeCycle = detectNegativeCycle
        }
    }

    /// A result from the SPFA algorithm.
    ///
    /// Contains the computed distances, predecessor edges, and whether a negative cycle was detected.
    public struct Result {
        public let distances: [Vertex: Cost<Weight>]
        public let predecessors: [Vertex: Edge?]
        public let hasNegativeCycle: Bool

        @inlinable
        public init(distances: [Vertex: Cost<Weight>], predecessors: [Vertex: Edge?], hasNegativeCycle: Bool) {
            self.distances = distances
            self.predecessors = predecessors
            self.hasNegativeCycle = hasNegativeCycle
        }
    }

    @usableFromInline
    let graph: Graph
    @usableFromInline
    let edgeWeight: CostDefinition<Graph, Weight>

    @inlinable
    public init(
        on graph: Graph,
        edgeWeight: CostDefinition<Graph, Weight>
    ) {
        self.graph = graph
        self.edgeWeight = edgeWeight
    }

    @inlinable
    public func shortestPathsFromSource(_ source: Vertex, visitor: Visitor? = nil) -> Result {
        var distances: [Vertex: Cost<Weight>] = [:]
        var predecessors: [Vertex: Edge?] = [:]

        // Initialize distances
        for vertex in graph.vertices() {
            distances[vertex] = .infinite
            predecessors[vertex] = nil
        }
        distances[source] = .finite(.zero)

        var queue = Deque<Vertex>()
        var inQueue = Set<Vertex>()
        var enqueueCount: [Vertex: Int] = [:]

        queue.enqueue(source)
        inQueue.insert(source)
        enqueueCount[source] = 1

        let vertexCount = graph.vertexCount

        while let vertex = queue.dequeue() {
            inQueue.remove(vertex)
            visitor?.examineVertex?(vertex)

            for edge in graph.outgoingEdges(of: vertex) {
                guard let destinationVertex = graph.destination(of: edge) else {
                    continue
                }

                visitor?.examineEdge?(edge)

                guard let sourceCost = distances[vertex] else { continue }
                let weight = edgeWeight.costToExplore(edge, graph)
                let newCost = sourceCost + weight

                guard let destinationCost = distances[destinationVertex] else { continue }
                if newCost < destinationCost {
                    distances[destinationVertex] = newCost
                    predecessors[destinationVertex] = edge
                    visitor?.edgeRelaxed?(edge)

                    if !inQueue.contains(destinationVertex) {
                        queue.enqueue(destinationVertex)
                        inQueue.insert(destinationVertex)
                        let count = (enqueueCount[destinationVertex] ?? 0) + 1
                        enqueueCount[destinationVertex] = count

                        if count > vertexCount {
                            visitor?.detectNegativeCycle?(destinationVertex)
                            return Result(
                                distances: distances,
                                predecessors: predecessors,
                                hasNegativeCycle: true
                            )
                        }
                    }
                } else {
                    visitor?.edgeNotRelaxed?(edge)
                }
            }
        }

        return Result(
            distances: distances,
            predecessors: predecessors,
            hasNegativeCycle: false
        )
    }

}

extension SPFA: VisitorSupporting {}
#endif
