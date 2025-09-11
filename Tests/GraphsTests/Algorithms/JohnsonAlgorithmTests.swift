@testable import Graphs
import Testing

struct JohnsonAlgorithmTests {
    
    @Test func testJohnsonBasic() {
        var graph = AdjacencyList()
        
        // Create a simple test graph: A -> B -> C
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        
        graph.addEdge(from: a, to: b) { $0.weight = 2 }
        graph.addEdge(from: b, to: c) { $0.weight = 3 }
        
        let result = graph.shortestPathsForAllPairs(using: .johnson(on: graph, edgeWeight: .property(\.weight)))
        
        // Test some known shortest paths
        #expect(result.distance(from: a, to: c) == 5.0) // A -> B -> C (2 + 3 = 5)
        #expect(result.distance(from: a, to: b) == 2.0) // A -> B
        #expect(result.distance(from: a, to: a) == 0.0) // Self-loop
        #expect(result.distance(from: b, to: c) == 3.0) // B -> C
    }
    
    @Test func testJohnsonWithNegativeWeights() {
        var graph = AdjacencyList()
        
        // Create a graph with negative weights: A -> B -> C with negative edge
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        
        graph.addEdge(from: a, to: b) { $0.weight = 1 }
        graph.addEdge(from: b, to: c) { $0.weight = -2 }
        graph.addEdge(from: a, to: c) { $0.weight = 3 }
        
        let result = graph.shortestPathsForAllPairs(using: .johnson(on: graph, edgeWeight: .property(\.weight)))
        
        // Test shortest paths with negative weights
        #expect(result.distance(from: a, to: c) == -1.0) // A -> B -> C (1 + (-2) = -1)
        #expect(result.distance(from: a, to: b) == 1.0) // A -> B
        #expect(result.distance(from: b, to: c) == -2.0) // B -> C
    }
    
    @Test func testJohnsonComplex() {
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
        
        let result = graph.shortestPathsForAllPairs(using: .johnson(on: graph, edgeWeight: .property(\.weight)))
        
        // Test shortest paths
        #expect(result.distance(from: a, to: d) == 0.0) // A -> B -> C -> D (1 + (-2) + 1 = 0)
        #expect(result.distance(from: a, to: c) == -1.0) // A -> B -> C (1 + (-2) = -1)
        #expect(result.distance(from: b, to: d) == -1.0) // B -> C -> D (-2 + 1 = -1)
    }
    
    @Test func testJohnsonUnreachable() {
        var graph = AdjacencyList()
        
        // Create disconnected components
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        
        graph.addEdge(from: a, to: b) { $0.weight = 1 }
        graph.addEdge(from: c, to: d) { $0.weight = 2 }
        // No connection between A-B and C-D components
        
        let result = graph.shortestPathsForAllPairs(using: .johnson(on: graph, edgeWeight: .property(\.weight)))
        
        // Test unreachable paths
        #expect(result.distance(from: a, to: c) == .infinite)
        #expect(result.distance(from: a, to: d) == .infinite)
        #expect(result.distance(from: b, to: c) == .infinite)
        #expect(result.distance(from: b, to: d) == .infinite)
        
        // Test reachable paths
        #expect(result.distance(from: a, to: b) == 1.0)
        #expect(result.distance(from: c, to: d) == 2.0)
    }
    
    @Test func testJohnsonSingleVertex() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        
        let result = graph.shortestPathsForAllPairs(using: .johnson(on: graph, edgeWeight: .property(\.weight)))
        
        #expect(result.distance(from: a, to: a) == 0.0)
    }
    
    @Test func testJohnsonEmptyGraph() {
        let graph = AdjacencyList()
        
        let result = graph.shortestPathsForAllPairs(using: .johnson(on: graph, edgeWeight: .property(\.weight)))
        
        #expect(result.distances.isEmpty)
    }
    
    @Test func testJohnsonNegativeCycle() {
        var graph = AdjacencyList()
        
        // Create a graph with a negative cycle: A -> B -> C -> A
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        
        graph.addEdge(from: a, to: b) { $0.weight = 1 }
        graph.addEdge(from: b, to: c) { $0.weight = 1 }
        graph.addEdge(from: c, to: a) { $0.weight = -3 } // Creates negative cycle
        
        let result = graph.shortestPathsForAllPairs(using: .johnson(on: graph, edgeWeight: .property(\.weight)))
        
        // Johnson's algorithm should detect the negative cycle and return empty result
        #expect(result.distances.isEmpty)
    }
}
