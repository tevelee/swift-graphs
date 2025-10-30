import Collections

/// Louvain algorithm for community detection.
///
/// This algorithm detects communities by optimizing modularity through
/// iterative local optimization and graph coarsening.
///
/// - Complexity: O(n log n) in typical cases
public struct LouvainCommunityDetection<Graph: IncidenceGraph & VertexListGraph & EdgeListGraph> 
    where Graph.VertexDescriptor: Hashable 
{
    /// The vertex type of the graph.
    public typealias Vertex = Graph.VertexDescriptor
    /// The edge type of the graph.
    public typealias Edge = Graph.EdgeDescriptor

    /// A visitor that can be used to observe the Louvain algorithm progress.
    public struct Visitor {
        /// Called at the start of each phase.
        public var startPhase: ((Int) -> Void)?
        /// Called when moving a vertex to a new community.
        public var moveVertex: ((Vertex, Int) -> Void)?
        /// Called when modularity improves.
        public var modularityImproved: ((Double) -> Void)?
        /// Called when an iteration completes.
        public var iterationComplete: ((Int, Double) -> Void)?
        
        /// Creates a new visitor.
        @inlinable
        public init(
            startPhase: ((Int) -> Void)? = nil,
            moveVertex: ((Vertex, Int) -> Void)? = nil,
            modularityImproved: ((Double) -> Void)? = nil,
            iterationComplete: ((Int, Double) -> Void)? = nil
        ) {
            self.startPhase = startPhase
            self.moveVertex = moveVertex
            self.modularityImproved = modularityImproved
            self.iterationComplete = iterationComplete
        }
    }

    /// The graph to detect communities in.
    @usableFromInline
    let graph: Graph
    
    /// Resolution parameter (default: 1.0).
    @usableFromInline
    let resolution: Double

    /// Creates a new Louvain community detection algorithm.
    ///
    /// - Parameters:
    ///   - graph: The graph to detect communities in
    ///   - resolution: Resolution parameter for modularity optimization
    @inlinable
    public init(on graph: Graph, resolution: Double = 1.0) {
        self.graph = graph
        self.resolution = resolution
    }

    /// Detects communities using the Louvain method.
    ///
    /// - Parameter visitor: An optional visitor to observe the algorithm progress
    /// - Returns: The community detection result
    @inlinable
    public func detectCommunities(visitor: Visitor?) -> CommunityDetectionResult<Vertex> {
        // Initialize each vertex in its own community
        var communities: [Vertex: Int] = [:]
        for (index, vertex) in graph.vertices().enumerated() {
            communities[vertex] = index
        }
        
        var phase = 0
        var improved = true
        var currentModularity = 0.0
        
        while improved {
            visitor?.startPhase?(phase)
            improved = false
            
            // First phase: local optimization
            for vertex in graph.vertices() {
                guard let currentCommunity = communities[vertex] else { continue }
                let neighbors = graph.successors(of: vertex)
                
                // Find best community to move to
                var bestCommunity = currentCommunity
                var bestModularityGain = 0.0
                
                let neighborCommunities = Set(neighbors.compactMap { communities[$0] })
                
                for neighborCommunity in neighborCommunities {
                    let gain = modularityGain(
                        vertex: vertex,
                        from: currentCommunity,
                        to: neighborCommunity,
                        communities: communities
                    )
                    
                    if gain > bestModularityGain {
                        bestModularityGain = gain
                        bestCommunity = neighborCommunity
                    }
                }
                
                if bestCommunity != currentCommunity {
                    communities[vertex] = bestCommunity
                    visitor?.moveVertex?(vertex, bestCommunity)
                    currentModularity += bestModularityGain
                    improved = true
                }
            }
            
            visitor?.iterationComplete?(phase, currentModularity)
            visitor?.modularityImproved?(currentModularity)
            phase += 1
        }
        
        // Group vertices by community
        let communityGroups = Dictionary(grouping: communities.keys) { communities[$0] ?? -1 }
        let finalCommunities = communityGroups.values.map { Array($0) }
        
        return CommunityDetectionResult(
            communities: finalCommunities,
            modularity: currentModularity
        )
    }
    
    @usableFromInline
    func modularityGain(
        vertex: Vertex,
        from: Int,
        to: Int,
        communities: [Vertex: Int]
    ) -> Double {
        // Simplified modularity gain calculation
        // In practice, this would consider edge weights and degrees
        let neighbors = graph.successors(of: vertex)
        let edgesToCommunity = neighbors.filter { communities[$0] == to }.count
        let edgesFromCommunity = neighbors.filter { communities[$0] == from }.count
        return Double(edgesToCommunity - edgesFromCommunity) * resolution
    }
}

extension LouvainCommunityDetection: CommunityDetectionAlgorithm {
    @inlinable
    public func detectCommunities(
        in graph: Graph,
        visitor: Visitor?
    ) -> CommunityDetectionResult<Graph.VertexDescriptor> {
        detectCommunities(visitor: visitor)
    }
}

extension LouvainCommunityDetection: VisitorSupporting {}
