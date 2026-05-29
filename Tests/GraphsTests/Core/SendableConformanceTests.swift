@testable import Graphs
import Testing

/// Compile-time and runtime checks that graph types and storage backends conform to `Sendable`
/// and therefore can safely cross actor / `Task` boundaries.
///
/// Every test passes a value into a `Task.detached` closure — the compiler enforces `Sendable`
/// at the call-site, making a build failure the canonical RED signal. Runtime assertions
/// confirm the value was received intact.
struct SendableConformanceTests {

    // MARK: - Storage backends (no trait guard, always compiled)

    @Test func orderedVertexStorageIsSendable() async {
        var store = OrderedVertexStorage()
        _ = store.addVertex()
        _ = store.addVertex()
        let count = await Task.detached { store.vertexCount }.value
        #expect(count == 2)
    }

    @Test func orderedEdgeStorageIsSendable() async {
        var store = OrderedEdgeStorage<Int>()
        _ = store.addEdge(from: 1, to: 2)
        let count = await Task.detached { store.edgeCount }.value
        #expect(count == 1)
    }

    @Test func cacheInOutEdgesIsSendable() async {
        var store = CacheInOutEdges(base: OrderedEdgeStorage<Int>())
        _ = store.addEdge(from: 1, to: 2)
        let count = await Task.detached { store.edgeCount }.value
        #expect(count == 1)
    }

    #if !GRAPHS_USES_TRAITS || GRAPHS_SPECIALIZED_STORAGE
    @Test func csrEdgeStorageIsSendable() async {
        var store = CSREdgeStorage<Int>()
        _ = store.addEdge(from: 1, to: 2)
        let count = await Task.detached { store.edgeCount }.value
        #expect(count == 1)
    }

    @Test func cooEdgeStorageIsSendable() async {
        var store = COOEdgeStorage<Int>()
        _ = store.addEdge(from: 1, to: 2)
        let count = await Task.detached { store.edgeCount }.value
        #expect(count == 1)
    }
    #endif

    // MARK: - InlineGraph (no trait guard)

    @Test func inlineGraphIsSendable() async {
        var graph = InlineGraph<String, SimpleEdge<String>>()
        graph.addEdge(from: "A", to: "B")
        let count = await Task.detached { graph.edgeCount }.value
        #expect(count == 1)
    }

    // MARK: - Default AdjacencyList (no trait gate, always compiled)

    @Test func defaultAdjacencyListIsSendable() async {
        var graph = AdjacencyList()
        let a = graph.addVertex()
        let b = graph.addVertex()
        graph.addEdge(from: a, to: b)
        let count = await Task.detached { graph.edgeCount }.value
        #expect(count == 1, "default AdjacencyList must cross Task boundaries safely")
    }

    // MARK: - GridGraph (trait-gated)

    #if !GRAPHS_USES_TRAITS || GRAPHS_GRID_GRAPH
    @Test func gridGraphIsSendable() async {
        let grid = GridGraph(width: 3, height: 3, allowedDirections: .orthogonal)
        let count = await Task.detached { grid.vertexCount }.value
        #expect(count == 9)
    }
    #endif

    // MARK: - CompleteGraph (trait-gated)

    #if !GRAPHS_USES_TRAITS || GRAPHS_COMPLETE_GRAPH
    @Test func completeGraphIsSendable() async {
        let graph = CompleteGraph(vertices: [1, 2, 3])
        let count = await Task.detached { graph.vertexCount }.value
        #expect(count == 3)
    }
    #endif
}


// Static assertion: if this function compiles the default AdjacencyList() satisfies Sendable.
// It is never called at runtime.
@inline(never)
private func _assertDefaultAdjacencyListIsSendable() {
    func require<T: Sendable>(_: T.Type) {}
    require(type(of: AdjacencyList()))
}
