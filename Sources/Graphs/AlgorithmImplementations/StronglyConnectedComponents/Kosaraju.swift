import Collections

/// Kosaraju's algorithm for finding strongly connected components.
///
/// Kosaraju's algorithm finds strongly connected components in a directed graph
/// by performing two depth-first searches: first on the original graph to get
/// finish times, then on the transposed graph in reverse finish time order.
///
/// - Complexity: O(V + E) where V is the number of vertices and E is the number of edges
public struct Kosaraju<Graph: BidirectionalGraph & VertexListGraph> where Graph.VertexDescriptor: Hashable {
    /// The vertex type of the graph.
    public typealias Vertex = Graph.VertexDescriptor
    /// The edge type of the graph.
    public typealias Edge = Graph.EdgeDescriptor

    /// A visitor that can be used to observe Kosaraju's algorithm progress.
    public struct Visitor {
        /// Called when discovering a vertex.
        public var discoverVertex: ((Vertex) -> Void)?
        /// Called when examining an edge.
        public var examineEdge: ((Edge) -> Void)?
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
            finishVertex: ((Vertex) -> Void)? = nil,
            startComponent: ((Vertex) -> Void)? = nil,
            finishComponent: (([Vertex]) -> Void)? = nil
        ) {
            self.discoverVertex = discoverVertex
            self.examineEdge = examineEdge
            self.finishVertex = finishVertex
            self.startComponent = startComponent
            self.finishComponent = finishComponent
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

    @usableFromInline
    enum ColorProperty: VertexProperty {
        @usableFromInline
        static var defaultValue: Color { .white }
    }

    /// The graph to find strongly connected components in.
    @usableFromInline
    let graph: Graph

    /// Creates a new Kosaraju algorithm instance.
    ///
    /// - Parameter graph: The graph to find strongly connected components in.
    @inlinable
    public init(on graph: Graph) {
        self.graph = graph
    }

    /// Finds strongly connected components in the graph.
    ///
    /// - Parameter visitor: An optional visitor to observe the algorithm's progress.
    /// - Returns: The strongly connected components result.
    @inlinable
    public func stronglyConnectedComponents(visitor: Visitor?) -> StronglyConnectedComponentsResult<Vertex> {
        var propertyMap = graph.makeVertexPropertyMap()
        let colorProperty = ColorProperty.self

        // Step 1: Perform DFS on the original graph to get finish times
        var finishOrder: [Vertex] = []
        
        /// First DFS pass to get finish times.
        ///
        /// - Parameter vertex: The vertex to start DFS from.
        func dfs1(_ vertex: Vertex) {
            propertyMap[vertex][colorProperty] = .gray
            visitor?.discoverVertex?(vertex)

            for edge in graph.outgoingEdges(of: vertex) {
                visitor?.examineEdge?(edge)
                guard let destination = graph.destination(of: edge) else { continue }
                
                if propertyMap[destination][colorProperty] == .white {
                    dfs1(destination)
                }
            }

            propertyMap[vertex][colorProperty] = .black
            visitor?.finishVertex?(vertex)
            finishOrder.append(vertex)
        }

        // First pass: DFS on original graph
        for vertex in graph.vertices() {
            if propertyMap[vertex][colorProperty] == .white {
                dfs1(vertex)
            }
        }

        // Step 2: Reset colors and perform DFS on the transpose graph
        for vertex in graph.vertices() {
            propertyMap[vertex][colorProperty] = .white
        }

        var components: [[Vertex]] = []

        /// Second DFS pass on the transpose graph.
        ///
        /// - Parameters:
        ///   - vertex: The vertex to start DFS from.
        ///   - component: The current component being built.
        func dfs2(_ vertex: Vertex, component: inout [Vertex]) {
            propertyMap[vertex][colorProperty] = .gray
            visitor?.discoverVertex?(vertex)
            component.append(vertex)

            // For Kosaraju's algorithm, we need to traverse the transpose graph
            // We use incoming edges to simulate the transpose
            for edge in graph.incomingEdges(of: vertex) {
                visitor?.examineEdge?(edge)
                guard let source = graph.source(of: edge) else { continue }
                
                if propertyMap[source][colorProperty] == .white {
                    dfs2(source, component: &component)
                }
            }

            propertyMap[vertex][colorProperty] = .black
            visitor?.finishVertex?(vertex)
        }

        // Second pass: DFS on transpose graph in reverse finish order
        for vertex in finishOrder.reversed() {
            if propertyMap[vertex][colorProperty] == .white {
                var component: [Vertex] = []
                visitor?.startComponent?(vertex)
                dfs2(vertex, component: &component)
                visitor?.finishComponent?(component)
                components.append(component)
            }
        }

        return StronglyConnectedComponentsResult(components: components)
    }
}

