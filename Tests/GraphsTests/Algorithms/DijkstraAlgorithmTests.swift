#if !GRAPHS_USES_TRAITS || GRAPHS_PATHFINDING
@testable import Graphs
import Testing

struct DijkstraTests {

    // MARK: - Core Behavior

    @Test func findsShortestPathAndFinalCosts() {
        var graph = AdjacencyList()
        let a = graph.addVertex()
        let b = graph.addVertex()
        let e = graph.addEdge(from: a, to: b) { $0.weight = 2 }!

        #expect(graph.shortestPath(from: a, to: b, using: .dijkstra(weight: .property(\.weight)))?.vertices == [a, b])

        let res = Dijkstra(on: graph, from: a, edgeWeight: .property(\.weight)).reduce(into: nil) { $0 = $1 }
        #expect(res?.distance(of: b) == 2.0)
        #expect(res?.vertices(to: b, in: graph) == [a, b])
        #expect(graph[e].weight == 2)
    }

    // MARK: - Multi-Backend Coverage

    @Test func choosesLowerCostAmongMultiplePaths_allBackends() {
        func check<G: TestablePropertyGraph>(_ graph: inout G, _ backend: String)
        where G.VertexProperties == VertexPropertyValues, G.EdgeProperties == EdgePropertyValues,
              G.VertexDescriptor: Hashable {
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            graph.addEdge(from: a, to: b) { $0.weight = 1 }
            graph.addEdge(from: a, to: c) { $0.weight = 10 }
            graph.addEdge(from: b, to: c) { $0.weight = 1 }
            let path = graph.shortestPath(from: a, to: c, using: .dijkstra(weight: .property(\.weight)))
            #expect(path?.vertices.count == 3, "[\(backend)] expected A→B→C (3 vertices)")
        }
        var g1 = AdjacencyList();   check(&g1, "default")
        var g4 = AdjacencyMatrix(); check(&g4, "Matrix")
        #if !GRAPHS_USES_TRAITS || GRAPHS_SPECIALIZED_STORAGE
        var g2 = AdjacencyList(edgeStore: CSREdgeStorage().cacheInOutEdges()); check(&g2, "CSR")
        var g3 = AdjacencyList(edgeStore: COOEdgeStorage().cacheInOutEdges()); check(&g3, "COO")
        #endif
    }

    @Test func returnsNilForUnreachableVertex_allBackends() {
        func check<G: TestablePropertyGraph>(_ graph: inout G, _ backend: String)
        where G.VertexProperties == VertexPropertyValues, G.EdgeProperties == EdgePropertyValues,
              G.VertexDescriptor: Hashable {
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let path = graph.shortestPath(from: a, to: b, using: .dijkstra(weight: .property(\.weight)))
            #expect(path == nil, "[\(backend)] expected nil for unreachable vertex")
        }
        var g1 = AdjacencyList();   check(&g1, "default")
        var g4 = AdjacencyMatrix(); check(&g4, "Matrix")
        #if !GRAPHS_USES_TRAITS || GRAPHS_SPECIALIZED_STORAGE
        var g2 = AdjacencyList(edgeStore: CSREdgeStorage().cacheInOutEdges()); check(&g2, "CSR")
        var g3 = AdjacencyList(edgeStore: COOEdgeStorage().cacheInOutEdges()); check(&g3, "COO")
        #endif
    }

    @Test func singleVertexTrivialPath_allBackends() {
        func check<G: TestablePropertyGraph>(_ graph: inout G, _ backend: String)
        where G.VertexProperties == VertexPropertyValues, G.EdgeProperties == EdgePropertyValues,
              G.VertexDescriptor: Hashable {
            let a = graph.addVertex { $0.label = "A" }
            let path = graph.shortestPath(from: a, to: a, using: .dijkstra(weight: .property(\.weight)))
            #expect(path?.vertices == [a], "[\(backend)] trivial path from vertex to itself")
        }
        var g1 = AdjacencyList();   check(&g1, "default")
        var g4 = AdjacencyMatrix(); check(&g4, "Matrix")
        #if !GRAPHS_USES_TRAITS || GRAPHS_SPECIALIZED_STORAGE
        var g2 = AdjacencyList(edgeStore: CSREdgeStorage().cacheInOutEdges()); check(&g2, "CSR")
        var g3 = AdjacencyList(edgeStore: COOEdgeStorage().cacheInOutEdges()); check(&g3, "COO")
        #endif
    }

    @Test func distancesFromSourceCorrect_allBackends() {
        func check<G: TestablePropertyGraph>(_ graph: inout G, _ backend: String)
        where G.VertexProperties == VertexPropertyValues, G.EdgeProperties == EdgePropertyValues,
              G.VertexDescriptor: Hashable {
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            graph.addEdge(from: a, to: b) { $0.weight = 3.0 }
            graph.addEdge(from: b, to: c) { $0.weight = 4.0 }
            let result = Dijkstra(on: graph, from: a, edgeWeight: .property(\.weight)).reduce(into: nil) { $0 = $1 }
            #expect(result?.distance(of: a) == .finite(0.0), "[\(backend)]")
            #expect(result?.distance(of: b) == .finite(3.0), "[\(backend)]")
            #expect(result?.distance(of: c) == .finite(7.0), "[\(backend)]")
        }
        var g1 = AdjacencyList();   check(&g1, "default")
        var g4 = AdjacencyMatrix(); check(&g4, "Matrix")
        #if !GRAPHS_USES_TRAITS || GRAPHS_SPECIALIZED_STORAGE
        var g2 = AdjacencyList(edgeStore: CSREdgeStorage().cacheInOutEdges()); check(&g2, "CSR")
        var g3 = AdjacencyList(edgeStore: COOEdgeStorage().cacheInOutEdges()); check(&g3, "COO")
        #endif
    }

    @Test func pathVerticesAndEdgesMatchEachOther_allBackends() {
        func check<G: TestablePropertyGraph>(_ graph: inout G, _ backend: String)
        where G.VertexProperties == VertexPropertyValues, G.EdgeProperties == EdgePropertyValues,
              G.VertexDescriptor: Hashable {
            let a = graph.addVertex()
            let b = graph.addVertex()
            let c = graph.addVertex()
            graph.addEdge(from: a, to: b) { $0.weight = 1 }
            graph.addEdge(from: b, to: c) { $0.weight = 1 }
            let path = graph.shortestPath(from: a, to: c, using: .dijkstra(weight: .property(\.weight)))
            #expect(path?.vertices.count == 3, "[\(backend)]")
            #expect(path?.edges.count == 2, "[\(backend)]")
        }
        var g1 = AdjacencyList();   check(&g1, "default")
        var g4 = AdjacencyMatrix(); check(&g4, "Matrix")
        #if !GRAPHS_USES_TRAITS || GRAPHS_SPECIALIZED_STORAGE
        var g2 = AdjacencyList(edgeStore: CSREdgeStorage().cacheInOutEdges()); check(&g2, "CSR")
        var g3 = AdjacencyList(edgeStore: COOEdgeStorage().cacheInOutEdges()); check(&g3, "COO")
        #endif
    }

    // MARK: - Edge Cases

    /// A self-loop (a → a) must not influence Dijkstra's path computation.
    ///
    /// The self-loop has weight 0.0, which could in theory be preferred over a real path.
    /// Dijkstra with a proper visited-set implementation must not loop on it and must still
    /// find the correct shortest path to other vertices.
    @Test func selfLoopDoesNotInfluenceShortestPath() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        graph.addEdge(from: a, to: a) { $0.weight = 0.0 }  // self-loop with weight 0
        graph.addEdge(from: a, to: b) { $0.weight = 5.0 }

        let path = graph.shortestPath(from: a, to: b, using: .dijkstra(weight: .property(\.weight)))
        #expect(path?.vertices == [a, b], "Dijkstra must find a→b, not be confused by the self-loop a→a")
        #expect(path?.vertices.count == 2)

        let result = Dijkstra(on: graph, from: a, edgeWeight: .property(\.weight)).reduce(into: nil) { $0 = $1 }
        #expect(result?.distance(of: a) == .finite(0.0), "Source distance must always be 0")
        #expect(result?.distance(of: b) == .finite(5.0), "Distance to b must be 5, not affected by self-loop")
    }

    /// When two parallel edges connect a → b, Dijkstra must pick the cheaper one.
    ///
    /// If there is an edge with weight 3 and another with weight 1 between the same pair,
    /// Dijkstra must settle on cost 1 for reaching `b`, regardless of edge iteration order.
    @Test func parallelEdgesPicksCheaperEdge() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        graph.addEdge(from: a, to: b) { $0.weight = 3.0 }  // expensive parallel edge
        graph.addEdge(from: a, to: b) { $0.weight = 1.0 }  // cheaper parallel edge
        graph.addEdge(from: b, to: c) { $0.weight = 1.0 }

        let result = Dijkstra(on: graph, from: a, edgeWeight: .property(\.weight)).reduce(into: nil) { $0 = $1 }
        #expect(result?.distance(of: b) == .finite(1.0), "Dijkstra must select the cheaper (weight=1) edge to b")
        #expect(result?.distance(of: c) == .finite(2.0), "Dijkstra must route a→b (w=1) → c (w=1) for total 2")
    }

    /// On a complete directed graph K4 (every vertex connected to every other),
    /// all-pairs reachability must hold and distances must be the direct edge weight.
    ///
    /// Since every vertex has a direct edge to every other vertex, the shortest path
    /// from any source to any destination is the single direct edge (weight = 1.0).
    @Test func completeGraphAllPairsReachable() {
        var graph = AdjacencyList()
        let vertices = (0..<4).map { _ in graph.addVertex() }

        // Add all directed edges (K4): weight = 1.0 for every edge
        for i in vertices {
            for j in vertices where i != j {
                graph.addEdge(from: i, to: j) { $0.weight = 1.0 }
            }
        }

        // From the first vertex, all others must be reachable at distance 1
        let source = vertices[0]
        let result = Dijkstra(on: graph, from: source, edgeWeight: .property(\.weight)).reduce(into: nil) { $0 = $1 }
        #expect(result?.distance(of: source) == .finite(0.0), "Source distance must be 0")
        for v in vertices.dropFirst() {
            #expect(result?.distance(of: v) == .finite(1.0), "All K4 neighbors are one direct hop away")
        }
    }
}
#endif
