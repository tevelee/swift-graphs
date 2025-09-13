extension BidirectionalGraph where Self: VertexListGraph, VertexDescriptor: Hashable {
    func eulerianPath(
        using algorithm: some EulerianPathAlgorithm<Self>
    ) -> Path<VertexDescriptor, EdgeDescriptor>? {
        algorithm.eulerianPath(in: self)
    }
    
    func eulerianCycle(
        using algorithm: some EulerianCycleAlgorithm<Self>
    ) -> Path<VertexDescriptor, EdgeDescriptor>? {
        algorithm.eulerianCycle(in: self)
    }
    
    func hasEulerianPath() -> Bool {
        // A graph has an Eulerian path if and only if:
        // 1. It's connected
        // 2. It has exactly 0 or 2 vertices of odd degree
        let vertices = Array(vertices())
        
        // Empty graph has no Eulerian path
        if vertices.isEmpty {
            return false
        }
        
        var oddDegreeCount = 0
        
        for vertex in vertices {
            let degree = degree(of: vertex)
            if degree % 2 == 1 {
                oddDegreeCount += 1
            }
        }
        
        return oddDegreeCount == 0 || oddDegreeCount == 2
    }
    
    func hasEulerianCycle() -> Bool {
        // A graph has an Eulerian cycle if and only if:
        // 1. It's connected
        // 2. All vertices have even degree
        let vertices = Array(vertices())
        
        // Empty graph has no Eulerian cycle
        if vertices.isEmpty {
            return false
        }
        
        for vertex in vertices {
            if degree(of: vertex) % 2 == 1 {
                return false
            }
        }
        
        return true
    }
}

protocol EulerianPathAlgorithm<Graph> {
    associatedtype Graph: BidirectionalGraph & VertexListGraph where Graph.VertexDescriptor: Hashable
    
    func eulerianPath(in graph: Graph) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>?
}

protocol EulerianCycleAlgorithm<Graph> {
    associatedtype Graph: BidirectionalGraph & VertexListGraph where Graph.VertexDescriptor: Hashable
    
    func eulerianCycle(in graph: Graph) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>?
}
