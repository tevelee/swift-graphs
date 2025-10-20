import Collections

/// DFS-based connected components algorithm.
///
/// This algorithm finds connected components using depth-first search.
/// It visits all vertices reachable from each unvisited vertex to form components.
///
/// - Complexity: O(V + E) where V is the number of vertices and E is the number of edges
public struct DFSConnectedComponents<Graph: IncidenceGraph & VertexListGraph> where Graph.VertexDescriptor: Hashable {
    /// The vertex type of the graph.
    public typealias Vertex = Graph.VertexDescriptor
    /// The edge type of the graph.
    public typealias Edge = Graph.EdgeDescriptor

    /// A visitor that can be used to observe the DFS connected components algorithm progress.
    public struct Visitor {
        /// Called when discovering a vertex.
        public var discoverVertex: ((Vertex) -> Void)?
        /// Called when examining an edge.
        public var examineEdge: ((Edge) -> Void)?
        /// Called when finishing a component.
        public var finishComponent: (([Vertex]) -> Void)?
        
        /// Creates a new visitor.
        @inlinable
        public init(
            discoverVertex: ((Vertex) -> Void)? = nil,
            examineEdge: ((Edge) -> Void)? = nil,
            finishComponent: (([Vertex]) -> Void)? = nil
        ) {
            self.discoverVertex = discoverVertex
            self.examineEdge = examineEdge
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

    /// Property for tracking vertex colors.
    @usableFromInline
    enum ColorProperty: VertexProperty {
        @usableFromInline
        static var defaultValue: Color { .white }
    }

    /// The graph to find connected components in.
    @usableFromInline
    let graph: Graph

    /// Creates a new DFS connected components algorithm.
    ///
    /// - Parameter graph: The graph to find connected components in
    @inlinable
    public init(on graph: Graph) {
        self.graph = graph
    }

    /// Finds connected components using DFS.
    ///
    /// - Parameter visitor: An optional visitor to observe the algorithm progress
    /// - Returns: The connected components result
    @inlinable
    public func connectedComponents(visitor: Visitor?) -> ConnectedComponentsResult<Vertex> {
        var propertyMap = graph.makeVertexPropertyMap()
        let colorProperty = ColorProperty.self
        var components: [[Vertex]] = []

        func dfs(_ vertex: Vertex, component: inout [Vertex]) {
            propertyMap[vertex][colorProperty] = .gray
            visitor?.discoverVertex?(vertex)
            component.append(vertex)

            for edge in graph.outgoingEdges(of: vertex) {
                visitor?.examineEdge?(edge)
                guard let destination = graph.destination(of: edge) else { continue }
                
                if propertyMap[destination][colorProperty] == .white {
                    dfs(destination, component: &component)
                }
            }

            propertyMap[vertex][colorProperty] = .black
        }

        // Process all vertices
        for vertex in graph.vertices() {
            if propertyMap[vertex][colorProperty] == .white {
                var component: [Vertex] = []
                dfs(vertex, component: &component)
                visitor?.finishComponent?(component)
                components.append(component)
            }
        }

        return ConnectedComponentsResult(components: components)
    }
}

extension DFSConnectedComponents: ConnectedComponentsAlgorithm {
    @inlinable
    public func connectedComponents(
        in graph: Graph,
        visitor: Visitor?
    ) -> ConnectedComponentsResult<Graph.VertexDescriptor> {
        connectedComponents(visitor: visitor)
    }
}
