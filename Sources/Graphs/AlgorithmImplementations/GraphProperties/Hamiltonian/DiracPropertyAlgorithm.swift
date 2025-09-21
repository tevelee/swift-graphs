import Foundation

struct StandardDiracPropertyAlgorithm<Graph: IncidenceGraph & VertexListGraph & BidirectionalGraph> where Graph.VertexDescriptor: Hashable {
    typealias Visitor = DiracProperty<Graph>.Visitor
    
    func satisfiesDirac(
        in graph: Graph,
        visitor: Visitor?
    ) -> Bool {
        let n = graph.vertexCount
        
        // Dirac's theorem requires at least 3 vertices
        guard n >= 3 else {
            visitor?.insufficientVertices?(n)
            return false
        }
        
        let minDegree = n / 2
        visitor?.checkMinimumDegree?(minDegree)
        
        // Check if every vertex has degree >= n/2
        for vertex in graph.vertices() {
            let degree = graph.degree(of: vertex)
            visitor?.checkVertexDegree?(vertex, degree, minDegree)
            
            // Use proper comparison: degree must be >= n/2
            // Since we can't have fractional degrees, we need degree >= (n+1)/2
            if degree * 2 < n {
                visitor?.degreeTooLow?(vertex, degree, minDegree)
                return false
            }
        }
        
        return true
    }
}
