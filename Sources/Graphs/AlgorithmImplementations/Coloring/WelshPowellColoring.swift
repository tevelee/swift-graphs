/// A Welsh-Powell graph coloring algorithm.
///
/// This algorithm sorts vertices by degree in descending order and then colors them,
/// trying to assign the same color to as many non-adjacent vertices as possible.
///
/// - Complexity: O(V^2) where V is the number of vertices
public struct WelshPowellColoringAlgorithm<
    Graph: IncidenceGraph & VertexListGraph,
    Color: IntegerBasedColor
> where Graph.VertexDescriptor: Hashable {
    
    /// A visitor that can be used to observe Welsh-Powell coloring progress.
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
    
    /// Creates a new Welsh-Powell coloring algorithm.
    @inlinable
    public init() {}
    
    /// Colors the graph using the Welsh-Powell algorithm.
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
        
        // Sort vertices by degree in descending order
        let sortedVertices = vertices.sorted { v1, v2 in
            visitor?.examineVertex?(v1)
            visitor?.examineVertex?(v2)
            return graph.outDegree(of: v1) > graph.outDegree(of: v2)
        }
        
        var currentColor = Color(integerValue: 0)
        
        // Color vertices in order of decreasing degree
        for vertex in sortedVertices {
            // Skip if already colored
            if vertexColors[vertex] != nil {
                visitor?.skipVertex?(vertex, "Already colored")
                continue
            }
            
            visitor?.examineVertex?(vertex)
            
            // Color this vertex with current color
            vertexColors[vertex] = currentColor
            visitor?.assignColor?(vertex, currentColor)
            
            // Try to color as many uncolored vertices as possible with the same color
            for otherVertex in sortedVertices {
                // Skip if already colored or if it's the same vertex
                if vertexColors[otherVertex] != nil || otherVertex == vertex {
                    continue
                }
                
                visitor?.examineVertex?(otherVertex)
                
                // Check if this vertex can be colored with the current color
                let neighbors = Set(graph.successors(of: otherVertex))
                
                // Examine edges to neighbors
                for edge in graph.outgoingEdges(of: otherVertex) {
                    visitor?.examineEdge?(edge)
                }
                
                let canUseCurrentColor = !neighbors.contains { neighbor in
                    if let neighborColor = vertexColors[neighbor] {
                        return neighborColor == currentColor
                    }
                    return false
                }
                
                if canUseCurrentColor {
                    vertexColors[otherVertex] = currentColor
                    visitor?.assignColor?(otherVertex, currentColor)
                }
            }
            
            // Move to next color
            currentColor = Color(integerValue: currentColor.integerValue + 1)
            usedColors.insert(currentColor)
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

extension WelshPowellColoringAlgorithm: VisitorSupporting {}

