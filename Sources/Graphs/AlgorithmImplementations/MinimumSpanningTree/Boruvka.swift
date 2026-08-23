#if !GRAPHS_USES_TRAITS || GRAPHS_OPTIMIZATION
    /// Borůvka's algorithm for finding minimum spanning trees.
    ///
    /// This algorithm finds the MST by repeatedly finding the minimum weight edge
    /// for each component and adding them to the MST, then merging components.
    ///
    /// - Complexity: O(E log V) where E is the number of edges and V is the number of vertices
    public struct Boruvka<
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
        /// The event type published by Boruvka's algorithm.
        public typealias Event = MinimumSpanningTreeEvent<Vertex, Edge, Weight>

        /// The result of Borůvka's algorithm.
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

        /// Creates a new Borůvka's algorithm.
        ///
        /// - Parameter edgeWeight: The cost definition for edge weights
        @inlinable
        public init(
            edgeWeight: CostDefinition<Graph, Weight>
        ) {
            self.edgeWeight = edgeWeight
        }

        /// Computes the minimum spanning tree using Borůvka's algorithm.
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
            // Union-Find data structure
            var parent: [Vertex: Vertex] = [:]
            var rank: [Vertex: Int] = [:]

            // Initialize all vertices as separate components
            for vertex in graph.vertices() {
                parent[vertex] = vertex
                rank[vertex] = 0
            }

            // Find root with path compression
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

            // Union by rank
            func union(_ x: Vertex, _ y: Vertex) {
                let rootX = find(x)
                let rootY = find(y)

                if rootX == rootY { return }

                let rankX = rank[rootX] ?? 0
                let rankY = rank[rootY] ?? 0

                if rankX < rankY {
                    parent[rootX] = rootY
                } else if rankX > rankY {
                    parent[rootY] = rootX
                } else {
                    parent[rootY] = rootX
                    rank[rootX] = rankX + 1
                }
            }

            var mstEdges: [Edge] = []
            var totalWeight = Weight.zero
            var mstVertices: Set<Vertex> = []

            // Get all edges
            let allEdges = Array(graph.edges())

            // Report every edge before the merge phases begin.
            for edge in allEdges {
                observation?.receive(.edgeExamined(edge))
            }

            var iteration = 0
            // Repeat until we have one component or no more edges
            while mstEdges.count < graph.vertexCount - 1 && !allEdges.isEmpty {
                // Find minimum weight edge for each component
                var componentMinEdges: [Vertex: (Edge, Weight)] = [:]

                for edge in allEdges {
                    guard let source = graph.source(of: edge),
                        let destination = graph.destination(of: edge)
                    else { continue }

                    let sourceRoot = find(source)
                    let destRoot = find(destination)

                    // Skip if both vertices are in the same component
                    if sourceRoot == destRoot { continue }

                    let edgeWeight = edgeWeight.costToExplore(edge, graph)

                    // Update minimum edge for source component
                    if let existing = componentMinEdges[sourceRoot] {
                        if edgeWeight < existing.1 {
                            componentMinEdges[sourceRoot] = (edge, edgeWeight)
                        }
                    } else {
                        componentMinEdges[sourceRoot] = (edge, edgeWeight)
                    }

                    // Update minimum edge for destination component
                    if let existing = componentMinEdges[destRoot] {
                        if edgeWeight < existing.1 {
                            componentMinEdges[destRoot] = (edge, edgeWeight)
                        }
                    } else {
                        componentMinEdges[destRoot] = (edge, edgeWeight)
                    }
                }

                // Add minimum edges to MST
                var addedAnyEdge = false
                for (_, (edge, edgeWeight)) in componentMinEdges {
                    guard let source = graph.source(of: edge),
                        let destination = graph.destination(of: edge)
                    else { continue }

                    let sourceRoot = find(source)
                    let destRoot = find(destination)

                    // Skip if both vertices are now in the same component
                    if sourceRoot == destRoot {
                        observation?.receive(.edgeSkipped(edge, reason: "Vertices already in same component"))
                        continue
                    }

                    // Add edge to MST
                    mstEdges.append(edge)
                    totalWeight += edgeWeight
                    mstVertices.insert(source)
                    mstVertices.insert(destination)
                    union(source, destination)
                    observation?.receive(.edgeAdded(edge, weight: edgeWeight))
                    observation?.receive(.verticesJoined(source, destination))
                    addedAnyEdge = true
                }

                observation?.receive(.componentMergeFinished(iteration))
                iteration += 1

                // If no edges were added, break to avoid infinite loop
                if !addedAnyEdge { break }
            }

            let result = MinimumSpanningTree(
                edges: mstEdges,
                totalWeight: totalWeight,
                vertices: mstVertices
            )

            return result
        }
    }

#endif
