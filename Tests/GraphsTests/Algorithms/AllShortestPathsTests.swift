@testable import Graphs
import Testing

struct AllShortestPathsTests {
    
    /// Creates a graph with multiple paths of equal cost.
    /// Structure:
    ///     A --2--> B --1--> D
    ///     |                 ^
    ///     +-----1--> C --2--+
    /// 
    /// Two paths from A to D both cost 3:
    /// - A -> B -> D (2 + 1 = 3)
    /// - A -> C -> D (1 + 2 = 3)
    func createMultipleEqualPathsGraph() -> some AdjacencyListProtocol {
        var graph = AdjacencyList()
        
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        
        graph.addEdge(from: a, to: b) { $0.weight = 2 }
        graph.addEdge(from: b, to: d) { $0.weight = 1 }
        graph.addEdge(from: a, to: c) { $0.weight = 1 }
        graph.addEdge(from: c, to: d) { $0.weight = 2 }
        
        return graph
    }
    
    /// Creates a graph with three paths of equal cost.
    /// Structure:
    ///     A --1--> B --1--> C
    ///     |        |        ^
    ///     +--1--> D  --1----+
    ///     |                 ^
    ///     +------2----------+
    ///
    /// Three paths from A to C all cost 2:
    /// - A -> B -> C (1 + 1 = 2)
    /// - A -> D -> C (1 + 1 = 2)  
    /// - A -> C (2)
    func createThreeEqualPathsGraph() -> some AdjacencyListProtocol {
        var graph = AdjacencyList()
        
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        
        graph.addEdge(from: a, to: b) { $0.weight = 1 }
        graph.addEdge(from: b, to: c) { $0.weight = 1 }
        graph.addEdge(from: a, to: d) { $0.weight = 1 }
        graph.addEdge(from: d, to: c) { $0.weight = 1 }
        graph.addEdge(from: a, to: c) { $0.weight = 2 }
        
        return graph
    }
    
    /// Creates a linear graph (single path).
    func createLinearGraph() -> some AdjacencyListProtocol {
        var graph = AdjacencyList()
        
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        
        graph.addEdge(from: a, to: b) { $0.weight = 2 }
        graph.addEdge(from: b, to: c) { $0.weight = 3 }
        
        return graph
    }
    
    /// Creates a disconnected graph (no path).
    func createDisconnectedGraph() -> some AdjacencyListProtocol {
        var graph = AdjacencyList()
        
        graph.addVertex { $0.label = "A" }
        graph.addVertex { $0.label = "B" }
        
        return graph
    }
    
    /// Creates a diamond graph with multiple paths of different costs.
    /// Structure:
    ///     A --1--> B --1--> D
    ///     |                 ^
    ///     +--3--> C --1-----+
    ///
    /// Two paths from A to D:
    /// - A -> B -> D (1 + 1 = 2) - shortest
    /// - A -> C -> D (3 + 1 = 4) - longer
    func createDiamondGraphDifferentCosts() -> some AdjacencyListProtocol {
        var graph = AdjacencyList()
        
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        
        graph.addEdge(from: a, to: b) { $0.weight = 1 }
        graph.addEdge(from: b, to: d) { $0.weight = 1 }
        graph.addEdge(from: a, to: c) { $0.weight = 3 }
        graph.addEdge(from: c, to: d) { $0.weight = 1 }
        
        return graph
    }
    
    @Test func testTwoEqualPaths() {
        let graph = createMultipleEqualPathsGraph()
        
        let a = graph.findVertex(labeled: "A")!
        let d = graph.findVertex(labeled: "D")!
        
        let paths = graph.allShortestPaths(from: a, to: d, weight: .property(\.weight))
        
        #expect(paths.count == 2)
        
        // Both paths should have cost 3
        for path in paths {
            let cost = path.edges.reduce(0.0) { sum, edge in
                sum + graph[edge].weight
            }
            #expect(cost == 3.0)
        }
        
        // Verify the paths are the expected ones
        let pathVertexSets = Set(paths.map { Set($0.vertices.map { graph[$0].label }) })
        let expectedPath1 = Set(["A", "B", "D"])
        let expectedPath2 = Set(["A", "C", "D"])
        
        #expect(pathVertexSets.contains(expectedPath1))
        #expect(pathVertexSets.contains(expectedPath2))
    }
    
    @Test func testThreeEqualPaths() {
        let graph = createThreeEqualPathsGraph()
        
        let a = graph.findVertex(labeled: "A")!
        let c = graph.findVertex(labeled: "C")!
        
        let paths = graph.allShortestPaths(from: a, to: c, weight: .property(\.weight))
        
        #expect(paths.count == 3)
        
        // All paths should have cost 2
        for path in paths {
            let cost = path.edges.reduce(0.0) { sum, edge in
                sum + graph[edge].weight
            }
            #expect(cost == 2.0)
        }
    }
    
    @Test func testSinglePath() {
        let graph = createLinearGraph()
        
        let a = graph.findVertex(labeled: "A")!
        let c = graph.findVertex(labeled: "C")!
        
        let paths = graph.allShortestPaths(from: a, to: c, weight: .property(\.weight))
        
        #expect(paths.count == 1)
        
        let path = paths[0]
        #expect(path.vertices.count == 3)
        #expect(path.edges.count == 2)
        
        let cost = path.edges.reduce(0.0) { sum, edge in
            sum + graph[edge].weight
        }
        #expect(cost == 5.0)
    }
    
    @Test func testNoPath() {
        let graph = createDisconnectedGraph()
        
        let a = graph.findVertex(labeled: "A")!
        let b = graph.findVertex(labeled: "B")!
        
        let paths = graph.allShortestPaths(from: a, to: b, weight: .property(\.weight))
        
        #expect(paths.isEmpty)
    }
    
    @Test func testOnlyShortestPathsReturned() {
        let graph = createDiamondGraphDifferentCosts()
        
        let a = graph.findVertex(labeled: "A")!
        let d = graph.findVertex(labeled: "D")!
        
        let paths = graph.allShortestPaths(from: a, to: d, weight: .property(\.weight))
        
        // Should only return the path with cost 2 (A -> B -> D), not the path with cost 4
        #expect(paths.count == 1)
        
        let path = paths[0]
        let cost = path.edges.reduce(0.0) { sum, edge in
            sum + graph[edge].weight
        }
        #expect(cost == 2.0)
    }
    
    @Test func testSelfPath() {
        let graph = createLinearGraph()
        
        let a = graph.findVertex(labeled: "A")!
        
        let paths = graph.allShortestPaths(from: a, to: a, weight: .property(\.weight))
        
        // Path from a vertex to itself
        #expect(paths.count == 1)
        #expect(paths[0].vertices.count == 1)
        #expect(paths[0].edges.isEmpty)
    }
    
    @Test func testBacktrackingDijkstraDirectly() {
        let graph = createMultipleEqualPathsGraph()
        
        let a = graph.findVertex(labeled: "A")!
        let d = graph.findVertex(labeled: "D")!
        
        let algorithm = BacktrackingDijkstra(on: graph, edgeWeight: .property(\.weight))
        let result = algorithm.findAllShortestPaths(from: a, to: d, visitor: nil)
        
        #expect(result.paths.count == 2)
        #expect(result.optimalCost == 3.0)
        #expect(result.source == a)
        #expect(result.destination == d)
    }
    
    @Test func testWithAlgorithmParameter() {
        let graph = createMultipleEqualPathsGraph()
        
        let a = graph.findVertex(labeled: "A")!
        let d = graph.findVertex(labeled: "D")!
        
        let paths = graph.allShortestPaths(
            from: a,
            to: d,
            using: .backtrackingDijkstra(weight: .property(\.weight))
        )
        
        #expect(paths.count == 2)
    }
    
    @Test func testComplexGraph() {
        // Create a more complex graph with multiple intersecting paths
        var graph = AdjacencyList()
        
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        let e = graph.addVertex { $0.label = "E" }
        let f = graph.addVertex { $0.label = "F" }
        
        // Create a graph with multiple shortest paths
        graph.addEdge(from: a, to: b) { $0.weight = 1 }
        graph.addEdge(from: a, to: c) { $0.weight = 1 }
        graph.addEdge(from: b, to: d) { $0.weight = 1 }
        graph.addEdge(from: c, to: d) { $0.weight = 1 }
        graph.addEdge(from: d, to: e) { $0.weight = 1 }
        graph.addEdge(from: d, to: f) { $0.weight = 1 }
        graph.addEdge(from: e, to: f) { $0.weight = 0 }
        
        let paths = graph.allShortestPaths(from: a, to: f, weight: .property(\.weight))
        
        // Should find multiple paths with cost 3
        #expect(paths.count > 1)
        
        for path in paths {
            let cost = path.edges.reduce(0.0) { sum, edge in
                sum + graph[edge].weight
            }
            #expect(cost == 3.0)
        }
    }
}

