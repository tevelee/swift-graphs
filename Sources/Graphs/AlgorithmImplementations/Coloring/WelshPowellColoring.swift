import Foundation

struct WelshPowellColoringAlgorithm<
    Graph: IncidenceGraph & VertexListGraph,
    Color: Hashable & Equatable
>: ColoringAlgorithm where Graph.VertexDescriptor: Hashable {
    
    func color(graph: Graph) -> GraphColoring<Graph.VertexDescriptor, Color> {
        var vertexColors: [Graph.VertexDescriptor: Color] = [:]
        var usedColors: Set<Color> = []
        
        // Get all vertices
        let vertices = Array(graph.vertices())
        
        // If no vertices, return empty coloring
        guard !vertices.isEmpty else {
            return GraphColoring(vertexColors: [:], isProper: true)
        }
        
        // Sort vertices by degree in descending order
        let sortedVertices = vertices.sorted { v1, v2 in
            graph.outDegree(of: v1) > graph.outDegree(of: v2)
        }
        
        var currentColor = 0 as! Color
        
        // Color vertices in order of decreasing degree
        for vertex in sortedVertices {
            // Skip if already colored
            if vertexColors[vertex] != nil {
                continue
            }
            
            // Color this vertex with current color
            vertexColors[vertex] = currentColor
            
            // Try to color as many uncolored vertices as possible with the same color
            for otherVertex in sortedVertices {
                // Skip if already colored or if it's the same vertex
                if vertexColors[otherVertex] != nil || otherVertex == vertex {
                    continue
                }
                
                // Check if this vertex can be colored with the current color
                let neighbors = Set(graph.successors(of: otherVertex))
                let canUseCurrentColor = !neighbors.contains { neighbor in
                    if let neighborColor = vertexColors[neighbor] {
                        return neighborColor == currentColor
                    }
                    return false
                }
                
                if canUseCurrentColor {
                    vertexColors[otherVertex] = currentColor
                }
            }
            
            // Move to next color
            currentColor = (currentColor as! Int + 1) as! Color
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

