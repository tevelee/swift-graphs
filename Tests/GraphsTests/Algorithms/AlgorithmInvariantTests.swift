@testable import Graphs
import Testing

/// Tests that encode mathematical laws about graph algorithms.
///
/// These invariants must hold regardless of algorithm choice or storage backend.
/// A failure here indicates a correctness bug in one or more algorithm implementations,
/// not merely a wrong expected value in a scenario test.
struct AlgorithmInvariantTests {

    // MARK: - Traversal Invariants

    /// DFS and BFS starting from the same vertex must visit the same set of reachable vertices.
    ///
    /// They explore in different orders, but reachability is a graph property independent
    /// of traversal strategy. An isolated vertex must appear in neither result.
    @Test func dfsAndBfsVisitSameReachableSet_allBackends() {
        func check<G: TestablePropertyGraph>(_ graph: inout G, _ backend: String)
        where G.VertexProperties == VertexPropertyValues, G.EdgeProperties == EdgePropertyValues,
              G.VertexDescriptor: Hashable {
            let a        = graph.addVertex { $0.label = "A" }
            let b        = graph.addVertex { $0.label = "B" }
            let c        = graph.addVertex { $0.label = "C" }
            let d        = graph.addVertex { $0.label = "D" }
            _            = graph.addVertex { $0.label = "isolated" }
            graph.addEdge(from: a, to: b)
            graph.addEdge(from: b, to: c)
            graph.addEdge(from: a, to: d)

            let dfsVertices = Set(graph.traverse(from: a, using: .dfs()).vertices)
            let bfsVertices = Set(graph.traverse(from: a, using: .bfs()).vertices)

            #expect(dfsVertices == bfsVertices,
                    "[\(backend)] DFS and BFS must visit the same reachable vertex set")
            #expect(dfsVertices.count == 4,
                    "[\(backend)] exactly 4 reachable vertices from A (not the isolated one)")
        }
        var g1 = AdjacencyList();   check(&g1, "default")
        var g4 = AdjacencyMatrix(); check(&g4, "Matrix")
        #if !GRAPHS_USES_TRAITS || GRAPHS_SPECIALIZED_STORAGE
        var g2 = AdjacencyList(edgeStore: CSREdgeStorage().cacheInOutEdges()); check(&g2, "CSR")
        var g3 = AdjacencyList(edgeStore: COOEdgeStorage().cacheInOutEdges()); check(&g3, "COO")
        #endif
    }

    /// Reversing a directed graph twice restores the original edge directions.
    ///
    /// DFS traversal on `reversed().reversed()` must produce the same vertex visit order
    /// as on the original graph, because the reachable edges are identical.
    @Test func doubleReversePreservesTraversalOrder_allBackends() {
        func check<G: TestablePropertyGraph>(_ graph: inout G, _ backend: String)
        where G.VertexProperties == VertexPropertyValues, G.EdgeProperties == EdgePropertyValues,
              G.VertexDescriptor: Hashable {
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            let d = graph.addVertex { $0.label = "D" }
            graph.addEdge(from: a, to: b)
            graph.addEdge(from: b, to: c)
            graph.addEdge(from: b, to: d)

            let original       = graph.traverse(from: a, using: .dfs())
            let doubleReversed = graph.reversed().reversed().traverse(from: a, using: .dfs())

            #expect(original.vertices == doubleReversed.vertices,
                    "[\(backend)] reversed().reversed() must produce identical DFS vertex order")
        }
        var g1 = AdjacencyList();   check(&g1, "default")
        var g4 = AdjacencyMatrix(); check(&g4, "Matrix")
        #if !GRAPHS_USES_TRAITS || GRAPHS_SPECIALIZED_STORAGE
        var g2 = AdjacencyList(edgeStore: CSREdgeStorage().cacheInOutEdges()); check(&g2, "CSR")
        var g3 = AdjacencyList(edgeStore: COOEdgeStorage().cacheInOutEdges()); check(&g3, "COO")
        #endif
    }

    // MARK: - Shortest Path Invariants

    #if !GRAPHS_USES_TRAITS || GRAPHS_PATHFINDING

    /// BFS hop-count distance equals Dijkstra distance with uniform edge weight 1.
    ///
    /// BFS finds minimum-hop paths; Dijkstra with all weights = 1 is equivalent to BFS.
    /// They must agree on every vertex's distance from the source — including unreachable
    /// vertices (both report "unreachable" / "infinite").
    @Test func bfsHopsMatchDijkstraUniformDistance_allBackends() {
        func check<G: TestablePropertyGraph>(_ graph: inout G, _ backend: String)
        where G.VertexProperties == VertexPropertyValues, G.EdgeProperties == EdgePropertyValues,
              G.VertexDescriptor: Hashable {
            let a        = graph.addVertex { $0.label = "A" }
            let b        = graph.addVertex { $0.label = "B" }
            let c        = graph.addVertex { $0.label = "C" }
            let d        = graph.addVertex { $0.label = "D" }
            let isolated = graph.addVertex { $0.label = "isolated" }
            graph.addEdge(from: a, to: b)   // depth 1
            graph.addEdge(from: b, to: c)   // depth 2
            graph.addEdge(from: a, to: d)   // depth 1 (also reachable via b→... but shorter directly)
            graph.addEdge(from: c, to: d)   // extra edge; d is still depth 1 from a

            let bfsResult      = BreadthFirstSearch(on: graph, from: a).reduce(into: nil) { $0 = $1 }
            let dijkstraResult = Dijkstra(on: graph, from: a, edgeWeight: .uniform(Double(1))).reduce(into: nil) { $0 = $1 }

            for v in [a, b, c, d, isolated] {
                let bfsDist      = bfsResult?.depth(of: v) ?? .unreachable
                let dijkstraDist = dijkstraResult?.distance(of: v) ?? Cost<Double>.infinite

                // Reachability must agree
                let bfsReachable      = bfsDist != .unreachable
                let dijkstraReachable = dijkstraDist != .infinite
                #expect(bfsReachable == dijkstraReachable,
                        "[\(backend)] BFS and Dijkstra disagree on reachability of vertex \(v)")

                // When both agree vertex is reachable, distances must match
                if case .reachable(let hops) = bfsDist, case .finite(let weight) = dijkstraDist {
                    #expect(Double(hops) == weight,
                            "[\(backend)] BFS depth \(hops) ≠ Dijkstra uniform-weight distance \(weight)")
                }
            }
        }
        var g1 = AdjacencyList();   check(&g1, "default")
        var g4 = AdjacencyMatrix(); check(&g4, "Matrix")
        #if !GRAPHS_USES_TRAITS || GRAPHS_SPECIALIZED_STORAGE
        var g2 = AdjacencyList(edgeStore: CSREdgeStorage().cacheInOutEdges()); check(&g2, "CSR")
        var g3 = AdjacencyList(edgeStore: COOEdgeStorage().cacheInOutEdges()); check(&g3, "COO")
        #endif
    }

    /// Triangle inequality: d(a, c) ≤ d(a, b) + d(b, c) for all vertex triples.
    ///
    /// This is a fundamental metric property of shortest-path distances. The inequality
    /// becomes equality precisely when b lies on an optimal path from a to c.
    @Test func shortestPathSatisfiesTriangleInequality_allBackends() {
        func check<G: TestablePropertyGraph>(_ graph: inout G, _ backend: String)
        where G.VertexProperties == VertexPropertyValues, G.EdgeProperties == EdgePropertyValues,
              G.VertexDescriptor: Hashable {
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            graph.addEdge(from: a, to: b) { $0.weight = 1.0 }
            graph.addEdge(from: b, to: c) { $0.weight = 1.0 }
            graph.addEdge(from: a, to: c) { $0.weight = 10.0 }  // suboptimal direct edge

            // Dijkstra from a: d(a,b) = 1, d(a,c) = 2 (via b), not 10 (direct)
            let fromA = Dijkstra(on: graph, from: a, edgeWeight: .property(\.weight)).reduce(into: nil) { $0 = $1 }
            // Dijkstra from b: d(b,c) = 1
            let fromB = Dijkstra(on: graph, from: b, edgeWeight: .property(\.weight)).reduce(into: nil) { $0 = $1 }

            let dAB: Cost<Double> = fromA?.distance(of: b) ?? .infinite
            let dBC: Cost<Double> = fromB?.distance(of: c) ?? .infinite
            let dAC: Cost<Double> = fromA?.distance(of: c) ?? .infinite

            // Core invariant
            #expect(dAC <= dAB + dBC,
                    "[\(backend)] triangle inequality violated: d(a,c)=\(dAC) > d(a,b)=\(dAB) + d(b,c)=\(dBC)")

            // Concrete values: Dijkstra must find the 2-hop path, ignoring the costly direct edge
            #expect(dAB  == .finite(1.0),  "[\(backend)] d(a,b) should be 1")
            #expect(dBC  == .finite(1.0),  "[\(backend)] d(b,c) should be 1")
            #expect(dAC  == .finite(2.0),  "[\(backend)] d(a,c) should be 2 via b, not 10 directly")

            // Equality holds here: d(a,c) == d(a,b) + d(b,c), confirming b is on the optimal path
            #expect(dAC == dAB + dBC,
                    "[\(backend)] b lies on the optimal path, so d(a,c) should equal d(a,b) + d(b,c)")
        }
        var g1 = AdjacencyList();   check(&g1, "default")
        var g4 = AdjacencyMatrix(); check(&g4, "Matrix")
        #if !GRAPHS_USES_TRAITS || GRAPHS_SPECIALIZED_STORAGE
        var g2 = AdjacencyList(edgeStore: CSREdgeStorage().cacheInOutEdges()); check(&g2, "CSR")
        var g3 = AdjacencyList(edgeStore: COOEdgeStorage().cacheInOutEdges()); check(&g3, "COO")
        #endif
    }

    /// A shortest path with N vertices contains exactly N−1 edges.
    ///
    /// This is a structural property of simple paths in graphs: each step from one
    /// vertex to the next consumes one edge, so a path of length k has k+1 vertices.
    @Test func pathEdgeCountIsVertexCountMinusOne_allBackends() {
        func check<G: TestablePropertyGraph>(_ graph: inout G, _ backend: String)
        where G.VertexProperties == VertexPropertyValues, G.EdgeProperties == EdgePropertyValues,
              G.VertexDescriptor: Hashable {
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            let d = graph.addVertex { $0.label = "D" }
            graph.addEdge(from: a, to: b) { $0.weight = 1.0 }
            graph.addEdge(from: b, to: c) { $0.weight = 1.0 }
            graph.addEdge(from: c, to: d) { $0.weight = 1.0 }

            let cases: [(G.VertexDescriptor, G.VertexDescriptor, Int)] = [
                (a, a, 1),  // trivial path: just the source vertex, no edges
                (a, b, 2),  // one hop
                (a, c, 3),  // two hops
                (a, d, 4),  // three hops
            ]
            for (src, dst, expectedVertexCount) in cases {
                let path = graph.shortestPath(from: src, to: dst, using: .dijkstra(weight: .property(\.weight)))
                #expect(path != nil, "[\(backend)] expected a path from \(src) to \(dst)")
                if let path {
                    #expect(path.vertices.count == expectedVertexCount,
                            "[\(backend)] \(src)→\(dst): expected \(expectedVertexCount) vertices, got \(path.vertices.count)")
                    #expect(path.edges.count == path.vertices.count - 1,
                            "[\(backend)] \(src)→\(dst): edges (\(path.edges.count)) must equal vertices (\(path.vertices.count)) minus 1")
                }
            }
        }
        var g1 = AdjacencyList();   check(&g1, "default")
        var g4 = AdjacencyMatrix(); check(&g4, "Matrix")
        #if !GRAPHS_USES_TRAITS || GRAPHS_SPECIALIZED_STORAGE
        var g2 = AdjacencyList(edgeStore: CSREdgeStorage().cacheInOutEdges()); check(&g2, "CSR")
        var g3 = AdjacencyList(edgeStore: COOEdgeStorage().cacheInOutEdges()); check(&g3, "COO")
        #endif
    }

    #endif  // !GRAPHS_USES_TRAITS || GRAPHS_PATHFINDING
}
