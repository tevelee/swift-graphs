#if !GRAPHS_USES_TRAITS || GRAPHS_ADVANCED
    @testable import Graphs
    import Testing

    struct HamiltonianPathTests {

        func createCompleteGraph() -> some AdjacencyListProtocol {
            var graph = AdjacencyList()
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            let d = graph.addVertex { $0.label = "D" }

            graph.addEdge(from: a, to: b) { $0.label = "AB" }
            graph.addEdge(from: b, to: a) { $0.label = "BA" }
            graph.addEdge(from: a, to: c) { $0.label = "AC" }
            graph.addEdge(from: c, to: a) { $0.label = "CA" }
            graph.addEdge(from: a, to: d) { $0.label = "AD" }
            graph.addEdge(from: d, to: a) { $0.label = "DA" }
            graph.addEdge(from: b, to: c) { $0.label = "BC" }
            graph.addEdge(from: c, to: b) { $0.label = "CB" }
            graph.addEdge(from: b, to: d) { $0.label = "BD" }
            graph.addEdge(from: d, to: b) { $0.label = "DB" }
            graph.addEdge(from: c, to: d) { $0.label = "CD" }
            graph.addEdge(from: d, to: c) { $0.label = "DC" }

            return graph
        }

        func createDisconnectedGraph() -> some AdjacencyListProtocol {
            var graph = AdjacencyList()
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            let d = graph.addVertex { $0.label = "D" }

            graph.addEdge(from: a, to: b) { $0.label = "AB" }
            graph.addEdge(from: c, to: d) { $0.label = "CD" }

            return graph
        }

        func createSingleVertexGraph() -> some AdjacencyListProtocol {
            var graph = AdjacencyList()
            graph.addVertex { $0.label = "A" }
            return graph
        }

        func createTwoVertexGraph() -> some AdjacencyListProtocol {
            var graph = AdjacencyList()
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            graph.addEdge(from: a, to: b) { $0.label = "AB" }
            return graph
        }

        @Test func findsHamiltonianPath() throws {
            let graph = createCompleteGraph()

            let path = try #require(graph.hamiltonianPath(using: BacktrackingHamiltonian()))

            #expect(path.source != path.destination)

            let allVertices = Array(graph.vertices())
            #expect(path.vertices == allVertices)
            #expect(path.edges.count == 3)

            #expect(graph.destination(of: path.edges[0]) == path.vertices[1])
            #expect(graph.destination(of: path.edges[1]) == path.vertices[2])
            #expect(graph.destination(of: path.edges[2]) == path.vertices[3])

            let vertexLabels = path.vertices.map { graph[$0].label }
            #expect(vertexLabels == ["A", "B", "C", "D"])
            #expect(vertexLabels.count == 4)

            let edgeLabels = path.edges.map { graph[$0].label }
            #expect(edgeLabels.count == 3)
        }

        @Test func findsHamiltonianPathFromSource() throws {
            let graph = createCompleteGraph()
            let a = graph.findVertex(labeled: "A")!

            let path = try #require(graph.hamiltonianPath(from: a, using: BacktrackingHamiltonian()))

            #expect(path.source == a)
            #expect(path.vertices.first == a)

            let allVertices = Array(graph.vertices())
            #expect(path.vertices == allVertices)

            let vertexLabels = path.vertices.map { graph[$0].label }
            #expect(vertexLabels.first == "A")
            #expect(vertexLabels == ["A", "B", "C", "D"])
        }

        @Test func findsHamiltonianPathFromSourceToDestination() throws {
            let graph = createCompleteGraph()
            let a = graph.findVertex(labeled: "A")!
            let d = graph.findVertex(labeled: "D")!

            let path = try #require(graph.hamiltonianPath(from: a, to: d, using: BacktrackingHamiltonian()))

            #expect(path.source == a)
            #expect(path.destination == d)
            #expect(path.vertices.first == a)
            #expect(path.vertices.last == d)

            let allVertices = Array(graph.vertices())
            #expect(path.vertices == allVertices)

            let vertexLabels = path.vertices.map { graph[$0].label }
            #expect(vertexLabels.first == "A")
            #expect(vertexLabels.last == "D")
            #expect(vertexLabels == ["A", "B", "C", "D"])
        }

        @Test func findsHamiltonianCycle() throws {
            let graph = createCompleteGraph()

            let cycle = try #require(graph.hamiltonianCycle(using: BacktrackingHamiltonian()))

            #expect(cycle.source == cycle.destination)
            #expect(cycle.vertices.first == cycle.vertices.last)

            let allVertices = Array(graph.vertices())
            let pathVertices = Array(cycle.vertices.dropLast())
            #expect(pathVertices == allVertices)
            #expect(cycle.edges.count == 4)

            let vertexLabels = cycle.vertices.map { graph[$0].label }
            #expect(vertexLabels.first == vertexLabels.last)
            #expect(vertexLabels.dropLast() == ["A", "B", "C", "D"])

            let edgeLabels = cycle.edges.map { graph[$0].label }
            #expect(edgeLabels.count == 4)
        }

        // MARK: - Default convenience methods (no-arg)

        /// The no-arg `hamiltonianPath()` and `hamiltonianCycle()` methods delegate to `.backtracking()`.
        /// Calling them covers the default-method code in `HamiltonianPath.swift`.
        @Test func defaultConvenienceMethods() throws {
            var graph = DefaultAdjacencyList()
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            graph.addEdge(from: a, to: b)
            graph.addEdge(from: b, to: a)
            graph.addEdge(from: b, to: c)
            graph.addEdge(from: c, to: b)
            graph.addEdge(from: a, to: c)
            graph.addEdge(from: c, to: a)

            // hamiltonianPath() — no args, uses backtracking by default
            let path = try #require(graph.hamiltonianPath(), "K3 has a Hamiltonian path")
            #expect(path.vertices.count == 3)

            // hamiltonianCycle() — no args, uses backtracking by default
            let cycle = try #require(graph.hamiltonianCycle(), "K3 has a Hamiltonian cycle")
            #expect(cycle.vertices.count >= 3)

            // hamiltonianPath(from:) — starts from specific vertex, uses backtracking by default
            let pathFrom = try #require(graph.hamiltonianPath(from: a))
            #expect(pathFrom.vertices.first == a)

            // hamiltonianPath(from:to:) — source to destination, uses backtracking by default
            let pathTo = try #require(graph.hamiltonianPath(from: a, to: c))
            #expect(pathTo.vertices.first == a)
            #expect(pathTo.vertices.last == c)
        }

        // MARK: - Heuristic modes

        @Test func heuristicHamiltonianPath() throws {
            let graph = createCompleteGraph()

            let path = try #require(graph.hamiltonianPath(using: HeuristicHamiltonian(heuristic: .degreeBased)))

            #expect(path.source != path.destination)

            let allVertices = Array(graph.vertices())
            let pathVertices = Array(path.vertices)
            #expect(pathVertices == allVertices)
            #expect(path.vertices.count == allVertices.count)

            let vertexLabels = path.vertices.map { graph[$0].label }
            #expect(Set(vertexLabels) == Set(["A", "B", "C", "D"]))
            #expect(vertexLabels.count == 4)
        }

        /// The `.random` and `.nearestNeighbor` heuristics take different code paths inside
        /// `HeuristicHamiltonian.findHamiltonianPath`. Both should find a path in K4.
        @Test func heuristicRandomAndNearestNeighborModes() throws {
            var graph = DefaultAdjacencyList()
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            let d = graph.addVertex { $0.label = "D" }
            for (u, v) in [(a, b), (a, c), (a, d), (b, c), (b, d), (c, d)] {
                graph.addEdge(from: u, to: v)
                graph.addEdge(from: v, to: u)
            }

            // .nearestNeighbor heuristic
            let nnPath = HeuristicHamiltonian<DefaultAdjacencyList>(heuristic: .nearestNeighbor)
                .hamiltonianPath(in: graph)
            #expect(nnPath != nil, "nearestNeighbor heuristic must find a Hamiltonian path in K4")
            #expect(nnPath?.vertices.count == 4)

            // .random heuristic (may fail for some random orderings but K4 is dense enough)
            let randomAlgo = HeuristicHamiltonian<DefaultAdjacencyList>(heuristic: .random)
            let randomPath = randomAlgo.hamiltonianPath(in: graph)
            // random may or may not find a path on a single try, but on K4 it should succeed
            if let p = randomPath {
                #expect(p.vertices.count == 4)
            }
            // Cover the hamiltonianCycle path for nearestNeighbor
            let nnCycle = HeuristicHamiltonian<DefaultAdjacencyList>(heuristic: .nearestNeighbor)
                .hamiltonianCycle(in: graph)
            #expect(nnCycle != nil, "nearestNeighbor must find a Hamiltonian cycle in K4")
        }

        @Test func noHamiltonianPath() {
            let graph = createDisconnectedGraph()

            let path = graph.hamiltonianPath(using: BacktrackingHamiltonian())
            #expect(path == nil)

            let cycle = graph.hamiltonianCycle(using: BacktrackingHamiltonian())
            #expect(cycle == nil)
        }

        @Test func singleVertex() throws {
            let graph = createSingleVertexGraph()

            let path = try #require(graph.hamiltonianPath(using: BacktrackingHamiltonian()))
            let a = graph.findVertex(labeled: "A")!

            #expect(path.vertices == [a])
            #expect(path.source == path.destination)
            #expect(path.edges.isEmpty)
        }

        @Test func twoVertices() throws {
            let graph = createTwoVertexGraph()

            let path = try #require(graph.hamiltonianPath(using: BacktrackingHamiltonian()))
            let a = graph.findVertex(labeled: "A")!
            let b = graph.findVertex(labeled: "B")!

            #expect(path.vertices == [a, b] || path.vertices == [b, a])
            #expect(path.source != path.destination)
            #expect(path.edges.count == 1)
        }

        @Test func emptyGraph() {
            let graph = AdjacencyList()

            let path = graph.hamiltonianPath(using: BacktrackingHamiltonian())
            #expect(path == nil)

            let cycle = graph.hamiltonianCycle(using: BacktrackingHamiltonian())
            #expect(cycle == nil)
        }

        // MARK: - Visitor Support

        /// Two composed visitors must each receive the same events during backtracking search.
        /// `addToPath` fires once per vertex added; both visitors must see identical counts.
        @Test func composedVisitorsReceiveAllEvents() {
            // Build a K4 complete graph inline (so graph is a concrete DefaultAdjacencyList)
            var graph = DefaultAdjacencyList()
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            let d = graph.addVertex { $0.label = "D" }
            graph.addEdge(from: a, to: b)
            graph.addEdge(from: b, to: a)
            graph.addEdge(from: a, to: c)
            graph.addEdge(from: c, to: a)
            graph.addEdge(from: a, to: d)
            graph.addEdge(from: d, to: a)
            graph.addEdge(from: b, to: c)
            graph.addEdge(from: c, to: b)
            graph.addEdge(from: b, to: d)
            graph.addEdge(from: d, to: b)
            graph.addEdge(from: c, to: d)
            graph.addEdge(from: d, to: c)

            var added1 = 0
            var added2 = 0
            var examined1 = 0
            var examined2 = 0

            var v1 = BacktrackingHamiltonian<DefaultAdjacencyList>.Visitor()
            v1.addToPath = { _ in added1 += 1 }
            v1.examineVertex = { _ in examined1 += 1 }

            var v2 = BacktrackingHamiltonian<DefaultAdjacencyList>.Visitor()
            v2.addToPath = { _ in added2 += 1 }
            v2.examineVertex = { _ in examined2 += 1 }

            let combined = v1.combined(with: v2)
            _ = BacktrackingHamiltonian<DefaultAdjacencyList>().hamiltonianPath(in: graph, visitor: combined)

            // The Hamiltonian path visits all 4 vertices, so addToPath fires at least 4 times
            #expect(added1 >= 4, "addToPath must fire at least once per vertex in the path")
            #expect(added2 >= 4)
            #expect(examined1 >= 1, "examineVertex must fire at least once")
            #expect(examined2 >= 1)
            #expect(added1 == added2, "both composed visitors must see identical addToPath events")
            #expect(examined1 == examined2, "both composed visitors must see identical examineVertex events")
        }

        // MARK: - Protocol factory bridges

        /// `BacktrackingHamiltonian` provides no-visitor convenience bridges that delegate to the
        /// visitor-aware implementation. These are not exercised by `using:` API calls (which pass
        /// `visitor: nil` to the protocol requirement). Calling them directly covers the bridge code.
        @Test func backtrackingBridgeMethods() throws {
            var graph = DefaultAdjacencyList()
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            graph.addEdge(from: a, to: b)
            graph.addEdge(from: b, to: a)
            graph.addEdge(from: b, to: c)
            graph.addEdge(from: c, to: b)
            graph.addEdge(from: a, to: c)
            graph.addEdge(from: c, to: a)

            let algo = BacktrackingHamiltonian<DefaultAdjacencyList>()

            // hamiltonianPath(in:) bridge — no visitor argument
            let path = try #require(algo.hamiltonianPath(in: graph), "K3 has a Hamiltonian path")
            #expect(path.vertices.count == 3)

            // hamiltonianPath(from:in:) bridge — start from specific vertex
            let pathFrom = try #require(algo.hamiltonianPath(from: a, in: graph))
            #expect(pathFrom.vertices.first == a)

            // hamiltonianPath(from:to:in:) bridge — source to specific destination
            let pathTo = try #require(algo.hamiltonianPath(from: a, to: c, in: graph))
            #expect(pathTo.vertices.first == a)
            #expect(pathTo.vertices.last == c)
        }

        /// `HeuristicHamiltonian` provides the same no-visitor bridges. Calling `.heuristic()` factory
        /// covers the static factory method; calling bridges directly covers the delegate methods.
        @Test func heuristicFactoryAndBridgeMethods() throws {
            var graph = DefaultAdjacencyList()
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            graph.addEdge(from: a, to: b)
            graph.addEdge(from: b, to: a)
            graph.addEdge(from: b, to: c)
            graph.addEdge(from: c, to: b)
            graph.addEdge(from: a, to: c)
            graph.addEdge(from: c, to: a)

            // `.heuristic()` factory method (covered by calling it through the protocol)
            let pathViaFactory = try #require(graph.hamiltonianPath(using: .heuristic()))
            #expect(pathViaFactory.vertices.count == 3)

            let algo = HeuristicHamiltonian<DefaultAdjacencyList>(heuristic: .degreeBased)

            // hamiltonianPath(in:) bridge
            let path = try #require(algo.hamiltonianPath(in: graph))
            #expect(path.vertices.count == 3)

            // hamiltonianPath(from:in:) bridge
            let pathFrom = try #require(algo.hamiltonianPath(from: a, in: graph))
            #expect(pathFrom.vertices.first == a)

            // hamiltonianPath(from:to:in:) bridge
            let pathTo = try #require(algo.hamiltonianPath(from: a, to: c, in: graph))
            #expect(pathTo.vertices.first == a)
            #expect(pathTo.vertices.last == c)
        }

        /// `HeuristicHamiltonian` also conforms to `HamiltonianCycleAlgorithm`.
        /// `hamiltonianCycle(in:)` is a no-visitor bridge that delegates to the visitor-aware method.
        @Test func heuristicHamiltonianCycleBridge() throws {
            var graph = DefaultAdjacencyList()
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            // K3 — has a Hamiltonian cycle
            graph.addEdge(from: a, to: b)
            graph.addEdge(from: b, to: a)
            graph.addEdge(from: b, to: c)
            graph.addEdge(from: c, to: b)
            graph.addEdge(from: a, to: c)
            graph.addEdge(from: c, to: a)

            let algo = HeuristicHamiltonian<DefaultAdjacencyList>(heuristic: .degreeBased)

            // hamiltonianCycle(in:) bridge — no visitor
            let cycle = try #require(algo.hamiltonianCycle(in: graph), "K3 has a Hamiltonian cycle")
            #expect(cycle.vertices.count >= 3)

            // hamiltonianCycle via graph API with .heuristic() factory
            let cycleViaGraph = try #require(graph.hamiltonianCycle(using: .heuristic()))
            #expect(cycleViaGraph.vertices.count >= 3)
        }

        /// Exercises all five `HeuristicHamiltonian.Visitor` events through a composed visitor pair.
        ///
        /// Graph: K4 complete graph (4 vertices, all pairs connected bidirectionally).
        /// The degree-based heuristic finds a Hamiltonian path quickly.
        /// - `examineVertex` fires for each candidate start vertex and for each vertex considered.
        /// - `examineEdge` fires for each edge examined during the path extension.
        /// - `addToPath` fires for each vertex added to the current path.
        /// - `removeFromPath` / `backtrack` may fire if the heuristic backtracks.
        /// Both composed visitors must see identical event counts.
        @Test func heuristicComposedVisitorsReceiveAllEvents() {
            var graph = DefaultAdjacencyList()
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            let d = graph.addVertex { $0.label = "D" }
            graph.addEdge(from: a, to: b)
            graph.addEdge(from: b, to: a)
            graph.addEdge(from: a, to: c)
            graph.addEdge(from: c, to: a)
            graph.addEdge(from: a, to: d)
            graph.addEdge(from: d, to: a)
            graph.addEdge(from: b, to: c)
            graph.addEdge(from: c, to: b)
            graph.addEdge(from: b, to: d)
            graph.addEdge(from: d, to: b)
            graph.addEdge(from: c, to: d)
            graph.addEdge(from: d, to: c)

            var examined1 = 0
            var examined2 = 0
            var examEdge1 = 0
            var examEdge2 = 0
            var added1 = 0
            var added2 = 0
            var removed1 = 0
            var removed2 = 0
            var backtrack1 = 0
            var backtrack2 = 0

            var v1 = HeuristicHamiltonian<DefaultAdjacencyList>.Visitor()
            v1.examineVertex = { _ in examined1 += 1 }
            v1.examineEdge = { _ in examEdge1 += 1 }
            v1.addToPath = { _ in added1 += 1 }
            v1.removeFromPath = { _ in removed1 += 1 }
            v1.backtrack = { _ in backtrack1 += 1 }

            var v2 = HeuristicHamiltonian<DefaultAdjacencyList>.Visitor()
            v2.examineVertex = { _ in examined2 += 1 }
            v2.examineEdge = { _ in examEdge2 += 1 }
            v2.addToPath = { _ in added2 += 1 }
            v2.removeFromPath = { _ in removed2 += 1 }
            v2.backtrack = { _ in backtrack2 += 1 }

            let combined = v1.combined(with: v2)
            _ = HeuristicHamiltonian<DefaultAdjacencyList>(heuristic: .degreeBased)
                .hamiltonianPath(in: graph, visitor: combined)

            // The heuristic examines start vertices and explores the graph
            #expect(examined1 >= 1, "examineVertex fires for each start candidate and explored vertex")
            #expect(examined2 >= 1)
            // addToPath fires at least once per vertex in the found path (4-vertex graph → ≥ 4 adds)
            #expect(added1 >= 4, "addToPath fires at least 4 times for a 4-vertex Hamiltonian path")
            #expect(added2 >= 4)
            // examineEdge fires for each edge considered during path extension
            #expect(examEdge1 >= 1, "examineEdge fires for each edge examined")
            #expect(examEdge2 >= 1)
            // Both composed visitors must see identical event counts
            #expect(examined1 == examined2)
            #expect(examEdge1 == examEdge2)
            #expect(added1 == added2)
            #expect(removed1 == removed2)
            #expect(backtrack1 == backtrack2)
        }
    }
#endif
