@testable import Graphs
import Testing

struct ShortestPathsFromSourceTests {
    
    @Test func testDijkstraAllPathsBasic() {
        var graph = AdjacencyList()
        
        // Create a simple test graph: A -> B -> C
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        
        graph.addEdge(from: a, to: b) { $0.weight = 2 }
        graph.addEdge(from: b, to: c) { $0.weight = 3 }
        
        let result = graph.shortestPathsFromSource(a, using: .dijkstra(weight: .property(\.weight)))
        
        // Test distances
        #expect(result.distance(to: c) == 5.0)
        #expect(result.distance(to: b) == 2.0)
        #expect(result.distance(to: a) == 0.0)
    }
    
    @Test func testDijkstraAllPathsComplex() {
        var graph = AdjacencyList()
        
        // Create a more complex graph
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        let e = graph.addVertex { $0.label = "E" }
        
        graph.addEdge(from: a, to: b) { $0.weight = 4 }
        graph.addEdge(from: a, to: c) { $0.weight = 2 }
        graph.addEdge(from: b, to: c) { $0.weight = 1 }
        graph.addEdge(from: b, to: d) { $0.weight = 5 }
        graph.addEdge(from: c, to: d) { $0.weight = 8 }
        graph.addEdge(from: c, to: e) { $0.weight = 10 }
        graph.addEdge(from: d, to: e) { $0.weight = 2 }
        
        let result = graph.shortestPathsFromSource(a, using: .dijkstra(weight: .property(\.weight)))
        
        // Test shortest paths from A
        #expect(result.distance(to: a) == 0.0)
        #expect(result.distance(to: c) == 2.0) // A -> C
        #expect(result.distance(to: b) == 4.0) // A -> B (direct)
        #expect(result.distance(to: d) == 9.0) // A -> B -> D
        #expect(result.distance(to: e) == 11.0) // A -> B -> D -> E
    }
    
    @Test func testDijkstraAllPathsUnreachable() {
        var graph = AdjacencyList()
        
        // Create disconnected components
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        
        graph.addEdge(from: a, to: b) { $0.weight = 1 }
        graph.addEdge(from: c, to: d) { $0.weight = 2 }
        // No connection between A-B and C-D components
        
        let result = graph.shortestPathsFromSource(a, using: .dijkstra(weight: .property(\.weight)))
        
        // Test unreachable vertices
        #expect(result.distance(to: c) == nil)
        #expect(result.distance(to: d) == nil)
        #expect(result.hasPath(to: c) == false)
        #expect(result.hasPath(to: d) == false)
        
        // Test reachable vertices
        #expect(result.distance(to: a) == 0.0)
        #expect(result.distance(to: b) == 1.0)
        #expect(result.hasPath(to: a) == true)
        #expect(result.hasPath(to: b) == true)
    }
    
    
    @Test func testBellmanFordBasic() {
        var graph = AdjacencyList()
        
        // Create a graph with negative weights
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        
        graph.addEdge(from: a, to: b) { $0.weight = 2 }
        graph.addEdge(from: b, to: c) { $0.weight = -1 }
        
        let result = graph.shortestPathsFromSource(a, using: .bellmanFord(weight: .property(\.weight)))
        
        // Test that negative weights are handled correctly
        #expect(result.distance(to: c) == 1.0) // A -> B -> C (2 + (-1) = 1)
        #expect(result.distance(to: b) == 2.0) // A -> B
        #expect(result.distance(to: a) == 0.0) // A -> A
    }
    
    @Test func testBellmanFordNegativeCycle() {
        var graph = AdjacencyList()
        
        // Create a graph with a negative cycle
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        
        graph.addEdge(from: a, to: b) { $0.weight = 1 }
        graph.addEdge(from: b, to: c) { $0.weight = 1 }
        graph.addEdge(from: c, to: a) { $0.weight = -3 } // Negative cycle
        
        let result = graph.shortestPathsFromSource(a, using: .bellmanFord(weight: .property(\.weight)))
        
        // With negative cycle, distances should be undefined
        // The algorithm should still return some result, but it may not be optimal
        #expect(result.distance(to: a) == -2.0) // Source distance may be affected by negative cycle
    }
    
    @Test func testBellmanFordComplex() {
        var graph = AdjacencyList()
        
        // Create a more complex graph with mixed positive and negative weights
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        
        graph.addEdge(from: a, to: b) { $0.weight = 4 }
        graph.addEdge(from: a, to: c) { $0.weight = 5 }
        graph.addEdge(from: b, to: c) { $0.weight = -2 }
        graph.addEdge(from: b, to: d) { $0.weight = 1 }
        graph.addEdge(from: c, to: d) { $0.weight = 3 }
        
        let result = graph.shortestPathsFromSource(a, using: .bellmanFord(weight: .property(\.weight)))
        
        // Test shortest paths considering negative weights
        #expect(result.distance(to: a) == 0.0)
        #expect(result.distance(to: b) == 4.0) // A -> B
        #expect(result.distance(to: c) == 2.0) // A -> B -> C (4 + (-2) = 2)
        #expect(result.distance(to: d) == 5.0) // A -> B -> C -> D (4 + (-2) + 3 = 5)
    }
    
    @Test func testSingleVertex() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        
        let result = graph.shortestPathsFromSource(a, using: .dijkstra(weight: .property(\.weight)))
        
        #expect(result.distance(to: a) == 0.0)
        #expect(result.hasPath(to: a) == true)
    }
}
