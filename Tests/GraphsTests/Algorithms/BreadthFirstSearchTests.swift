@testable import Graphs
import Testing

struct BFSTests {
    
    func createMultiLevelTreeGraph() -> some AdjacencyListProtocol {
        var graph = AdjacencyList()
        
        let root = graph.addVertex { $0.label = "root" }
        let a = graph.addVertex { $0.label = "a" }
        let b = graph.addVertex { $0.label = "b" }
        let c = graph.addVertex { $0.label = "c" }
        let x = graph.addVertex { $0.label = "x" }
        let y = graph.addVertex { $0.label = "y" }
        let z = graph.addVertex { $0.label = "z" }
        
        graph.addEdge(from: root, to: a)
        graph.addEdge(from: root, to: b)
        graph.addEdge(from: root, to: c)
        graph.addEdge(from: a, to: x)
        graph.addEdge(from: a, to: y)
        graph.addEdge(from: a, to: z)
        
        return graph
    }
    
    func createSimpleTreeGraph() -> some AdjacencyListProtocol {
        var graph = AdjacencyList()
        
        let root = graph.addVertex { $0.label = "root" }
        let a = graph.addVertex { $0.label = "a" }
        let b = graph.addVertex { $0.label = "b" }
        let c = graph.addVertex { $0.label = "c" }
        let d = graph.addVertex { $0.label = "d" }
        
        graph.addEdge(from: root, to: a)
        graph.addEdge(from: root, to: c)
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: c, to: d)
        
        return graph
    }
    
    func createComplexTreeGraph() -> some AdjacencyListProtocol {
        var graph = AdjacencyList()
        
        let root = graph.addVertex { $0.label = "root" }
        let a = graph.addVertex { $0.label = "a" }
        let b = graph.addVertex { $0.label = "b" }
        let c = graph.addVertex { $0.label = "c" }
        let d = graph.addVertex { $0.label = "d" }
        let e = graph.addVertex { $0.label = "e" }
        let f = graph.addVertex { $0.label = "f" }
        let g = graph.addVertex { $0.label = "g" }
        
        graph.addEdge(from: root, to: a)
        graph.addEdge(from: root, to: b)
        graph.addEdge(from: a, to: c)
        graph.addEdge(from: a, to: d)
        graph.addEdge(from: b, to: d)
        graph.addEdge(from: b, to: e)
        graph.addEdge(from: c, to: f)
        graph.addEdge(from: d, to: f)
        graph.addEdge(from: d, to: g)
        graph.addEdge(from: e, to: g)
        
        return graph
    }
    
    @Test func order() {
        let graph = createMultiLevelTreeGraph()
        
        let root = graph.findVertex(labeled: "root")!
        
        let result = graph.traverse(from: root, using: .bfs())
        #expect(result.vertexLabels(in: graph) == ["root", "a", "b", "c", "x", "y", "z"])
    }
    
    @Test func startsAtSourceAndComputesDistancesAndPaths() {
        let graph = createSimpleTreeGraph()
        
        let root = graph.findVertex(labeled: "root")!
        let a = graph.findVertex(labeled: "a")!
        let b = graph.findVertex(labeled: "b")!
        let c = graph.findVertex(labeled: "c")!
        let d = graph.findVertex(labeled: "d")!

        let result = BreadthFirstSearch(on: graph, from: root)
            .prefix { $0.depth() < 3 }
            .reduce(into: nil) { $0 = $1 }

        #expect(result?.depth(of: root) == 0)
        #expect(result?.depth(of: a) == 1)
        #expect(result?.depth(of: c) == 1)
        #expect(result?.depth(of: b) == 2)
        #expect(result?.depth(of: d) == 2)

        #expect(result?.vertices(to: a, in: graph) == [root, a])
        #expect(result?.vertices(to: b, in: graph) == [root, a, b])
        #expect(result?.vertices(to: c, in: graph) == [root, c])
        #expect(result?.vertices(to: d, in: graph) == [root, c, d])
    }

    @Test func visitorReportsDiscoveryThenExaminationInBFSOrder() {
        let graph = createComplexTreeGraph()
        
        let root = graph.findVertex(labeled: "root")!

        var discovered: [Any] = []
        var examined: [Any] = []

        BreadthFirstSearch(on: graph, from: root)
            .withVisitor {
                .init(
                    discoverVertex: { discovered.append($0) },
                    examineVertex: { examined.append($0) }
                )
            }
            .forEach { _ in }

        #expect(discovered.count == 7)
        #expect(examined.count == 8)
    }

    @Test func traversalWrapperReturnsBFSVertexAndEdgeOrder() {
        let graph = createSimpleTreeGraph()
        
        let root = graph.findVertex(labeled: "root")!
        let a = graph.findVertex(labeled: "a")!
        let b = graph.findVertex(labeled: "b")!
        let c = graph.findVertex(labeled: "c")!
        let d = graph.findVertex(labeled: "d")!
        
        let edges = Array(graph.edges())
        let ra = edges.first { graph.source(of: $0) == root && graph.destination(of: $0) == a }!
        let rc = edges.first { graph.source(of: $0) == root && graph.destination(of: $0) == c }!
        let ab = edges.first { graph.source(of: $0) == a && graph.destination(of: $0) == b }!
        let cd = edges.first { graph.source(of: $0) == c && graph.destination(of: $0) == d }!

        let result = graph.traverse(from: root, using: .bfs())
        #expect(result.vertices == [root, a, c, b, d])
        #expect(result.edges == [ra, rc, ab, cd])
    }
}


