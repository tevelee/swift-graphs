// MARK: - Observation-Free Algorithm Operations

// Swift does not permit default arguments on protocol requirements. These
// overloads keep observation opt-in while preserving an explicit observation
// parameter in every algorithm witness.

extension AllShortestPathsAlgorithm {
    /// Finds all shortest paths without observing algorithm events.
    @inlinable
    public func allShortestPaths(
        from source: Graph.VertexDescriptor,
        to destination: Graph.VertexDescriptor,
        in graph: Graph
    ) -> [Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>] {
        allShortestPaths(from: source, to: destination, in: graph, observation: nil)
    }
}

extension AllShortestPathsUntilAlgorithm {
    /// Finds all shortest paths to matching vertices without observing algorithm events.
    @inlinable
    public func allShortestPaths(
        from source: Graph.VertexDescriptor,
        until condition: @escaping (Graph.VertexDescriptor) -> Bool,
        in graph: Graph
    ) -> [Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>] {
        allShortestPaths(from: source, until: condition, in: graph, observation: nil)
    }
}

extension ArticulationPointsAlgorithm {
    /// Finds articulation points and bridges without observing algorithm events.
    @inlinable
    public func articulationPoints(
        in graph: Graph
    ) -> ArticulationPointsResult<Graph.VertexDescriptor, Graph.EdgeDescriptor> {
        articulationPoints(in: graph, observation: nil)
    }
}

extension CentralityAlgorithm {
    /// Computes centrality without observing algorithm events.
    @inlinable
    public func centrality(in graph: Graph) -> CentralityResult<Graph.VertexDescriptor> {
        centrality(in: graph, observation: nil)
    }
}

extension CliqueDetectionAlgorithm {
    /// Finds maximal cliques without observing algorithm events.
    @inlinable
    public func findCliques(in graph: Graph) -> CliqueDetectionResult<Graph.VertexDescriptor> {
        findCliques(in: graph, observation: nil)
    }
}

extension ColoringAlgorithm {
    /// Colors a graph without observing algorithm events.
    @inlinable
    public func color(graph: Graph) -> GraphColoring<Graph.VertexDescriptor, Color> {
        color(graph: graph, observation: nil)
    }
}

extension CommunityDetectionAlgorithm {
    /// Detects communities without observing algorithm events.
    @inlinable
    public func detectCommunities(in graph: Graph) -> CommunityDetectionResult<Graph.VertexDescriptor> {
        detectCommunities(in: graph, observation: nil)
    }
}

extension ConnectedComponentsAlgorithm {
    /// Finds connected components without observing algorithm events.
    @inlinable
    public func connectedComponents(in graph: Graph) -> ConnectedComponentsResult<Graph.VertexDescriptor> {
        connectedComponents(in: graph, observation: nil)
    }
}

extension EulerianPathAlgorithm {
    /// Finds an Eulerian path without observing algorithm events.
    @inlinable
    public func eulerianPath(in graph: Graph) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
        eulerianPath(in: graph, observation: nil)
    }
}

extension EulerianCycleAlgorithm {
    /// Finds an Eulerian cycle without observing algorithm events.
    @inlinable
    public func eulerianCycle(in graph: Graph) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
        eulerianCycle(in: graph, observation: nil)
    }
}

extension BipartitePropertyAlgorithm {
    /// Checks bipartiteness without observing algorithm events.
    @inlinable
    public func isBipartite(in graph: Graph) -> Bool {
        isBipartite(in: graph, observation: nil)
    }
}

extension ConnectedPropertyAlgorithm {
    /// Checks connectivity without observing algorithm events.
    @inlinable
    public func isConnected(in graph: Graph) -> Bool {
        isConnected(in: graph, observation: nil)
    }
}

extension CyclicPropertyAlgorithm {
    /// Checks cyclicity without observing algorithm events.
    @inlinable
    public func isCyclic(in graph: Graph) -> Bool {
        isCyclic(in: graph, observation: nil)
    }
}

extension DiracPropertyAlgorithm {
    /// Checks Dirac's condition without observing algorithm events.
    @inlinable
    public func satisfiesDirac(in graph: Graph) -> Bool {
        satisfiesDirac(in: graph, observation: nil)
    }
}

extension OrePropertyAlgorithm {
    /// Checks Ore's condition without observing algorithm events.
    @inlinable
    public func satisfiesOre(in graph: Graph) -> Bool {
        satisfiesOre(in: graph, observation: nil)
    }
}

extension PlanarPropertyAlgorithm {
    /// Checks planarity without observing algorithm events.
    @inlinable
    public func isPlanar(in graph: Graph) -> Bool {
        isPlanar(in: graph, observation: nil)
    }
}

extension TreePropertyAlgorithm {
    /// Checks whether a graph is a tree without observing algorithm events.
    @inlinable
    public func isTree(in graph: Graph) -> Bool {
        isTree(in: graph, observation: nil)
    }
}

extension HamiltonianPathAlgorithm {
    /// Finds a Hamiltonian path without observing algorithm events.
    @inlinable
    public func hamiltonianPath(in graph: Graph) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
        hamiltonianPath(in: graph, observation: nil)
    }

    /// Finds a Hamiltonian path from a source without observing algorithm events.
    @inlinable
    public func hamiltonianPath(
        from source: Graph.VertexDescriptor,
        in graph: Graph
    ) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
        hamiltonianPath(from: source, in: graph, observation: nil)
    }

    /// Finds a Hamiltonian path between two vertices without observing algorithm events.
    @inlinable
    public func hamiltonianPath(
        from source: Graph.VertexDescriptor,
        to destination: Graph.VertexDescriptor,
        in graph: Graph
    ) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
        hamiltonianPath(from: source, to: destination, in: graph, observation: nil)
    }
}

extension HamiltonianCycleAlgorithm {
    /// Finds a Hamiltonian cycle without observing algorithm events.
    @inlinable
    public func hamiltonianCycle(in graph: Graph) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
        hamiltonianCycle(in: graph, observation: nil)
    }
}

extension IsomorphismAlgorithm {
    /// Checks graph isomorphism without observing algorithm events.
    @inlinable
    public func areIsomorphic(_ graph1: Graph, _ graph2: Graph) -> Bool {
        areIsomorphic(graph1, graph2, observation: nil)
    }

    /// Finds an isomorphism without observing algorithm events.
    @inlinable
    public func findIsomorphism(
        _ graph1: Graph,
        _ graph2: Graph
    ) -> [Graph.VertexDescriptor: Graph.VertexDescriptor]? {
        findIsomorphism(graph1, graph2, observation: nil)
    }
}

extension KShortestPathsAlgorithm {
    /// Finds the k shortest paths without observing algorithm events.
    @inlinable
    public func kShortestPaths(
        from source: Graph.VertexDescriptor,
        to destination: Graph.VertexDescriptor,
        k: Int,
        in graph: Graph
    ) -> [Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>] {
        kShortestPaths(from: source, to: destination, k: k, in: graph, observation: nil)
    }
}

extension MatchingAlgorithm {
    /// Finds a maximum matching without observing algorithm events.
    @inlinable
    public func maximumMatching(in graph: Graph) -> MatchingResult<Graph.VertexDescriptor, Graph.EdgeDescriptor> {
        maximumMatching(in: graph, observation: nil)
    }
}

extension MaxFlowAlgorithm {
    /// Computes maximum flow without observing algorithm events.
    @inlinable
    public func maximumFlow(
        from source: Graph.VertexDescriptor,
        to sink: Graph.VertexDescriptor,
        in graph: Graph
    ) -> MaxFlowResult<Graph.VertexDescriptor, Graph.EdgeDescriptor, Flow> {
        maximumFlow(from: source, to: sink, in: graph, observation: nil)
    }
}

extension MinCostFlowAlgorithm {
    /// Computes minimum-cost flow without observing algorithm events.
    @inlinable
    public func minimumCostFlow(
        from source: Graph.VertexDescriptor,
        to sink: Graph.VertexDescriptor,
        demand: Value?,
        in graph: Graph
    ) -> MinCostFlowResult<Graph.VertexDescriptor, Graph.EdgeDescriptor, Value> {
        minimumCostFlow(from: source, to: sink, demand: demand, in: graph, observation: nil)
    }
}

extension MinimumCutAlgorithm {
    /// Computes a minimum cut without observing algorithm events.
    @inlinable
    public func minimumCut(
        in graph: Graph
    ) -> MinimumCutResult<Graph.VertexDescriptor, Graph.EdgeDescriptor, Weight>? {
        minimumCut(in: graph, observation: nil)
    }
}

extension MinimumSpanningTreeAlgorithm {
    /// Computes a minimum spanning tree without observing algorithm events.
    @inlinable
    public func minimumSpanningTree(
        in graph: Graph
    ) -> MinimumSpanningTree<Graph.VertexDescriptor, Graph.EdgeDescriptor, Weight> {
        minimumSpanningTree(in: graph, observation: nil)
    }
}

extension PlanarDrawingAlgorithm {
    /// Computes a planar drawing without observing algorithm events.
    @inlinable
    public func planarDrawing(in graph: Graph) -> PlanarDrawing<Graph.VertexDescriptor>? {
        planarDrawing(in: graph, observation: nil)
    }
}

extension PlanarEmbeddingAlgorithm {
    /// Computes a planar embedding without observing algorithm events.
    @inlinable
    public func planarEmbedding(in graph: Graph) -> PlanarEmbeddingResult<Graph.VertexDescriptor> {
        planarEmbedding(in: graph, observation: nil)
    }
}

extension RandomGraphAlgorithm {
    /// Appends a random graph without observing algorithm events.
    @inlinable
    public func appendRandomGraph<RNG: RandomNumberGenerator>(
        into graph: inout Graph,
        vertexCount: Int,
        using generator: inout RNG
    ) {
        appendRandomGraph(into: &graph, vertexCount: vertexCount, using: &generator, observation: nil)
    }
}

extension SearchAlgorithm {
    /// Creates a search sequence without observing algorithm events.
    @inlinable
    public func search(
        from source: Graph.VertexDescriptor,
        in graph: Graph
    ) -> SearchSequence {
        search(from: source, in: graph, observation: nil)
    }
}

extension ShortestPathAlgorithm {
    /// Finds a shortest path without observing algorithm events.
    @inlinable
    public func shortestPath(
        from source: Graph.VertexDescriptor,
        to destination: Graph.VertexDescriptor,
        in graph: Graph
    ) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
        shortestPath(from: source, to: destination, in: graph, observation: nil)
    }
}

extension ShortestPathUntilAlgorithm {
    /// Finds a shortest path to a matching vertex without observing algorithm events.
    @inlinable
    public func shortestPath(
        from source: Graph.VertexDescriptor,
        until condition: @escaping (Graph.VertexDescriptor) -> Bool,
        in graph: Graph
    ) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
        shortestPath(from: source, until: condition, in: graph, observation: nil)
    }
}

extension ShortestPathsForAllPairsAlgorithm {
    /// Computes all-pairs shortest paths without observing algorithm events.
    @inlinable
    public func shortestPathsForAllPairs(
        in graph: Graph
    ) -> AllPairsShortestPaths<Graph.VertexDescriptor, Graph.EdgeDescriptor, Weight> {
        shortestPathsForAllPairs(in: graph, observation: nil)
    }
}

extension SingleSourceShortestPathAlgorithm {
    /// Computes single-source shortest paths without observing algorithm events.
    @inlinable
    public func shortestPaths(
        from source: Graph.VertexDescriptor,
        in graph: Graph
    ) -> SingleSourceShortestPaths<Graph.VertexDescriptor, Graph.EdgeDescriptor, Weight> {
        shortestPaths(from: source, in: graph, observation: nil)
    }
}

extension StronglyConnectedComponentsAlgorithm {
    /// Finds strongly connected components without observing algorithm events.
    @inlinable
    public func stronglyConnectedComponents(
        in graph: Graph
    ) -> StronglyConnectedComponentsResult<Graph.VertexDescriptor> {
        stronglyConnectedComponents(in: graph, observation: nil)
    }
}

extension TopologicalSortAlgorithm {
    /// Computes a topological order without observing algorithm events.
    @inlinable
    public func topologicalSort(in graph: Graph) -> TopologicalSortResult<Graph.VertexDescriptor> {
        topologicalSort(in: graph, observation: nil)
    }
}

extension TraversalAlgorithm {
    /// Traverses a graph without observing algorithm events.
    @inlinable
    public func traverse(
        from source: Graph.VertexDescriptor,
        in graph: Graph
    ) -> TraversalResult<Graph.VertexDescriptor, Graph.EdgeDescriptor> {
        traverse(from: source, in: graph, observation: nil)
    }
}

extension VertexOrderingAlgorithm {
    /// Orders graph vertices without observing algorithm events.
    @inlinable
    public func orderVertices(in graph: Graph) -> [Graph.VertexDescriptor] {
        orderVertices(in: graph, observation: nil)
    }
}
