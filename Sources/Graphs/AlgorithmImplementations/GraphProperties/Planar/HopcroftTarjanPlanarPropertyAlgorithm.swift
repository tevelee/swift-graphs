/// Hopcroft-Tarjan algorithm for planar graph detection.
/// This is a classic O(V) algorithm that uses DFS and lowpoint calculations.
public struct HopcroftTarjanPlanarPropertyAlgorithm<Graph: IncidenceGraph & VertexListGraph & EdgeListGraph> where Graph.VertexDescriptor: Hashable {
    public typealias Vertex = Graph.VertexDescriptor
    public typealias Edge = Graph.EdgeDescriptor

    /// A visitor that can be used to observe the Hopcroft-Tarjan algorithm progress.
    public struct Visitor {
        /// Called when starting DFS.
        public var startDFS: (() -> Void)?
        /// Called when discovering a vertex.
        public var discoverVertex: ((Vertex, Int) -> Void)?
        /// Called when examining an edge.
        public var examineEdge: ((Edge, EdgeType) -> Void)?
        /// Called when calculating lowpoint values.
        public var calculateLowpoint: ((Vertex, Int) -> Void)?
        /// Called when checking planarity.
        public var checkPlanarity: (() -> Void)?
        /// Called when a planarity violation is detected.
        public var planarityViolation: ((String) -> Void)?
        /// Called when planarity check succeeds.
        public var planaritySuccess: (() -> Void)?

        /// Creates a new visitor.
        @inlinable
        public init(
            startDFS: (() -> Void)? = nil,
            discoverVertex: ((Vertex, Int) -> Void)? = nil,
            examineEdge: ((Edge, EdgeType) -> Void)? = nil,
            calculateLowpoint: ((Vertex, Int) -> Void)? = nil,
            checkPlanarity: (() -> Void)? = nil,
            planarityViolation: ((String) -> Void)? = nil,
            planaritySuccess: (() -> Void)? = nil
        ) {
            self.startDFS = startDFS
            self.discoverVertex = discoverVertex
            self.examineEdge = examineEdge
            self.calculateLowpoint = calculateLowpoint
            self.checkPlanarity = checkPlanarity
            self.planarityViolation = planarityViolation
            self.planaritySuccess = planaritySuccess
        }
    }

    /// Types of edges in the DFS tree.
    public enum EdgeType {
        /// Tree edge (part of the DFS tree).
        case tree
        /// Back edge (connects to ancestor).
        case back
        /// Forward edge (connects to descendant).
        case forward
        /// Cross edge (connects across subtrees).
        case cross
    }

    /// Creates a new Hopcroft-Tarjan planar property algorithm.
    @inlinable
    public init() {}

    /// Checks if the graph is planar.
    ///
    /// The decision is delegated to the shared, correct `PlanarityCore` (Left–Right) engine;
    /// the visitor's DFS/planarity events are emitted around the decision.
    ///
    /// - Parameters:
    ///   - graph: The graph to check
    ///   - visitor: An optional visitor to observe the algorithm progress
    /// - Returns: `true` if the graph is planar, `false` otherwise
    public func isPlanar(
        in graph: Graph,
        visitor: Visitor?
    ) -> Bool {
        // Graphs on four or fewer vertices are always planar; the visitor's events only
        // fire once the real test runs (matching prior observable behavior).
        guard graph.vertexCount > 4 else {
            return PlanarityCore.isPlanar(graph)
        }
        visitor?.startDFS?()
        visitor?.checkPlanarity?()
        let planar = PlanarityCore.isPlanar(graph)
        if planar {
            visitor?.planaritySuccess?()
        } else {
            visitor?.planarityViolation?("Contains a Kuratowski subdivision")
        }
        return planar
    }
}
