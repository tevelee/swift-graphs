@testable import Graphs
import Testing

struct SearchAlgorithmTests {
    
    @Test func basicSearchAPI() {
        var graph = AdjacencyList()
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()
        let d = graph.addVertex()
        let e = graph.addVertex()
        let f = graph.addVertex()
        
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: a, to: c)
        graph.addEdge(from: b, to: d)
        graph.addEdge(from: c, to: e)
        graph.addEdge(from: d, to: f)
        graph.addEdge(from: e, to: f)
        
        let bfsSequence = graph.search(from: a, using: .bfs())
        
        let found = bfsSequence.first { result in
            result.currentVertex == f
        }
        
        #expect(found != nil)
        #expect(found?.currentVertex == f)
        #expect(found?.depth() == 3)
        
        let dfsSequence = graph.search(from: a, using: .dfs())
        
        let dfsOrder = dfsSequence.map { $0.currentVertex }
        let collected = Array(dfsOrder)
        
        #expect(collected == [f, d, b, e, c, a])
    }
    
    @Test func lazyEvaluation() {
        var graph = AdjacencyList()
        
        let start = graph.addVertex()
        let middle = graph.addVertex()
        let end = graph.addVertex()
        
        var chainVertices: [OrderedVertexStorage.Vertex] = [start]
        for _ in 1 ..< 50 {
            chainVertices.append(graph.addVertex())
        }
        chainVertices.append(middle)
        for _ in 51 ..< 100 {
            chainVertices.append(graph.addVertex())
        }
        chainVertices.append(end)
        
        for i in 0 ..< chainVertices.count - 1 {
            graph.addEdge(from: chainVertices[i], to: chainVertices[i+1])
        }
        
        var visitCount = 0
        
        let result = graph.search(from: start, using: .bfs())
            .first { result in
                visitCount += 1
                return result.currentVertex == middle
            }
        
        #expect(result != nil)
        #expect(visitCount == 51)
    }
    
    @Test func sequenceOperations() {
        var graph = AdjacencyList()
        let root = graph.addVertex()
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()
        let d = graph.addVertex()
        let e = graph.addVertex()
        let f = graph.addVertex()
        
        graph.addEdge(from: root, to: a)
        graph.addEdge(from: root, to: b)
        graph.addEdge(from: a, to: c)
        graph.addEdge(from: a, to: d)
        graph.addEdge(from: b, to: e)
        graph.addEdge(from: b, to: f)
        
        let depthTwo = graph.search(from: root, using: .bfs())
            .filter { $0.depth() == 2 }
            .map { $0.currentVertex }
        
        let collected = Array(depthTwo)
        #expect(collected == [c, d, e, f])
        
        let limited = graph.search(from: root, using: .bfs())
            .prefix { $0.depth() <= 1 }
            .map { $0.currentVertex }
        
        let limitedCollected = Array(limited)
        #expect(limitedCollected == [root, a, b])
        
        let hasDeep = graph.search(from: root, using: .bfs())
            .contains { $0.depth() > 2 }
        
        #expect(hasDeep == false)
    }
    
    @Test func comparisonWithTraversal() {
        var graph = AdjacencyList()
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()
        let d = graph.addVertex()
        
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: a, to: c)
        graph.addEdge(from: b, to: d)
        graph.addEdge(from: c, to: d)
        
        let traversalResult = graph.traverse(from: a, using: .bfs())
        let allVertices = traversalResult.vertices
        
        let searchVertices = graph.search(from: a, using: .bfs())
            .map { $0.currentVertex }
        
        #expect(Array(searchVertices) == allVertices)
        
        let firstD = graph.search(from: a, using: .bfs())
            .first { $0.currentVertex == d }

        #expect(firstD != nil)
        #expect(firstD?.depth() == 2)
    }

    // MARK: - Multi-Backend Coverage

    @Test func bfsSearchFindsVertexAtCorrectDepth_allBackends() {
        func check<G: TestablePropertyGraph>(_ graph: inout G, _ backend: String)
        where G.VertexProperties == VertexPropertyValues, G.EdgeProperties == EdgePropertyValues,
              G.VertexDescriptor: Hashable {
            let a = graph.addVertex { $0.label = "a" }
            let b = graph.addVertex { $0.label = "b" }
            let c = graph.addVertex { $0.label = "c" }
            let d = graph.addVertex { $0.label = "d" }
            graph.addEdge(from: a, to: b)
            graph.addEdge(from: a, to: c)
            graph.addEdge(from: b, to: d)

            let found = graph.search(from: a, using: .bfs())
                .first { graph[$0.currentVertex].label == "d" }

            #expect(found != nil, "[\(backend)] BFS should find vertex 'd'")
            #expect(found?.depth() == 2, "[\(backend)] 'd' is 2 hops from 'a'")
        }
        var g1 = AdjacencyList();   check(&g1, "default")
        var g4 = AdjacencyMatrix(); check(&g4, "Matrix")
        #if !GRAPHS_USES_TRAITS || GRAPHS_SPECIALIZED_STORAGE
        var g2 = AdjacencyList(edgeStore: CSREdgeStorage().cacheInOutEdges()); check(&g2, "CSR")
        var g3 = AdjacencyList(edgeStore: COOEdgeStorage().cacheInOutEdges()); check(&g3, "COO")
        #endif
    }

    @Test func bfsSearchDoesNotCrossDisconnectedComponent_allBackends() {
        func check<G: TestablePropertyGraph>(_ graph: inout G, _ backend: String)
        where G.VertexProperties == VertexPropertyValues, G.EdgeProperties == EdgePropertyValues,
              G.VertexDescriptor: Hashable {
            let a = graph.addVertex { $0.label = "a" }
            let b = graph.addVertex { $0.label = "b" }
            _ = graph.addVertex { $0.label = "c" }   // isolated
            graph.addEdge(from: a, to: b)

            let labels = graph.search(from: a, using: .bfs()).map { graph[$0.currentVertex].label }
            let found = Array(labels)
            #expect(found.count == 2, "[\(backend)] BFS from 'a' reaches 'a' and 'b' only")
            #expect(!found.contains("c"), "[\(backend)] isolated 'c' must not be reached")
        }
        var g1 = AdjacencyList();   check(&g1, "default")
        var g4 = AdjacencyMatrix(); check(&g4, "Matrix")
        #if !GRAPHS_USES_TRAITS || GRAPHS_SPECIALIZED_STORAGE
        var g2 = AdjacencyList(edgeStore: CSREdgeStorage().cacheInOutEdges()); check(&g2, "CSR")
        var g3 = AdjacencyList(edgeStore: COOEdgeStorage().cacheInOutEdges()); check(&g3, "COO")
        #endif
    }

    @Test func dfsSearchEmitsVerticesExactlyOnce_allBackends() {
        func check<G: TestablePropertyGraph>(_ graph: inout G, _ backend: String)
        where G.VertexProperties == VertexPropertyValues, G.EdgeProperties == EdgePropertyValues,
              G.VertexDescriptor: Hashable {
            let a = graph.addVertex { $0.label = "a" }
            let b = graph.addVertex { $0.label = "b" }
            let c = graph.addVertex { $0.label = "c" }
            graph.addEdge(from: a, to: b)
            graph.addEdge(from: a, to: c)
            graph.addEdge(from: b, to: c)   // diamond: multiple paths to c

            let labels = graph.search(from: a, using: .dfs()).map { graph[$0.currentVertex].label }
            let all = Array(labels)
            #expect(all.count == 3, "[\(backend)] each vertex visited exactly once despite multiple paths")
            #expect(Set(all) == ["a", "b", "c"], "[\(backend)] all three vertices discovered")
        }
        var g1 = AdjacencyList();   check(&g1, "default")
        var g4 = AdjacencyMatrix(); check(&g4, "Matrix")
        #if !GRAPHS_USES_TRAITS || GRAPHS_SPECIALIZED_STORAGE
        var g2 = AdjacencyList(edgeStore: CSREdgeStorage().cacheInOutEdges()); check(&g2, "CSR")
        var g3 = AdjacencyList(edgeStore: COOEdgeStorage().cacheInOutEdges()); check(&g3, "COO")
        #endif
    }
}

// MARK: - A* Search API
// These tests exercise AStarSearch — the SearchAlgorithm-conforming wrapper around the core AStar sequence.

#if !GRAPHS_USES_TRAITS || GRAPHS_PATHFINDING
struct AStarSearchTests {

    // MARK: - Core Behavior

    @Test func aStarSearchFindsTargetVertex() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        graph.addEdge(from: a, to: b) { $0.weight = 1.0 }
        graph.addEdge(from: b, to: c) { $0.weight = 1.0 }

        let found = graph.search(from: a, using: .aStar(edgeWeight: .property(\.weight), heuristic: .uniform(0)))
            .first { $0.currentVertex == c }

        #expect(found != nil, "A* via SearchAlgorithm must find c from a")
        #expect(found?.currentVertex == c)
    }

    /// A* with a uniform-0 heuristic explores vertices in ascending cost order — lower-cost neighbors first.
    @Test func aStarSearchExploreLowerCostFirst() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        graph.addEdge(from: a, to: b) { $0.weight = 1.0 }
        graph.addEdge(from: a, to: c) { $0.weight = 5.0 }

        let collected = Array(graph.search(from: a, using: .aStar(edgeWeight: .property(\.weight), heuristic: .uniform(0)))
            .map { $0.currentVertex })

        let bIdx = collected.firstIndex(of: b)!
        let cIdx = collected.firstIndex(of: c)!
        #expect(bIdx < cIdx, "A* must explore lower-cost vertex b (cost 1) before higher-cost c (cost 5)")
    }

    // MARK: - Edge Cases

    @Test func aStarSearchDoesNotReachIsolatedVertex() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let isolated = graph.addVertex { $0.label = "X" }
        graph.addEdge(from: a, to: b) { $0.weight = 1.0 }

        let found = graph.search(from: a, using: .aStar(edgeWeight: .property(\.weight), heuristic: .uniform(0)))
            .first { $0.currentVertex == isolated }

        #expect(found == nil, "A* must not reach a vertex with no incoming path from the source")
    }

    // MARK: - Multi-Backend Coverage

    @Test func aStarSearchFindsVertex_allBackends() {
        func check<G: TestablePropertyGraph>(_ graph: inout G, _ backend: String)
        where G.VertexProperties == VertexPropertyValues, G.EdgeProperties == EdgePropertyValues,
              G.VertexDescriptor: Hashable {
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            graph.addEdge(from: a, to: b) { $0.weight = 1.0 }
            graph.addEdge(from: b, to: c) { $0.weight = 1.0 }

            let found = graph.search(from: a, using: .aStar(edgeWeight: .property(\.weight), heuristic: .uniform(0)))
                .first { $0.currentVertex == c }

            #expect(found != nil, "[\(backend)] A* search must find c from a")
        }
        var g1 = AdjacencyList();   check(&g1, "default")
        var g4 = AdjacencyMatrix(); check(&g4, "Matrix")
        #if !GRAPHS_USES_TRAITS || GRAPHS_SPECIALIZED_STORAGE
        var g2 = AdjacencyList(edgeStore: CSREdgeStorage().cacheInOutEdges()); check(&g2, "CSR")
        var g3 = AdjacencyList(edgeStore: COOEdgeStorage().cacheInOutEdges()); check(&g3, "COO")
        #endif
    }
}
#endif  // !GRAPHS_USES_TRAITS || GRAPHS_PATHFINDING