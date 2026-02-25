#if !GRAPHS_USES_TRAITS || GRAPHS_CONNECTIVITY
/// Tarjan's algorithm for finding articulation points and bridges.
///
/// Uses a single depth-first search tracking discovery times and low-link values
/// to identify cut vertices and bridge edges in linear time.
///
/// - Complexity: O(V + E) where V is the number of vertices and E is the number of edges
public struct TarjanArticulationPoints<Graph: IncidenceGraph & VertexListGraph> where Graph.VertexDescriptor: Hashable, Graph.EdgeDescriptor: Hashable {
    /// The vertex type of the graph.
    public typealias Vertex = Graph.VertexDescriptor
    /// The edge type of the graph.
    public typealias Edge = Graph.EdgeDescriptor

    /// A visitor that can be used to observe the articulation points algorithm progress.
    public struct Visitor {
        /// Called when discovering a vertex.
        public var discoverVertex: ((Vertex) -> Void)?
        /// Called when examining an edge.
        public var examineEdge: ((Edge) -> Void)?
        /// Called when encountering a tree edge.
        public var treeEdge: ((Edge) -> Void)?
        /// Called when encountering a back edge.
        public var backEdge: ((Edge) -> Void)?
        /// Called when finishing a vertex.
        public var finishVertex: ((Vertex) -> Void)?
        /// Called when an articulation point is found.
        public var foundArticulationPoint: ((Vertex) -> Void)?
        /// Called when a bridge is found.
        public var foundBridge: ((Edge) -> Void)?

        /// Creates a new visitor.
        @inlinable
        public init(
            discoverVertex: ((Vertex) -> Void)? = nil,
            examineEdge: ((Edge) -> Void)? = nil,
            treeEdge: ((Edge) -> Void)? = nil,
            backEdge: ((Edge) -> Void)? = nil,
            finishVertex: ((Vertex) -> Void)? = nil,
            foundArticulationPoint: ((Vertex) -> Void)? = nil,
            foundBridge: ((Edge) -> Void)? = nil
        ) {
            self.discoverVertex = discoverVertex
            self.examineEdge = examineEdge
            self.treeEdge = treeEdge
            self.backEdge = backEdge
            self.finishVertex = finishVertex
            self.foundArticulationPoint = foundArticulationPoint
            self.foundBridge = foundBridge
        }
    }

    /// The color of a vertex in the algorithm.
    @usableFromInline
    enum Color {
        /// Undiscovered vertex.
        case white
        /// Discovered but not fully processed vertex.
        case gray
        /// Fully processed vertex.
        case black
    }

    /// Property for tracking vertex colors.
    @usableFromInline
    enum ColorProperty: VertexProperty {
        @usableFromInline
        static var defaultValue: Color { .white }
    }

    /// Property for tracking vertex discovery times.
    @usableFromInline
    enum DiscoveryTimeProperty: VertexProperty {
        @usableFromInline
        static var defaultValue: UInt? { nil }
    }

    /// Property for tracking vertex low-link values.
    @usableFromInline
    enum LowProperty: VertexProperty {
        @usableFromInline
        static var defaultValue: UInt? { nil }
    }

    /// Property for tracking parent vertices in the DFS tree.
    @usableFromInline
    enum ParentProperty: VertexProperty {
        @usableFromInline
        static var defaultValue: Vertex? { nil }
    }

    /// The graph to analyze.
    @usableFromInline
    let graph: Graph

    /// Creates a new Tarjan articulation points algorithm.
    ///
    /// - Parameter graph: The graph to analyze
    @inlinable
    public init(on graph: Graph) {
        self.graph = graph
    }

    /// Finds articulation points and bridges using Tarjan's algorithm.
    ///
    /// - Parameter visitor: An optional visitor to observe the algorithm progress
    /// - Returns: The articulation points result
    @inlinable
    public func articulationPoints(visitor: Visitor?) -> ArticulationPointsResult<Vertex, Edge> {
        var propertyMap = graph.makeVertexPropertyMap()
        let colorProperty = ColorProperty.self
        let discoveryTimeProperty = DiscoveryTimeProperty.self
        let lowProperty = LowProperty.self
        let parentProperty = ParentProperty.self

        var timer: UInt = 0
        var cutVertices: Set<Vertex> = []
        var bridges: [Edge] = []

        func dfs(_ vertex: Vertex, isRoot: Bool) {
            timer += 1
            propertyMap[vertex][discoveryTimeProperty] = timer
            propertyMap[vertex][lowProperty] = timer
            propertyMap[vertex][colorProperty] = .gray

            visitor?.discoverVertex?(vertex)

            var childCount: UInt = 0
            let parent = propertyMap[vertex][parentProperty]
            var skippedParentEdge = false

            for edge in graph.outgoingEdges(of: vertex) {
                visitor?.examineEdge?(edge)

                guard let destination = graph.destination(of: edge) else { continue }

                let destinationColor = propertyMap[destination][colorProperty]

                switch destinationColor {
                case .white:
                    // Tree edge
                    childCount += 1
                    propertyMap[destination][parentProperty] = vertex
                    visitor?.treeEdge?(edge)

                    dfs(destination, isRoot: false)

                    let vertexLow = propertyMap[vertex][lowProperty] ?? 0
                    let destinationLow = propertyMap[destination][lowProperty] ?? 0
                    propertyMap[vertex][lowProperty] = min(vertexLow, destinationLow)

                    // Articulation point check for non-root
                    if !isRoot {
                        let vertexDiscovery = propertyMap[vertex][discoveryTimeProperty] ?? 0
                        if destinationLow >= vertexDiscovery {
                            if cutVertices.insert(vertex).inserted {
                                visitor?.foundArticulationPoint?(vertex)
                            }
                        }
                    }

                    // Bridge check
                    let vertexDiscovery = propertyMap[vertex][discoveryTimeProperty] ?? 0
                    if destinationLow > vertexDiscovery {
                        bridges.append(edge)
                        visitor?.foundBridge?(edge)
                    }

                case .gray:
                    // Back edge — skip exactly one edge back to parent (handles multigraphs)
                    if destination == parent && !skippedParentEdge {
                        skippedParentEdge = true
                        continue
                    }
                    visitor?.backEdge?(edge)
                    let vertexLow = propertyMap[vertex][lowProperty] ?? 0
                    let destinationDiscovery = propertyMap[destination][discoveryTimeProperty] ?? 0
                    propertyMap[vertex][lowProperty] = min(vertexLow, destinationDiscovery)

                case .black:
                    // Already fully processed — can happen in undirected graphs
                    let vertexLow = propertyMap[vertex][lowProperty] ?? 0
                    let destinationDiscovery = propertyMap[destination][discoveryTimeProperty] ?? 0
                    propertyMap[vertex][lowProperty] = min(vertexLow, destinationDiscovery)
                }
            }

            // Root articulation point check: 2+ DFS tree children
            if isRoot && childCount >= 2 {
                if cutVertices.insert(vertex).inserted {
                    visitor?.foundArticulationPoint?(vertex)
                }
            }

            propertyMap[vertex][colorProperty] = .black
            visitor?.finishVertex?(vertex)
        }

        // Process all vertices
        for vertex in graph.vertices() {
            if propertyMap[vertex][colorProperty] == .white {
                dfs(vertex, isRoot: true)
            }
        }

        return ArticulationPointsResult(cutVertices: cutVertices, bridges: bridges)
    }
}
#endif
