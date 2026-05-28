@testable import Graphs
import Testing

struct MemoizedGraphTests {

    // MARK: - Helpers

    /// A reference counter for tracking closure invocations.
    private final class CallCounter {
        var count: Int = 0
    }

    /// Builds a `LazyIncidenceGraph` whose edge closure increments `counter` on every call.
    private func countingLazyGraph(
        edges edgeMap: [Int: [Int]],
        counter: CallCounter
    ) -> LazyIncidenceGraph<Int, SimpleEdge<Int>, [SimpleEdge<Int>]> {
        LazyIncidenceGraph(edges: { v -> [SimpleEdge<Int>] in
            counter.count += 1
            return (edgeMap[v] ?? []).map { SimpleEdge(source: v, destination: $0) }
        })
    }

    // MARK: - Memoization correctness

    @Test func outgoingEdgesMatchBase() {
        let counter = CallCounter()
        let base = countingLazyGraph(edges: [0: [1, 2], 1: [2], 2: []], counter: counter)
        let memo = base.memoized()

        for v in 0...2 {
            let baseEdges = Array(base.outgoingEdges(of: v)).map(\.destination)
            let memoEdges = memo.outgoingEdges(of: v).map(\.destination)
            #expect(baseEdges == memoEdges)
        }
    }

    @Test func eachVertexQueriedOnce() {
        let counter = CallCounter()
        let base = countingLazyGraph(edges: [0: [1], 1: [2]], counter: counter)
        let memo = base.memoized()

        _ = memo.outgoingEdges(of: 0)
        _ = memo.outgoingEdges(of: 0)  // cache hit
        _ = memo.outgoingEdges(of: 1)
        _ = memo.outgoingEdges(of: 1)  // cache hit

        #expect(counter.count == 2)
    }

    @Test func differentVerticesQueriedSeparately() {
        let counter = CallCounter()
        let base = countingLazyGraph(edges: [0: [1], 1: [2], 2: []], counter: counter)
        let memo = base.memoized()

        _ = memo.outgoingEdges(of: 0)
        _ = memo.outgoingEdges(of: 1)
        _ = memo.outgoingEdges(of: 2)
        _ = memo.outgoingEdges(of: 0)  // cached
        _ = memo.outgoingEdges(of: 2)  // cached

        #expect(counter.count == 3)
    }

    // MARK: - invalidate

    @Test func invalidateForcesRecomputation() {
        let counter = CallCounter()
        let base = countingLazyGraph(edges: [0: [1]], counter: counter)
        let memo = base.memoized()

        _ = memo.outgoingEdges(of: 0)
        #expect(counter.count == 1)

        memo.invalidate()
        _ = memo.outgoingEdges(of: 0)
        #expect(counter.count == 2)
    }

    // MARK: - Shared cache across copies

    @Test func copiesShareCache() {
        let counter = CallCounter()
        let base = countingLazyGraph(edges: [0: [1]], counter: counter)
        let memo1 = base.memoized()
        let memo2 = memo1  // struct copy — same cache reference

        _ = memo1.outgoingEdges(of: 0)
        _ = memo2.outgoingEdges(of: 0)  // should be a cache hit

        #expect(counter.count == 1)
    }

    // MARK: - Degree

    @Test func outDegreeMatchesEdgeCount() {
        let base = countingLazyGraph(edges: [0: [1, 2, 3], 1: []], counter: CallCounter())
        let memo = base.memoized()

        #expect(memo.outDegree(of: 0) == 3)
        #expect(memo.outDegree(of: 1) == 0)
    }

    // MARK: - BidirectionalGraph

    @Test func incomingEdgesMemoized() {
        var graph = AdjacencyList()
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: c, to: b)
        graph.addEdge(from: a, to: c)

        let memo = graph.memoized()

        #expect(memo.incomingEdges(of: b).count == 2)
        #expect(memo.inDegree(of: b) == 2)
        #expect(memo.inDegree(of: a) == 0)

        // Second call should use the cache (no crash / same result)
        #expect(memo.incomingEdges(of: b).count == 2)
    }

    // MARK: - VertexListGraph / EdgeListGraph forwarding

    #if !GRAPHS_USES_TRAITS || GRAPHS_COMPLETE_GRAPH
    @Test func verticesForwarded() {
        let g = CompleteGraph(count: 4).memoized()
        #expect(g.vertexCount == 4)
        #expect(Array(g.vertices()) == [0, 1, 2, 3])
    }

    @Test func edgesForwarded() {
        let g = CompleteGraph(count: 3).memoized()
        #expect(g.edgeCount == 6)
        #expect(Array(g.edges()).count == 6)
    }
    #endif

    // MARK: - AdjacencyGraph

    @Test func adjacentVerticesUseCachedEdges() {
        let counter = CallCounter()
        let base = countingLazyGraph(edges: [0: [1, 2]], counter: counter)
        let memo = base.memoized()

        let adj = memo.adjacentVertices(of: 0)
        _ = memo.adjacentVertices(of: 0)  // second call — edges already cached

        #expect(adj == [1, 2])
        #expect(counter.count == 1)  // underlying graph queried only once
    }

    // MARK: - source / destination accessors

    @Test func sourceAndDestinationForwarded() {
        let base = countingLazyGraph(edges: [0: [1]], counter: CallCounter())
        let memo = base.memoized()
        let edge = memo.outgoingEdges(of: 0)[0]

        #expect(memo.source(of: edge) == 0)
        #expect(memo.destination(of: edge) == 1)
    }
}
