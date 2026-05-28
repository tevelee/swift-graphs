@testable import Graphs
import Testing

/// Tests that run algorithms through graph views (`reversed()`, `filtered()`, `undirected()`).
///
/// These tests verify that the view implementations correctly transform graph structure,
/// and that algorithms running on those views observe the transformed structure.
/// A failure here indicates a bug in the view layer, not in the algorithm itself
/// (which is tested separately in its own file).
struct AlgorithmOnViewsTests {

    // MARK: - ReversedGraphView

    /// BFS on a reversed graph must follow reversed edge directions.
    ///
    /// If the original graph has `a → b → c`, BFS from `c` on the original
    /// visits only `{c}` (no outgoing edges). On the reversed graph, BFS from `c`
    /// follows `c → b → a` and visits all three vertices.
    @Test func bfsVisitsVerticesReachableViaReversedEdges() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)

        // BFS from c on ORIGINAL: c has no outgoing edges, visits {c} only
        let originalResult = graph.traverse(from: c, using: .bfs())
        #expect(originalResult.vertices == [c],
                "BFS from c on directed a→b→c should visit only c (no outgoing edges from c)")

        // BFS from c on REVERSED: reversed edges give c→b→a, visits all three
        let reversedResult = graph.reversed().traverse(from: c, using: .bfs())
        #expect(Set(reversedResult.vertices) == Set([a, b, c]),
                "BFS from c on reversed graph must reach all vertices via c→b→a")
        #expect(reversedResult.vertices.first == c,
                "BFS source c must appear first in the reversed traversal")
    }

    /// DFS from source `a` on the original graph visits all reachable vertices in the directed chain.
    /// After reversal, DFS from the ORIGINAL sink `c` reaches all vertices via reversed edges.
    @Test func dfsVisitsCorrectSubgraphAfterReversal() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        _ = graph.addVertex { $0.label = "D" }  // isolated vertex; unreachable from a in either direction
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)

        // On original: DFS from a visits a, b, c (chain follows a→b→c)
        let forwardDFS = graph.traverse(from: a, using: .dfs())
        #expect(Set(forwardDFS.vertices) == Set([a, b, c]),
                "DFS from a must visit a, b, c in the original directed chain")

        // On reversed: DFS from c visits c, b, a (chain follows c→b→a)
        let reversedDFS = graph.reversed().traverse(from: c, using: .dfs())
        #expect(Set(reversedDFS.vertices) == Set([a, b, c]),
                "DFS from c on reversed graph must visit the same 3 vertices")
    }

    // MARK: - FilteredGraphView

    /// DFS on a filtered view must skip excluded vertices and edges leading to them.
    ///
    /// If vertex `c` is filtered out, the edge `b → c` becomes invisible,
    /// so `c` never appears in the traversal result even though it exists in the base graph.
    @Test func dfsOnFilteredViewIgnoresExcludedVertices() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)  // this edge becomes invisible when c is filtered
        graph.addEdge(from: a, to: d)

        // On original: DFS visits all four vertices
        let originalDFS = graph.traverse(from: a, using: .dfs())
        #expect(Set(originalDFS.vertices) == Set([a, b, c, d]),
                "DFS on original must visit all 4 vertices")

        // Filter out c: the edge b→c disappears, so b becomes a dead end
        let filteredDFS = graph.filterVertices(where: { $0 != c }).traverse(from: a, using: .dfs())
        #expect(Set(filteredDFS.vertices) == Set([a, b, d]),
                "DFS on filtered view must visit {a,b,d} but not excluded vertex c")
        #expect(!filteredDFS.vertices.contains(c),
                "Excluded vertex c must not appear in the filtered traversal")
    }

    /// BFS on a filtered view should also respect the vertex exclusion.
    @Test func bfsOnFilteredViewIgnoresExcludedEdges() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        graph.addEdge(from: a, to: b) { $0.weight = 1.0 }
        graph.addEdge(from: a, to: c) { $0.weight = 2.0 }
        graph.addEdge(from: b, to: c) { $0.weight = 0.5 }  // this edge is filtered out below

        // Filter out any edge with weight > 1.5: only a→b and b→c remain (weights 1.0 and 0.5)
        // Edge a→c (weight 2.0) is invisible; c is still reachable via a→b→c
        let filtered = graph.filterEdges(where: { graph[$0].weight <= 1.5 })
        let bfsResult = filtered.traverse(from: a, using: .bfs())

        #expect(Set(bfsResult.vertices) == Set([a, b, c]),
                "c is still reachable via a→b→c even when the a→c edge is filtered out")
    }

    // MARK: - UndirectedGraphView

    #if !GRAPHS_USES_TRAITS || GRAPHS_CONNECTIVITY

    /// ConnectedComponents on an undirected view finds weakly connected components.
    ///
    /// With directed edges `a → b` and `c → b`, in the directed graph:
    /// - DFS from `a` visits `{a, b}` (one component)
    /// - `c` is unvisited next, forming `{c}` (second component)
    ///
    /// On the undirected view, `b`'s incoming edges become outgoing too, so DFS from `a`
    /// can now reach `c` via the reversed `c→b` edge: one single component `{a,b,c}`.
    @Test func connectedComponentsOnUndirectedViewFindsWeakComponents() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        graph.addEdge(from: a, to: b)   // directed; b is only reachable from a
        graph.addEdge(from: c, to: b)   // directed; b is also reachable from c, but c isn't from b

        // Directed: DFS from a reaches {a,b}; c starts its own component {c}
        let directedCC = graph.connectedComponents(using: .dfs())
        #expect(directedCC.componentCount == 2,
                "Directed graph has 2 weakly-connected components: {a,b} and {c}")

        // Undirected: b's incoming edges become outgoing, linking a and c
        let undirectedCC = graph.undirected().connectedComponents(using: .dfs())
        #expect(undirectedCC.componentCount == 1,
                "Undirected view has 1 component: a, b, c are all weakly connected via b")
        #expect(undirectedCC.areInSameComponent(a, c),
                "a and c must be in the same component in the undirected view")
    }

    /// Topological sort on a reversed DAG produces the reverse of the original order.
    ///
    /// For DAG `a → b → c`, the topological order is `[a, b, c]`.
    /// The reversed DAG `c → b → a` has topological order `[c, b, a]`,
    /// which is exactly the reverse of the original order.
    @Test func topologicalSortOnReversedGraphIsReverseOrder() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)

        let originalSort = graph.topologicalSort(using: .kahn())
        #expect(originalSort.isValid, "linear DAG a→b→c must have a valid topological order")
        #expect(originalSort.sortedVertices == [a, b, c],
                "topological order of a→b→c must be [a,b,c]")

        let reversedSort = graph.reversed().topologicalSort(using: .kahn())
        #expect(reversedSort.isValid, "reversed linear DAG c→b→a must still be a valid DAG")
        #expect(reversedSort.sortedVertices == [c, b, a],
                "topological order of reversed graph must be [c,b,a]")

        // Structural invariant: the reversed DAG's sort is the exact reverse of the original
        #expect(originalSort.sortedVertices == Array(reversedSort.sortedVertices.reversed()),
                "topological sort of reversed(G) must be the reverse of sort(G) for a linear DAG")
    }

    #endif  // !GRAPHS_USES_TRAITS || GRAPHS_CONNECTIVITY
}
