import Foundation

/// Reverse Cuthill-McKee Ordering algorithm
/// 
/// This algorithm reorders the vertices of a graph to reduce the bandwidth of its adjacency matrix.
/// It uses breadth-first search starting from a vertex with minimum degree, enqueuing adjacent
/// vertices in order of increasing degree. The reverse ordering often produces better results
/// with less fill-in during matrix operations.
struct ReverseCuthillMcKeeOrderingAlgorithm<
    Graph: IncidenceGraph & VertexListGraph & BidirectionalGraph
> where Graph.VertexDescriptor: Hashable {
    
    struct Visitor {
        var examineVertex: ((Graph.VertexDescriptor) -> Void)?
        var enqueueVertex: ((Graph.VertexDescriptor, Int) -> Void)?
        var dequeueVertex: ((Graph.VertexDescriptor) -> Void)?
        var startFromVertex: ((Graph.VertexDescriptor) -> Void)?
        
        init(
            examineVertex: ((Graph.VertexDescriptor) -> Void)? = nil,
            enqueueVertex: ((Graph.VertexDescriptor, Int) -> Void)? = nil,
            dequeueVertex: ((Graph.VertexDescriptor) -> Void)? = nil,
            startFromVertex: ((Graph.VertexDescriptor) -> Void)? = nil
        ) {
            self.examineVertex = examineVertex
            self.enqueueVertex = enqueueVertex
            self.dequeueVertex = dequeueVertex
            self.startFromVertex = startFromVertex
        }
    }
    
    init() {}
    
    func orderVertices(in graph: Graph, visitor: Visitor? = nil) -> [Graph.VertexDescriptor] {
        var visited = Set<Graph.VertexDescriptor>()
        var ordering: [Graph.VertexDescriptor] = []

        // Process each connected component
        for vertex in graph.vertices() {
            if !visited.contains(vertex) {
                let componentOrdering = cuthillMcKeeForComponent(
                    startingFrom: vertex,
                    in: graph,
                    visited: &visited,
                    visitor: visitor
                )
                ordering.append(contentsOf: componentOrdering)
            }
        }

        // Reverse the ordering for better bandwidth reduction
        return ordering.reversed()
    }
    
    private func cuthillMcKeeForComponent(
        startingFrom startVertex: Graph.VertexDescriptor,
        in graph: Graph,
        visited: inout Set<Graph.VertexDescriptor>,
        visitor: Visitor?
    ) -> [Graph.VertexDescriptor] {
        var ordering: [Graph.VertexDescriptor] = []
        var queue: [Graph.VertexDescriptor] = [startVertex]
        var queueIndex = 0
        
        visitor?.startFromVertex?(startVertex)
        
        while queueIndex < queue.count {
            let currentVertex = queue[queueIndex]
            queueIndex += 1
            
            if visited.contains(currentVertex) {
                continue
            }
            
            visited.insert(currentVertex)
            ordering.append(currentVertex)
            visitor?.examineVertex?(currentVertex)
            visitor?.dequeueVertex?(currentVertex)
            
            // Get neighbors and sort by degree
            let neighbors = graph.successors(of: currentVertex)
                .filter { !visited.contains($0) }
                .sorted { graph.outDegree(of: $0) < graph.outDegree(of: $1) }
            
            // Add neighbors to queue in order of increasing degree
            for neighbor in neighbors {
                if !visited.contains(neighbor) && !queue.contains(neighbor) {
                    queue.append(neighbor)
                    visitor?.enqueueVertex?(neighbor, graph.outDegree(of: neighbor))
                }
            }
        }
        
        return ordering
    }
}

extension ReverseCuthillMcKeeOrderingAlgorithm: VisitorSupporting {}
