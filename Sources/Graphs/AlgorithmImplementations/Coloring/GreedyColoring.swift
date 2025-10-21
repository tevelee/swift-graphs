/// A greedy graph coloring algorithm.
///
/// This algorithm colors vertices one by one, assigning each vertex the smallest
/// available color that doesn't conflict with its already colored neighbors.
///
/// - Complexity: O(V^2) where V is the number of vertices
public struct GreedyColoringAlgorithm<
    Graph: IncidenceGraph & VertexListGraph,
    Color: IntegerBasedColor
> where Graph.VertexDescriptor: Hashable {
    
    /// A visitor that can be used to observe greedy coloring progress.
    public struct Visitor {
        /// Called when examining a vertex.
        public var examineVertex: ((Graph.VertexDescriptor) -> Void)?
        /// Called when examining an edge.
        public var examineEdge: ((Graph.EdgeDescriptor) -> Void)?
        /// Called when assigning a color to a vertex.
        public var assignColor: ((Graph.VertexDescriptor, Color) -> Void)?
        /// Called when skipping a vertex.
        public var skipVertex: ((Graph.VertexDescriptor, String) -> Void)?
        
        /// Creates a new visitor.
        @inlinable
        public init(
            examineVertex: ((Graph.VertexDescriptor) -> Void)? = nil,
            examineEdge: ((Graph.EdgeDescriptor) -> Void)? = nil,
            assignColor: ((Graph.VertexDescriptor, Color) -> Void)? = nil,
            skipVertex: ((Graph.VertexDescriptor, String) -> Void)? = nil
        ) {
            self.examineVertex = examineVertex
            self.examineEdge = examineEdge
            self.assignColor = assignColor
            self.skipVertex = skipVertex
        }
    }
    
    /// Creates a new greedy coloring algorithm.
    @inlinable
    public init() {}
    
    /// Colors the graph using the greedy algorithm.
    ///
    /// - Parameters:
    ///   - graph: The graph to color.
    ///   - visitor: An optional visitor to observe the algorithm progress.
    /// - Returns: The graph coloring result.
    @inlinable
    public func color(graph: Graph, visitor: Visitor? = nil) -> GraphColoring<Graph.VertexDescriptor, Color> {
        var vertexColors: [Graph.VertexDescriptor: Color] = [:]
        var usedColors: Set<Color> = []
        
        // Get all vertices
        let vertices = Array(graph.vertices())
        
        // If no vertices, return empty coloring
        guard !vertices.isEmpty else {
            return GraphColoring<Graph.VertexDescriptor, Color>(vertexColors: [:], isProper: true)
        }
        
        // Color the first vertex with color 0
        let firstColor = Color(integerValue: 0)
        vertexColors[vertices[0]] = firstColor
        usedColors.insert(firstColor)
        visitor?.examineVertex?(vertices[0])
        visitor?.assignColor?(vertices[0], firstColor)
        
        // Color remaining vertices
        for i in 1..<vertices.count {
            let vertex = vertices[i]
            visitor?.examineVertex?(vertex)
            
            let neighbors = Set(graph.successors(of: vertex))
            
            // Examine edges to neighbors
            for edge in graph.outgoingEdges(of: vertex) {
                visitor?.examineEdge?(edge)
            }
            
            // Find the smallest available color
            var colorIndex = 0
            var assignedColor: Color?
            
            while assignedColor == nil {
                let candidateColor = Color(integerValue: colorIndex)
                
                // Check if this color is used by any neighbor
                let isColorUsedByNeighbor = neighbors.contains { neighbor in
                    if let neighborColor = vertexColors[neighbor] {
                        return neighborColor == candidateColor
                    }
                    return false
                }
                
                if !isColorUsedByNeighbor {
                    assignedColor = candidateColor
                } else {
                    colorIndex += 1
                }
            }
            
            vertexColors[vertex] = assignedColor!
            usedColors.insert(assignedColor!)
            visitor?.assignColor?(vertex, assignedColor!)
        }
        
        // Check if the coloring is proper
        let isProper = checkProperColoring(in: graph, vertexColors: vertexColors)
        
        return GraphColoring(vertexColors: vertexColors, isProper: isProper)
    }
    
    @usableFromInline
    func checkProperColoring(
        in graph: Graph,
        vertexColors: [Graph.VertexDescriptor: Color]
    ) -> Bool {
        for vertex in graph.vertices() {
            guard let vertexColor = vertexColors[vertex] else { continue }
            
            for neighbor in graph.successors(of: vertex) {
                if let neighborColor = vertexColors[neighbor],
                   vertexColor == neighborColor {
                    return false
                }
            }
        }
        return true
    }
}

extension GreedyColoringAlgorithm: VisitorSupporting {}

