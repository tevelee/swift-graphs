#if !GRAPHS_USES_TRAITS || GRAPHS_OPTIMIZATION
    /// Kruskal's algorithm for finding minimum spanning trees.
    ///
    /// This algorithm finds the MST by sorting edges by weight and adding them
    /// to the MST if they don't create a cycle (using Union-Find data structure).
    ///
    /// - Complexity: O(E log E) where E is the number of edges
    public struct Kruskal<
        Graph: EdgeListGraph & IncidenceGraph & VertexListGraph,
        Weight: AdditiveArithmetic & Comparable
    >
    where
        Graph.VertexDescriptor: Hashable
    {
        /// The vertex type of the graph.
        public typealias Vertex = Graph.VertexDescriptor
        /// The edge type of the graph.
        public typealias Edge = Graph.EdgeDescriptor
        /// The event type published by Kruskal's algorithm.
        public typealias Event = MinimumSpanningTreeEvent<Vertex, Edge, Weight>

        /// The result of Kruskal's algorithm.
        @usableFromInline
        struct Result {
            @usableFromInline
            let edges: [Edge]
            @usableFromInline
            let totalWeight: Weight
            @usableFromInline
            let vertices: Set<Vertex>

            @usableFromInline
            init(edges: [Edge], totalWeight: Weight, vertices: Set<Vertex>) {
                self.edges = edges
                self.totalWeight = totalWeight
                self.vertices = vertices
            }
        }

        /// The edge weight definition.
        @usableFromInline
        let edgeWeight: CostDefinition<Graph, Weight>

        /// Creates a new Kruskal's algorithm.
        ///
        /// - Parameter edgeWeight: The cost definition for edge weights
        @inlinable
        public init(
            edgeWeight: CostDefinition<Graph, Weight>
        ) {
            self.edgeWeight = edgeWeight
        }

        /// Computes the minimum spanning tree using Kruskal's algorithm.
        ///
        /// - Parameters:
        ///   - graph: The graph to find the MST for
        ///   - observation: An optional observation of algorithm progress.
        /// - Returns: The minimum spanning tree result
        @inlinable
        public func minimumSpanningTree(
            on graph: Graph,
            observation: AlgorithmObservation<Event>? = nil
        ) -> MinimumSpanningTree<Vertex, Edge, Weight> {
            var parent: [Vertex: Vertex] = [:]
            var rank: [Vertex: Int] = [:]

            for vertex in graph.vertices() {
                parent[vertex] = vertex
                rank[vertex] = 0
            }

            func find(_ vertex: Vertex) -> Vertex {
                guard let currentParent = parent[vertex] else {
                    // Initialize if not found
                    parent[vertex] = vertex
                    return vertex
                }

                if currentParent != vertex {
                    parent[vertex] = find(currentParent)
                }
                return parent[vertex] ?? vertex
            }

            func union(_ firstVertex: Vertex, _ secondVertex: Vertex) {
                let firstRoot = find(firstVertex)
                let secondRoot = find(secondVertex)

                if firstRoot == secondRoot { return }

                let firstRank = rank[firstRoot] ?? 0
                let secondRank = rank[secondRoot] ?? 0

                if firstRank < secondRank {
                    parent[firstRoot] = secondRoot
                } else if firstRank > secondRank {
                    parent[secondRoot] = firstRoot
                } else {
                    parent[secondRoot] = firstRoot
                    rank[firstRoot] = firstRank + 1
                }
            }

            let sortedEdges = graph.edges().sorted { firstEdge, secondEdge in
                let firstWeight = edgeWeight.costToExplore(firstEdge, graph)
                let secondWeight = edgeWeight.costToExplore(secondEdge, graph)
                return firstWeight < secondWeight
            }

            var mstEdges: [Edge] = []
            var totalWeight = Weight.zero
            var mstVertices: Set<Vertex> = []

            for edge in sortedEdges {
                observation?.receive(.edgeExamined(edge))
                guard let source = graph.source(of: edge),
                    let destination = graph.destination(of: edge)
                else { continue }

                let sourceRoot = find(source)
                let destinationRoot = find(destination)

                if sourceRoot != destinationRoot {
                    mstEdges.append(edge)
                    let currentEdgeWeight = edgeWeight.costToExplore(edge, graph)
                    totalWeight += currentEdgeWeight
                    mstVertices.insert(source)
                    mstVertices.insert(destination)
                    union(source, destination)
                    observation?.receive(.edgeAdded(edge, weight: currentEdgeWeight))
                    observation?.receive(.verticesJoined(source, destination))
                } else {
                    observation?.receive(.edgeSkipped(edge, reason: "Would create cycle"))
                }
            }

            for vertex in graph.vertices() {
                mstVertices.insert(vertex)
            }

            return MinimumSpanningTree(
                edges: mstEdges,
                totalWeight: totalWeight,
                vertices: mstVertices
            )
        }
    }

#endif
