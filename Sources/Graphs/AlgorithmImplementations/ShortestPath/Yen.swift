import Foundation

/// Yen's algorithm for finding K shortest paths between two vertices.
///
/// Yen's algorithm finds the K shortest paths between a source and destination vertex
/// by iteratively finding the shortest path and then finding alternative paths
/// by removing edges from previous paths.
///
/// - Complexity: O(K * V * (E + V log V)) where K is the number of paths, V is the number of vertices, and E is the number of edges
public struct Yen<
    Graph: IncidenceGraph & EdgePropertyGraph,
    Weight: Numeric & Comparable
> where
    Graph.VertexDescriptor: Hashable,
    Graph.EdgeDescriptor: Hashable,
    Weight.Magnitude == Weight
{
    /// The vertex type of the graph.
    public typealias Vertex = Graph.VertexDescriptor
    /// The edge type of the graph.
    public typealias Edge = Graph.EdgeDescriptor
    
    @usableFromInline
    let edgeWeight: CostDefinition<Graph, Weight>
    @usableFromInline
    let makePriorityQueue: () -> any QueueProtocol<PriorityItem>
    
    /// A priority queue item for Yen's algorithm.
    public struct PriorityItem {
        /// The path.
        public let path: Path<Vertex, Edge>
        /// The cost of the path.
        public let cost: Cost<Weight>
        
        /// Creates a new priority item.
        @inlinable
        public init(path: Path<Vertex, Edge>, cost: Cost<Weight>) {
            self.path = path
            self.cost = cost
        }
    }
    
    /// A visitor that can be used to observe Yen's algorithm progress.
    public struct Visitor {
        /// Called when a path is found.
        public var onPathFound: (Path<Vertex, Edge>) -> Void = { _ in }
        /// Called when a candidate path is added.
        public var onCandidateAdded: (Path<Vertex, Edge>, Cost<Weight>) -> Void = { _, _ in }
        /// Called when a path is selected.
        public var onPathSelected: (Path<Vertex, Edge>, Cost<Weight>) -> Void = { _, _ in }
        
        /// Creates a new visitor.
        @inlinable
        public init(
            onPathFound: @escaping (Path<Vertex, Edge>) -> Void = { _ in },
            onCandidateAdded: @escaping (Path<Vertex, Edge>, Cost<Weight>) -> Void = { _, _ in },
            onPathSelected: @escaping (Path<Vertex, Edge>, Cost<Weight>) -> Void = { _, _ in }
        ) {
            self.onPathFound = onPathFound
            self.onCandidateAdded = onCandidateAdded
            self.onPathSelected = onPathSelected
        }
    }
    
    /// Creates a new Yen algorithm instance.
    ///
    /// - Parameters:
    ///   - edgeWeight: The cost definition for edge weights.
    ///   - makePriorityQueue: A factory for creating priority queues.
    @inlinable
    public init(
        edgeWeight: CostDefinition<Graph, Weight>,
        makePriorityQueue: @escaping () -> any QueueProtocol<PriorityItem> = {
            PriorityQueue()
        }
    ) {
        self.edgeWeight = edgeWeight
        self.makePriorityQueue = makePriorityQueue
    }
    
    /// Finds the K shortest paths between two vertices.
    ///
    /// - Parameters:
    ///   - source: The source vertex.
    ///   - destination: The destination vertex.
    ///   - k: The number of shortest paths to find.
    ///   - graph: The graph to search in.
    ///   - visitor: An optional visitor to observe the algorithm's progress.
    /// - Returns: An array of the K shortest paths.
    @inlinable
    public func kShortestPaths(
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
    
    /// Creates a temporary graph for edge removal.
    ///
    /// - Parameter graph: The original graph.
    /// - Returns: A temporary graph.
    @usableFromInline
    func createTemporaryGraph(from graph: Graph) -> TemporaryGraph<Graph> {
        TemporaryGraph(originalGraph: graph)
    }
    
    /// Removes edges for a root path.
    ///
    /// - Parameters:
    ///   - tempGraph: The temporary graph to modify.
    ///   - previousPaths: The previous paths.
    ///   - rootPath: The root path.
    ///   - spurNode: The spur node.
    @usableFromInline
    func removeEdgesForRootPath(
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
    
    
    
    
    /// Finds the shortest path in a temporary graph.
    ///
    /// - Parameters:
    ///   - source: The source vertex.
    ///   - destination: The destination vertex.
    ///   - tempGraph: The temporary graph.
    /// - Returns: The shortest path, if one exists.
    @usableFromInline
    func findShortestPathInTemporaryGraph(
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
    
    /// Reconstructs a path from predecessors.
    ///
    /// - Parameters:
    ///   - source: The source vertex.
    ///   - destination: The destination vertex.
    ///   - predecessors: The predecessors dictionary.
    ///   - graph: The graph.
    /// - Returns: The reconstructed path, if one exists.
    @usableFromInline
    func reconstructPath(
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
    
    /// Creates a total path from a root path and spur path.
    ///
    /// - Parameters:
    ///   - rootPath: The root path.
    ///   - spurPath: The spur path.
    /// - Returns: The total path, if valid.
    @usableFromInline
    func createTotalPath(
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
    
    /// Checks if a path is already found.
    ///
    /// - Parameters:
    ///   - path: The path to check.
    ///   - results: The results array.
    ///   - candidates: The candidates array.
    /// - Returns: `true` if the path is already found, `false` otherwise.
    @usableFromInline
    func isPathAlreadyFound(
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
    
    /// Calculates the cost of a path.
    ///
    /// - Parameters:
    ///   - path: The path to calculate the cost for.
    ///   - graph: The graph.
    /// - Returns: The cost of the path.
    @usableFromInline
    func calculatePathCost(_ path: Path<Vertex, Edge>, in graph: Graph) -> Cost<Weight> {
        var totalCost: Weight = .zero
        for edge in path.edges {
            let weight = edgeWeight.costToExplore(edge, graph)
            totalCost += weight
        }
        return .finite(totalCost)
    }
    
    /// Selects the shortest candidate path.
    ///
    /// - Parameter candidates: The candidates array to modify.
    /// - Returns: The shortest candidate path, if one exists.
    @usableFromInline
    func selectShortestCandidate(_ candidates: inout [PriorityItem]) -> Path<Vertex, Edge>? {
        guard let shortest = candidates.min(by: { $0.cost < $1.cost }) else {
            return nil
        }
        
        candidates.removeAll { $0.path.vertices == shortest.path.vertices && $0.path.edges == shortest.path.edges }
        return shortest.path
    }
    
    /// Gets edges to remove for a root path.
    ///
    /// - Parameters:
    ///   - graph: The graph.
    ///   - previousPaths: The previous paths.
    ///   - rootPath: The root path.
    ///   - spurNode: The spur node.
    /// - Returns: The edges to remove.
    @usableFromInline
    func getEdgesToRemove(
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
    @inlinable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.path.vertices == rhs.path.vertices
    }
}

extension Yen.PriorityItem: Comparable {
    @inlinable
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.cost < rhs.cost
    }
}

// MARK: - Temporary Graph for Edge Removal

/// A temporary graph that allows edge removal for Yen's algorithm.
@usableFromInline
struct TemporaryGraph<BaseGraph: IncidenceGraph & EdgePropertyGraph>: IncidenceGraph & EdgePropertyGraph where BaseGraph.EdgeDescriptor: Hashable {
    @usableFromInline
    typealias VertexDescriptor = BaseGraph.VertexDescriptor
    @usableFromInline
    typealias EdgeDescriptor = BaseGraph.EdgeDescriptor
    @usableFromInline
    typealias OutgoingEdges = FilteredEdges<BaseGraph.OutgoingEdges>
    @usableFromInline
    typealias EdgeProperties = BaseGraph.EdgeProperties
    @usableFromInline
    typealias EdgePropertyMap = BaseGraph.EdgePropertyMap
    
    @usableFromInline
    let originalGraph: BaseGraph
    @usableFromInline
    var removedEdges: Set<EdgeDescriptor> = []
    
    @usableFromInline
    var edgePropertyMap: EdgePropertyMap {
        originalGraph.edgePropertyMap
    }
    
    @inlinable
    init(originalGraph: BaseGraph) {
        self.originalGraph = originalGraph
    }
    
    @inlinable
    mutating func removeEdge(_ edge: EdgeDescriptor) {
        removedEdges.insert(edge)
    }
    
    @inlinable
    func outgoingEdges(of vertex: VertexDescriptor) -> OutgoingEdges {
        FilteredEdges(
            base: originalGraph.outgoingEdges(of: vertex),
            removedEdges: removedEdges
        )
    }
    
    @inlinable
    func source(of edge: EdgeDescriptor) -> VertexDescriptor? {
        originalGraph.source(of: edge)
    }
    
    @inlinable
    func destination(of edge: EdgeDescriptor) -> VertexDescriptor? {
        originalGraph.destination(of: edge)
    }
    
    @inlinable
    func outDegree(of vertex: VertexDescriptor) -> Int {
        originalGraph.outgoingEdges(of: vertex).filter { !removedEdges.contains($0) }.count
    }
    
    // MARK: - EdgePropertyGraph conformance
    // The protocol only requires edgePropertyMap, which is already provided
}

@usableFromInline
struct FilteredEdges<BaseEdges: Sequence>: Sequence where BaseEdges.Element: Hashable {
    @usableFromInline
    let base: BaseEdges
    @usableFromInline
    let removedEdges: Set<BaseEdges.Element>
    
    @inlinable
    init(base: BaseEdges, removedEdges: Set<BaseEdges.Element>) {
        self.base = base
        self.removedEdges = removedEdges
    }
    
    @inlinable
    func makeIterator() -> FilteredIterator<BaseEdges.Iterator> {
        FilteredIterator(
            base: base.makeIterator(),
            removedEdges: removedEdges
        )
    }
}

@usableFromInline
struct FilteredIterator<BaseIterator: IteratorProtocol>: IteratorProtocol where BaseIterator.Element: Hashable {
    @usableFromInline
    var base: BaseIterator
    @usableFromInline
    let removedEdges: Set<BaseIterator.Element>
    
    @inlinable
    init(base: BaseIterator, removedEdges: Set<BaseIterator.Element>) {
        self.base = base
        self.removedEdges = removedEdges
    }
    
    @inlinable
    mutating func next() -> BaseIterator.Element? {
        while let element = base.next() {
            if !removedEdges.contains(element) {
                return element
            }
        }
        return nil
    }
}

