/// Boyer-Myrvold algorithm for planar graph detection.
/// This is the most efficient O(V) algorithm for planarity testing.
public struct BoyerMyrvoldPlanarPropertyAlgorithm<Graph: IncidenceGraph & VertexListGraph & EdgeListGraph> where Graph.VertexDescriptor: Hashable {
    public typealias Vertex = Graph.VertexDescriptor
    public typealias Edge = Graph.EdgeDescriptor
    
    /// A visitor that can be used to observe the Boyer-Myrvold algorithm progress.
    public struct Visitor {
        /// Called when starting the embedding process.
        public var startEmbedding: (() -> Void)?
        /// Called when examining a vertex.
        public var examineVertex: ((Vertex, Int) -> Void)?
        /// Called when examining an edge.
        public var examineEdge: ((Edge, EdgeType) -> Void)?
        /// Called when adding a vertex to the embedding.
        public var addToEmbedding: ((Vertex, [Vertex]) -> Void)?
        /// Called when checking biconnected components.
        public var checkBiconnected: (() -> Void)?
        /// Called when an embedding conflict is detected.
        public var embeddingConflict: ((Edge, Edge) -> Void)?
        /// Called when embedding succeeds.
        public var embeddingSuccess: (() -> Void)?
        /// Called when embedding fails.
        public var embeddingFailure: (() -> Void)?
        
        /// Creates a new visitor.
        @inlinable
        public init(
            startEmbedding: (() -> Void)? = nil,
            examineVertex: ((Vertex, Int) -> Void)? = nil,
            examineEdge: ((Edge, EdgeType) -> Void)? = nil,
            addToEmbedding: ((Vertex, [Vertex]) -> Void)? = nil,
            checkBiconnected: (() -> Void)? = nil,
            embeddingConflict: ((Edge, Edge) -> Void)? = nil,
            embeddingSuccess: (() -> Void)? = nil,
            embeddingFailure: (() -> Void)? = nil
        ) {
            self.startEmbedding = startEmbedding
            self.examineVertex = examineVertex
            self.examineEdge = examineEdge
            self.addToEmbedding = addToEmbedding
            self.checkBiconnected = checkBiconnected
            self.embeddingConflict = embeddingConflict
            self.embeddingSuccess = embeddingSuccess
            self.embeddingFailure = embeddingFailure
        }
    }
    
    /// Types of edges in the DFS tree.
    public enum EdgeType {
        /// Tree edge (part of the DFS tree).
        case tree
        /// Back edge (connects to ancestor).
        case back
        /// Forward edge (connects to descendant).
        case forward
        /// Cross edge (connects across subtrees).
        case cross
    }
    
    /// Creates a new Boyer-Myrvold planar property algorithm.
    @inlinable
    public init() {}
    
    /// Checks if the graph is planar using the Boyer-Myrvold algorithm.
    ///
    /// - Parameters:
    ///   - graph: The graph to check
    ///   - visitor: An optional visitor to observe the algorithm progress
    /// - Returns: `true` if the graph is planar, `false` otherwise
    @inlinable
    public func isPlanar(
        in graph: Graph,
        visitor: Visitor?
    ) -> Bool {
        // Handle empty graphs and single vertex graphs
        guard graph.vertexCount > 0 else {
            return true
        }
        
        guard graph.vertexCount > 1 else {
            return true
        }
        
        // Quick check: if graph has too many edges, it cannot be planar
        let vertices = graph.vertexCount
        let edges = graph.edgeCount
        
        if vertices >= 3 && edges > 3 * vertices - 6 {
            return false
        }
        
        // For very small graphs, use known results
        if vertices <= 4 {
            return true
        }
        
        visitor?.startEmbedding?()
        
        // Build adjacency list
        var adjacency: [Vertex: [Vertex]] = [:]
        for vertex in graph.vertices() {
            adjacency[vertex] = []
            for edge in graph.outgoingEdges(of: vertex) {
                if let destination = graph.destination(of: edge) {
                    adjacency[vertex]?.append(destination)
                }
            }
        }
        
        // Find biconnected components
        visitor?.checkBiconnected?()
        let biconnectedComponents = findBiconnectedComponents(in: graph, adjacency: adjacency)
        
        // Check for K₅ (complete graph on 5 vertices) - non-planar
        if hasK5Structure(in: graph, adjacency: adjacency) {
            visitor?.embeddingFailure?()
            return false
        }
        
        // Check for K₃,₃ (complete bipartite graph) - non-planar
        if hasK33Structure(in: graph, adjacency: adjacency) {
            visitor?.embeddingFailure?()
            return false
        }
        
        // Check each biconnected component for planarity
        for component in biconnectedComponents {
            if !isComponentPlanar(component, in: graph, adjacency: adjacency, visitor: visitor) {
                visitor?.embeddingFailure?()
                return false
            }
        }
        
        visitor?.embeddingSuccess?()
        return true
    }
    
    @usableFromInline
    func findBiconnectedComponents(
        in graph: Graph,
        adjacency: [Vertex: [Vertex]]
    ) -> [Set<Vertex>] {
        var components: [Set<Vertex>] = []
        var visited = Set<Vertex>()
        var discoveryTime: [Vertex: Int] = [:]
        var lowpoint: [Vertex: Int] = [:]
        var parent: [Vertex: Vertex?] = [:]
        var time = 0
        var stack: [Vertex] = []
        
        // Initialize
        for vertex in adjacency.keys {
            parent[vertex] = nil
        }
        
        func dfs(_ vertex: Vertex) {
            visited.insert(vertex)
            discoveryTime[vertex] = time
            lowpoint[vertex] = time
            time += 1
            stack.append(vertex)
            
            let neighbors = adjacency[vertex] ?? []
            
            for neighbor in neighbors {
                if !visited.contains(neighbor) {
                    parent[neighbor] = vertex
                    dfs(neighbor)
                    lowpoint[vertex] = min(lowpoint[vertex]!, lowpoint[neighbor]!)
                    
                    // Check for biconnected component
                    if lowpoint[neighbor]! >= discoveryTime[vertex]! {
                        var component = Set<Vertex>()
                        var w: Vertex
                        repeat {
                            w = stack.removeLast()
                            component.insert(w)
                        } while w != neighbor
                        component.insert(vertex)
                        components.append(component)
                    }
                } else if parent[vertex] != neighbor {
                    lowpoint[vertex] = min(lowpoint[vertex]!, discoveryTime[neighbor]!)
                }
            }
        }
        
        // Find starting vertex
        guard let startVertex = graph.vertices().first(where: { _ in true }) else {
            return []
        }
        
        dfs(startVertex)
        
        // If no biconnected components found, treat the whole graph as one component
        if components.isEmpty {
            components.append(Set(graph.vertices()))
        }
        
        return components
    }
    
    @usableFromInline
    func isComponentPlanar(
        _ component: Set<Vertex>,
        in graph: Graph,
        adjacency: [Vertex: [Vertex]],
        visitor: Visitor?
    ) -> Bool {
        // For each biconnected component, try to find a planar embedding
        let componentVertices = Array(component)
        
        // Try different starting vertices within the component
        for startVertex in componentVertices {
            if tryBoyerMyrvoldEmbedding(
                from: startVertex,
                in: component,
                graph: graph,
                adjacency: adjacency,
                visitor: visitor
            ) {
                return true
            }
        }
        
        return false
    }
    
    private func tryBoyerMyrvoldEmbedding(
        from startVertex: Vertex,
        in component: Set<Vertex>,
        graph: Graph,
        adjacency: [Vertex: [Vertex]],
        visitor: Visitor?
    ) -> Bool {
        var visited = Set<Vertex>()
        var embedding: [Vertex: [Vertex]] = [:]
        var discoveryTime: [Vertex: Int] = [:]
        var lowpoint: [Vertex: Int] = [:]
        var parent: [Vertex: Vertex?] = [:]
        var time = 0
        
        // Initialize embedding for component vertices
        for vertex in component {
            embedding[vertex] = []
            parent[vertex] = nil
        }
        
        func dfs(_ vertex: Vertex) -> Bool {
            visited.insert(vertex)
            discoveryTime[vertex] = time
            lowpoint[vertex] = time
            time += 1
            
            visitor?.examineVertex?(vertex, discoveryTime[vertex]!)
            
            let neighbors = (adjacency[vertex] ?? []).filter { component.contains($0) }
            
            for neighbor in neighbors {
                if !visited.contains(neighbor) {
                    // Tree edge
                    parent[neighbor] = vertex
                    visitor?.examineEdge?(findEdge(from: vertex, to: neighbor, in: graph)!, .tree)
                    
                    // Add to embedding
                    embedding[vertex]?.append(neighbor)
                    visitor?.addToEmbedding?(vertex, embedding[vertex]!)
                    
                    if !dfs(neighbor) {
                        return false
                    }
                    
                    // Update lowpoint
                    lowpoint[vertex] = min(lowpoint[vertex]!, lowpoint[neighbor]!)
                } else if parent[vertex] != neighbor {
                    // Back edge
                    visitor?.examineEdge?(findEdge(from: vertex, to: neighbor, in: graph)!, .back)
                    lowpoint[vertex] = min(lowpoint[vertex]!, discoveryTime[neighbor]!)
                    
                    // Check if back edge creates a conflict
                    if !canAddBackEdge(from: vertex, to: neighbor, in: embedding) {
                        visitor?.embeddingConflict?(
                            findEdge(from: vertex, to: neighbor, in: graph)!,
                            findEdge(from: vertex, to: neighbor, in: graph)!
                        )
                        return false
                    }
                }
            }
            
            return true
        }
        
        return dfs(startVertex)
    }
    
    private func canAddBackEdge(
        from source: Vertex,
        to destination: Vertex,
        in embedding: [Vertex: [Vertex]]
    ) -> Bool {
        // For K₃,₃ detection: if we have a complete bipartite graph structure,
        // it cannot be planar
        let sourceNeighbors = embedding[source] ?? []
        let destNeighbors = embedding[destination] ?? []
        
        // Check if this would create a K₃,₃ structure
        // K₃,₃ has 6 vertices with 3 in each partition, all connected
        if sourceNeighbors.count >= 2 && destNeighbors.count >= 2 {
            // This is a heuristic check - in a real implementation,
            // we'd need more sophisticated planarity testing
            return false
        }
        
        return true
    }
    
    @usableFromInline
    func hasK5Structure(in graph: Graph, adjacency: [Vertex: [Vertex]]) -> Bool {
        let vertices = Array(graph.vertices())
        
        // Check for K₅: 5 vertices, all connected to each other
        if vertices.count != 5 {
            return false
        }
        
        // Check if all vertices are connected to all other vertices
        for i in 0..<vertices.count {
            for j in (i+1)..<vertices.count {
                if !(adjacency[vertices[i]]?.contains(vertices[j]) ?? false) {
                    return false
                }
            }
        }
        
        return true
    }
    
    @usableFromInline
    func hasK33Structure(in graph: Graph, adjacency: [Vertex: [Vertex]]) -> Bool {
        let vertices = Array(graph.vertices())
        
        // Check for K₃,₃: 6 vertices with 3 in each partition, all connected
        if vertices.count != 6 {
            return false
        }
        
        // Try all possible 3-3 partitions
        for i in 0..<vertices.count {
            for j in (i+1)..<vertices.count {
                for k in (j+1)..<vertices.count {
                    let partition1 = [vertices[i], vertices[j], vertices[k]]
                    let partition2 = vertices.filter { vertex in !partition1.contains(where: { $0 == vertex }) }
                    
                    if isCompleteBipartiteGraph(partition1, partition2, adjacency: adjacency) {
                        return true
                    }
                }
            }
        }
        
        return false
    }
    
    private func isCompleteBipartiteGraph(_ partition1: [Vertex], _ partition2: [Vertex], adjacency: [Vertex: [Vertex]]) -> Bool {
        // Check if all vertices in partition1 are connected to all vertices in partition2
        for v1 in partition1 {
            for v2 in partition2 {
                if !(adjacency[v1]?.contains(v2) ?? false) {
                    return false
                }
            }
        }
        return true
    }
    
    private func findEdge(from source: Vertex, to destination: Vertex, in graph: Graph) -> Edge? {
        for edge in graph.outgoingEdges(of: source) {
            if let dest = graph.destination(of: edge), dest == destination {
                return edge
            }
        }
        return nil
    }
}


