@testable import Graphs
import Testing

struct HamiltonianPathTests {
    
    func createCompleteGraph() -> some AdjacencyListProtocol {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        
        graph.addEdge(from: a, to: b) { $0.label = "AB" }
        graph.addEdge(from: b, to: a) { $0.label = "BA" }
        graph.addEdge(from: a, to: c) { $0.label = "AC" }
        graph.addEdge(from: c, to: a) { $0.label = "CA" }
        graph.addEdge(from: a, to: d) { $0.label = "AD" }
        graph.addEdge(from: d, to: a) { $0.label = "DA" }
        graph.addEdge(from: b, to: c) { $0.label = "BC" }
        graph.addEdge(from: c, to: b) { $0.label = "CB" }
        graph.addEdge(from: b, to: d) { $0.label = "BD" }
        graph.addEdge(from: d, to: b) { $0.label = "DB" }
        graph.addEdge(from: c, to: d) { $0.label = "CD" }
        graph.addEdge(from: d, to: c) { $0.label = "DC" }
        
        return graph
    }
    
    func createDisconnectedGraph() -> some AdjacencyListProtocol {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        
        graph.addEdge(from: a, to: b) { $0.label = "AB" }
        graph.addEdge(from: c, to: d) { $0.label = "CD" }
        
        return graph
    }
    
    func createSingleVertexGraph() -> some AdjacencyListProtocol {
        var graph = AdjacencyList()
        graph.addVertex { $0.label = "A" }
        return graph
    }
    
    func createTwoVertexGraph() -> some AdjacencyListProtocol {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        graph.addEdge(from: a, to: b) { $0.label = "AB" }
        return graph
    }
    
    @Test func testHamiltonianPathFinding() throws {
        let graph = createCompleteGraph()
        
        let path = try #require(graph.hamiltonianPath(using: BacktrackingHamiltonian()))
        
        #expect(path.source != path.destination)
        
        let allVertices = Array(graph.vertices())
        #expect(path.vertices == allVertices)
        #expect(path.edges.count == 3)
        
        #expect(graph.destination(of: path.edges[0]) == path.vertices[1])
        #expect(graph.destination(of: path.edges[1]) == path.vertices[2])
        #expect(graph.destination(of: path.edges[2]) == path.vertices[3])
        
        let vertexLabels = path.vertices.map { graph[$0].label }
        #expect(vertexLabels == ["A", "B", "C", "D"])
        #expect(vertexLabels.count == 4)
        
        let edgeLabels = path.edges.map { graph[$0].label }
        #expect(edgeLabels.count == 3)
    }
    
    @Test func testHamiltonianPathFromSource() throws {
        let graph = createCompleteGraph()
        let a = graph.findVertex(labeled: "A")!
        
        let path = try #require(graph.hamiltonianPath(from: a, using: BacktrackingHamiltonian()))
        
        #expect(path.source == a)
        #expect(path.vertices.first == a)
        
        let allVertices = Array(graph.vertices())
        #expect(path.vertices == allVertices)
        
        let vertexLabels = path.vertices.map { graph[$0].label }
        #expect(vertexLabels.first == "A")
        #expect(vertexLabels == ["A", "B", "C", "D"])
    }
    
    @Test func testHamiltonianPathFromSourceToDestination() throws {
        let graph = createCompleteGraph()
        let a = graph.findVertex(labeled: "A")!
        let d = graph.findVertex(labeled: "D")!
        
        let path = try #require(graph.hamiltonianPath(from: a, to: d, using: BacktrackingHamiltonian()))
        
        #expect(path.source == a)
        #expect(path.destination == d)
        #expect(path.vertices.first == a)
        #expect(path.vertices.last == d)
        
        let allVertices = Array(graph.vertices())
        #expect(path.vertices == allVertices)
        
        let vertexLabels = path.vertices.map { graph[$0].label }
        #expect(vertexLabels.first == "A")
        #expect(vertexLabels.last == "D")
        #expect(vertexLabels == ["A", "B", "C", "D"])
    }
    
    @Test func testHamiltonianCycleFinding() throws {
        let graph = createCompleteGraph()
        
        let cycle = try #require(graph.hamiltonianCycle(using: BacktrackingHamiltonian()))
        
        #expect(cycle.source == cycle.destination)
        #expect(cycle.vertices.first == cycle.vertices.last)
        
        let allVertices = Array(graph.vertices())
        let pathVertices = Array(cycle.vertices.dropLast())
        #expect(pathVertices == allVertices)
        #expect(cycle.edges.count == 4)
        
        let vertexLabels = cycle.vertices.map { graph[$0].label }
        #expect(vertexLabels.first == vertexLabels.last)
        #expect(vertexLabels.dropLast() == ["A", "B", "C", "D"])
        
        let edgeLabels = cycle.edges.map { graph[$0].label }
        #expect(edgeLabels.count == 4)
    }
    
    @Test func testHeuristicHamiltonianPath() throws {
        let graph = createCompleteGraph()
        
        let path = try #require(graph.hamiltonianPath(using: HeuristicHamiltonian(heuristic: .degreeBased)))
        
        #expect(path.source != path.destination)
        
        let allVertices = Array(graph.vertices())
        let pathVertices = Array(path.vertices)
        #expect(pathVertices == allVertices)
        #expect(path.vertices.count == allVertices.count)
        
        let vertexLabels = path.vertices.map { graph[$0].label }
        #expect(Set(vertexLabels) == Set(["A", "B", "C", "D"]))
        #expect(vertexLabels.count == 4)
    }
    
    @Test func testNoHamiltonianPath() {
        let graph = createDisconnectedGraph()
        
        let path = graph.hamiltonianPath(using: BacktrackingHamiltonian())
        #expect(path == nil)
        
        let cycle = graph.hamiltonianCycle(using: BacktrackingHamiltonian())
        #expect(cycle == nil)
    }
    
    @Test func testSingleVertex() throws {
        let graph = createSingleVertexGraph()
        
        let path = try #require(graph.hamiltonianPath(using: BacktrackingHamiltonian()))
        let a = graph.findVertex(labeled: "A")!
        
        #expect(path.vertices == [a])
        #expect(path.source == path.destination)
        #expect(path.edges == [])
    }
    
    @Test func testTwoVertices() throws {
        let graph = createTwoVertexGraph()
        
        let path = try #require(graph.hamiltonianPath(using: BacktrackingHamiltonian()))
        let a = graph.findVertex(labeled: "A")!
        let b = graph.findVertex(labeled: "B")!
        
        #expect(path.vertices == [a, b] || path.vertices == [b, a])
        #expect(path.source != path.destination)
        #expect(path.edges.count == 1)
    }
    
    @Test func testEmptyGraph() {
        let graph = AdjacencyList()
        
        let path = graph.hamiltonianPath(using: BacktrackingHamiltonian())
        #expect(path == nil)
        
        let cycle = graph.hamiltonianCycle(using: BacktrackingHamiltonian())
        #expect(cycle == nil)
    }
}
