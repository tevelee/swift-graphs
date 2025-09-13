import Foundation

struct GreedyColoringAlgorithm<
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
        
        // Color the first vertex with color 0
        let firstColor = 0 as! Color
        vertexColors[vertices[0]] = firstColor
        usedColors.insert(firstColor)
        
        // Color remaining vertices
        for i in 1..<vertices.count {
            let vertex = vertices[i]
            let neighbors = Set(graph.successors(of: vertex))
            
            // Find the smallest available color
            var colorIndex = 0
            var assignedColor: Color?
            
            while assignedColor == nil {
                let candidateColor = colorIndex as! Color
                
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

