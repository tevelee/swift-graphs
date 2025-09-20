import Collections

/// Kahn's algorithm for topological sorting.
/// 
/// This algorithm works by repeatedly removing vertices with no incoming edges.
/// If all vertices are processed, the graph is acyclic and the order is a valid topological sort.
/// If some vertices remain, the graph contains a cycle.
struct Kahn<Graph: IncidenceGraph & VertexListGraph>: TopologicalSortAlgorithm where Graph.VertexDescriptor: Hashable {
    typealias Vertex = Graph.VertexDescriptor
    typealias Edge = Graph.EdgeDescriptor

    struct Visitor {
        var discoverVertex: ((Vertex) -> Void)?
        var examineEdge: ((Edge) -> Void)?
        var finishVertex: ((Vertex) -> Void)?
        var detectCycle: (([Vertex]) -> Void)?
    }

    private let makeQueue: () -> any QueueProtocol<Vertex>

    init(makeQueue: @escaping () -> any QueueProtocol<Vertex> = { Deque() }) {
        self.makeQueue = makeQueue
    }

    func topologicalSort(
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
