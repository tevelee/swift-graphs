import Foundation

/// Dinic's algorithm for computing maximum flow.
///
/// This algorithm finds the maximum flow in a flow network by building level graphs
/// and finding blocking flows, which provides better time complexity than Edmonds-Karp.
///
/// - Complexity: O(V^2 * E) where V is the number of vertices and E is the number of edges
public struct Dinic<
    Graph: IncidenceGraph & EdgePropertyGraph & BidirectionalGraph & EdgeListGraph & VertexListGraph,
    Flow: AdditiveArithmetic & Comparable & Numeric & FloatingPoint
> where
    Graph.VertexDescriptor: Hashable,
    Graph.EdgeDescriptor: Hashable,
    Flow.Magnitude == Flow
{
    /// The vertex type of the graph.
    public typealias Vertex = Graph.VertexDescriptor
    /// The edge type of the graph.
    public typealias Edge = Graph.EdgeDescriptor
    
    /// A visitor that can be used to observe Dinic's algorithm progress.
    public struct Visitor {
        /// Called when examining an edge.
        public var examineEdge: ((Edge, Flow) -> Void)?
        /// Called when augmenting a path.
        public var augmentPath: (([Edge], Flow) -> Void)?
        /// Called when updating flow on an edge.
        public var updateFlow: ((Edge, Flow) -> Void)?
        /// Called when building the level graph.
        public var buildLevelGraph: (() -> Void)?
        /// Called when finding a blocking flow.
        public var findBlockingFlow: (() -> Void)?
        /// Called when assigning a level to a vertex.
        public var levelAssigned: ((Vertex, Int) -> Void)?
        /// Called when an edge is blocked.
        public var edgeBlocked: ((Edge) -> Void)?
        
        /// Creates a new visitor.
        @inlinable
        public init(
            examineEdge: ((Edge, Flow) -> Void)? = nil,
            augmentPath: (([Edge], Flow) -> Void)? = nil,
            updateFlow: ((Edge, Flow) -> Void)? = nil,
            buildLevelGraph: (() -> Void)? = nil,
            findBlockingFlow: (() -> Void)? = nil,
            levelAssigned: ((Vertex, Int) -> Void)? = nil,
            edgeBlocked: ((Edge) -> Void)? = nil
        ) {
            self.examineEdge = examineEdge
            self.augmentPath = augmentPath
            self.updateFlow = updateFlow
            self.buildLevelGraph = buildLevelGraph
            self.findBlockingFlow = findBlockingFlow
            self.levelAssigned = levelAssigned
            self.edgeBlocked = edgeBlocked
        }
    }
    
    /// The capacity cost definition for edge capacities.
    @usableFromInline
    let capacityCost: CostDefinition<Graph, Flow>
    
    /// Creates a new Dinic's algorithm.
    ///
    /// - Parameter capacityCost: The capacity cost definition for edge capacities.
    @inlinable
    public init(capacityCost: CostDefinition<Graph, Flow>) {
        self.capacityCost = capacityCost
    }
    
    /// Computes the maximum flow using Dinic's algorithm.
    ///
    /// - Parameters:
    ///   - source: The source vertex
    ///   - sink: The sink vertex
    ///   - graph: The flow network graph
    ///   - visitor: An optional visitor to observe the algorithm progress
    /// - Returns: The maximum flow result
    @inlinable
    public func maximumFlow(
        from source: Vertex,
        to sink: Vertex,
        in graph: Graph,
        visitor: Visitor? = nil
    ) -> MaxFlowResult<Vertex, Edge, Flow> {
        // Initialize flow and residual capacity maps
        var edgeFlows: [Edge: Flow] = [:]
        var residualCapacities: [Edge: Flow] = [:]
        
        // Initialize all flows to zero and residual capacities to edge capacities
        for edge in graph.edges() {
            let capacity = capacityCost.costToExplore(edge, graph)
            edgeFlows[edge] = .zero
            residualCapacities[edge] = capacity
        }
        
        var totalFlow: Flow = .zero
        
        // Main Dinic's algorithm loop
        while true {
            // Build level graph using BFS
            guard let levelGraph = buildLevelGraph(
                from: source,
                to: sink,
                in: graph,
                residualCapacities: residualCapacities,
                visitor: visitor
            ) else {
                break // No more augmenting paths
            }
            
            // Find blocking flow in level graph
            let blockingFlow = findBlockingFlow(
                from: source,
                to: sink,
                in: graph,
                levelGraph: levelGraph,
                residualCapacities: &residualCapacities,
                visitor: visitor
            )
            
            if blockingFlow == .zero {
                break // No more flow can be pushed
            }
            
            totalFlow = totalFlow + blockingFlow
            
            // Update flows along the paths found in blocking flow
            updateFlows(
                in: graph,
                edgeFlows: &edgeFlows,
                residualCapacities: residualCapacities,
                visitor: visitor
            )
        }
        
        // Find minimum cut
        let (minCutEdges, sourceSide, sinkSide) = findMinimumCut(
            from: source,
            to: sink,
            in: graph,
            residualCapacities: residualCapacities
        )
        
        return MaxFlowResult(
            flowValue: totalFlow,
            edgeFlows: edgeFlows,
            residualCapacities: residualCapacities,
            minCutEdges: minCutEdges,
            sourceSideVertices: sourceSide,
            sinkSideVertices: sinkSide
        )
    }
    
    @usableFromInline
    func buildLevelGraph(
        from source: Vertex,
        to sink: Vertex,
        in graph: Graph,
        residualCapacities: [Edge: Flow],
        visitor: Visitor?
    ) -> [Vertex: Int]? {
        visitor?.buildLevelGraph?()
        
        var level: [Vertex: Int] = [:]
        var queue: [Vertex] = [source]
        level[source] = 0
        
        while !queue.isEmpty {
            let current = queue.removeFirst()
            let currentLevel = level[current] ?? 0
            
            if current == sink {
                return level
            }
            
            for edge in graph.outgoingEdges(of: current) {
                guard let destination = graph.destination(of: edge) else { continue }
                let residual = residualCapacities[edge] ?? .zero
                
                if level[destination] == nil && residual > .zero {
                    level[destination] = currentLevel + 1
                    queue.append(destination)
                    visitor?.levelAssigned?(destination, currentLevel + 1)
                }
            }
        }
        
        return nil // No path to sink
    }
    
    @usableFromInline
    func findBlockingFlow(
        from source: Vertex,
        to sink: Vertex,
        in graph: Graph,
        levelGraph: [Vertex: Int],
        residualCapacities: inout [Edge: Flow],
        visitor: Visitor?
    ) -> Flow {
        visitor?.findBlockingFlow?()
        
        var totalFlow: Flow = .zero
        var current: [Vertex: Int] = [:]
        
        // Initialize current edge pointer for each vertex
        for vertex in graph.vertices() {
            current[vertex] = 0
        }
        
        // DFS to find blocking flow
        func dfs(_ vertex: Vertex, _ flow: Flow) -> Flow {
            if vertex == sink {
                return flow
            }
            
            let vertexLevel = levelGraph[vertex] ?? Int.max
            let outgoingEdges = Array(graph.outgoingEdges(of: vertex))
            
            for i in (current[vertex] ?? 0)..<outgoingEdges.count {
                let edge = outgoingEdges[i]
                guard let destination = graph.destination(of: edge) else { continue }
                
                let destinationLevel = levelGraph[destination] ?? Int.max
                let residual = residualCapacities[edge] ?? .zero
                
                if destinationLevel == vertexLevel + 1 && residual > .zero {
                    let pushedFlow = dfs(destination, min(flow, residual))
                    
                    if pushedFlow > .zero {
                        residualCapacities[edge] = residual - pushedFlow
                        
                        // Update backward edge
                        if let reverseEdge = findReverseEdge(edge, in: graph) {
                            let reverseResidual = residualCapacities[reverseEdge] ?? .zero
                            residualCapacities[reverseEdge] = reverseResidual + pushedFlow
                        }
                        
                        visitor?.updateFlow?(edge, pushedFlow)
                        return pushedFlow
                    }
                }
            }
            
            return .zero
        }
        
        while true {
            let flow = dfs(source, Flow.greatestFiniteMagnitude)
            if flow == .zero {
                break
            }
            totalFlow = totalFlow + flow
        }
        
        return totalFlow
    }
    
    @usableFromInline
    func updateFlows(
        in graph: Graph,
        edgeFlows: inout [Edge: Flow],
        residualCapacities: [Edge: Flow],
        visitor: Visitor?
    ) {
        // Update flows based on residual capacity changes
        for edge in graph.edges() {
            let originalCapacity = capacityCost.costToExplore(edge, graph)
            let currentResidual = residualCapacities[edge] ?? .zero
            let flow = originalCapacity - currentResidual
            edgeFlows[edge] = flow
        }
    }
    
    private func findReverseEdge(_ edge: Edge, in graph: Graph) -> Edge? {
        guard let source = graph.source(of: edge),
              let destination = graph.destination(of: edge) else { return nil }
        
        // Look for the reverse edge
        for reverseEdge in graph.outgoingEdges(of: destination) {
            if graph.destination(of: reverseEdge) == source {
                return reverseEdge
            }
        }
        
        return nil
    }
    
    @usableFromInline
    func findMinimumCut(
        from source: Vertex,
        to sink: Vertex,
        in graph: Graph,
        residualCapacities: [Edge: Flow]
    ) -> ([Edge], Set<Vertex>, Set<Vertex>) {
        var visited: Set<Vertex> = []
        var queue: [Vertex] = [source]
        visited.insert(source)
        
        // BFS to find reachable vertices from source
        while !queue.isEmpty {
            let current = queue.removeFirst()
            
            for edge in graph.outgoingEdges(of: current) {
                guard let destination = graph.destination(of: edge) else { continue }
                let residual = residualCapacities[edge] ?? .zero
                
                if !visited.contains(destination) && residual > .zero {
                    visited.insert(destination)
                    queue.append(destination)
                }
            }
        }
        
        // Find edges that cross the cut
        var minCutEdges: [Edge] = []
        for edge in graph.edges() {
            guard let sourceVertex = graph.source(of: edge),
                  let destinationVertex = graph.destination(of: edge) else { continue }
            
            if visited.contains(sourceVertex) && !visited.contains(destinationVertex) {
                minCutEdges.append(edge)
            }
        }
        
        let sourceSide = visited
        let sinkSide = Set(graph.vertices().filter { !visited.contains($0) })
        
        return (minCutEdges, sourceSide, sinkSide)
    }
}

extension Dinic: VisitorSupporting {}
