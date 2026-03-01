#if !GRAPHS_USES_TRAITS || GRAPHS_ADVANCED
/// VF2 (Vento-Foggia) algorithm for graph isomorphism.
/// This is a state-space search algorithm that explores possible vertex mappings
/// between two graphs in a systematic way.
///
/// - Complexity: O(V! * V) in the worst case, but much better in practice
public struct VF2Isomorphism<Graph: IncidenceGraph & VertexListGraph & EdgeListGraph> where Graph.VertexDescriptor: Hashable {
    /// The vertex type of the graph.
    public typealias Vertex = Graph.VertexDescriptor
    /// The edge type of the graph.
    public typealias Edge = Graph.EdgeDescriptor
    
    /// A visitor that can be used to observe the VF2 algorithm progress.
    public struct Visitor {
        /// Called when examining a vertex.
        public var examineVertex: ((Vertex) -> Void)?
        /// Called when examining an edge.
        public var examineEdge: ((Edge) -> Void)?
        /// Called when trying a vertex mapping.
        public var tryMapping: ((Vertex, Vertex) -> Void)?
        /// Called when a mapping is found.
        public var mappingFound: (([Vertex: Vertex]) -> Void)?
        /// Called when backtracking.
        public var backtrack: ((Vertex, Vertex) -> Void)?
        
        /// Creates a new visitor.
        @inlinable
        public init(
            examineVertex: ((Vertex) -> Void)? = nil,
            examineEdge: ((Edge) -> Void)? = nil,
            tryMapping: ((Vertex, Vertex) -> Void)? = nil,
            mappingFound: (([Vertex: Vertex]) -> Void)? = nil,
            backtrack: ((Vertex, Vertex) -> Void)? = nil
        ) {
            self.examineVertex = examineVertex
            self.examineEdge = examineEdge
            self.tryMapping = tryMapping
            self.mappingFound = mappingFound
            self.backtrack = backtrack
        }
    }
    
    /// Creates a new VF2 isomorphism algorithm.
    @inlinable
    public init() {}
    
    /// Determines if two graphs are isomorphic using VF2 algorithm.
    ///
    /// - Parameters:
    ///   - graph1: The first graph
    ///   - graph2: The second graph
    ///   - visitor: An optional visitor to observe the algorithm progress
    /// - Returns: True if the graphs are isomorphic, false otherwise
    @inlinable
    public func areIsomorphic(_ graph1: Graph, _ graph2: Graph, visitor: Visitor? = nil) -> Bool {
        return findIsomorphism(graph1, graph2, visitor: visitor) != nil
    }
    
    /// Finds an isomorphism mapping between two graphs using VF2 algorithm.
    ///
    /// - Parameters:
    ///   - graph1: The first graph
    ///   - graph2: The second graph
    ///   - visitor: An optional visitor to observe the algorithm progress
    /// - Returns: A mapping from vertices of graph1 to vertices of graph2, or nil if not isomorphic
    @inlinable
    public func findIsomorphism(_ graph1: Graph, _ graph2: Graph, visitor: Visitor? = nil) -> [Vertex: Vertex]? {
        // Quick checks for basic isomorphism requirements
        guard graph1.vertexCount == graph2.vertexCount else { return nil }
        guard graph1.edgeCount == graph2.edgeCount else { return nil }
        
        let vertices1 = Array(graph1.vertices())
        let vertices2 = Array(graph2.vertices())
        
        // Try to find a valid mapping
        var mapping: [Vertex: Vertex] = [:]
        var reverseMapping: [Vertex: Vertex] = [:]
        
        if findMapping(
            graph1: graph1,
            graph2: graph2,
            vertices1: vertices1,
            vertices2: vertices2,
            mapping: &mapping,
            reverseMapping: &reverseMapping,
            index1: 0,
            visitor: visitor
        ) {
            visitor?.mappingFound?(mapping)
            return mapping
        }
        
        return nil
    }
    
    @usableFromInline
    func findMapping(
        graph1: Graph,
        graph2: Graph,
        vertices1: [Vertex],
        vertices2: [Vertex],
        mapping: inout [Vertex: Vertex],
        reverseMapping: inout [Vertex: Vertex],
        index1: Int,
        visitor: Visitor?
    ) -> Bool {
        // If we've mapped all vertices, we found an isomorphism
        if index1 >= vertices1.count {
            return true
        }
        
        let vertex1 = vertices1[index1]
        visitor?.examineVertex?(vertex1)
        
        // Try mapping vertex1 to each unmapped vertex in graph2
        for vertex2 in vertices2 {
            // Skip if vertex2 is already mapped
            if reverseMapping[vertex2] != nil {
                continue
            }
            
            visitor?.tryMapping?(vertex1, vertex2)
            
            // Check if this mapping is feasible
            if isFeasible(
                graph1: graph1,
                graph2: graph2,
                vertex1: vertex1,
                vertex2: vertex2,
                mapping: mapping,
                reverseMapping: reverseMapping
            ) {
                // Add the mapping
                mapping[vertex1] = vertex2
                reverseMapping[vertex2] = vertex1
                
                // Recursively try to map the remaining vertices
                if findMapping(
                    graph1: graph1,
                    graph2: graph2,
                    vertices1: vertices1,
                    vertices2: vertices2,
                    mapping: &mapping,
                    reverseMapping: &reverseMapping,
                    index1: index1 + 1,
                    visitor: visitor
                ) {
                    return true
                }
                
                // Backtrack: remove the mapping
                visitor?.backtrack?(vertex1, vertex2)
                mapping.removeValue(forKey: vertex1)
                reverseMapping.removeValue(forKey: vertex2)
            }
        }
        
        return false
    }
    
    private func isFeasible(
        graph1: Graph,
        graph2: Graph,
        vertex1: Vertex,
        vertex2: Vertex,
        mapping: [Vertex: Vertex],
        reverseMapping: [Vertex: Vertex]
    ) -> Bool {
        // Check degree constraint
        let degree1 = graph1.outDegree(of: vertex1)
        let degree2 = graph2.outDegree(of: vertex2)
        guard degree1 == degree2 else { return false }
        
        // Check adjacency constraints
        return checkAdjacencyConstraints(
            graph1: graph1,
            graph2: graph2,
            vertex1: vertex1,
            vertex2: vertex2,
            mapping: mapping,
            reverseMapping: reverseMapping
        )
    }
    
    private func checkAdjacencyConstraints(
        graph1: Graph,
        graph2: Graph,
        vertex1: Vertex,
        vertex2: Vertex,
        mapping: [Vertex: Vertex],
        reverseMapping: [Vertex: Vertex]
    ) -> Bool {
        // Count edges between mapped vertices
        var mappedEdges1 = 0
        var mappedEdges2 = 0
        
        // Count edges from vertex1 to mapped vertices in graph1
        for edge in graph1.outgoingEdges(of: vertex1) {
            guard let target = graph1.destination(of: edge) else { continue }
            if mapping[target] != nil {
                mappedEdges1 += 1
            }
        }
        
        // Count edges from vertex2 to mapped vertices in graph2
        for edge in graph2.outgoingEdges(of: vertex2) {
            guard let target = graph2.destination(of: edge) else { continue }
            if reverseMapping[target] != nil {
                mappedEdges2 += 1
            }
        }
        
        // The number of edges to mapped vertices must be equal
        guard mappedEdges1 == mappedEdges2 else { return false }
        
        // Check that the actual edge targets match through the mapping
        for edge1 in graph1.outgoingEdges(of: vertex1) {
            guard let target1 = graph1.destination(of: edge1) else { continue }
            if let mappedTarget1 = mapping[target1] {
                // Check if there's a corresponding edge in graph2
                var found = false
                for edge2 in graph2.outgoingEdges(of: vertex2) {
                    guard let target2 = graph2.destination(of: edge2) else { continue }
                    if target2 == mappedTarget1 {
                        found = true
                        break
                    }
                }
                if !found {
                    return false
                }
            }
        }
        
        return true
    }
}

extension VF2Isomorphism: VisitorSupporting {}
#endif
