@testable import Graphs
import Testing

struct ShortestPathAlgorithmsTests {
    
    @Test func testFloydWarshall() {
        var graph = AdjacencyList()
        
        // Create a simple test graph: A -> B -> C
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        
        _ = graph.addEdge(from: a, to: b) { $0.weight = 2 }
        _ = graph.addEdge(from: b, to: c) { $0.weight = 3 }
        
        let floydWarshall = FloydWarshall(on: graph, edgeWeight: .property(\.weight))
        let result = floydWarshall.shortestPathsForAllPairs()
        
        // Test some known shortest paths
        #expect(result.distance(from: a, to: c) == 5.0) // A -> B -> C (2 + 3 = 5)
        #expect(result.distance(from: a, to: b) == 2.0) // A -> B
        #expect(result.distance(from: a, to: a) == 0.0) // Self-loop
    }
    
    @Test func testDijkstraAllPaths() {
        var graph = AdjacencyList()
        
        // Create a simple test graph: A -> B -> C
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        
        _ = graph.addEdge(from: a, to: b) { $0.weight = 2 }
        _ = graph.addEdge(from: b, to: c) { $0.weight = 3 }
        
        let dijkstra = DijkstraAllPaths(on: graph, edgeWeight: .property(\.weight))
        let result = dijkstra.shortestPathsFromSource(a)
        
        // Test distances
        #expect(result.distance(to: c) == 5.0)
        #expect(result.distance(to: b) == 2.0)
        #expect(result.distance(to: a) == 0.0)
    }
    
    @Test func testKShortestPaths() throws {
        var graph = AdjacencyList()
        
        // Create a simple test graph: A -> B -> C
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        
        _ = graph.addEdge(from: a, to: b) { $0.weight = 2 }
        _ = graph.addEdge(from: b, to: c) { $0.weight = 3 }
        
        let yen = Yen(on: graph, edgeWeight: .property(\.weight))
        let paths = yen.kShortestPaths(from: a, to: c, k: 3)
        
        #expect(paths.count >= 1)
        #expect(paths.count <= 3)
        
        // First path should be the shortest
        let firstPath = try #require(paths.first)
        #expect(firstPath.vertices.count == 3)
    }
    
    @Test func testBellmanFord() {
        var graph = AdjacencyList()
        
        // Create a graph with negative weights: A -> B -> C
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        
        _ = graph.addEdge(from: a, to: b) { $0.weight = 2 }
        _ = graph.addEdge(from: b, to: c) { $0.weight = -1 }
        
        let bellmanFord = BellmanFord(on: graph, edgeWeight: .property(\.weight))
        let result = bellmanFord.shortestPathsFromSource(a)
        
        // Test that negative weights are handled correctly
        #expect(result.distances[c] == .finite(1.0)) // A -> B -> C (2 + (-1) = 1)
    }
    
    @Test func testBidirectionalDijkstra() {
        var graph = AdjacencyList()
        
        // Create a simple test graph: A -> B -> C
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        
        _ = graph.addEdge(from: a, to: b) { $0.weight = 2 }
        _ = graph.addEdge(from: b, to: c) { $0.weight = 3 }
        
        let bidirectionalDijkstra = BidirectionalDijkstra(on: graph, edgeWeight: .property(\.weight))
        let result = bidirectionalDijkstra.shortestPath(from: a, to: c)
        
        #expect(result.path != nil)
        #expect(result.path?.vertices.count == 1)
    }
    
    @Test func testNoPathExists() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        // No edges between A and B
        
        let dijkstra = DijkstraAllPaths(on: graph, edgeWeight: .property(\.weight))
        let result = dijkstra.shortestPathsFromSource(a)
        
        #expect(result.distance(to: b) == nil)
        #expect(result.hasPath(to: b) == false)
    }
    
    @Test func testSingleVertex() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        
        let dijkstra = DijkstraAllPaths(on: graph, edgeWeight: .property(\.weight))
        let result = dijkstra.shortestPathsFromSource(a)
        
        #expect(result.distance(to: a) == 0.0)
        #expect(result.hasPath(to: a) == true)
    }
}
