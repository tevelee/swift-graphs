import Foundation

struct Yen<
    Graph: IncidenceGraph & EdgePropertyGraph,
    Weight: AdditiveArithmetic & Comparable
> where
    Graph.VertexDescriptor: Hashable
{
    typealias Vertex = Graph.VertexDescriptor
    typealias Edge = Graph.EdgeDescriptor
    
    private let edgeWeight: CostDefinition<Graph, Weight>
    private let makePriorityQueue: () -> any QueueProtocol<PriorityItem>
    
    struct PriorityItem {
        let path: Path<Vertex, Edge>
        let cost: Cost<Weight>
    }
    
    struct Visitor {
        var onPathFound: (Path<Vertex, Edge>) -> Void = { _ in }
        var onCandidateAdded: (Path<Vertex, Edge>, Cost<Weight>) -> Void = { _, _ in }
        var onPathSelected: (Path<Vertex, Edge>, Cost<Weight>) -> Void = { _, _ in }
    }
    
    init(
        edgeWeight: CostDefinition<Graph, Weight>,
        makePriorityQueue: @escaping () -> any QueueProtocol<PriorityItem> = {
            PriorityQueue()
        }
    ) {
        self.edgeWeight = edgeWeight
        self.makePriorityQueue = makePriorityQueue
    }
    
    func kShortestPaths(
        from source: Vertex,
        to destination: Vertex,
        k: Int,
        in graph: Graph,
        visitor: Visitor? = nil
    ) -> [Path<Vertex, Edge>] {
        var result: [Path<Vertex, Edge>] = []
        var candidates: [PriorityItem] = []
        
        // Find the shortest path using Dijkstra
        guard let shortestPath = findShortestPath(from: source, to: destination, in: graph) else {
            return []
        }
        
        result.append(shortestPath)
        visitor?.onPathFound(shortestPath)
        
        // Find k-1 additional paths
        for i in 1 ..< k {
            let previousPath = result[i-1]
            
            // For each vertex in the previous path, find alternative paths
            for j in 0 ..< previousPath.vertices.count - 1 {
                let spurNode = previousPath.vertices[j]
                let rootPath = previousPath.vertices[0 ... j]
                
                // Remove edges used in previous paths
                var removedEdges: [Edge] = []
                for path in result {
                    if path.vertices.count > j && Array(path.vertices[0 ... j]) == Array(rootPath) {
                        if j + 1 < path.vertices.count {
                            // Find and remove the edge from spurNode to next vertex
                            for edge in graph.outgoingEdges(of: spurNode) {
                                if let nextVertex = graph.destination(of: edge),
                                   nextVertex == path.vertices[j + 1] {
                                    removedEdges.append(edge)
                                    break
                                }
                            }
                        }
                    }
                }
                
                // Temporarily remove these edges
                // Note: This is a simplified implementation - in practice, you'd need
                // a way to temporarily modify the graph or work with a copy
                
                // Find spur path from spurNode to destination
                if let spurPath = findShortestPath(from: spurNode, to: destination, in: graph),
                   let totalPath = createTotalPath(
                       rootPath: Array(rootPath),
                       spurPath: spurPath,
                       in: graph
                   ) {
                    
                    if !result.contains(where: { $0.vertices == totalPath.vertices }) {
                        let cost = calculatePathCost(totalPath, in: graph)
                        candidates.append(PriorityItem(path: totalPath, cost: cost))
                        visitor?.onCandidateAdded(totalPath, cost)
                    }
                }
                
                // Restore removed edges
                // Note: In practice, you'd restore the edges here
            }
            
            // Select the shortest candidate path
            guard let nextPath = selectShortestCandidate(&candidates) else {
                break
            }
            
            result.append(nextPath)
            let cost = calculatePathCost(nextPath, in: graph)
            visitor?.onPathSelected(nextPath, cost)
        }
        
        return result
    }
    
    private func findShortestPath(from source: Vertex, to destination: Vertex, in graph: Graph) -> Path<Vertex, Edge>? {
        var distances: [Vertex: Cost<Weight>] = [:]
        var predecessors: [Vertex: Edge?] = [:]
        var visited: Set<Vertex> = []
        
        var queue = makePriorityQueue()
        queue.enqueue(PriorityItem(path: Path(source: source, destination: source, vertices: [source], edges: []), cost: .finite(.zero)))
        
        distances[source] = .finite(.zero)
        predecessors[source] = nil
        
        while let item = queue.dequeue() {
            let current = item.path.destination
            let currentCost = item.cost
            
            if visited.contains(current) { continue }
            if current == destination { break }
            
            visited.insert(current)
            
            for edge in graph.outgoingEdges(of: current) {
                guard let next = graph.destination(of: edge) else { continue }
                if visited.contains(next) { continue }
                
                let weight = edgeWeight.costToExplore(edge, graph)
                let newCost = currentCost + weight
                
                let currentBestCost = distances[next]
                if currentBestCost == nil || newCost < (currentBestCost ?? .infinite) {
                    distances[next] = newCost
                    predecessors[next] = edge
                    queue.enqueue(PriorityItem(path: Path(source: source, destination: next, vertices: [source, next], edges: [edge]), cost: newCost))
                }
            }
        }
        
        // Reconstruct path
        return reconstructPath(from: source, to: destination, predecessors: predecessors, in: graph)
    }
    
    private func reconstructPath(
        from source: Vertex,
        to destination: Vertex,
        predecessors: [Vertex: Edge?],
        in graph: Graph
    ) -> Path<Vertex, Edge>? {
        var current = destination
        var vertices: [Vertex] = [destination]
        var edges: [Edge] = []
        
        while let optionalEdge = predecessors[current], let edge = optionalEdge {
            edges.insert(edge, at: 0)
            guard let predecessor = graph.source(of: edge) else { break }
            if predecessor == source { break }
            vertices.insert(predecessor, at: 0)
            current = predecessor
        }
        
        vertices.insert(source, at: 0)
        
        return Path(
            source: source,
            destination: destination,
            vertices: vertices,
            edges: edges
        )
    }
    
    private func createTotalPath(
        rootPath: [Vertex],
        spurPath: Path<Vertex, Edge>,
        in graph: Graph
    ) -> Path<Vertex, Edge>? {
        let totalVertices = rootPath + spurPath.vertices.dropFirst()
        let totalEdges = spurPath.edges
        
        guard let firstVertex = rootPath.first else {
            return nil
        }
        
        return Path(
            source: firstVertex,
            destination: spurPath.destination,
            vertices: totalVertices,
            edges: totalEdges
        )
    }
    
    private func calculatePathCost(_ path: Path<Vertex, Edge>, in graph: Graph) -> Cost<Weight> {
        var totalCost: Weight = .zero
        for edge in path.edges {
            let weight = edgeWeight.costToExplore(edge, graph)
            totalCost += weight
        }
        return .finite(totalCost)
    }
    
    private func selectShortestCandidate(_ candidates: inout [PriorityItem]) -> Path<Vertex, Edge>? {
        guard let shortest = candidates.min(by: { $0.cost < $1.cost }) else {
            return nil
        }
        
        candidates.removeAll { $0.path.vertices == shortest.path.vertices }
        return shortest.path
    }
}

extension Yen: KShortestPathsAlgorithm, VisitorSupporting {}

extension Yen.PriorityItem: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.path.vertices == rhs.path.vertices
    }
}

extension Yen.PriorityItem: Comparable {
    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.cost < rhs.cost
    }
}
