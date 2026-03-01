#if !GRAPHS_USES_TRAITS || GRAPHS_ANALYSIS
/// Reverse Cuthill-McKee Ordering algorithm.
/// 
/// This algorithm reorders the vertices of a graph to reduce the bandwidth of its adjacency matrix.
/// It uses breadth-first search starting from a vertex with minimum degree, enqueuing adjacent
/// vertices in order of increasing degree. The reverse ordering often produces better results
/// with less fill-in during matrix operations.
///
/// - Complexity: O(V + E) where V is the number of vertices and E is the number of edges
public struct ReverseCuthillMcKeeOrderingAlgorithm<
    Graph: IncidenceGraph & VertexListGraph & BidirectionalGraph
> where Graph.VertexDescriptor: Hashable {
    
    /// A visitor that can be used to observe the Reverse Cuthill-McKee algorithm progress.
    public struct Visitor {
        /// Called when examining a vertex.
        public var examineVertex: ((Graph.VertexDescriptor) -> Void)?
        /// Called when enqueuing a vertex.
        public var enqueueVertex: ((Graph.VertexDescriptor, Int) -> Void)?
        /// Called when dequeuing a vertex.
        public var dequeueVertex: ((Graph.VertexDescriptor) -> Void)?
        /// Called when starting from a vertex.
        public var startFromVertex: ((Graph.VertexDescriptor) -> Void)?
        
        /// Creates a new visitor.
        @inlinable
        public init(
            examineVertex: ((Graph.VertexDescriptor) -> Void)? = nil,
            enqueueVertex: ((Graph.VertexDescriptor, Int) -> Void)? = nil,
            dequeueVertex: ((Graph.VertexDescriptor) -> Void)? = nil,
            startFromVertex: ((Graph.VertexDescriptor) -> Void)? = nil
        ) {
            self.examineVertex = examineVertex
            self.enqueueVertex = enqueueVertex
            self.dequeueVertex = dequeueVertex
            self.startFromVertex = startFromVertex
        }
    }
    
    /// Creates a new Reverse Cuthill-McKee Ordering algorithm.
    @inlinable
    public init() {}
    
    /// Orders vertices using the Reverse Cuthill-McKee algorithm.
    ///
    /// - Parameters:
    ///   - graph: The graph to order vertices for
    ///   - visitor: An optional visitor to observe the algorithm progress
    /// - Returns: An array of vertex descriptors in the computed order
    @inlinable
    public func orderVertices(in graph: Graph, visitor: Visitor? = nil) -> [Graph.VertexDescriptor] {
        var visited = Set<Graph.VertexDescriptor>()
        var ordering: [Graph.VertexDescriptor] = []

        // Process each connected component
        for vertex in graph.vertices() {
            if !visited.contains(vertex) {
                let componentOrdering = cuthillMcKeeForComponent(
                    startingFrom: vertex,
                    in: graph,
                    visited: &visited,
                    visitor: visitor
                )
                ordering.append(contentsOf: componentOrdering)
            }
        }

        // Reverse the ordering for better bandwidth reduction
        return ordering.reversed()
    }
    
    @usableFromInline
    func cuthillMcKeeForComponent(
        startingFrom startVertex: Graph.VertexDescriptor,
        in graph: Graph,
        visited: inout Set<Graph.VertexDescriptor>,
        visitor: Visitor?
    ) -> [Graph.VertexDescriptor] {
        var ordering: [Graph.VertexDescriptor] = []
        var queue: [Graph.VertexDescriptor] = [startVertex]
        var queueIndex = 0
        
        visitor?.startFromVertex?(startVertex)
        
        while queueIndex < queue.count {
            let currentVertex = queue[queueIndex]
            queueIndex += 1
            
            if visited.contains(currentVertex) {
                continue
            }
            
            visited.insert(currentVertex)
            ordering.append(currentVertex)
            visitor?.examineVertex?(currentVertex)
            visitor?.dequeueVertex?(currentVertex)
            
            // Get neighbors and sort by degree
            let neighbors = graph.successors(of: currentVertex)
                .filter { !visited.contains($0) }
                .sorted { graph.outDegree(of: $0) < graph.outDegree(of: $1) }
            
            // Add neighbors to queue in order of increasing degree
            for neighbor in neighbors {
                if !visited.contains(neighbor) && !queue.contains(neighbor) {
                    queue.append(neighbor)
                    visitor?.enqueueVertex?(neighbor, graph.outDegree(of: neighbor))
                }
            }
        }
        
        return ordering
    }
}

extension ReverseCuthillMcKeeOrderingAlgorithm: VisitorSupporting {}
#endif
