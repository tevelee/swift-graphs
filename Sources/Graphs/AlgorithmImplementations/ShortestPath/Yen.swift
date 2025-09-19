import Foundation

struct Yen<
    Graph: IncidenceGraph & EdgePropertyGraph,
    Weight: Numeric & Comparable
> where
    Graph.VertexDescriptor: Hashable,
    Graph.EdgeDescriptor: Hashable,
    Weight.Magnitude == Weight
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
        // Handle edge cases
        if source == destination {
            return []
        }
        
        var result: [Path<Vertex, Edge>] = []
        var candidates: [PriorityItem] = []
        
        // Step 1: Find the shortest path using Dijkstra
        guard let shortestPath = graph.shortestPath(from: source, to: destination, using: .dijkstra(weight: edgeWeight)) else {
            return []
        }
        
        result.append(shortestPath)
        visitor?.onPathFound(shortestPath)
        
        // Step 2: Find k-1 additional paths using Yen's algorithm
        for i in 1..<k {
            let previousPath = result[i-1]
            
            // For each vertex in the previous path (except the last one)
            for j in 0..<(previousPath.vertices.count - 1) {
                let spurNode = previousPath.vertices[j]
                let rootPath = Array(previousPath.vertices[0...j])
                
                // Create a temporary graph with removed edges
                var tempGraph = createTemporaryGraph(from: graph)
                
                // Remove edges used in previous paths that share the same root path
                removeEdgesForRootPath(
                    in: &tempGraph,
                    previousPaths: result,
                    rootPath: rootPath,
                    spurNode: spurNode
                )
                
                // Find spur path from spurNode to destination
                if let spurPath = findShortestPathInTemporaryGraph(from: spurNode, to: destination, in: tempGraph),
                   let totalPath = createTotalPath(
                       rootPath: rootPath,
                       spurPath: spurPath
                   ) {
                    // Check if this path is already in results or candidates
                    if !isPathAlreadyFound(totalPath, in: result, candidates: candidates) {
                        let cost = calculatePathCost(totalPath, in: graph)
                        candidates.append(PriorityItem(path: totalPath, cost: cost))
                        visitor?.onCandidateAdded(totalPath, cost)
                    }
                }
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
    
    // MARK: - Temporary Graph Management
    
    private func createTemporaryGraph(from graph: Graph) -> TemporaryGraph<Graph> {
        TemporaryGraph(originalGraph: graph)
    }
    
    private func removeEdgesForRootPath(
        in tempGraph: inout TemporaryGraph<Graph>,
        previousPaths: [Path<Vertex, Edge>],
        rootPath: [Vertex],
        spurNode: Vertex
    ) {
        for path in previousPaths {
            // Check if this path shares the same root path
            if path.vertices.count > rootPath.count &&
               Array(path.vertices[0..<rootPath.count]) == rootPath {
                
                // Find the edge from spurNode to the next vertex in the path
                if rootPath.count < path.vertices.count {
                    let nextVertex = path.vertices[rootPath.count]
                    
                    // Find and remove the edge from spurNode to nextVertex
                    for edge in tempGraph.originalGraph.outgoingEdges(of: spurNode) {
                        if let destination = tempGraph.originalGraph.destination(of: edge),
                           destination == nextVertex {
                            tempGraph.removeEdge(edge)
                            break
                        }
                    }
                }
            }
        }
    }
    
    
    
    
    private func findShortestPathInTemporaryGraph(
        from source: Vertex,
        to destination: Vertex,
        in tempGraph: TemporaryGraph<Graph>
    ) -> Path<Vertex, Edge>? {
        var distances: [Vertex: Cost<Weight>] = [:]
        var predecessors: [Vertex: Edge?] = [:]
        var visited: Set<Vertex> = []
        
        var queue: [(Vertex, Cost<Weight>)] = [(source, .finite(.zero))]
        distances[source] = .finite(.zero)
        predecessors[source] = nil
        
        while !queue.isEmpty {
            queue.sort { $0.1 < $1.1 }
            let (current, currentCost) = queue.removeFirst()
            
            if visited.contains(current) { continue }
            if current == destination { break }
            
            visited.insert(current)
            
            for edge in tempGraph.outgoingEdges(of: current) {
                guard let next = tempGraph.destination(of: edge) else { continue }
                if visited.contains(next) { continue }
                
                let weight = edgeWeight.costToExplore(edge, tempGraph.originalGraph)
                let newCost = currentCost + weight
                
                let currentBestCost = distances[next]
                if currentBestCost == nil || newCost < (currentBestCost ?? .infinite) {
                    distances[next] = newCost
                    predecessors[next] = edge
                    queue.append((next, newCost))
                }
            }
        }
        
        // Reconstruct path
        return reconstructPath(from: source, to: destination, predecessors: predecessors, in: tempGraph.originalGraph)
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
    
    // MARK: - Path Management
    
    private func createTotalPath(
        rootPath: [Vertex],
        spurPath: Path<Vertex, Edge>
    ) -> Path<Vertex, Edge>? {
        // Ensure the spur path starts from the last vertex of the root path
        guard let rootLast = rootPath.last,
              let spurFirst = spurPath.vertices.first,
              rootLast == spurFirst else {
            return nil
        }
        
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
    
    private func isPathAlreadyFound(
        _ path: Path<Vertex, Edge>,
        in results: [Path<Vertex, Edge>],
        candidates: [PriorityItem]
    ) -> Bool {
        // Validate path first - must have at least one edge
        guard !path.edges.isEmpty else { return true }
        
        // Check if path is already in results
        if results.contains(where: { $0.vertices == path.vertices && $0.edges == path.edges }) {
            return true
        }
        
        // Check if path is already in candidates
        if candidates.contains(where: { $0.path.vertices == path.vertices && $0.path.edges == path.edges }) {
            return true
        }
        
        return false
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
        
        candidates.removeAll { $0.path.vertices == shortest.path.vertices && $0.path.edges == shortest.path.edges }
        return shortest.path
    }
    
    private func getEdgesToRemove(
        from graph: Graph,
        previousPaths: [Path<Vertex, Edge>],
        rootPath: [Vertex],
        spurNode: Vertex
    ) -> [Edge] {
        var edgesToRemove: [Edge] = []
        
        for path in previousPaths {
            if path.vertices.count > rootPath.count && 
               Array(path.vertices[0..<rootPath.count]) == rootPath {
                if rootPath.count < path.vertices.count {
                    let nextVertex = path.vertices[rootPath.count]
                    // Find the edge from spurNode to nextVertex
                    for edge in graph.outgoingEdges(of: spurNode) {
                        if let destination = graph.destination(of: edge),
                           destination == nextVertex {
                            edgesToRemove.append(edge)
                            break
                        }
                    }
                }
            }
        }
        
        return edgesToRemove
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

// MARK: - Temporary Graph for Edge Removal

private struct TemporaryGraph<BaseGraph: IncidenceGraph & EdgePropertyGraph>: IncidenceGraph & EdgePropertyGraph where BaseGraph.EdgeDescriptor: Hashable {
    typealias VertexDescriptor = BaseGraph.VertexDescriptor
    typealias EdgeDescriptor = BaseGraph.EdgeDescriptor
    typealias OutgoingEdges = FilteredEdges<BaseGraph.OutgoingEdges>
    typealias EdgeProperties = BaseGraph.EdgeProperties
    typealias EdgePropertyMap = BaseGraph.EdgePropertyMap
    
    let originalGraph: BaseGraph
    private var removedEdges: Set<EdgeDescriptor> = []
    
    var edgePropertyMap: EdgePropertyMap {
        originalGraph.edgePropertyMap
    }
    
    init(originalGraph: BaseGraph) {
        self.originalGraph = originalGraph
    }
    
    mutating func removeEdge(_ edge: EdgeDescriptor) {
        removedEdges.insert(edge)
    }
    
    func outgoingEdges(of vertex: VertexDescriptor) -> OutgoingEdges {
        FilteredEdges(
            base: originalGraph.outgoingEdges(of: vertex),
            removedEdges: removedEdges
        )
    }
    
    func source(of edge: EdgeDescriptor) -> VertexDescriptor? {
        originalGraph.source(of: edge)
    }
    
    func destination(of edge: EdgeDescriptor) -> VertexDescriptor? {
        originalGraph.destination(of: edge)
    }
    
    func outDegree(of vertex: VertexDescriptor) -> Int {
        originalGraph.outgoingEdges(of: vertex).filter { !removedEdges.contains($0) }.count
    }
    
    // MARK: - EdgePropertyGraph conformance
    // The protocol only requires edgePropertyMap, which is already provided
}

private struct FilteredEdges<BaseEdges: Sequence>: Sequence where BaseEdges.Element: Hashable {
    let base: BaseEdges
    let removedEdges: Set<BaseEdges.Element>
    
    func makeIterator() -> FilteredIterator<BaseEdges.Iterator> {
        FilteredIterator(
            base: base.makeIterator(),
            removedEdges: removedEdges
        )
    }
}

private struct FilteredIterator<BaseIterator: IteratorProtocol>: IteratorProtocol where BaseIterator.Element: Hashable {
    var base: BaseIterator
    let removedEdges: Set<BaseIterator.Element>
    
    mutating func next() -> BaseIterator.Element? {
        while let element = base.next() {
            if !removedEdges.contains(element) {
                return element
            }
        }
        return nil
    }
}

