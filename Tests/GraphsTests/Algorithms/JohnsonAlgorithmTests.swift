#if !GRAPHS_USES_TRAITS || GRAPHS_PATHFINDING
@testable import Graphs
import Testing

struct JohnsonAlgorithmTests {
    
    // MARK: - Core Behavior

    @Test func johnsonBasic() {
        var graph = AdjacencyList()
        
        // Create a simple test graph: A -> B -> C
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        
        graph.addEdge(from: a, to: b) { $0.weight = 2 }
        graph.addEdge(from: b, to: c) { $0.weight = 3 }
        
        let result = graph.shortestPathsForAllPairs(using: .johnson(edgeWeight: .property(\.weight)))
        
        // Test some known shortest paths
        #expect(result.distance(from: a, to: c) == 5.0) // A -> B -> C (2 + 3 = 5)
        #expect(result.distance(from: a, to: b) == 2.0) // A -> B
        #expect(result.distance(from: a, to: a) == 0.0) // Self-loop
        #expect(result.distance(from: b, to: c) == 3.0) // B -> C
    }
    
    @Test func johnsonHandlesNegativeWeights() {
        var graph = AdjacencyList()
        
        // Create a graph with negative weights: A -> B -> C with negative edge
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        
        graph.addEdge(from: a, to: b) { $0.weight = 1 }
        graph.addEdge(from: b, to: c) { $0.weight = -2 }
        graph.addEdge(from: a, to: c) { $0.weight = 3 }
        
        let result = graph.shortestPathsForAllPairs(using: .johnson(edgeWeight: .property(\.weight)))
        
        // Test shortest paths with negative weights
        #expect(result.distance(from: a, to: c) == -1.0) // A -> B -> C (1 + (-2) = -1)
        #expect(result.distance(from: a, to: b) == 1.0) // A -> B
        #expect(result.distance(from: b, to: c) == -2.0) // B -> C
    }
    
    @Test func johnsonComplex() {
        var graph = AdjacencyList()
        
        // Create a more complex graph with multiple paths and negative weights
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        
        graph.addEdge(from: a, to: b) { $0.weight = 1 }
        graph.addEdge(from: a, to: c) { $0.weight = 4 }
        graph.addEdge(from: b, to: c) { $0.weight = -2 }
        graph.addEdge(from: b, to: d) { $0.weight = 7 }
        graph.addEdge(from: c, to: d) { $0.weight = 1 }
        
        let result = graph.shortestPathsForAllPairs(using: .johnson(edgeWeight: .property(\.weight)))
        
        // Test shortest paths
        #expect(result.distance(from: a, to: d) == 0.0) // A -> B -> C -> D (1 + (-2) + 1 = 0)
        #expect(result.distance(from: a, to: c) == -1.0) // A -> B -> C (1 + (-2) = -1)
        #expect(result.distance(from: b, to: d) == -1.0) // B -> C -> D (-2 + 1 = -1)
    }
    
    // MARK: - Edge Cases

    @Test func johnsonHandlesUnreachableVertex() {
        var graph = AdjacencyList()
        
        // Create disconnected components
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        
        graph.addEdge(from: a, to: b) { $0.weight = 1 }
        graph.addEdge(from: c, to: d) { $0.weight = 2 }
        // No connection between A-B and C-D components
        
        let result = graph.shortestPathsForAllPairs(using: .johnson(edgeWeight: .property(\.weight)))
        
        // Test unreachable paths
        #expect(result.distance(from: a, to: c) == .infinite)
        #expect(result.distance(from: a, to: d) == .infinite)
        #expect(result.distance(from: b, to: c) == .infinite)
        #expect(result.distance(from: b, to: d) == .infinite)
        
        // Test reachable paths
        #expect(result.distance(from: a, to: b) == 1.0)
        #expect(result.distance(from: c, to: d) == 2.0)
    }
    
    @Test func johnsonHandlesSingleVertex() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        
        let result = graph.shortestPathsForAllPairs(using: .johnson(edgeWeight: .property(\.weight)))
        
        #expect(result.distance(from: a, to: a) == 0.0)
    }
    
    @Test func johnsonHandlesEmptyGraph() {
        let graph = AdjacencyList()
        
        let result = graph.shortestPathsForAllPairs(using: .johnson(edgeWeight: .property(\.weight)))
        
        #expect(result.distances.isEmpty)
    }
    
    @Test func johnsonAllPairsDistances_allBackends() {
        func check<G: TestablePropertyGraph>(_ graph: inout G, _ backend: String)
        where G.VertexProperties == VertexPropertyValues, G.EdgeProperties == EdgePropertyValues,
              G.VertexDescriptor: Hashable {
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            graph.addEdge(from: a, to: b) { $0.weight = 2 }
            graph.addEdge(from: b, to: c) { $0.weight = 3 }
            graph.addEdge(from: a, to: c) { $0.weight = 10 } // longer direct path

            let result = graph.shortestPathsForAllPairs(using: .johnson(edgeWeight: .property(\.weight)))

            #expect(result.distance(from: a, to: b) == 2.0,  "[\(backend)] a→b costs 2")
            #expect(result.distance(from: a, to: c) == 5.0,  "[\(backend)] a→b→c (5) beats a→c (10)")
            #expect(result.distance(from: b, to: c) == 3.0,  "[\(backend)] b→c costs 3")
            #expect(result.distance(from: a, to: a) == 0.0,  "[\(backend)] self-distance is 0")
            #expect(result.distance(from: c, to: a) == .infinite, "[\(backend)] no path c→a")
        }
        var g1 = AdjacencyList();   check(&g1, "default")
        var g4 = AdjacencyMatrix(); check(&g4, "Matrix")
        #if !GRAPHS_USES_TRAITS || GRAPHS_SPECIALIZED_STORAGE
        var g2 = AdjacencyList(edgeStore: CSREdgeStorage().cacheInOutEdges()); check(&g2, "CSR")
        var g3 = AdjacencyList(edgeStore: COOEdgeStorage().cacheInOutEdges()); check(&g3, "COO")
        #endif
    }

    @Test func johnsonDetectsNegativeCycle() {
        var graph = AdjacencyList()
        
        // Create a graph with a negative cycle: A -> B -> C -> A
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        
        graph.addEdge(from: a, to: b) { $0.weight = 1 }
        graph.addEdge(from: b, to: c) { $0.weight = 1 }
        graph.addEdge(from: c, to: a) { $0.weight = -3 } // Creates negative cycle
        
        let result = graph.shortestPathsForAllPairs(using: .johnson(edgeWeight: .property(\.weight)))
        
        // Johnson's algorithm should detect the negative cycle and return empty result
        #expect(result.distances.isEmpty)
    }
}
#endif
