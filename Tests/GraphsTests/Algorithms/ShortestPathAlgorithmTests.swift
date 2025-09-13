@testable import Graphs
import Testing

struct ShortestPathAlgorithmsTests {
    
    func createLinearGraph() -> some AdjacencyListProtocol {
        var graph = AdjacencyList()
        
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        
        graph.addEdge(from: a, to: b) { $0.weight = 2 }
        graph.addEdge(from: b, to: c) { $0.weight = 3 }
        
        return graph
    }
    
    func createNegativeWeightGraph() -> some AdjacencyListProtocol {
        var graph = AdjacencyList()
        
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        
        graph.addEdge(from: a, to: b) { $0.weight = 2 }
        graph.addEdge(from: b, to: c) { $0.weight = -1 }
        
        return graph
    }
    
    func createDisconnectedGraph() -> some AdjacencyListProtocol {
        var graph = AdjacencyList()
        
        graph.addVertex { $0.label = "A" }
        graph.addVertex { $0.label = "B" }
        // No edges between A and B
        
        return graph
    }
    
    func createSingleVertexGraph() -> some AdjacencyListProtocol {
        var graph = AdjacencyList()
        
        graph.addVertex { $0.label = "A" }
        
        return graph
    }
    
    @Test func testFloydWarshall() {
        let graph = createLinearGraph()
        
        let a = graph.findVertex(labeled: "A")!
        let b = graph.findVertex(labeled: "B")!
        let c = graph.findVertex(labeled: "C")!
        
        let floydWarshall = FloydWarshall(on: graph, edgeWeight: .property(\.weight))
        let result = floydWarshall.shortestPathsForAllPairs()
        
        #expect(result.distance(from: a, to: c) == 5.0) // A -> B -> C (2 + 3 = 5)
        #expect(result.distance(from: a, to: b) == 2.0) // A -> B
        #expect(result.distance(from: a, to: a) == 0.0) // Self-loop
    }
    
    @Test func testDijkstraAllPaths() {
        let graph = createLinearGraph()
        
        let a = graph.findVertex(labeled: "A")!
        let b = graph.findVertex(labeled: "B")!
        let c = graph.findVertex(labeled: "C")!
        
        let dijkstra = Dijkstra(on: graph, from: a, edgeWeight: .property(\.weight))
        let result = dijkstra.reduce(into: nil) { $0 = $1 }!
        
        // Extract distances from property map
        let distanceToC = result.propertyMap[c][result.distanceProperty]
        let distanceToB = result.propertyMap[b][result.distanceProperty]
        let distanceToA = result.propertyMap[a][result.distanceProperty]
        
        #expect(distanceToC == .finite(5.0))
        #expect(distanceToB == .finite(2.0))
        #expect(distanceToA == .finite(0.0))
    }
    
    @Test func testKShortestPaths() throws {
        let graph = createLinearGraph()
        
        let a = graph.findVertex(labeled: "A")!
        let c = graph.findVertex(labeled: "C")!
        
        let paths = graph.kShortestPaths(from: a, to: c, k: 3, using: .yen(weight: .property(\.weight)))
        
        #expect(paths.count >= 1)
        #expect(paths.count <= 3)
        
        let firstPath = try #require(paths.first)
        #expect(firstPath.vertices.count == 3)
    }
    
    @Test func testBellmanFord() {
        let graph = createNegativeWeightGraph()
        
        let a = graph.findVertex(labeled: "A")!
        let c = graph.findVertex(labeled: "C")!
        
        let bellmanFord = BellmanFord(on: graph, edgeWeight: .property(\.weight))
        let result = bellmanFord.shortestPathsFromSource(a)
        
        #expect(result.distances[c] == .finite(1.0)) // A -> B -> C (2 + (-1) = 1)
    }
    
    @Test func testBidirectionalDijkstra() {
        let graph = createLinearGraph()
        
        let a = graph.findVertex(labeled: "A")!
        let c = graph.findVertex(labeled: "C")!
        
        let bidirectionalDijkstra = BidirectionalDijkstra(on: graph, edgeWeight: .property(\.weight))
        let result = bidirectionalDijkstra.shortestPath(from: a, to: c)
        
        #expect(result.path != nil)
        #expect(result.path?.vertices.count == 1)
    }
    
    @Test func testNoPathExists() {
        let graph = createDisconnectedGraph()
        
        let a = graph.findVertex(labeled: "A")!
        let b = graph.findVertex(labeled: "B")!
        
        let dijkstra = Dijkstra(on: graph, from: a, edgeWeight: .property(\.weight))
        let result = dijkstra.reduce(into: nil) { $0 = $1 }!
        
        // Check that b is unreachable (distance should be infinite)
        let distanceToB = result.propertyMap[b][result.distanceProperty]
        #expect(distanceToB == .infinite)
    }
    
    @Test func testSingleVertex() {
        let graph = createSingleVertexGraph()
        
        let a = graph.findVertex(labeled: "A")!
        
        let dijkstra = Dijkstra(on: graph, from: a, edgeWeight: .property(\.weight))
        let result = dijkstra.reduce(into: nil) { $0 = $1 }!
        
        // Check that distance to self is 0
        let distanceToA = result.propertyMap[a][result.distanceProperty]
        #expect(distanceToA == .finite(0.0))
    }
}
