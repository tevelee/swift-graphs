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
        enum Color: Sendable {
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

        /// DFS stack frame for iterative depth-first search.
        @usableFromInline
        struct Frame {
            /// The vertex being processed.
            @usableFromInline var vertex: Vertex
            /// The parent vertex in the DFS tree.
            @usableFromInline var parentVertex: Vertex?
            /// Whether this frame is the root of the DFS tree.
            @usableFromInline var isRoot: Bool
            /// The tree edge that was used to reach this vertex (nil for root).
            @usableFromInline var treeEdgeFromParent: Edge?
            /// Outgoing edges from this vertex.
            @usableFromInline var edges: [Edge]
            /// Current index into the edges array.
            @usableFromInline var edgeIndex: Int
            /// Number of DFS tree children discovered so far.
            @usableFromInline var childCount: UInt
            /// Whether the edge back to the parent has already been skipped.
            @usableFromInline var skippedParentEdge: Bool

            @usableFromInline
            init(vertex: Vertex, parentVertex: Vertex?, isRoot: Bool, treeEdgeFromParent: Edge?, edges: [Edge]) {
                self.vertex = vertex
                self.parentVertex = parentVertex
                self.isRoot = isRoot
                self.treeEdgeFromParent = treeEdgeFromParent
                self.edges = edges
                self.edgeIndex = 0
                self.childCount = 0
                self.skippedParentEdge = false
            }
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

            var timer: UInt = 0
            var cutVertices: Set<Vertex> = []
            var bridges: [Edge] = []
            var frameStack: [Frame] = []

            for startVertex in graph.vertices() where propertyMap[startVertex][colorProperty] == .white {

                // Initialize root frame
                timer += 1
                propertyMap[startVertex][discoveryTimeProperty] = timer
                propertyMap[startVertex][lowProperty] = timer
                propertyMap[startVertex][colorProperty] = .gray
                visitor?.discoverVertex?(startVertex)

                frameStack.append(
                    Frame(
                        vertex: startVertex,
                        parentVertex: nil,
                        isRoot: true,
                        treeEdgeFromParent: nil,
                        edges: Array(graph.outgoingEdges(of: startVertex))
                    )
                )

                while !frameStack.isEmpty {
                    let frameIndex = frameStack.count - 1

                    if frameStack[frameIndex].edgeIndex < frameStack[frameIndex].edges.count {
                        let edge = frameStack[frameIndex].edges[frameStack[frameIndex].edgeIndex]
                        frameStack[frameIndex].edgeIndex += 1

                        visitor?.examineEdge?(edge)

                        guard let destination = graph.destination(of: edge) else { continue }

                        let currentVertex = frameStack[frameIndex].vertex
                        let destinationColor = propertyMap[destination][colorProperty]

                        switch destinationColor {
                            case .white:
                                // Tree edge — push child frame
                                frameStack[frameIndex].childCount += 1
                                visitor?.treeEdge?(edge)

                                timer += 1
                                propertyMap[destination][discoveryTimeProperty] = timer
                                propertyMap[destination][lowProperty] = timer
                                propertyMap[destination][colorProperty] = .gray
                                visitor?.discoverVertex?(destination)

                                frameStack.append(
                                    Frame(
                                        vertex: destination,
                                        parentVertex: currentVertex,
                                        isRoot: false,
                                        treeEdgeFromParent: edge,
                                        edges: Array(graph.outgoingEdges(of: destination))
                                    )
                                )

                            case .gray:
                                // Back edge — skip exactly one edge back to parent (handles multigraphs)
                                let parentVertex = frameStack[frameIndex].parentVertex
                                if destination == parentVertex && !frameStack[frameIndex].skippedParentEdge {
                                    frameStack[frameIndex].skippedParentEdge = true
                                } else {
                                    visitor?.backEdge?(edge)
                                    let vertexLow = propertyMap[currentVertex][lowProperty] ?? 0
                                    let destinationDiscovery = propertyMap[destination][discoveryTimeProperty] ?? 0
                                    propertyMap[currentVertex][lowProperty] = min(vertexLow, destinationDiscovery)
                                }

                            case .black:
                                // Already fully processed — can happen in undirected graphs
                                let vertexLow = propertyMap[currentVertex][lowProperty] ?? 0
                                let destinationDiscovery = propertyMap[destination][discoveryTimeProperty] ?? 0
                                propertyMap[currentVertex][lowProperty] = min(vertexLow, destinationDiscovery)
                        }
                    } else {
                        // Frame is done — finalize and pop
                        let frame = frameStack.removeLast()
                        let vertex = frame.vertex

                        // Root AP check: 2+ DFS tree children
                        if frame.isRoot && frame.childCount >= 2 {
                            if cutVertices.insert(vertex).inserted {
                                visitor?.foundArticulationPoint?(vertex)
                            }
                        }

                        propertyMap[vertex][colorProperty] = .black
                        visitor?.finishVertex?(vertex)

                        // Propagate low-link and perform AP / bridge checks on the parent
                        if !frameStack.isEmpty {
                            let parentFrameIndex = frameStack.count - 1
                            let parentVertex = frameStack[parentFrameIndex].vertex
                            let childLow = propertyMap[vertex][lowProperty] ?? 0

                            // Update parent's low-link
                            let parentLow = propertyMap[parentVertex][lowProperty] ?? 0
                            propertyMap[parentVertex][lowProperty] = min(parentLow, childLow)

                            // Non-root AP check
                            if !frameStack[parentFrameIndex].isRoot {
                                let parentDiscovery = propertyMap[parentVertex][discoveryTimeProperty] ?? 0
                                if childLow >= parentDiscovery {
                                    if cutVertices.insert(parentVertex).inserted {
                                        visitor?.foundArticulationPoint?(parentVertex)
                                    }
                                }
                            }

                            // Bridge check
                            if let treeEdge = frame.treeEdgeFromParent {
                                let parentDiscovery = propertyMap[parentVertex][discoveryTimeProperty] ?? 0
                                if childLow > parentDiscovery {
                                    bridges.append(treeEdge)
                                    visitor?.foundBridge?(treeEdge)
                                }
                            }
                        }
                    }
                }
            }

            return ArticulationPointsResult(cutVertices: cutVertices, bridges: bridges)
        }
    }
#endif
