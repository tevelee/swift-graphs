#if !GRAPHS_USES_TRAITS || GRAPHS_CONNECTIVITY
import OrderedCollections

/// Tarjan's algorithm for finding strongly connected components.
///
/// Tarjan's algorithm finds strongly connected components in a directed graph
/// using a single depth-first search with a stack to track the current path.
///
/// - Complexity: O(V + E) where V is the number of vertices and E is the number of edges
public struct Tarjan<Graph: IncidenceGraph & VertexListGraph> where Graph.VertexDescriptor: Hashable {
    /// The vertex type of the graph.
    public typealias Vertex = Graph.VertexDescriptor
    /// The edge type of the graph.
    public typealias Edge = Graph.EdgeDescriptor

    /// A visitor that can be used to observe Tarjan's algorithm progress.
    public struct Visitor {
        /// Called when discovering a vertex.
        public var discoverVertex: ((Vertex) -> Void)?
        /// Called when examining an edge.
        public var examineEdge: ((Edge) -> Void)?
        /// Called when encountering a back edge.
        public var backEdge: ((Edge) -> Void)?
        /// Called when encountering a cross edge.
        public var crossEdge: ((Edge) -> Void)?
        /// Called when finishing a vertex.
        public var finishVertex: ((Vertex) -> Void)?
        /// Called when starting a new component.
        public var startComponent: ((Vertex) -> Void)?
        /// Called when finishing a component.
        public var finishComponent: (([Vertex]) -> Void)?

        /// Creates a new visitor.
        @inlinable
        public init(
            discoverVertex: ((Vertex) -> Void)? = nil,
            examineEdge: ((Edge) -> Void)? = nil,
            backEdge: ((Edge) -> Void)? = nil,
            crossEdge: ((Edge) -> Void)? = nil,
            finishVertex: ((Vertex) -> Void)? = nil,
            startComponent: ((Vertex) -> Void)? = nil,
            finishComponent: (([Vertex]) -> Void)? = nil
        ) {
            self.discoverVertex = discoverVertex
            self.examineEdge = examineEdge
            self.backEdge = backEdge
            self.crossEdge = crossEdge
            self.finishVertex = finishVertex
            self.startComponent = startComponent
            self.finishComponent = finishComponent
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

    /// Property for tracking vertex indices.
    @usableFromInline
    enum IndexProperty: VertexProperty {
        @usableFromInline
        static var defaultValue: UInt? { nil }
    }

    /// Property for tracking vertex low links.
    @usableFromInline
    enum LowLinkProperty: VertexProperty {
        @usableFromInline
        static var defaultValue: UInt? { nil }
    }

    /// Property for tracking if vertex is on stack.
    @usableFromInline
    enum OnStackProperty: VertexProperty {
        @usableFromInline
        static var defaultValue: Bool { false }
    }

    /// DFS stack frame for iterative depth-first search.
    @usableFromInline
    struct Frame {
        /// The vertex being processed.
        @usableFromInline var vertex: Vertex
        /// Outgoing edges from this vertex.
        @usableFromInline var edges: [Edge]
        /// Current index into the edges array.
        @usableFromInline var edgeIndex: Int

        @usableFromInline
        init(vertex: Vertex, edges: [Edge]) {
            self.vertex = vertex
            self.edges = edges
            self.edgeIndex = 0
        }
    }

    /// The graph to find SCCs in.
    @usableFromInline
    let graph: Graph

    /// Creates a new Tarjan's algorithm.
    ///
    /// - Parameter graph: The graph to find SCCs in
    @inlinable
    public init(on graph: Graph) {
        self.graph = graph
    }

    /// Finds strongly connected components using Tarjan's algorithm.
    ///
    /// - Parameter visitor: An optional visitor to observe the algorithm progress
    /// - Returns: The strongly connected components result
    @inlinable
    public func stronglyConnectedComponents(visitor: Visitor?) -> StronglyConnectedComponentsResult<Vertex> {
        var propertyMap = graph.makeVertexPropertyMap()
        let colorProperty = ColorProperty.self
        let indexProperty = IndexProperty.self
        let lowLinkProperty = LowLinkProperty.self
        let onStackProperty = OnStackProperty.self

        var index: UInt = 0
        var sccStack: [Vertex] = []
        var frameStack: [Frame] = []
        var components: [[Vertex]] = []

        for startVertex in graph.vertices() {
            guard propertyMap[startVertex][colorProperty] == .white else { continue }

            // Initialize root frame
            index += 1
            propertyMap[startVertex][indexProperty] = index
            propertyMap[startVertex][lowLinkProperty] = index
            propertyMap[startVertex][colorProperty] = .gray
            propertyMap[startVertex][onStackProperty] = true
            sccStack.append(startVertex)
            visitor?.discoverVertex?(startVertex)
            frameStack.append(Frame(vertex: startVertex, edges: Array(graph.outgoingEdges(of: startVertex))))

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
                        index += 1
                        propertyMap[destination][indexProperty] = index
                        propertyMap[destination][lowLinkProperty] = index
                        propertyMap[destination][colorProperty] = .gray
                        propertyMap[destination][onStackProperty] = true
                        sccStack.append(destination)
                        visitor?.discoverVertex?(destination)
                        frameStack.append(Frame(vertex: destination, edges: Array(graph.outgoingEdges(of: destination))))

                    case .gray:
                        // Back edge
                        visitor?.backEdge?(edge)
                        if propertyMap[destination][onStackProperty] == true {
                            let vertexLowLink = propertyMap[currentVertex][lowLinkProperty] ?? 0
                            let destinationIndex = propertyMap[destination][indexProperty] ?? 0
                            propertyMap[currentVertex][lowLinkProperty] = min(vertexLowLink, destinationIndex)
                        }

                    case .black:
                        // Cross edge
                        visitor?.crossEdge?(edge)
                    }
                } else {
                    // Frame done — finalize and pop
                    let frame = frameStack.removeLast()
                    let vertex = frame.vertex

                    propertyMap[vertex][colorProperty] = .black
                    visitor?.finishVertex?(vertex)

                    // If vertex is a root node, pop the SCC stack and create a component
                    let vertexIndex = propertyMap[vertex][indexProperty] ?? 0
                    let vertexLowLink = propertyMap[vertex][lowLinkProperty] ?? 0

                    if vertexIndex == vertexLowLink {
                        var component: [Vertex] = []
                        var w: Vertex
                        repeat {
                            w = sccStack.removeLast()
                            propertyMap[w][onStackProperty] = false
                            component.append(w)
                        } while w != vertex

                        visitor?.startComponent?(vertex)
                        visitor?.finishComponent?(component)
                        components.append(component)
                    }

                    // Update parent's low-link
                    if !frameStack.isEmpty {
                        let parentFrameIndex = frameStack.count - 1
                        let parentVertex = frameStack[parentFrameIndex].vertex
                        let parentLowLink = propertyMap[parentVertex][lowLinkProperty] ?? 0
                        let childLowLink = propertyMap[vertex][lowLinkProperty] ?? 0
                        propertyMap[parentVertex][lowLinkProperty] = min(parentLowLink, childLowLink)
                    }
                }
            }
        }

        return StronglyConnectedComponentsResult(components: components)
    }
}
#endif
