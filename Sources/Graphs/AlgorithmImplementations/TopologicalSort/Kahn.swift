#if !GRAPHS_USES_TRAITS || GRAPHS_CONNECTIVITY
import Collections

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

    /// A visitor that can be used to observe Kahn's algorithm progress.
    public struct Visitor {
        /// Called when discovering a vertex.
        public var discoverVertex: ((Vertex) -> Void)?
        /// Called when examining an edge.
        public var examineEdge: ((Edge) -> Void)?
        /// Called when finishing a vertex.
        public var finishVertex: ((Vertex) -> Void)?
        /// Called when detecting a cycle.
        public var detectCycle: (([Vertex]) -> Void)?
        
        /// Creates a new visitor.
        @inlinable
        public init(
            discoverVertex: ((Vertex) -> Void)? = nil,
            examineEdge: ((Edge) -> Void)? = nil,
            finishVertex: ((Vertex) -> Void)? = nil,
            detectCycle: (([Vertex]) -> Void)? = nil
        ) {
            self.discoverVertex = discoverVertex
            self.examineEdge = examineEdge
            self.finishVertex = finishVertex
            self.detectCycle = detectCycle
        }
    }

    /// The queue factory for Kahn's algorithm.
    @usableFromInline
    let makeQueue: () -> any QueueProtocol<Vertex>

    /// Creates a new Kahn's algorithm instance.
    ///
    /// - Parameter makeQueue: A factory for creating the queue used in the algorithm.
    @inlinable
    public init(makeQueue: @escaping () -> any QueueProtocol<Vertex> = { Deque() }) {
        self.makeQueue = makeQueue
    }

    /// Performs topological sort using Kahn's algorithm.
    ///
    /// - Parameters:
    ///   - graph: The graph to sort topologically.
    ///   - visitor: An optional visitor to observe the algorithm progress.
    /// - Returns: The topological sort result.
    @inlinable
    public func topologicalSort(
        in graph: Graph,
        visitor: Visitor?
    ) -> TopologicalSortResult<Graph.VertexDescriptor> {
        var inDegree: OrderedDictionary<Vertex, Int> = [:]
        var sortedVertices: [Vertex] = []
        var queue = makeQueue()
        
        // Calculate in-degrees for all vertices
        for vertex in graph.vertices() {
            inDegree[vertex] = 0
        }
        
        for vertex in graph.vertices() {
            for edge in graph.outgoingEdges(of: vertex) {
                visitor?.examineEdge?(edge)
                guard let destination = graph.destination(of: edge) else { continue }
                inDegree[destination, default: 0] += 1
            }
        }
        
        // Find all vertices with no incoming edges
        for (vertex, degree) in inDegree {
            if degree == 0 {
                queue.enqueue(vertex)
            }
        }
        
        // Process vertices
        while !queue.isEmpty {
            guard let current = queue.dequeue() else { break }
            
            visitor?.discoverVertex?(current)
            sortedVertices.append(current)
            visitor?.finishVertex?(current)
            
            // Remove this vertex and update in-degrees of its neighbors
            for edge in graph.outgoingEdges(of: current) {
                visitor?.examineEdge?(edge)
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
            visitor?.detectCycle?(cycleVertices)
        }
        
        return TopologicalSortResult(
            sortedVertices: sortedVertices,
            hasCycle: hasCycle,
            cycleVertices: cycleVertices
        )
    }
}

extension Kahn: VisitorSupporting {}
#endif
