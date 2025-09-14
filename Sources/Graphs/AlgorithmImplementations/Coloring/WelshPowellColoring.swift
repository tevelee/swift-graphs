import Foundation

struct WelshPowellColoringAlgorithm<
    Graph: IncidenceGraph & VertexListGraph,
    Color: IntegerBasedColor
> where Graph.VertexDescriptor: Hashable {
    
    struct Visitor {
        var examineVertex: ((Graph.VertexDescriptor) -> Void)?
        var examineEdge: ((Graph.EdgeDescriptor) -> Void)?
        var assignColor: ((Graph.VertexDescriptor, Color) -> Void)?
        var skipVertex: ((Graph.VertexDescriptor, String) -> Void)?
    }
    
    func color(graph: Graph, visitor: Visitor? = nil) -> GraphColoring<Graph.VertexDescriptor, Color> {
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
    
    private func checkProperColoring(
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

