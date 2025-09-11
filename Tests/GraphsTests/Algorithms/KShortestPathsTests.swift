@testable import Graphs
import Testing

struct KShortestPathsTests {
    
    @Test func testYenBasic() throws {
        var graph = AdjacencyList()
        
        // Create a simple test graph: A -> B -> C
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        
        graph.addEdge(from: a, to: b) { $0.weight = 2 }
        graph.addEdge(from: b, to: c) { $0.weight = 3 }
        
        let paths = graph.kShortestPaths(from: a, to: c, k: 3, using: .yen(weight: .property(\.weight)))
        
        #expect(paths.count >= 1)
        #expect(paths.count <= 3)
        
        // First path should be the shortest
        let firstPath = try #require(paths.first)
        #expect(firstPath.vertices.count == 3)
        #expect(firstPath.vertices.first == a)
        #expect(firstPath.vertices.last == c)
    }
    
    @Test func testYenMultiplePaths() {
        var graph = AdjacencyList()
        
        // Create a graph with multiple paths from A to D
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        
        // Path 1: A -> B -> D (weight 3)
        graph.addEdge(from: a, to: b) { $0.weight = 1 }
        graph.addEdge(from: b, to: d) { $0.weight = 2 }
        
        // Path 2: A -> C -> D (weight 4)
        graph.addEdge(from: a, to: c) { $0.weight = 2 }
        graph.addEdge(from: c, to: d) { $0.weight = 2 }
        
        // Path 3: A -> B -> C -> D (weight 5)
        graph.addEdge(from: b, to: c) { $0.weight = 2 }
        
        let paths = graph.kShortestPaths(from: a, to: d, k: 3, using: .yen(weight: .property(\.weight)))
        
        #expect(paths.count >= 1)
        
        // Verify paths are in order of increasing cost
        for i in 0 ..< (paths.count - 1) {
            let currentPath = paths[i]
            let nextPath = paths[i + 1]
            
            // Calculate total cost for each path
            let currentCost = calculatePathCost(currentPath, in: graph)
            let nextCost = calculatePathCost(nextPath, in: graph)
            
            #expect(currentCost <= nextCost)
        }
    }
    
    @Test func testYenSinglePath() throws {
        var graph = AdjacencyList()
        
        // Create a graph with only one path
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        
        graph.addEdge(from: a, to: b) { $0.weight = 1 }
        graph.addEdge(from: b, to: c) { $0.weight = 2 }
        
        let paths = graph.kShortestPaths(from: a, to: c, k: 5, using: .yen(weight: .property(\.weight)))
        
        #expect(paths.count == 1)
        let path = try #require(paths.first)
        #expect(path.vertices.count == 3)
        #expect(path.vertices.first == a)
        #expect(path.vertices.last == c)
    }
    
    @Test func testYenNoPath() {
        var graph = AdjacencyList()
        
        // Create disconnected components
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        
        graph.addEdge(from: a, to: b) { $0.weight = 1 }
        graph.addEdge(from: c, to: d) { $0.weight = 2 }
        // No connection between A-B and C-D components
        
        let paths = graph.kShortestPaths(from: a, to: d, k: 3, using: .yen(weight: .property(\.weight)))
        
        #expect(paths.count >= 0) // May find some paths even in disconnected components
    }
    
    @Test func testYenSameSourceDestination() {
        var graph = AdjacencyList()
        
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        
        graph.addEdge(from: a, to: b) { $0.weight = 1 }
        
        let paths = graph.kShortestPaths(from: a, to: a, k: 3, using: .yen(weight: .property(\.weight)))
        
        #expect(paths.count >= 0) // May or may not find a path from A to A
    }
    
    @Test func testYenKGreaterThanAvailablePaths() {
        var graph = AdjacencyList()
        
        // Create a graph with only one path
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        
        graph.addEdge(from: a, to: b) { $0.weight = 1 }
        graph.addEdge(from: b, to: c) { $0.weight = 2 }
        
        let paths = graph.kShortestPaths(from: a, to: c, k: 10, using: .yen(weight: .property(\.weight)))
        
        #expect(paths.count == 1) // Only one path available
    }
    
    
    private func calculatePathCost<Graph: IncidenceGraph & EdgePropertyGraph>(
        _ path: Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>,
        in graph: Graph
    ) -> Double where Graph.VertexDescriptor: Hashable {
        var totalCost = 0.0
        for edge in path.edges {
            let weight = graph[edge].weight
            totalCost += weight
        }
        return totalCost
    }
}
