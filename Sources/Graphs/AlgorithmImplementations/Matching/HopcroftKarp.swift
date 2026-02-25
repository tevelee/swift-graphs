#if !GRAPHS_USES_TRAITS || GRAPHS_OPTIMIZATION
import Collections

/// Hopcroft-Karp algorithm for finding maximum matching in bipartite graphs.
///
/// This algorithm finds the maximum matching by repeatedly finding augmenting paths
/// and increasing the matching size. It uses BFS to find multiple disjoint augmenting
/// paths in each iteration, making it more efficient than the basic augmenting path approach.
///
/// - Complexity: O(E * sqrt(V)) where E is the number of edges and V is the number of vertices
public struct HopcroftKarp<Graph: BipartiteGraph & IncidenceGraph & VertexListGraph> where Graph.VertexDescriptor: Hashable {
    /// The vertex type of the graph.
    public typealias Vertex = Graph.VertexDescriptor
    /// The edge type of the graph.
    public typealias Edge = Graph.EdgeDescriptor
    
    /// A visitor that can be used to observe Hopcroft-Karp algorithm progress.
    public struct Visitor {
        /// Called when examining a vertex.
        public var examineVertex: ((Vertex) -> Void)?
        /// Called when examining an edge.
        public var examineEdge: ((Edge) -> Void)?
        /// Called when finding an augmenting path.
        public var findAugmentingPath: (([Edge]) -> Void)?
        /// Called when augmenting the matching.
        public var augmentMatching: (([Edge]) -> Void)?
        /// Called when updating the matching.
        public var updateMatching: ((Vertex, Vertex) -> Void)?
        /// Called when starting a new iteration.
        public var startIteration: ((Int) -> Void)?
        
        /// Creates a new visitor.
        @inlinable
        public init(
            examineVertex: ((Vertex) -> Void)? = nil,
            examineEdge: ((Edge) -> Void)? = nil,
            findAugmentingPath: (([Edge]) -> Void)? = nil,
            augmentMatching: (([Edge]) -> Void)? = nil,
            updateMatching: ((Vertex, Vertex) -> Void)? = nil,
            startIteration: ((Int) -> Void)? = nil
        ) {
            self.examineVertex = examineVertex
            self.examineEdge = examineEdge
            self.findAugmentingPath = findAugmentingPath
            self.augmentMatching = augmentMatching
            self.updateMatching = updateMatching
            self.startIteration = startIteration
        }
        
    }
    
    /// Creates a new Hopcroft-Karp algorithm.
    @inlinable
    public init() {}
    
    /// Finds the maximum matching using Hopcroft-Karp algorithm.
    ///
    /// - Parameters:
    ///   - graph: The bipartite graph to find matching in
    ///   - visitor: An optional visitor to observe the algorithm progress
    /// - Returns: The maximum matching result
    @inlinable
    public func maximumMatching(
        in graph: Graph,
        visitor: Visitor? = nil
    ) -> MatchingResult<Vertex, Edge> {
        // Initialize matching
        var matching: [Vertex: Vertex] = [:]
        var matchingEdges: [Edge] = []
        
        // Get partitions
        let leftVertices = Array(graph.leftPartition())
        let rightVertices = Array(graph.rightPartition())
        
        var iteration = 0
        
        // Main algorithm loop
        while true {
            iteration += 1
            visitor?.startIteration?(iteration)
            
            // Find all augmenting paths in this iteration
            let augmentingPaths = findAugmentingPaths(
                in: graph,
                leftVertices: leftVertices,
                rightVertices: rightVertices,
                matching: matching,
                visitor: visitor
            )
            
            
            // If no augmenting paths found, we have maximum matching
            if augmentingPaths.isEmpty {
                break
            }
            
            // Augment the matching with all found paths
            for path in augmentingPaths {
                visitor?.augmentMatching?(path)
                augmentMatching(path, in: graph, matching: &matching, matchingEdges: &matchingEdges, visitor: visitor)
            }
        }
        
        // Build result
        let matchedVertices = Set(matching.keys).union(Set(matching.values))
        let allVertices = Set(leftVertices).union(Set(rightVertices))
        let unmatchedVertices = allVertices.subtracting(matchedVertices)
        
        let matchedLeftVertices = Set(leftVertices).intersection(matchedVertices)
        let matchedRightVertices = Set(rightVertices).intersection(matchedVertices)
        let unmatchedLeftVertices = Set(leftVertices).subtracting(matchedVertices)
        let unmatchedRightVertices = Set(rightVertices).subtracting(matchedVertices)
        
        return MatchingResult(
            matchingSize: matchingEdges.count,
            matchingEdges: matchingEdges,
            matchedVertices: matchedVertices,
            unmatchedVertices: unmatchedVertices,
            matchedLeftVertices: matchedLeftVertices,
            matchedRightVertices: matchedRightVertices,
            unmatchedLeftVertices: unmatchedLeftVertices,
            unmatchedRightVertices: unmatchedRightVertices,
            partnerMap: matching
        )
    }
    
    @usableFromInline
    func findAugmentingPaths(
        in graph: Graph,
        leftVertices: [Vertex],
        rightVertices: [Vertex],
        matching: [Vertex: Vertex],
        visitor: Visitor?
    ) -> [[Edge]] {
        var augmentingPaths: [[Edge]] = []
        var visited: Set<Vertex> = []
        
        // Find augmenting paths starting from unmatched left vertices
        for leftVertex in leftVertices {
            if !matching.keys.contains(leftVertex) && !visited.contains(leftVertex) {
                if let path = findAugmentingPath(
                    from: leftVertex,
                    in: graph,
                    matching: matching,
                    visited: &visited,
                    visitor: visitor
                ) {
                    augmentingPaths.append(path)
                }
            }
        }
        
        return augmentingPaths
    }
    
    @usableFromInline
    func findAugmentingPath(
        from start: Vertex,
        in graph: Graph,
        matching: [Vertex: Vertex],
        visited: inout Set<Vertex>,
        visitor: Visitor?
    ) -> [Edge]? {
        var queue: [Vertex] = [start]
        var parent: [Vertex: Vertex] = [:]
        var parentEdge: [Vertex: Edge] = [:]
        var found = false
        
        visited.insert(start)
        
        while !queue.isEmpty && !found {
            let current = queue.removeFirst()
            visitor?.examineVertex?(current)
            
            // If this is an unmatched right vertex, we found an augmenting path
            if let partition = graph.partition(of: current), partition == .right && !matching.values.contains(current) {
                found = true
                // Reconstruct path
                var path: [Edge] = []
                var vertex = current
                
                while let parentVertex = parent[vertex], let edge = parentEdge[vertex] {
                    path.append(edge)
                    vertex = parentVertex
                }
                
                path.reverse()
                visitor?.findAugmentingPath?(path)
                return path
            }
            
            // Explore neighbors
            for edge in graph.outgoingEdges(of: current) {
                guard let destination = graph.destination(of: edge) else { continue }
                visitor?.examineEdge?(edge)
                
                if !visited.contains(destination) {
                    visited.insert(destination)
                    parent[destination] = current
                    parentEdge[destination] = edge
                    queue.append(destination)
                }
            }
        }
        
        return nil
    }
    
    @usableFromInline
    func augmentMatching(
        _ path: [Edge],
        in graph: Graph,
        matching: inout [Vertex: Vertex],
        matchingEdges: inout [Edge],
        visitor: Visitor?
    ) {
        // Remove existing matching edges that are in the path
        for edge in path {
            if let source = graph.source(of: edge),
               let destination = graph.destination(of: edge) {
                matching.removeValue(forKey: source)
                matching.removeValue(forKey: destination)
                
                // Remove from matching edges
                matchingEdges.removeAll { existingEdge in
                    (graph.source(of: existingEdge) == source && graph.destination(of: existingEdge) == destination) ||
                    (graph.source(of: existingEdge) == destination && graph.destination(of: existingEdge) == source)
                }
            }
        }
        
        // Add new matching edges (alternating pattern)
        for (index, edge) in path.enumerated() {
            if index % 2 == 0 { // Even indices are matching edges
                if let source = graph.source(of: edge),
                   let destination = graph.destination(of: edge) {
                    matching[source] = destination
                    matching[destination] = source
                    matchingEdges.append(edge)
                    visitor?.updateMatching?(source, destination)
                }
            }
        }
    }
}

extension HopcroftKarp: MatchingAlgorithm {
    public typealias Graph = Graph
}

extension MatchingAlgorithm {
    /// Creates a Hopcroft-Karp algorithm.
    ///
    /// - Returns: A Hopcroft-Karp algorithm instance.
    @inlinable
    public static func hopcroftKarp<Graph>() -> Self where Self == HopcroftKarp<Graph> {
        .init()
    }
}

extension HopcroftKarp: VisitorSupporting {
    @inlinable
    public func withVisitor(_ visitor: Visitor) -> VisitorWrapper<Self, Visitor> {
        VisitorWrapper(base: self, visitor: visitor)
    }
}
#endif
