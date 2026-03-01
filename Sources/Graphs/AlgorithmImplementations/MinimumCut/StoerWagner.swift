#if !GRAPHS_USES_TRAITS || GRAPHS_OPTIMIZATION
/// Stoer-Wagner algorithm for finding the global minimum cut of an undirected weighted graph.
///
/// The algorithm works by repeatedly performing a "minimum cut phase" using maximum adjacency ordering,
/// then contracting the last two vertices. After V-1 phases, the lightest cut-of-the-phase is the global minimum cut.
///
/// - Complexity: O(V³) — each of the V-1 phases performs a linear scan over V vertices to find the most tightly connected one.
/// - Note: This algorithm assumes an undirected graph. For directed graphs, apply the `.undirected()` view first.
public struct StoerWagner<
    Graph: EdgeListGraph & IncidenceGraph & VertexListGraph,
    Weight: Numeric & Comparable
> where
    Graph.VertexDescriptor: Hashable,
    Graph.EdgeDescriptor: Hashable
{
    /// The vertex type of the graph.
    public typealias Vertex = Graph.VertexDescriptor
    /// The edge type of the graph.
    public typealias Edge = Graph.EdgeDescriptor

    /// A visitor that can be used to observe Stoer-Wagner algorithm progress.
    public struct Visitor {
        /// Called at the start of each minimum cut phase.
        public var startPhase: ((Int) -> Void)?
        /// Called when a vertex is added to the ordering with its connectivity weight.
        public var addVertex: ((Vertex, Weight) -> Void)?
        /// Called when a phase completes with its cut-of-the-phase weight.
        public var phaseComplete: ((Int, Weight) -> Void)?
        /// Called when two vertices are merged (contracted).
        public var mergeVertices: ((Vertex, Vertex) -> Void)?
        /// Called when a new best minimum cut is found.
        public var newMinimumCut: ((Weight) -> Void)?

        /// Creates a new visitor.
        @inlinable
        public init(
            startPhase: ((Int) -> Void)? = nil,
            addVertex: ((Vertex, Weight) -> Void)? = nil,
            phaseComplete: ((Int, Weight) -> Void)? = nil,
            mergeVertices: ((Vertex, Vertex) -> Void)? = nil,
            newMinimumCut: ((Weight) -> Void)? = nil
        ) {
            self.startPhase = startPhase
            self.addVertex = addVertex
            self.phaseComplete = phaseComplete
            self.mergeVertices = mergeVertices
            self.newMinimumCut = newMinimumCut
        }
    }

    /// The edge weight definition.
    @usableFromInline
    let edgeWeight: CostDefinition<Graph, Weight>

    /// Creates a new Stoer-Wagner algorithm.
    ///
    /// - Parameter edgeWeight: The cost definition for edge weights
    @inlinable
    public init(edgeWeight: CostDefinition<Graph, Weight>) {
        self.edgeWeight = edgeWeight
    }

    /// Internal representation of the contracted graph for vertex merging without mutating the input.
    @usableFromInline
    struct ContractedGraph {
        /// The super-vertices still active in the contracted graph.
        @usableFromInline
        var activeVertices: Set<Vertex>
        /// Combined edge weights between super-vertices: adjacency[u][v] = total weight.
        @usableFromInline
        var adjacency: [Vertex: [Vertex: Weight]]
        /// Original vertices contained in each super-vertex.
        @usableFromInline
        var members: [Vertex: Set<Vertex>]

        @usableFromInline
        init(activeVertices: Set<Vertex>, adjacency: [Vertex: [Vertex: Weight]], members: [Vertex: Set<Vertex>]) {
            self.activeVertices = activeVertices
            self.adjacency = adjacency
            self.members = members
        }
    }

    /// Computes the global minimum cut using the Stoer-Wagner algorithm.
    ///
    /// - Parameters:
    ///   - graph: The undirected weighted graph
    ///   - visitor: An optional visitor to observe algorithm progress
    /// - Returns: The minimum cut result, or `nil` if the graph has fewer than 2 vertices
    @inlinable
    public func minimumCut(on graph: Graph, visitor: Visitor? = nil) -> MinimumCutResult<Vertex, Edge, Weight>? {
        let allVertices = Array(graph.vertices())
        guard allVertices.count >= 2 else { return nil }

        // Build the contracted graph from the input graph's adjacency
        var contracted = buildContractedGraph(from: graph, vertices: allVertices)

        var bestCutWeight: Weight?
        var bestPartition: Set<Vertex>?

        var phase = 0
        while contracted.activeVertices.count > 1 {
            visitor?.startPhase?(phase)

            let (s, t, cutOfPhaseWeight) = minimumCutPhase(contracted: &contracted, visitor: visitor)

            visitor?.phaseComplete?(phase, cutOfPhaseWeight)

            // Track the best (minimum) cut
            if bestCutWeight == nil || cutOfPhaseWeight < bestCutWeight! {
                bestCutWeight = cutOfPhaseWeight
                bestPartition = contracted.members[t]
                visitor?.newMinimumCut?(cutOfPhaseWeight)
            }

            // Merge t into s
            mergeVertices(s: s, t: t, in: &contracted)
            visitor?.mergeVertices?(s, t)

            phase += 1
        }

        guard bestCutWeight != nil, let partition = bestPartition else { return nil }

        // Build the two partitions from original vertices
        let partitionB = partition
        let partitionA = Set(allVertices).subtracting(partitionB)

        // Find the cut edges and compute the actual cut weight from all directed edges crossing the partition
        let (cutEdges, actualCutWeight) = findCutEdgesAndWeight(in: graph, partitionA: partitionA, partitionB: partitionB)

        return MinimumCutResult(
            cutWeight: actualCutWeight,
            partitionA: partitionA,
            partitionB: partitionB,
            cutEdges: cutEdges
        )
    }

    /// Builds the initial contracted graph from the input graph.
    @inlinable
    func buildContractedGraph(from graph: Graph, vertices: [Vertex]) -> ContractedGraph {
        var adjacency: [Vertex: [Vertex: Weight]] = [:]
        var members: [Vertex: Set<Vertex>] = [:]
        let activeVertices = Set(vertices)

        for vertex in vertices {
            adjacency[vertex] = [:]
            members[vertex] = [vertex]
        }

        // Build symmetric adjacency from outgoing edges
        for vertex in vertices {
            for edge in graph.outgoingEdges(of: vertex) {
                guard let destination = graph.destination(of: edge) else { continue }
                guard activeVertices.contains(destination) else { continue }
                guard vertex != destination else { continue }
                let weight = edgeWeight.costToExplore(edge, graph)
                let current = adjacency[vertex]?[destination] ?? Weight.zero
                adjacency[vertex, default: [:]][destination] = current + weight
            }
        }

        return ContractedGraph(activeVertices: activeVertices, adjacency: adjacency, members: members)
    }

    /// Performs one minimum cut phase: maximum adjacency ordering.
    ///
    /// Returns the last two vertices (s, t) in the ordering and the cut-of-the-phase weight.
    @inlinable
    func minimumCutPhase(contracted: inout ContractedGraph, visitor: Visitor?) -> (s: Vertex, t: Vertex, cutWeight: Weight) {
        let active = contracted.activeVertices
        var inOrdering = Set<Vertex>()

        // Start with an arbitrary vertex
        let current = active.first!
        inOrdering.insert(current)
        visitor?.addVertex?(current, Weight.zero)

        // Track connectivity of each vertex to the already-ordered set
        var connectivity: [Vertex: Weight] = [:]
        for vertex in active where vertex != current {
            connectivity[vertex] = contracted.adjacency[current]?[vertex] ?? Weight.zero
        }

        var s = current
        var t = current
        var cutOfPhaseWeight = Weight.zero

        while inOrdering.count < active.count {
            // Find the vertex outside the ordering with maximum connectivity
            var bestVertex: Vertex?
            var bestWeight = Weight.zero
            var first = true

            for (vertex, weight) in connectivity {
                if first || weight > bestWeight {
                    bestVertex = vertex
                    bestWeight = weight
                    first = false
                }
            }

            guard let next = bestVertex else { break }

            s = t
            t = next
            cutOfPhaseWeight = bestWeight

            inOrdering.insert(next)
            connectivity[next] = nil
            visitor?.addVertex?(next, bestWeight)

            // Update connectivity for remaining vertices
            if let neighbors = contracted.adjacency[next] {
                for (neighbor, weight) in neighbors where connectivity[neighbor] != nil {
                    connectivity[neighbor] = (connectivity[neighbor] ?? Weight.zero) + weight
                }
            }
        }

        return (s, t, cutOfPhaseWeight)
    }

    /// Merges vertex t into vertex s in the contracted graph.
    @inlinable
    func mergeVertices(s: Vertex, t: Vertex, in contracted: inout ContractedGraph) {
        // Combine adjacency: for each neighbor of t, add its weight to s's neighbor
        if let tNeighbors = contracted.adjacency[t] {
            for (neighbor, weight) in tNeighbors {
                guard neighbor != s else { continue }
                let currentSN = contracted.adjacency[s]?[neighbor] ?? Weight.zero
                contracted.adjacency[s, default: [:]][neighbor] = currentSN + weight
                let currentNS = contracted.adjacency[neighbor]?[s] ?? Weight.zero
                contracted.adjacency[neighbor, default: [:]][s] = currentNS + weight
                // Remove t from neighbor's adjacency
                contracted.adjacency[neighbor]?[t] = nil
            }
        }

        // Remove t's adjacency entry and s->t edge
        contracted.adjacency[t] = nil
        contracted.adjacency[s]?[t] = nil

        // Merge members
        let tMembers = contracted.members[t] ?? []
        contracted.members[s, default: []].formUnion(tMembers)
        contracted.members[t] = nil

        // Remove t from active vertices
        contracted.activeVertices.remove(t)
    }

    /// Finds edges in the original graph that cross between the two partitions and computes their total weight.
    @inlinable
    func findCutEdgesAndWeight(in graph: Graph, partitionA: Set<Vertex>, partitionB: Set<Vertex>) -> (edges: [Edge], weight: Weight) {
        var cutEdges: [Edge] = []
        var totalWeight = Weight.zero
        for edge in graph.edges() {
            guard let source = graph.source(of: edge),
                  let destination = graph.destination(of: edge) else { continue }
            if (partitionA.contains(source) && partitionB.contains(destination))
                || (partitionB.contains(source) && partitionA.contains(destination))
            {
                cutEdges.append(edge)
                totalWeight = totalWeight + edgeWeight.costToExplore(edge, graph)
            }
        }
        return (cutEdges, totalWeight)
    }
}

extension StoerWagner: VisitorSupporting {}
#endif
