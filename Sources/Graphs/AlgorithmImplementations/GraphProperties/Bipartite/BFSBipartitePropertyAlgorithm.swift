/// BFS-based algorithm for checking if a graph is bipartite.
public struct BFSBipartitePropertyAlgorithm<Graph: IncidenceGraph & VertexListGraph> where Graph.VertexDescriptor: Hashable {
    public typealias Visitor = BFSBipartiteProperty<Graph>.Visitor
    
    /// Creates a new BFS-based bipartite property algorithm.
    @inlinable
    public init() {}
    
    /// Checks if the graph is bipartite using BFS.
    ///
    /// - Parameters:
    ///   - graph: The graph to check
    ///   - visitor: An optional visitor to observe the algorithm progress
    /// - Returns: `true` if the graph is bipartite, `false` otherwise
    @inlinable
    public func isBipartite(
        in graph: Graph,
        visitor: Visitor?
    ) -> Bool {
        // Handle empty graphs and single vertex graphs
        guard graph.vertexCount > 0 else {
            return true // Empty graph is considered bipartite
        }
        
        guard graph.vertexCount > 1 else {
            return true // Single vertex graph is bipartite
        }
        
        // Color map: 0 = uncolored, 1 = color A, 2 = color B
        var color = [Graph.VertexDescriptor: Int]()
        var isBipartite = true
        
        // Process each connected component
        for vertex in graph.vertices() {
            if color[vertex] == nil && isBipartite {
                // Start BFS from this unvisited vertex
                var queue: [Graph.VertexDescriptor] = [vertex]
                color[vertex] = 1 // Assign first color
                visitor?.assignColor?(vertex, 1)
                
                while !queue.isEmpty && isBipartite {
                    let currentVertex = queue.removeFirst()
                    guard let currentColor = color[currentVertex] else { continue }
                    let nextColor = currentColor == 1 ? 2 : 1
                    
                    visitor?.examineVertex?(currentVertex)
                    
                    // Check all neighbors
                    for edge in graph.outgoingEdges(of: currentVertex) {
                        guard let neighbor = graph.destination(of: edge) else { continue }
                        
                        visitor?.examineEdge?(edge)
                        
                        if color[neighbor] == nil {
                            // Neighbor is uncolored, assign opposite color
                            color[neighbor] = nextColor
                            visitor?.assignColor?(neighbor, nextColor)
                            queue.append(neighbor)
                        } else if color[neighbor] == currentColor {
                            // Neighbor has same color as current vertex
                            // This violates bipartite property
                            isBipartite = false
                            visitor?.colorConflict?(currentVertex, neighbor, currentColor)
                            break
                        }
                    }
                }
            }
        }
        
        return isBipartite
    }
}

// MARK: - Visitor Support

public struct BFSBipartiteProperty<Graph: IncidenceGraph & VertexListGraph> where Graph.VertexDescriptor: Hashable {
    public typealias Vertex = Graph.VertexDescriptor
    public typealias Edge = Graph.EdgeDescriptor
    
    public struct Visitor {
        public var assignColor: ((Vertex, Int) -> Void)?
        public var examineVertex: ((Vertex) -> Void)?
        public var examineEdge: ((Edge) -> Void)?
        public var colorConflict: ((Vertex, Vertex, Int) -> Void)?
        
        public init(
            assignColor: ((Vertex, Int) -> Void)? = nil,
            examineVertex: ((Vertex) -> Void)? = nil,
            examineEdge: ((Edge) -> Void)? = nil,
            colorConflict: ((Vertex, Vertex, Int) -> Void)? = nil
        ) {
            self.assignColor = assignColor
            self.examineVertex = examineVertex
            self.examineEdge = examineEdge
            self.colorConflict = colorConflict
        }
    }
}

extension BFSBipartiteProperty.Visitor: Composable {
    @inlinable
    public func combined(with other: Self) -> Self {
        .init(
            assignColor: { vertex, color in
                self.assignColor?(vertex, color)
                other.assignColor?(vertex, color)
            },
            examineVertex: { vertex in
                self.examineVertex?(vertex)
                other.examineVertex?(vertex)
            },
            examineEdge: { edge in
                self.examineEdge?(edge)
                other.examineEdge?(edge)
            },
            colorConflict: { vertex1, vertex2, color in
                self.colorConflict?(vertex1, vertex2, color)
                other.colorConflict?(vertex1, vertex2, color)
            }
        )
    }
}

extension BFSBipartitePropertyAlgorithm: VisitorSupporting {}
