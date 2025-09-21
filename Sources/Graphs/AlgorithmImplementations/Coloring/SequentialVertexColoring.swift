import Foundation

/// Sequential Vertex Coloring algorithm that uses vertex ordering
/// 
/// This algorithm assigns colors to vertices in a specific order, ensuring that no two
/// adjacent vertices share the same color. The efficiency and effectiveness of this method
/// is heavily influenced by the chosen vertex ordering.
struct SequentialVertexColoringAlgorithm<
    Graph: IncidenceGraph & VertexListGraph & BidirectionalGraph,
    Color: IntegerBasedColor
> where Graph.VertexDescriptor: Hashable {
    
    struct Visitor {
        var examineVertex: ((Graph.VertexDescriptor) -> Void)?
        var examineEdge: ((Graph.EdgeDescriptor) -> Void)?
        var assignColor: ((Graph.VertexDescriptor, Color) -> Void)?
        var skipVertex: ((Graph.VertexDescriptor, String) -> Void)?
        var useOrdering: ((any VertexOrderingAlgorithm<Graph>) -> Void)?
        
        init(
            examineVertex: ((Graph.VertexDescriptor) -> Void)? = nil,
            examineEdge: ((Graph.EdgeDescriptor) -> Void)? = nil,
            assignColor: ((Graph.VertexDescriptor, Color) -> Void)? = nil,
            skipVertex: ((Graph.VertexDescriptor, String) -> Void)? = nil,
            useOrdering: ((any VertexOrderingAlgorithm<Graph>) -> Void)? = nil
        ) {
            self.examineVertex = examineVertex
            self.examineEdge = examineEdge
            self.assignColor = assignColor
            self.skipVertex = skipVertex
            self.useOrdering = useOrdering
        }
    }
    
    private let orderingAlgorithm: any VertexOrderingAlgorithm<Graph>
    
    init(using orderingAlgorithm: any VertexOrderingAlgorithm<Graph>) {
        self.orderingAlgorithm = orderingAlgorithm
    }
    
    func color(graph: Graph, visitor: Visitor? = nil) -> GraphColoring<Graph.VertexDescriptor, Color> {
        var vertexColors: [Graph.VertexDescriptor: Color] = [:]
        var usedColors: Set<Color> = []
        
        // Get vertex ordering - we need to work around the existential type limitation
        visitor?.useOrdering?(orderingAlgorithm)
        let orderedVertices: [Graph.VertexDescriptor]
        
        // Use type erasure to call the method
        if let smallestLast = orderingAlgorithm as? SmallestLastVertexOrderingAlgorithm<Graph> {
            orderedVertices = smallestLast.orderVertices(in: graph, visitor: nil)
        } else if let reverseCuthillMcKee = orderingAlgorithm as? ReverseCuthillMcKeeOrderingAlgorithm<Graph> {
            orderedVertices = reverseCuthillMcKee.orderVertices(in: graph, visitor: nil)
        } else {
            // Fallback to default ordering (just use vertices as-is)
            orderedVertices = Array(graph.vertices())
        }
        
        // If no vertices, return empty coloring
        guard !orderedVertices.isEmpty else {
            return GraphColoring<Graph.VertexDescriptor, Color>(vertexColors: [:], isProper: true)
        }
        
        // Color vertices in the specified order
        for vertex in orderedVertices {
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
