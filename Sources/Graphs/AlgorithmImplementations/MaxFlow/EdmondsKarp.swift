/// Edmonds-Karp algorithm for computing maximum flow.
///
/// This algorithm finds the maximum flow in a flow network by using BFS to find
/// shortest augmenting paths, which guarantees polynomial time complexity.
///
/// - Complexity: O(V * E^2) where V is the number of vertices and E is the number of edges
public struct EdmondsKarp<
    Graph: IncidenceGraph & BidirectionalGraph & EdgeListGraph & VertexListGraph,
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
    
    /// A visitor that can be used to observe Edmonds-Karp algorithm progress.
    public struct Visitor {
        /// Called when examining an edge.
        public var examineEdge: ((Edge, Flow) -> Void)?
        /// Called when augmenting a path.
        public var augmentPath: (([Edge], Flow) -> Void)?
        /// Called when updating flow on an edge.
        public var updateFlow: ((Edge, Flow) -> Void)?
        /// Called when finding a path.
        public var findPath: ((Vertex, Vertex) -> Void)?
        /// Called when assigning a level to a vertex.
        public var levelAssigned: ((Vertex, Int) -> Void)?
        
        /// Creates a new visitor.
        @inlinable
        public init(
            examineEdge: ((Edge, Flow) -> Void)? = nil,
            augmentPath: (([Edge], Flow) -> Void)? = nil,
            updateFlow: ((Edge, Flow) -> Void)? = nil,
            findPath: ((Vertex, Vertex) -> Void)? = nil,
            levelAssigned: ((Vertex, Int) -> Void)? = nil
        ) {
            self.examineEdge = examineEdge
            self.augmentPath = augmentPath
            self.updateFlow = updateFlow
            self.findPath = findPath
            self.levelAssigned = levelAssigned
        }
    }
    
    /// The capacity cost definition for edge capacities.
    @usableFromInline
    let capacityCost: CostDefinition<Graph, Flow>
    
    /// Creates a new Edmonds-Karp algorithm.
    ///
    /// - Parameter capacityCost: The capacity cost definition for edge capacities.
    @inlinable
    public init(capacityCost: CostDefinition<Graph, Flow>) {
        self.capacityCost = capacityCost
    }
    
    /// Computes the maximum flow using Edmonds-Karp algorithm.
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
        
        // Main Edmonds-Karp loop using BFS
        while let augmentingPath = findAugmentingPathBFS(
            from: source,
            to: sink,
            in: graph,
            residualCapacities: residualCapacities,
            visitor: visitor
        ) {
            let pathFlow = augmentingPath.bottleneck
            totalFlow = totalFlow + pathFlow
            
            visitor?.augmentPath?(augmentingPath.edges, pathFlow)
            
            // Update flows and residual capacities along the path
            for edge in augmentingPath.edges {
                let currentFlow = edgeFlows[edge] ?? .zero
                let newFlow = currentFlow + pathFlow
                edgeFlows[edge] = newFlow
                
                // Update residual capacity (forward edge)
                let currentResidual = residualCapacities[edge] ?? .zero
                residualCapacities[edge] = currentResidual - pathFlow
                
                // Update residual capacity (backward edge)
                if let reverseEdge = findReverseEdge(edge, in: graph) {
                    let reverseResidual = residualCapacities[reverseEdge] ?? .zero
                    residualCapacities[reverseEdge] = reverseResidual + pathFlow
                }
                
                visitor?.updateFlow?(edge, newFlow)
            }
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
    func findAugmentingPathBFS(
        from source: Vertex,
        to sink: Vertex,
        in graph: Graph,
        residualCapacities: [Edge: Flow],
        visitor: Visitor?
    ) -> AugmentingPath? {
        visitor?.findPath?(source, sink)
        
        var visited: Set<Vertex> = []
        var parent: [Vertex: Vertex] = [:]
        var parentEdge: [Vertex: Edge] = [:]
        var level: [Vertex: Int] = [:]
        
        var queue: [Vertex] = [source]
        visited.insert(source)
        level[source] = 0
        
        while !queue.isEmpty {
            let current = queue.removeFirst()
            let currentLevel = level[current] ?? 0
            
            if current == sink {
                // Reconstruct path
                var path: [Edge] = []
                var bottleneck: Flow = Flow.greatestFiniteMagnitude
                var vertex = sink
                
                while let parentVertex = parent[vertex], let edge = parentEdge[vertex] {
                    path.append(edge)
                    let residual = residualCapacities[edge] ?? .zero
                    if residual < bottleneck {
                        bottleneck = residual
                    }
                    vertex = parentVertex
                }
                
                path.reverse()
                return AugmentingPath(edges: path, bottleneck: bottleneck)
            }
            
            // Check outgoing edges
            for edge in graph.outgoingEdges(of: current) {
                guard let destination = graph.destination(of: edge) else { continue }
                let residual = residualCapacities[edge] ?? .zero
                
                if !visited.contains(destination) && residual > .zero {
                    visited.insert(destination)
                    parent[destination] = current
                    parentEdge[destination] = edge
                    level[destination] = currentLevel + 1
                    queue.append(destination)
                    visitor?.examineEdge?(edge, residual)
                    visitor?.levelAssigned?(destination, currentLevel + 1)
                }
            }
        }
        
        return nil
    }
    
    @usableFromInline
    func findReverseEdge(_ edge: Edge, in graph: Graph) -> Edge? {
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
    
    @usableFromInline
    struct AugmentingPath {
        @usableFromInline
        let edges: [Edge]
        @usableFromInline
        let bottleneck: Flow
    }
}

extension EdmondsKarp: VisitorSupporting {}
