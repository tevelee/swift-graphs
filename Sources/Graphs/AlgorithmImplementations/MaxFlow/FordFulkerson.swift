import Foundation

struct FordFulkerson<
    Graph: IncidenceGraph & EdgePropertyGraph & BidirectionalGraph & EdgeListGraph & VertexListGraph,
    Flow: AdditiveArithmetic & Comparable & Numeric & FloatingPoint
> where
    Graph.VertexDescriptor: Hashable,
    Graph.EdgeDescriptor: Hashable,
    Flow.Magnitude == Flow
{
    typealias Vertex = Graph.VertexDescriptor
    typealias Edge = Graph.EdgeDescriptor
    
    struct Visitor {
        var examineEdge: ((Edge, Flow) -> Void)?
        var augmentPath: (([Edge], Flow) -> Void)?
        var updateFlow: ((Edge, Flow) -> Void)?
        var findPath: ((Vertex, Vertex) -> Void)?
    }
    
    private let capacityCost: CostDefinition<Graph, Flow>
    
    init(capacityCost: CostDefinition<Graph, Flow>) {
        self.capacityCost = capacityCost
    }
    
    func maximumFlow(
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
        
        // Main Ford-Fulkerson loop
        while let augmentingPath = findAugmentingPath(
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
    
    private func findAugmentingPath(
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
        
        var queue: [Vertex] = [source]
        visited.insert(source)
        
        while !queue.isEmpty {
            let current = queue.removeFirst()
            
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
                    queue.append(destination)
                    visitor?.examineEdge?(edge, residual)
                }
            }
        }
        
        return nil
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
    
    private func findMinimumCut(
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
    
    private struct AugmentingPath {
        let edges: [Edge]
        let bottleneck: Flow
    }
}

extension FordFulkerson: VisitorSupporting {}
