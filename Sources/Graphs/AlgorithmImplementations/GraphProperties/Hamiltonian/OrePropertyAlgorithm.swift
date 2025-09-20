import Foundation

struct StandardOrePropertyAlgorithm<Graph: IncidenceGraph & VertexListGraph & BidirectionalGraph> where Graph.VertexDescriptor: Hashable {
    typealias Visitor = OreProperty<Graph>.Visitor
    
    func satisfiesOre(
        in graph: Graph,
        visitor: Visitor?
    ) -> Bool {
        let n = graph.vertexCount
        
        // Ore's theorem requires at least 3 vertices
        guard n >= 3 else {
            visitor?.insufficientVertices?(n)
            return false
        }
        
        let vertices = Array(graph.vertices())
        visitor?.checkVertexCount?(n)
        
        // Check all pairs of non-adjacent vertices
        for i in 0..<vertices.count {
            for j in (i+1)..<vertices.count {
                let u = vertices[i]
                let v = vertices[j]
                
                // Check if u and v are adjacent
                let areAdjacent = graph.outgoingEdges(of: u).contains { edge in
                    graph.destination(of: edge) == v
                }
                
                visitor?.checkVertexPair?(u, v, areAdjacent)
                
                if !areAdjacent {
                    let degreeSum = graph.degree(of: u) + graph.degree(of: v)
                    visitor?.checkDegreeSum?(u, v, degreeSum, n)
                    
                    if degreeSum < n {
                        visitor?.degreeSumTooLow?(u, v, degreeSum, n)
                        return false
                    }
                }
            }
        }
        
        return true
    }
}

extension StandardOrePropertyAlgorithm: OrePropertyAlgorithm {
    // Protocol conformance is already satisfied by the struct
}
