#if !GRAPHS_USES_TRAITS || GRAPHS_ADVANCED
    @testable import Graphs
    import Testing

    struct EulerianPathTests {

        func createEulerianPathGraph() -> AdjacencyList {
            var graph = AdjacencyList()
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            let d = graph.addVertex { $0.label = "D" }

            graph.addEdge(from: a, to: b) { $0.label = "AB" }
            graph.addEdge(from: b, to: c) { $0.label = "BC" }
            graph.addEdge(from: c, to: d) { $0.label = "CD" }
            graph.addEdge(from: d, to: a) { $0.label = "DA" }
            graph.addEdge(from: a, to: c) { $0.label = "AC" }

            return graph
        }

        func createEulerianCycleGraph() -> AdjacencyList {
            var graph = AdjacencyList()
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            let d = graph.addVertex { $0.label = "D" }

            graph.addEdge(from: a, to: b) { $0.label = "AB" }
            graph.addEdge(from: b, to: c) { $0.label = "BC" }
            graph.addEdge(from: c, to: d) { $0.label = "CD" }
            graph.addEdge(from: d, to: a) { $0.label = "DA" }

            return graph
        }

        func createNoEulerianPathGraph() -> AdjacencyList {
            var graph = AdjacencyList()
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            let d = graph.addVertex { $0.label = "D" }

            graph.addEdge(from: a, to: b) { $0.label = "AB" }
            graph.addEdge(from: b, to: c) { $0.label = "BC" }
            graph.addEdge(from: c, to: d) { $0.label = "CD" }
            graph.addEdge(from: d, to: a) { $0.label = "DA" }
            graph.addEdge(from: a, to: c) { $0.label = "AC" }
            graph.addEdge(from: b, to: d) { $0.label = "BD" }

            return graph
        }

        func createSingleVertexGraph() -> AdjacencyList {
            var graph = AdjacencyList()
            graph.addVertex { $0.label = "A" }
            return graph
        }

        @Test func detectsEulerianPath() {
            let graph = createEulerianPathGraph()

            #expect(graph.hasEulerianPath())
            #expect(!graph.hasEulerianCycle())
        }

        @Test func detectsEulerianCycle() {
            let graph = createEulerianCycleGraph()

            #expect(graph.hasEulerianPath())
            #expect(graph.hasEulerianCycle())
        }

        @Test func findsEulerianPath() throws {
            let graph = createEulerianPathGraph()

            let path = try #require(graph.eulerianPath(using: Hierholzer()))

            #expect(path.source != path.destination)
            #expect(path.edges.count == 5)
            #expect(graph.destination(of: path.edges[0]) == path.vertices[1])
            #expect(graph.destination(of: path.edges[1]) == path.vertices[2])
            #expect(graph.destination(of: path.edges[2]) == path.vertices[3])
            #expect(graph.destination(of: path.edges[3]) == path.vertices[4])
            #expect(graph.destination(of: path.edges[4]) == path.vertices[5])

            let vertexLabels = path.vertices.map { graph[$0].label }
            #expect(vertexLabels == ["A", "B", "C", "D", "A", "C"])

            let edgeLabels = path.edges.map { graph[$0].label }
            #expect(edgeLabels == ["AB", "BC", "CD", "DA", "AC"])
        }

        @Test func findsEulerianCycle() throws {
            let graph = createEulerianCycleGraph()

            let cycle = try #require(graph.eulerianCycle(using: Hierholzer()))

            #expect(cycle.source == cycle.destination)
            #expect(cycle.vertices.first == cycle.vertices.last)
            #expect(cycle.edges.count == 4)

            #expect(graph.destination(of: cycle.edges[0]) == cycle.vertices[1])
            #expect(graph.destination(of: cycle.edges[1]) == cycle.vertices[2])
            #expect(graph.destination(of: cycle.edges[2]) == cycle.vertices[3])
            #expect(graph.destination(of: cycle.edges[3]) == cycle.vertices[4])

            let vertexLabels = cycle.vertices.map { graph[$0].label }
            #expect(vertexLabels == ["A", "B", "C", "D", "A"])

            let edgeLabels = cycle.edges.map { graph[$0].label }
            #expect(edgeLabels == ["AB", "BC", "CD", "DA"])
        }

        @Test func noEulerianPath() {
            let graph = createNoEulerianPathGraph()

            #expect(!graph.hasEulerianPath())
            #expect(!graph.hasEulerianCycle())

            let path = graph.eulerianPath(using: Hierholzer())
            #expect(path == nil)
        }

        @Test func singleVertex() throws {
            let graph = createSingleVertexGraph()

            #expect(graph.hasEulerianPath())
            #expect(graph.hasEulerianCycle())

            let path = try #require(graph.eulerianPath(using: Hierholzer()))

            let a = graph.findVertex(labeled: "A")!
            #expect(path.vertices == [a])
            #expect(path.edges.isEmpty)
            #expect(path.source == path.destination)
        }

        @Test func emptyGraph() {
            let graph = AdjacencyList()

            #expect(!graph.hasEulerianPath())
            #expect(!graph.hasEulerianCycle())

            let path = graph.eulerianPath(using: Hierholzer())
            #expect(path == nil)
        }

        // MARK: - Observation Support

        /// Two observations must each receive the same edge-added events —
        /// one per edge in the Eulerian cycle, and a vertex-examined event at least once.
        @Test func composedObservationsReceiveAllEvents() {
            var graph = AdjacencyList()
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            let d = graph.addVertex { $0.label = "D" }
            // Eulerian cycle a→b→c→d→a (each vertex has in-degree == out-degree == 1)
            graph.addEdge(from: a, to: b) { $0.label = "AB" }
            graph.addEdge(from: b, to: c) { $0.label = "BC" }
            graph.addEdge(from: c, to: d) { $0.label = "CD" }
            graph.addEdge(from: d, to: a) { $0.label = "DA" }

            var edgesAdded1 = 0
            var edgesAdded2 = 0
            var examined1 = 0
            var examined2 = 0

            let observed = Hierholzer<AdjacencyList>()
                .observing(Hierholzer<AdjacencyList>.EventCases.edgeAddedToPath) { _ in edgesAdded1 += 1 }
                .observing(Hierholzer<AdjacencyList>.EventCases.vertexExamined) { _ in examined1 += 1 }
                .observing(Hierholzer<AdjacencyList>.EventCases.edgeAddedToPath) { _ in edgesAdded2 += 1 }
                .observing(Hierholzer<AdjacencyList>.EventCases.vertexExamined) { _ in examined2 += 1 }
            _ = graph.eulerianCycle(using: observed)

            #expect(edgesAdded1 == 4, "addEdgeToPath must fire once per edge in the 4-cycle")
            #expect(edgesAdded2 == 4)
            #expect(examined1 >= 1, "examineVertex must fire at least once")
            #expect(examined2 >= 1)
            #expect(edgesAdded1 == edgesAdded2, "both observations must see identical edge-added events")
            #expect(examined1 == examined2, "both observations must see identical vertex-examined events")
        }
    }
#endif
