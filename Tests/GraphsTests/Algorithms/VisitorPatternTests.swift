import Testing
@testable import Graphs

final class VisitorPatternTests {
    @Test func bfs() {
        // Create a simple graph
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)
        
        var visitedVertices: [String] = []
        let result = graph.traverse(from: a, using: .bfs().withVisitor(.init(
            examineVertex: { vertex in
                visitedVertices.append(graph[vertex].label)
            }
        )))
        
        #expect(result.vertices.count == 3)
        #expect(visitedVertices.count >= 3)
        #expect(visitedVertices.contains("A"))
        #expect(visitedVertices.contains("B"))
        #expect(visitedVertices.contains("C"))
    }
    
    @Test func visitorChaining() {
        // Create a simple graph
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)
        
        var visitedVertices1: [String] = []
        var visitedVertices2: [String] = []
        
        // Test chaining visitors
        let result = graph.traverse(from: a, using: .bfs()
            .withVisitor(.init(examineVertex: { vertex in
                visitedVertices1.append(graph[vertex].label)
            }))
            .withVisitor(.init(examineVertex: { vertex in
                visitedVertices2.append(graph[vertex].label)
            }))
        )
        
        #expect(result.vertices.count == 3)
        #expect(visitedVertices1.count == 3)
        #expect(visitedVertices2.count == 3)
        #expect(visitedVertices1 == visitedVertices2) // Both visitors should see the same events
    }
    
    // MARK: - DFS Tests
    
    @Test func dfsPreorder() {
        // Create a simple graph
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)
        
        var visitedVertices: [String] = []
        let result = graph.traverse(from: a, using: .dfs(order: .preorder).withVisitor(.init(
            discoverVertex: { vertex in
                visitedVertices.append(graph[vertex].label)
            }
        )))
        
        #expect(result.vertices.count == 3)
        #expect(visitedVertices.count >= 3)
        #expect(visitedVertices.contains("A"))
        #expect(visitedVertices.contains("B"))
        #expect(visitedVertices.contains("C"))
    }
    
    @Test func dfsPostorder() {
        // Create a simple graph
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)
        
        var visitedVertices: [String] = []
        let result = graph.traverse(from: a, using: .dfs(order: .postorder).withVisitor(.init(
            finishVertex: { vertex in
                visitedVertices.append(graph[vertex].label)
            }
        )))
        
        #expect(result.vertices.count == 3)
        #expect(visitedVertices.count >= 3)
        #expect(visitedVertices.contains("A"))
        #expect(visitedVertices.contains("B"))
        #expect(visitedVertices.contains("C"))
    }
    
    @Test func dfsDepthLimited() {
        // Create a simple graph
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: c, to: d)
        
        var visitedVertices: [String] = []
        _ = graph.traverse(from: a, using: .depthLimitedDFS(maxDepth: 2).withVisitor(.init(
            discoverVertex: { vertex in
                visitedVertices.append(graph[vertex].label)
            }
        )))
        
        #expect(visitedVertices.count <= 3) // Should not visit D due to depth limit
        #expect(visitedVertices.contains("A"))
        #expect(visitedVertices.contains("B"))
    }
    
    // MARK: - Shortest Path Tests

    #if !GRAPHS_USES_TRAITS || GRAPHS_PATHFINDING
    @Test func dijkstra() {
        // Create a weighted graph
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        
        graph.addEdge(from: a, to: b) { $0.weight = 1.0 }
        graph.addEdge(from: b, to: c) { $0.weight = 2.0 }
        
        var visitedVertices: [String] = []
        let result = graph.shortestPath(from: a, to: c, using: .dijkstra(weight: .property(\.weight)).withVisitor(.init(
            examineVertex: { vertex in
                visitedVertices.append(graph[vertex].label)
            }
        )))
        
        #expect(result != nil)
        #expect(visitedVertices.count >= 2)
        #expect(visitedVertices.contains("A"))
        #expect(visitedVertices.contains("B"))
    }
    
    @Test func aStar() {
        // Create a weighted graph
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        
        graph.addEdge(from: a, to: b) { $0.weight = 1.0 }
        graph.addEdge(from: b, to: c) { $0.weight = 2.0 }
        
        var visitedVertices: [String] = []
        let result = graph.shortestPath(from: a, to: c, using: .aStar(weight: .property(\.weight), heuristic: .uniform(0.0)).withVisitor(.init(
            examineVertex: { vertex in
                visitedVertices.append(graph[vertex].label)
            }
        )))
        
        #expect(result != nil)
        #expect(visitedVertices.count >= 2)
        #expect(visitedVertices.contains("A"))
        #expect(visitedVertices.contains("B"))
    }
    
    @Test func bellmanFord() {
        // Create a weighted graph
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        
        graph.addEdge(from: a, to: b) { $0.weight = 1.0 }
        graph.addEdge(from: b, to: c) { $0.weight = 2.0 }
        
        var visitedEdges: [String] = []
        let result = graph.shortestPath(from: a, to: c, using: .bellmanFord(weight: .property(\.weight)).withVisitor(.init(
            examineEdge: { edge in
                visitedEdges.append("Edge-\(edge)")
            }
        )))
        
        #expect(result != nil)
        #expect(visitedEdges.count >= 2)
    }
    
    #endif

    // MARK: - Minimum Spanning Tree Tests

    #if !GRAPHS_USES_TRAITS || GRAPHS_OPTIMIZATION
    @Test func kruskal() {
        // Create a weighted graph
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        
        graph.addEdge(from: a, to: b) { $0.weight = 1.0 }
        graph.addEdge(from: b, to: c) { $0.weight = 2.0 }
        graph.addEdge(from: a, to: c) { $0.weight = 3.0 }
        
        var visitedEdges: [String] = []
        let result = graph.minimumSpanningTree(using: .kruskal(weight: .property(\.weight)).withVisitor(.init(
            examineEdge: { edge in
                let source = graph.source(of: edge)!
                let dest = graph.destination(of: edge)!
                visitedEdges.append("\(graph[source].label)-\(graph[dest].label)")
            }
        )))
        
        #expect(result.edges.count == 2)
        #expect(visitedEdges.count >= 2)
    }
    
    @Test func prim() {
        // Create a weighted graph
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        
        graph.addEdge(from: a, to: b) { $0.weight = 1.0 }
        graph.addEdge(from: b, to: c) { $0.weight = 2.0 }
        graph.addEdge(from: a, to: c) { $0.weight = 3.0 }
        
        var visitedEdges: [String] = []
        let result = graph.minimumSpanningTree(using: .prim(weight: .property(\.weight)).withVisitor(.init(
            examineEdge: { edge in
                let source = graph.source(of: edge)!
                let dest = graph.destination(of: edge)!
                visitedEdges.append("\(graph[source].label)-\(graph[dest].label)")
            }
        )))
        
        #expect(result.edges.count == 2)
        #expect(visitedEdges.count >= 2)
    }
    
    #endif

    // MARK: - Graph Coloring Tests

    #if !GRAPHS_USES_TRAITS || GRAPHS_ANALYSIS
    @Test func greedyColoring() {
        // Create a simple graph
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: a, to: c)
        
        var visitedVertices: [String] = []
        let result = graph.colorGraph(using: .greedy().withVisitor(.init(
            examineVertex: { vertex in
                visitedVertices.append(graph[vertex].label)
            }
        )))
        
        #expect(result.vertexColors.count == 3)
        #expect(visitedVertices.count >= 3)
        #expect(visitedVertices.contains("A"))
        #expect(visitedVertices.contains("B"))
        #expect(visitedVertices.contains("C"))
    }
    
    @Test func dsaturColoring() {
        // Create a simple graph
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: a, to: c)
        
        var visitedVertices: [String] = []
        let result = graph.colorGraph(using: .dsatur().withVisitor(.init(
            examineVertex: { vertex in
                visitedVertices.append(graph[vertex].label)
            }
        )))
        
        #expect(result.vertexColors.count == 3)
        #expect(visitedVertices.count >= 3)
        #expect(visitedVertices.contains("A"))
        #expect(visitedVertices.contains("B"))
        #expect(visitedVertices.contains("C"))
    }
    
    #endif

    // MARK: - Hamiltonian Path Tests

    #if !GRAPHS_USES_TRAITS || GRAPHS_ADVANCED
    @Test func backtrackingHamiltonian() {
        // Create a simple graph
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: c, to: a)
        
        var visitedVertices: [String] = []
        let result = graph.hamiltonianPath(using: .backtracking().withVisitor(.init(
            examineVertex: { vertex in
                visitedVertices.append(graph[vertex].label)
            }
        )))
        
        #expect(result != nil)
        #expect(visitedVertices.count >= 2)
        #expect(visitedVertices.contains("A"))
    }
    
    // MARK: - Eulerian Path Tests
    
    @Test func hierholzer() {
        // Create a simple graph
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: c, to: a)
        
        var visitedVertices: [String] = []
        let result = graph.eulerianPath(using: .hierholzer().withVisitor(.init(
            examineVertex: { vertex in
                visitedVertices.append(graph[vertex].label)
            }
        )))
        
        #expect(result != nil)
        #expect(visitedVertices.count >= 2)
        #expect(visitedVertices.contains("A"))
    }
    
    // MARK: - Isomorphism Tests
    
    @Test func vf2Isomorphism() {
        // Create two identical graphs
        var graph1 = AdjacencyList()
        let a1 = graph1.addVertex { $0.label = "A" }
        let b1 = graph1.addVertex { $0.label = "B" }
        graph1.addEdge(from: a1, to: b1)
        
        var graph2 = AdjacencyList()
        let a2 = graph2.addVertex { $0.label = "A" }
        let b2 = graph2.addVertex { $0.label = "B" }
        graph2.addEdge(from: a2, to: b2)
        
        var visitedVertices: [String] = []
        let result = graph1.isIsomorphic(to: graph2, using: .vf2().withVisitor(.init(
            examineVertex: { vertex in
                visitedVertices.append(graph1[vertex].label)
            }
        )))
        
        #expect(result == true)
        #expect(visitedVertices.count >= 1)
    }
    
    #endif

    // MARK: - Random Graph Tests

    #if !GRAPHS_USES_TRAITS || GRAPHS_GENERATION
    @Test func erdosRenyi() {
        // Create a random graph
        var visitedVertices: [String] = []
        let graph = AdjacencyList.randomGraph(
            vertexCount: 3,
            using: .erdosRenyi(edgeProbability: 0.5),
            visitor: .init(
                examineVertexPair: { vertex1, vertex2 in
                    visitedVertices.append("Pair-\(vertex1)-\(vertex2)")
                }
            )
        )
        
        #expect(graph.vertexCount == 3)
        #expect(visitedVertices.count >= 3)
    }
    
    #endif

    // MARK: - Additional Shortest Path Tests

    #if !GRAPHS_USES_TRAITS || GRAPHS_PATHFINDING
    @Test func floydWarshall() {
        // Create a weighted graph
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        
        graph.addEdge(from: a, to: b) { $0.weight = 1.0 }
        graph.addEdge(from: b, to: c) { $0.weight = 2.0 }
        
        var visitedVertices: [String] = []
        let result = graph.shortestPath(from: a, to: c, using: .floydWarshall(weight: .property(\.weight)).withVisitor(.init(
            examineVertex: { vertex in
                visitedVertices.append(graph[vertex].label)
            }
        )))
        
        #expect(result != nil)
        #expect(visitedVertices.count >= 2)
        #expect(visitedVertices.contains("A"))
        #expect(visitedVertices.contains("B"))
    }
    
    @Test func johnson() {
        // Create a weighted graph
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        
        graph.addEdge(from: a, to: b) { $0.weight = 1.0 }
        graph.addEdge(from: b, to: c) { $0.weight = 2.0 }
        
        var dijkstraCalls: [String] = []
        let result = graph.shortestPath(from: a, to: c, using: .johnson(weight: .property(\.weight)).withVisitor(.init(
            startDijkstraFromSource: { vertex in
                dijkstraCalls.append("Start-\(graph[vertex].label)")
            },
            completeDijkstraFromSource: { vertex in
                dijkstraCalls.append("Complete-\(graph[vertex].label)")
            }
        )))
        
        #expect(result != nil)
        #expect(dijkstraCalls.count >= 2)
    }
    
    @Test func yen() {
        // Create a weighted graph
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        
        graph.addEdge(from: a, to: b) { $0.weight = 1.0 }
        graph.addEdge(from: b, to: c) { $0.weight = 2.0 }
        
        var visitedPaths: [String] = []
        let result = graph.shortestPath(from: a, to: c, using: .yen(weight: .property(\.weight)).withVisitor(.init(
            onPathFound: { path in
                visitedPaths.append("Path found with \(path.vertices.count) vertices")
            }
        )))
        
        #expect(result != nil)
        #expect(visitedPaths.count >= 1)
    }
    #endif
}
