#if !GRAPHS_USES_TRAITS || GRAPHS_PATHFINDING
@testable import Graphs
import Testing

struct AllPathsTests {
    
    func createDiamondGraph() -> some AdjacencyListProtocol {
        var graph = AdjacencyList()
        
        let a = graph.addVertex { $0.label = "a" }
        let b = graph.addVertex { $0.label = "b" }
        let c = graph.addVertex { $0.label = "c" }
        let d = graph.addVertex { $0.label = "d" }
        
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: d)
        graph.addEdge(from: a, to: c)
        graph.addEdge(from: c, to: d)
        graph.addEdge(from: a, to: d)
        
        return graph
    }
    
    @Test func findsAllPathsInDiamondGraph() {
        let graph = createDiamondGraph()
        let a = graph.findVertex(labeled: "a")!
        let d = graph.findVertex(labeled: "d")!
        
        let paths = Array(graph.allPaths(from: a, to: d))
        
        #expect(paths.count == 3)
        
        let pathsVertices = paths.map { $0.vertices.map { graph[$0].label } }
        let expectedPaths = [
            ["a", "b", "d"],
            ["a", "c", "d"],
            ["a", "d"]
        ]
        
        for expected in expectedPaths {
            #expect(pathsVertices.contains(where: { $0 == expected }))
        }
    }
    
    func createCyclicGraph() -> some AdjacencyListProtocol {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "a" }
        let b = graph.addVertex { $0.label = "b" }
        let c = graph.addVertex { $0.label = "c" }
        
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: a)
        graph.addEdge(from: b, to: c)
        
        return graph
    }
    
    @Test func findsAllPathsInCyclicGraph() {
        let graph = createCyclicGraph()
        let a = graph.findVertex(labeled: "a")!
        let c = graph.findVertex(labeled: "c")!
        
        let paths = Array(graph.allPaths(from: a, to: c))
        
        #expect(paths.count == 1)
        #expect(paths[0].vertices.map { graph[$0].label } == ["a", "b", "c"])
    }
    
    func createNoPathGraph() -> some AdjacencyListProtocol {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "a" }
        let b = graph.addVertex { $0.label = "b" }
        
        return graph
    }
    
    @Test func findsNoPathsWhenDisconnected() {
        let graph = createNoPathGraph()
        let a = graph.findVertex(labeled: "a")!
        let b = graph.findVertex(labeled: "b")!
        
        let paths = Array(graph.allPaths(from: a, to: b))
        
        #expect(paths.isEmpty)
    }
}
#endif
