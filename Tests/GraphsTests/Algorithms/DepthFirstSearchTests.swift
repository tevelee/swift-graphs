@testable import Graphs
import Testing

struct DFSTests {
    
    func createTreeGraph() -> some AdjacencyListProtocol {
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
    
    func createCyclicGraph() -> some AdjacencyListProtocol {
        var graph = AdjacencyList()
        
        let a = graph.addVertex { $0.label = "a" }
        let b = graph.addVertex { $0.label = "b" }
        let c = graph.addVertex { $0.label = "c" }
        
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: c, to: a)
        
        return graph
    }
    
    @Test func reconstructsPathsFromPredecessorEdges() {
        let graph = createTreeGraph()
        
        let root = graph.findVertex(labeled: "root")!
        let a = graph.findVertex(labeled: "a")!
        let b = graph.findVertex(labeled: "b")!
        let c = graph.findVertex(labeled: "c")!
        let d = graph.findVertex(labeled: "d")!
        
        let last = DepthFirstSearch(on: graph, from: root).reduce(into: nil) { $0 = $1 }
        #expect(last?.vertices(to: a, in: graph) == [root, a])
        #expect(last?.vertices(to: b, in: graph) == [root, a, b])
        #expect(last?.vertices(to: c, in: graph) == [root, c])
        #expect(last?.vertices(to: d, in: graph) == [root, c, d])
    }

    @Test func visitorSeesPreorderOfVertices() {
        let graph = createComplexTreeGraph()
        
        let root = graph.findVertex(labeled: "root")!
        
        var discovered: [Any] = []
        var examined: [Any] = []
        DepthFirstSearch(on: graph, from: root)
            .withVisitor {
                .init(
                    discoverVertex: { discovered.append($0) },
                    examineVertex: { examined.append($0) }
                )
            }
            .forEach { _ in }
        #expect(discovered.count == 8)
        #expect(examined.count == 8)
    }

    @Test func traversalWrapperReturnsVerticesPreorderAndEdgesInAdjacencyOrder() {
        let graph = createTreeGraph()
        
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

        let result = graph.traverse(from: root, using: .dfs())
        #expect(result.vertices == [root, a, b, c, d])
        #expect(result.edges == [ra, rc, ab, cd])
    }

    @Test func traversalWrapperReturnsVerticesPostorderAndEdgesInAdjacencyOrder() {
        let graph = createTreeGraph()
        
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

        let result = graph.traverse(from: root, using: .dfs(order: .postorder))
        #expect(result.vertices == [b, a, d, c, root])
        #expect(result.edges == [ra, rc, ab, cd])
    }

    @Test func classificationDetectsBackEdgesInCycles() {
        let graph = createCyclicGraph()
        
        let a = graph.findVertex(labeled: "a")!
        
        var backEdges: [Any] = []
        var treeEdges: [Any] = []
        DepthFirstSearch(on: graph, from: a)
            .withVisitor {
                .init(
                    treeEdge: { treeEdges.append($0) },
                    backEdge: { backEdges.append($0) }
                )
            }
            .forEach { _ in }

        #expect(backEdges.count == 1)
        #expect(treeEdges.count == 2)
    }
}


