import Testing

@testable import Graphs

struct AlgorithmObservationTests {
    @Test func selectedBreadthFirstSearchEvent() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)

        var examined: [AdjacencyList.VertexDescriptor] = []
        let result = graph.traverse(
            from: a,
            using: BFSTraversal<AdjacencyList>()
                .observing(.vertexExamined) {
                    examined.append($0)
                }
        )

        #expect(result.vertices == [a, b, c])
        #expect(examined == result.vertices)
    }

    @Test func observationsRunInAttachmentOrder() {
        var graph = AdjacencyList()
        let a = graph.addVertex()
        let b = graph.addVertex()
        graph.addEdge(from: a, to: b)

        var calls: [Int] = []
        _ = graph.traverse(
            from: a,
            using: BFSTraversal<AdjacencyList>()
                .observing(.vertexExamined) { _ in
                    calls.append(1)
                }
                .observing(.vertexExamined) { _ in
                    calls.append(2)
                }
        )

        #expect(calls == [1, 2, 1, 2])
    }

    @Test func observationDoesNotChangeTraversalResult() {
        var graph = AdjacencyList()
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)

        let baseline = graph.traverse(from: a, using: .bfs())
        let observed = graph.traverse(
            from: a,
            using: BFSTraversal<AdjacencyList>().observing { _ in }
        )

        #expect(observed.vertices == baseline.vertices)
        #expect(observed.edges == baseline.edges)
    }

    @Test func traversalPoliciesShortCircuitInAttachmentOrder() {
        var graph = AdjacencyList()
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: a, to: c)

        var firstPolicyCalls = 0
        var secondPolicyCalls = 0
        let result = graph.traverse(
            from: a,
            using: BFSTraversal<AdjacencyList>()
                .allowingTraversal { candidate in
                    firstPolicyCalls += 1
                    return candidate.to != b
                }
                .allowingTraversal { _ in
                    secondPolicyCalls += 1
                    return true
                }
        )

        #expect(result.vertices == [a, c])
        #expect(firstPolicyCalls == 2)
        #expect(secondPolicyCalls == 1)
    }

    @Test func sourceDiscoveryPrecedesExamination() {
        var graph = AdjacencyList()
        let source = graph.addVertex()
        var events: [String] = []

        BreadthFirstSearch(on: graph, from: source)
            .observing { event in
                switch event {
                    case .vertexDiscovered(let vertex) where vertex == source:
                        events.append("discovered")
                    case .vertexExamined(let vertex) where vertex == source:
                        events.append("examined")
                    default:
                        break
                }
            }
            .forEach { _ in }

        #expect(events == ["discovered", "examined"])
    }

    @Test func lazySequenceEmitsOnlyWhileConsumed() {
        var graph = AdjacencyList()
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)

        var examined: [AdjacencyList.VertexDescriptor] = []
        let search = BreadthFirstSearch(on: graph, from: a)
            .observing(.vertexExamined) {
                examined.append($0)
            }

        var iterator = search.makeIterator()
        #expect(iterator.next()?.currentVertex == a)
        #expect(examined == [a])
    }

    @Test func eachIteratorStartsIndependentAlgorithmState() {
        var graph = AdjacencyList()
        let a = graph.addVertex()
        let b = graph.addVertex()
        graph.addEdge(from: a, to: b)

        var examined: [AdjacencyList.VertexDescriptor] = []
        let search = BreadthFirstSearch(on: graph, from: a)
            .observing(.vertexExamined) {
                examined.append($0)
            }

        var first = search.makeIterator()
        var second = search.makeIterator()
        #expect(first.next()?.currentVertex == a)
        #expect(second.next()?.currentVertex == a)
        #expect(examined == [a, a])
    }

    #if !GRAPHS_USES_TRAITS || GRAPHS_PATHFINDING
        @Test func selectedDijkstraEventFlowsThroughOneShotAdapter() {
            var graph = AdjacencyList()
            let a = graph.addVertex()
            let b = graph.addVertex()
            let c = graph.addVertex()
            graph.addEdge(from: a, to: b) { $0.weight = 1.0 }
            graph.addEdge(from: b, to: c) { $0.weight = 2.0 }

            var examined: [AdjacencyList.VertexDescriptor] = []
            let path = graph.shortestPath(
                from: a,
                to: c,
                using: DijkstraShortestPathAlgorithm<AdjacencyList, Double>(weight: .property(\.weight))
                    .observing(.vertexExamined) {
                        examined.append($0)
                    }
            )

            #expect(path?.vertices == [a, b, c])
            #expect(examined.starts(with: [a, b]))
        }
    #endif
}
