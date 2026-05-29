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

    // MARK: - Result Context API Coverage

    /// `predecessor(in:)`, `predecessorEdge()`, `vertices(in:)`, `edges(in:)` and `path(in:)`
    /// are currentVertex-based convenience methods on `Dijkstra.Result`. They delegate to the
    /// explicit-vertex overloads using `currentVertex`. Only safe to call on non-source elements.
    @Test func dijkstraResultContextMethodsDuringIteration() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        graph.addEdge(from: a, to: b) { $0.weight = 1.0 }
        graph.addEdge(from: b, to: c) { $0.weight = 2.0 }

        var pathLengths: [Int] = []
        var edgeLengths: [Int] = []
        for result in Dijkstra(on: graph, from: a, edgeWeight: .property(\.weight)) {
            pathLengths.append(result.vertices(in: graph).count)
            edgeLengths.append(result.edges(in: graph).count)
            _ = result.path(in: graph)
            if result.currentVertex != a {
                _ = result.predecessor(in: graph)
                _ = result.predecessorEdge()
            }
        }

        // a: 1 vertex / 0 edges; b: 2 vertices / 1 edge; c: 3 vertices / 2 edges
        #expect(pathLengths == [1, 2, 3], "path vertex counts grow along the chain")
        #expect(edgeLengths == [0, 1, 2], "path edge counts grow along the chain")
    }

    /// `hasPath(to:)` returns true for reachable vertices and false for unreachable ones.
    /// `predecessor(of:in:)` returns the tree predecessor or nil for the source.
    @Test func dijkstraResultHasPathAndPredecessorForExplicitVertices() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let isolated = graph.addVertex { $0.label = "X" }
        graph.addEdge(from: a, to: b) { $0.weight = 1.0 }
        graph.addEdge(from: b, to: c) { $0.weight = 2.0 }

        let result = Dijkstra(on: graph, from: a, edgeWeight: .property(\.weight)).reduce(into: nil) { $0 = $1 }
        #expect(result?.hasPath(to: a) == true,  "source is always reachable")
        #expect(result?.hasPath(to: b) == true,  "b reachable via a→b")
        #expect(result?.hasPath(to: c) == true,  "c reachable via a→b→c")
        #expect(result?.hasPath(to: isolated) == false, "isolated vertex is not reachable")

        #expect(result?.predecessor(of: a, in: graph) == nil, "source has no predecessor")
        #expect(result?.predecessor(of: b, in: graph) == a,   "b's predecessor is a")
        #expect(result?.predecessor(of: c, in: graph) == b,   "c's predecessor is b")
    }

    /// `PriorityItem` is `Equatable` by vertex identity (cost is ignored in `==`).
    /// This allows the priority queue to identify items by vertex for priority updates.
    @Test func dijkstraPriorityItemEquatable() {
        var graph = AdjacencyList()
        let a = graph.addVertex()
        let b = graph.addVertex()

        let item1 = Dijkstra<DefaultAdjacencyList, Double>.PriorityItem(vertex: a, cost: .finite(1.0))
        let item2 = Dijkstra<DefaultAdjacencyList, Double>.PriorityItem(vertex: a, cost: .finite(9.0))
        let item3 = Dijkstra<DefaultAdjacencyList, Double>.PriorityItem(vertex: b, cost: .finite(1.0))

        #expect(item1 == item2, "same vertex, different cost → equal (vertex identity only)")
        #expect(item1 != item3, "different vertices → not equal")
    }

    // MARK: - Visitor Support

    /// Exercises all five Dijkstra visitor events through a composed visitor pair.
    ///
    /// Graph: a→b(1), a→c(1), b→c(5).
    /// - `examineVertex` fires for each of the 3 vertices.
    /// - `examineEdge` fires for each of the 3 edges.
    /// - `edgeRelaxed` fires for a→b and a→c (both improve their targets).
    /// - `edgeNotRelaxed` fires for b→c (c already settled at cost 1 via a→c; b→c would cost 6).
    /// - `finishVertex` fires for each of the 3 vertices.
    @Test func composedVisitorsReceiveAllEvents() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        // a→b and a→c cost 1; b→c costs 5 so c settles via a→c (dist=1), not b→c (dist=6)
        graph.addEdge(from: a, to: b) { $0.weight = 1.0 }
        graph.addEdge(from: a, to: c) { $0.weight = 1.0 }
        graph.addEdge(from: b, to: c) { $0.weight = 5.0 }

        var examined1 = 0;   var examined2 = 0
        var examEdge1 = 0;   var examEdge2 = 0
        var relaxed1 = 0;    var relaxed2 = 0
        var notRelaxed1 = 0; var notRelaxed2 = 0
        var finished1 = 0;   var finished2 = 0

        var v1 = Dijkstra<DefaultAdjacencyList, Double>.Visitor()
        v1.examineVertex  = { _ in examined1 += 1 }
        v1.examineEdge    = { _ in examEdge1 += 1 }
        v1.edgeRelaxed    = { _ in relaxed1 += 1 }
        v1.edgeNotRelaxed = { _ in notRelaxed1 += 1 }
        v1.finishVertex   = { _ in finished1 += 1 }

        var v2 = Dijkstra<DefaultAdjacencyList, Double>.Visitor()
        v2.examineVertex  = { _ in examined2 += 1 }
        v2.examineEdge    = { _ in examEdge2 += 1 }
        v2.edgeRelaxed    = { _ in relaxed2 += 1 }
        v2.edgeNotRelaxed = { _ in notRelaxed2 += 1 }
        v2.finishVertex   = { _ in finished2 += 1 }

        let combined = v1.combined(with: v2)
        Dijkstra(on: graph, from: a, edgeWeight: .property(\.weight))
            .withVisitor { combined }
            .forEach { _ in }

        #expect(examined1 == 3,    "examineVertex fires once per vertex")
        #expect(examined2 == 3)
        #expect(examEdge1 == 3,    "examineEdge fires once per edge (a→b, a→c, b→c)")
        #expect(examEdge2 == 3)
        #expect(relaxed1 == 2,     "a→b and a→c both improve their targets")
        #expect(relaxed2 == 2)
        #expect(notRelaxed1 >= 1,  "b→c does not improve c (already at cost 1)")
        #expect(notRelaxed2 >= 1)
        #expect(finished1 == 3,    "finishVertex fires once per vertex")
        #expect(finished2 == 3)
        // Both composed visitors must see identical event counts
        #expect(examined1 == examined2)
        #expect(examEdge1 == examEdge2)
        #expect(relaxed1 == relaxed2)
        #expect(notRelaxed1 == notRelaxed2)
        #expect(finished1 == finished2)
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

    // MARK: - ShortestPathUntil API

    /// `shortestPath(from:until:using:)` stops at the first vertex satisfying a condition.
    /// Unlike `shortestPath(from:to:)`, it doesn't need a specific target — it returns the
    /// first vertex for which the closure returns `true`.
    @Test func dijkstraShortestPathUntilCondition() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        graph.addEdge(from: a, to: b) { $0.weight = 1.0 }
        graph.addEdge(from: b, to: c) { $0.weight = 1.0 }
        graph.addEdge(from: c, to: d) { $0.weight = 1.0 }

        // Stop at the first vertex whose label contains "C" — should find c via a→b→c
        let path = graph.shortestPath(from: a, until: { graph[$0].label.hasPrefix("C") },
                                      using: .dijkstra(weight: .property(\.weight)))
        #expect(path != nil, "Dijkstra must find path to first vertex satisfying the condition")
        #expect(path?.destination == c, "first vertex satisfying 'label starts with C' is c")
        #expect(path?.vertices.count == 3, "path a→b→c includes all 3 intermediate vertices")
    }

    /// `shortestPath(from:until:)` returns `nil` when no vertex satisfies the condition.
    @Test func dijkstraShortestPathUntilNoMatch() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        graph.addEdge(from: a, to: b) { $0.weight = 1.0 }

        let path = graph.shortestPath(from: a, until: { graph[$0].label == "Z" },
                                      using: .dijkstra(weight: .property(\.weight)))
        #expect(path == nil, "shortestPath(until:) must return nil when no vertex satisfies the condition")
    }

    /// The default `shortestPath(from:until:weight:)` convenience uses Dijkstra implicitly.
    @Test func dijkstraShortestPathUntilConvenience() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        graph.addEdge(from: a, to: b) { $0.weight = 2.0 }
        graph.addEdge(from: b, to: c) { $0.weight = 3.0 }

        // Convenience method without explicit algorithm — uses Dijkstra by default
        let path = graph.shortestPath(from: a, until: { $0 == c }, weight: .property(\.weight))
        #expect(path != nil, "convenience shortestPath(until:weight:) must find a path")
        #expect(path?.destination == c)
        #expect(path?.vertices.count == 3, "a→b→c path includes all 3 vertices")
    }
}
#endif
