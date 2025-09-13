import Foundation

struct DSaturColoringAlgorithm<
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
        
        // Calculate degrees for all vertices
        let degrees = Dictionary(uniqueKeysWithValues: vertices.map { vertex in
            (vertex, graph.outDegree(of: vertex))
        })
        
        // Find vertex with maximum degree to start (break ties by vertex index for determinism)
        let startVertex = vertices.enumerated().max { 
            if degrees[$0.element]! != degrees[$1.element]! {
                return degrees[$0.element]! < degrees[$1.element]!
            }
            // Break ties by vertex index for determinism
            return $0.offset > $1.offset
        }!.element
        
        // Color the first vertex with color 0
        let firstColor = 0 as! Color
        vertexColors[startVertex] = firstColor
        usedColors.insert(firstColor)
        
        // Create priority queue for uncolored vertices
        var uncoloredVertices = Set(vertices)
        uncoloredVertices.remove(startVertex)
        
        // Color remaining vertices using DSatur heuristic
        while !uncoloredVertices.isEmpty {
            // Find vertex with maximum saturation degree
            let nextVertex = findMaxSaturationVertex(
                in: uncoloredVertices,
                graph: graph,
                vertexColors: vertexColors,
                vertices: vertices
            )
            
            // Find the smallest available color for this vertex
            let neighbors = Set(graph.successors(of: nextVertex))
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
            
            vertexColors[nextVertex] = assignedColor!
            usedColors.insert(assignedColor!)
            uncoloredVertices.remove(nextVertex)
        }
        
        // Check if the coloring is proper
        let isProper = checkProperColoring(in: graph, vertexColors: vertexColors)
        
        return GraphColoring(vertexColors: vertexColors, isProper: isProper)
    }
    
    private func findMaxSaturationVertex(
        in uncoloredVertices: Set<Graph.VertexDescriptor>,
        graph: Graph,
        vertexColors: [Graph.VertexDescriptor: Color],
        vertices: [Graph.VertexDescriptor]
    ) -> Graph.VertexDescriptor {
        var maxSaturation = -1
        var maxDegree = -1
        var selectedVertex = uncoloredVertices.first!
        
        for vertex in uncoloredVertices {
            let neighbors = Set(graph.successors(of: vertex))
            let saturationDegree = neighbors.compactMap { neighbor in
                vertexColors[neighbor]
            }.count
            
            let degree = graph.outDegree(of: vertex)
            
            // Select vertex with maximum saturation degree, breaking ties by degree, then by vertex index
            let shouldSelect: Bool
            if saturationDegree > maxSaturation {
                shouldSelect = true
            } else if saturationDegree == maxSaturation && degree > maxDegree {
                shouldSelect = true
            } else if saturationDegree == maxSaturation && degree == maxDegree {
                // Both saturation and degree are equal, use vertex index for determinism
                let currentIndex = vertices.firstIndex(of: vertex)!
                let selectedIndex = vertices.firstIndex(of: selectedVertex)!
                shouldSelect = currentIndex < selectedIndex
            } else {
                shouldSelect = false
            }
            
            if shouldSelect {
                maxSaturation = saturationDegree
                maxDegree = degree
                selectedVertex = vertex
            }
        }
        
        return selectedVertex
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

