import Graphs
import Testing

private enum ObservationWeight: EdgeProperty {
    static let defaultValue = 1.0
}

extension EdgeProperties {
    fileprivate var observationWeight: Double {
        get { self[ObservationWeight.self] }
        set { self[ObservationWeight.self] = newValue }
    }
}

struct AlgorithmObservationInterfaceTests {
    @Test func observationIsOptInForConcreteAndObservedAlgorithms() {
        var graph = AdjacencyList()
        let source = graph.addVertex()
        let destination = graph.addVertex()
        graph.addEdge(from: source, to: destination)

        let algorithm = BFSTraversal<AdjacencyList>()
        let unobserved = algorithm.traverse(from: source, in: graph)

        var examined: [AdjacencyList.VertexDescriptor] = []
        let observed =
            algorithm
            .observing(.vertexExamined) { examined.append($0) }
            .traverse(from: source, in: graph)

        #expect(unobserved.vertices == [source, destination])
        #expect(observed.vertices == unobserved.vertices)
        #expect(examined == observed.vertices)
    }

    @Test func observesSelectedTraversalEventsWithoutTestableImport() {
        var graph = AdjacencyList()
        let source = graph.addVertex()
        let destination = graph.addVertex()
        graph.addEdge(from: source, to: destination)

        var examined: [AdjacencyList.VertexDescriptor] = []
        let result = graph.traverse(
            from: source,
            using: BFSTraversal<AdjacencyList>()
                .observing(.vertexExamined) {
                    examined.append($0)
                }
        )

        #expect(result.vertices == [source, destination])
        #expect(examined == result.vertices)
    }

    #if !GRAPHS_USES_TRAITS || GRAPHS_PATHFINDING
        @Test func shortestPathFactoryInfersRichDijkstraObservationPayloads() throws {
            var graph = AdjacencyList()
            let source = graph.addVertex()
            let intermediate = graph.addVertex()
            let destination = graph.addVertex()
            let firstEdge = try #require(graph.addEdge(from: source, to: intermediate) { $0.observationWeight = 2 })
            let secondEdge = try #require(graph.addEdge(from: intermediate, to: destination) { $0.observationWeight = 3 })

            var examinedVertices: [AdjacencyList.VertexDescriptor] = []
            var relaxations: [(edge: AdjacencyList.EdgeDescriptor, newCost: Double)] = []
            let path = graph.shortestPath(
                from: source,
                to: destination,
                using: .dijkstra(weight: .property(\.observationWeight))
                    .observing(.vertexExamined) { vertex in
                        examinedVertices.append(vertex)
                    }
                    .observing(.edgeRelaxed) { relaxation in
                        relaxations.append((relaxation.edge, relaxation.newCost))
                    }
            )

            #expect(path?.vertices == [source, intermediate, destination])
            #expect(examinedVertices == [source, intermediate, destination])
            #expect(relaxations.map(\.edge) == [firstEdge, secondEdge])
            #expect(relaxations.map(\.newCost) == [2, 5])
        }
    #endif
}
