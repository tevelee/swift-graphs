#if !GRAPHS_USES_TRAITS || GRAPHS_OPTIMIZATION
@testable import Graphs
import Testing

struct MaxFlowAlgorithmTests {
    
    // MARK: - Simple Flow Network Tests
    
    @Test func testSimpleFlowNetwork() {
        var graph = AdjacencyList()
        
        // Add vertices
        let s = graph.addVertex { $0.label = "s" }
        let t = graph.addVertex { $0.label = "t" }
        let v1 = graph.addVertex { $0.label = "v1" }
        let v2 = graph.addVertex { $0.label = "v2" }
        
        // Add edges with capacities (using weight property)
        graph.addEdge(from: s, to: v1) { $0.weight = 10.0 }
        graph.addEdge(from: s, to: v2) { $0.weight = 5.0 }
        graph.addEdge(from: v1, to: t) { $0.weight = 8.0 }
        graph.addEdge(from: v2, to: t) { $0.weight = 3.0 }
        graph.addEdge(from: v1, to: v2) { $0.weight = 2.0 }
        
        // Test Ford-Fulkerson
        let fordFulkersonResult = graph.maximumFlow(
            from: s,
            to: t,
            using: .fordFulkerson(capacityCost: .property(\.weight))
        )
        
        #expect(fordFulkersonResult.flowValue == 11.0)
        
        // Test Edmonds-Karp
        let edmondsKarpResult = graph.maximumFlow(
            from: s,
            to: t,
            using: .edmondsKarp(capacityCost: .property(\.weight))
        )
        
        #expect(edmondsKarpResult.flowValue == 11.0)
        
        // Test Dinic
        let dinicResult = graph.maximumFlow(
            from: s,
            to: t,
            using: .dinic(capacityCost: .property(\.weight))
        )
        
        #expect(dinicResult.flowValue == 11.0)
    }
    
    @Test func testComplexFlowNetwork() {
        var graph = AdjacencyList()
        
        // Add vertices
        let s = graph.addVertex { $0.label = "s" }
        let t = graph.addVertex { $0.label = "t" }
        let a = graph.addVertex { $0.label = "a" }
        let b = graph.addVertex { $0.label = "b" }
        let c = graph.addVertex { $0.label = "c" }
        let d = graph.addVertex { $0.label = "d" }
        
        // Add edges with capacities (using weight property)
        graph.addEdge(from: s, to: a) { $0.weight = 10.0 }
        graph.addEdge(from: s, to: b) { $0.weight = 5.0 }
        graph.addEdge(from: a, to: c) { $0.weight = 8.0 }
        graph.addEdge(from: a, to: d) { $0.weight = 2.0 }
        graph.addEdge(from: b, to: d) { $0.weight = 3.0 }
        graph.addEdge(from: c, to: t) { $0.weight = 6.0 }
        graph.addEdge(from: d, to: t) { $0.weight = 4.0 }
        
        // Test Ford-Fulkerson
        let fordFulkersonResult = graph.maximumFlow(
            from: s,
            to: t,
            using: .fordFulkerson(capacityCost: .property(\.weight))
        )
        
        // Expected maximum flow is 10
        #expect(fordFulkersonResult.flowValue == 10.0)
        
        // Test Edmonds-Karp
        let edmondsKarpResult = graph.maximumFlow(
            from: s,
            to: t,
            using: .edmondsKarp(capacityCost: .property(\.weight))
        )
        
        #expect(edmondsKarpResult.flowValue == 10.0)
        
        // Test Dinic
        let dinicResult = graph.maximumFlow(
            from: s,
            to: t,
            using: .dinic(capacityCost: .property(\.weight))
        )
        
        #expect(dinicResult.flowValue == 10.0)
    }
    
    @Test func testMinimumCut() {
        var graph = AdjacencyList()
        
        let s = graph.addVertex { $0.label = "s" }
        let t = graph.addVertex { $0.label = "t" }
        let a = graph.addVertex { $0.label = "a" }
        let b = graph.addVertex { $0.label = "b" }
        
        // Add edges with capacities (using weight property)
        graph.addEdge(from: s, to: a) { $0.weight = 10.0 }
        graph.addEdge(from: s, to: b) { $0.weight = 5.0 }
        graph.addEdge(from: a, to: t) { $0.weight = 8.0 }
        graph.addEdge(from: b, to: t) { $0.weight = 3.0 }
        
        let result = graph.maximumFlow(
            from: s,
            to: t,
            using: .fordFulkerson(capacityCost: .property(\.weight))
        )
        
        // Verify minimum cut
        #expect(result.minCutEdges.count == 2)
        #expect(result.sourceSideVertices.contains(s))
        #expect(result.sourceSideVertices.contains(a))
        #expect(result.sinkSideVertices.contains(t))
        // Note: The actual minimum cut may vary depending on the algorithm implementation
    }
    
    @Test func testNoPathFromSourceToSink() {
        var graph = AdjacencyList()
        
        let s = graph.addVertex { $0.label = "s" }
        let t = graph.addVertex { $0.label = "t" }
        let isolated = graph.addVertex { $0.label = "isolated" }
        
        // Add edge that doesn't connect s to t
        graph.addEdge(from: s, to: isolated) { $0.weight = 10.0 }
        
        let result = graph.maximumFlow(
            from: s,
            to: t,
            using: .fordFulkerson(capacityCost: .property(\.weight))
        )
        
        #expect(result.flowValue == 0.0)
    }
    
    @Test func testSingleEdge() {
        var graph = AdjacencyList()
        
        let s = graph.addVertex { $0.label = "s" }
        let t = graph.addVertex { $0.label = "t" }
        
        graph.addEdge(from: s, to: t) { $0.weight = 5.0 }
        
        let result = graph.maximumFlow(
            from: s,
            to: t,
            using: .fordFulkerson(capacityCost: .property(\.weight))
        )
        
        #expect(result.flowValue == 5.0)
    }
    
    @Test func testZeroCapacityEdges() {
        var graph = AdjacencyList()
        
        let s = graph.addVertex { $0.label = "s" }
        let t = graph.addVertex { $0.label = "t" }
        
        graph.addEdge(from: s, to: t) { $0.weight = 0.0 }
        
        let result = graph.maximumFlow(
            from: s,
            to: t,
            using: .fordFulkerson(capacityCost: .property(\.weight))
        )
        
        #expect(result.flowValue == 0.0)
    }
    
    @Test func testPerformance() {
        let graph = createLargeFlowNetwork()
        
        // Test performance with Dinic (most efficient)
        let vertices = Array(graph.vertices())
        let result = graph.maximumFlow(
            from: vertices.first!,
            to: vertices.last!,
            using: .dinic(capacityCost: .property(\.weight))
        )
        #expect(result.flowValue > 0.0)
    }
    
    // MARK: - Helper Methods
    
    private func verifyFlowConservation<G: AdjacencyListProtocol>(
        graph: G,
        result: MaxFlowResult<G.VertexDescriptor, G.EdgeDescriptor, Double>,
        source: G.VertexDescriptor,
        sink: G.VertexDescriptor
    ) {
        // Check flow conservation at each vertex (except source and sink)
        for vertex in graph.vertices() {
            if vertex == source || vertex == sink { continue }
            
            var incomingFlow: Double = 0.0
            var outgoingFlow: Double = 0.0
            
            // Calculate incoming flow
            for edge in graph.incomingEdges(of: vertex) {
                incomingFlow += result.flow(through: edge)
            }
            
            // Calculate outgoing flow
            for edge in graph.outgoingEdges(of: vertex) {
                outgoingFlow += result.flow(through: edge)
            }
            
            #expect(incomingFlow == outgoingFlow)
        }
    }
    
    private func createLargeFlowNetwork() -> DefaultAdjacencyList {
        var graph = DefaultAdjacencyList()
        
        let s = graph.addVertex { $0.label = "s" }
        let t = graph.addVertex { $0.label = "t" }
        
        // Create a grid-like flow network
        let size = 10
        var vertices: [[DefaultAdjacencyList.VertexDescriptor]] = []
        
        for i in 0..<size {
            var row: [DefaultAdjacencyList.VertexDescriptor] = []
            for j in 0..<size {
                let vertex = graph.addVertex { $0.label = "v\(i)_\(j)" }
                row.append(vertex)
            }
            vertices.append(row)
        }
        
        // Connect source to first row
        for j in 0..<size {
            graph.addEdge(from: s, to: vertices[0][j]) { $0.weight = Double.random(in: 1...10) }
        }
        
        // Connect last row to sink
        for j in 0..<size {
            graph.addEdge(from: vertices[size-1][j], to: t) { $0.weight = Double.random(in: 1...10) }
        }
        
        // Connect grid vertices
        for i in 0..<size-1 {
            for j in 0..<size {
                // Downward edges
                graph.addEdge(from: vertices[i][j], to: vertices[i+1][j]) { $0.weight = Double.random(in: 1...5) }
                
                // Rightward edges (if not last column)
                if j < size - 1 {
                    graph.addEdge(from: vertices[i][j], to: vertices[i][j+1]) { $0.weight = Double.random(in: 1...5) }
                }
            }
        }
        
        return graph
    }
}
#endif
