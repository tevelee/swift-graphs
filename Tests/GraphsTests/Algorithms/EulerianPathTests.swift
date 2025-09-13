@testable import Graphs
import Testing

struct EulerianPathTests {
    
    func createEulerianPathGraph() -> some AdjacencyListProtocol {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        
        graph.addEdge(from: a, to: b) { $0.label = "AB" }
        graph.addEdge(from: b, to: c) { $0.label = "BC" }
        graph.addEdge(from: c, to: d) { $0.label = "CD" }
        graph.addEdge(from: d, to: a) { $0.label = "DA" }
        graph.addEdge(from: a, to: c) { $0.label = "AC" }
        
        return graph
    }
    
    func createEulerianCycleGraph() -> some AdjacencyListProtocol {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        
        graph.addEdge(from: a, to: b) { $0.label = "AB" }
        graph.addEdge(from: b, to: c) { $0.label = "BC" }
        graph.addEdge(from: c, to: d) { $0.label = "CD" }
        graph.addEdge(from: d, to: a) { $0.label = "DA" }
        
        return graph
    }
    
    func createNoEulerianPathGraph() -> some AdjacencyListProtocol {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        
        graph.addEdge(from: a, to: b) { $0.label = "AB" }
        graph.addEdge(from: b, to: c) { $0.label = "BC" }
        graph.addEdge(from: c, to: d) { $0.label = "CD" }
        graph.addEdge(from: d, to: a) { $0.label = "DA" }
        graph.addEdge(from: a, to: c) { $0.label = "AC" }
        graph.addEdge(from: b, to: d) { $0.label = "BD" }
        
        return graph
    }
    
    func createSingleVertexGraph() -> some AdjacencyListProtocol {
        var graph = AdjacencyList()
        _ = graph.addVertex { $0.label = "A" }
        return graph
    }
    
    @Test func testEulerianPathDetection() {
        let graph = createEulerianPathGraph()
        
        #expect(graph.hasEulerianPath())
        #expect(!graph.hasEulerianCycle())
    }
    
    @Test func testEulerianCycleDetection() {
        let graph = createEulerianCycleGraph()
        
        #expect(graph.hasEulerianPath())
        #expect(graph.hasEulerianCycle())
    }
    
    @Test func testEulerianPathFinding() throws {
        let graph = createEulerianPathGraph()
        
        let path = try #require(graph.eulerianPath(using: Hierholzer()))
        
        #expect(path.source != path.destination)
        #expect(path.edges.count == 5)
        #expect(graph.destination(of: path.edges[0]) == path.vertices[1])
        #expect(graph.destination(of: path.edges[1]) == path.vertices[2])
        #expect(graph.destination(of: path.edges[2]) == path.vertices[3])
        #expect(graph.destination(of: path.edges[3]) == path.vertices[4])
        #expect(graph.destination(of: path.edges[4]) == path.vertices[5])
        
        let vertexLabels = path.vertices.map { graph[$0].label }
        #expect(vertexLabels == ["A", "B", "C", "D", "A", "C"])
        
        let edgeLabels = path.edges.map { graph[$0].label }
        #expect(edgeLabels == ["AB", "BC", "CD", "DA", "AC"])
    }
    
    @Test func testEulerianCycleFinding() throws {
        let graph = createEulerianCycleGraph()
        
        let cycle = try #require(graph.eulerianCycle(using: Hierholzer()))
        
        #expect(cycle.source == cycle.destination)
        #expect(cycle.vertices.first == cycle.vertices.last)
        #expect(cycle.edges.count == 4)
        
        #expect(graph.destination(of: cycle.edges[0]) == cycle.vertices[1])
        #expect(graph.destination(of: cycle.edges[1]) == cycle.vertices[2])
        #expect(graph.destination(of: cycle.edges[2]) == cycle.vertices[3])
        #expect(graph.destination(of: cycle.edges[3]) == cycle.vertices[4])
        
        let vertexLabels = cycle.vertices.map { graph[$0].label }
        #expect(vertexLabels == ["A", "B", "C", "D", "A"])
        
        let edgeLabels = cycle.edges.map { graph[$0].label }
        #expect(edgeLabels == ["AB", "BC", "CD", "DA"])
    }
    
    @Test func testNoEulerianPath() {
        let graph = createNoEulerianPathGraph()
        
        #expect(!graph.hasEulerianPath())
        #expect(!graph.hasEulerianCycle())
        
        let path = graph.eulerianPath(using: Hierholzer())
        #expect(path == nil)
    }
    
    @Test func testSingleVertex() throws {
        let graph = createSingleVertexGraph()
        
        #expect(graph.hasEulerianPath())
        #expect(graph.hasEulerianCycle())
        
        let path = try #require(graph.eulerianPath(using: Hierholzer()))
        
        let a = graph.findVertex(labeled: "A")!
        #expect(path.vertices == [a])
        #expect(path.edges == [])
        #expect(path.source == path.destination)
    }
    
    @Test func testEmptyGraph() {
        let graph = AdjacencyList()
        
        #expect(!graph.hasEulerianPath())
        #expect(!graph.hasEulerianCycle())
        
        let path = graph.eulerianPath(using: Hierholzer())
        #expect(path == nil)
    }
}