import Collections

/// DFS-based algorithm for topological sorting.
/// 
/// This algorithm uses depth-first search and processes vertices in reverse finish time order.
/// If a back edge is detected during DFS, the graph contains a cycle.
///
/// - Complexity: O(V + E) where V is the number of vertices and E is the number of edges
public struct DFSTopologicalSort<Graph: IncidenceGraph & VertexListGraph>: TopologicalSortAlgorithm where Graph.VertexDescriptor: Hashable {
    /// The vertex type of the graph.
    public typealias Vertex = Graph.VertexDescriptor
    /// The edge type of the graph.
    public typealias Edge = Graph.EdgeDescriptor
    
    /// A visitor that can be used to observe DFS topological sort progress.
    public struct Visitor {
        /// Called when discovering a vertex.
        public var discoverVertex: ((Vertex) -> Void)?
        /// Called when examining an edge.
        public var examineEdge: ((Edge) -> Void)?
        /// Called when traversing a tree edge.
        public var treeEdge: ((Edge) -> Void)?
        /// Called when detecting a back edge (indicates a cycle).
        public var backEdge: ((Edge) -> Void)?
        /// Called when traversing a forward edge.
        public var forwardEdge: ((Edge) -> Void)?
        /// Called when traversing a cross edge.
        public var crossEdge: ((Edge) -> Void)?
        /// Called when finishing a vertex.
        public var finishVertex: ((Vertex) -> Void)?
        /// Called when detecting a cycle.
        public var detectCycle: (([Vertex]) -> Void)?
        
        /// Creates a new visitor.
        @inlinable
        public init(
            discoverVertex: ((Vertex) -> Void)? = nil,
            examineEdge: ((Edge) -> Void)? = nil,
            treeEdge: ((Edge) -> Void)? = nil,
            backEdge: ((Edge) -> Void)? = nil,
            forwardEdge: ((Edge) -> Void)? = nil,
            crossEdge: ((Edge) -> Void)? = nil,
            finishVertex: ((Vertex) -> Void)? = nil,
            detectCycle: (([Vertex]) -> Void)? = nil
        ) {
            self.discoverVertex = discoverVertex
            self.examineEdge = examineEdge
            self.treeEdge = treeEdge
            self.backEdge = backEdge
            self.forwardEdge = forwardEdge
            self.crossEdge = crossEdge
            self.finishVertex = finishVertex
            self.detectCycle = detectCycle
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
    
    /// The stack factory for DFS traversal.
    @usableFromInline
    let makeStack: () -> any StackProtocol<Vertex>
    
    /// Creates a new DFS topological sort algorithm.
    ///
    /// - Parameter makeStack: A factory for creating the stack used in DFS traversal.
    @inlinable
    public init(makeStack: @escaping () -> any StackProtocol<Vertex> = { Array() }) {
        self.makeStack = makeStack
    }
    
    /// Performs topological sort using DFS.
    ///
    /// - Parameters:
    ///   - graph: The graph to sort topologically.
    ///   - visitor: An optional visitor to observe the algorithm progress.
    /// - Returns: The topological sort result.
    @inlinable
    public func topologicalSort(
        in graph: Graph,
        visitor: Visitor?
    ) -> TopologicalSortResult<Graph.VertexDescriptor> {
        var sortedVertices: [Vertex] = []
        var hasCycle = false
        var cycleVertices: [Vertex] = []
        var propertyMap: any MutablePropertyMap<Vertex, VertexPropertyValues> = graph.makeVertexPropertyMap()
        let colorProperty: any VertexProperty<Color>.Type = ColorProperty.self
        
        // Process all vertices to handle disconnected components
        for vertex in graph.vertices() {
            let color = propertyMap[vertex][colorProperty]
            if color == .white {
                let (cycle, cycleNodes) = dfsVisit(
                    from: vertex,
                    in: graph,
                    propertyMap: &propertyMap,
                    colorProperty: colorProperty,
                    sortedVertices: &sortedVertices,
                    visitor: visitor
                )
                if cycle {
                    hasCycle = true
                    cycleVertices.append(contentsOf: cycleNodes)
                }
            }
        }
        
        if hasCycle {
            visitor?.detectCycle?(cycleVertices)
        }
        
        return TopologicalSortResult(
            sortedVertices: sortedVertices,
            hasCycle: hasCycle,
            cycleVertices: cycleVertices
        )
    }
    
    @usableFromInline
    func dfsVisit(
        from vertex: Vertex,
        in graph: Graph,
        propertyMap: inout any MutablePropertyMap<Vertex, VertexPropertyValues>,
        colorProperty: any VertexProperty<Color>.Type,
        sortedVertices: inout [Vertex],
        visitor: Visitor?
    ) -> (hasCycle: Bool, cycleVertices: [Vertex]) {
        var hasCycle = false
        var cycleVertices: [Vertex] = []
        var stack = makeStack()
        
        stack.push(vertex)
        
        while !stack.isEmpty {
            guard let current = stack.pop() else { break }
            let color = propertyMap[current][colorProperty]
            
            switch color {
            case .white:
                // Mark as discovered
                propertyMap[current][colorProperty] = .gray
                visitor?.discoverVertex?(current)
                
                // Push back for processing after neighbors
                stack.push(current)
                
                // Process all outgoing edges
                for edge in graph.outgoingEdges(of: current) {
                    visitor?.examineEdge?(edge)
                    guard let destination = graph.destination(of: edge) else { continue }
                    
                    let destColor = propertyMap[destination][colorProperty]
                    switch destColor {
                    case .white:
                        visitor?.treeEdge?(edge)
                        stack.push(destination)
                    case .gray:
                        // Back edge detected - cycle found
                        visitor?.backEdge?(edge)
                        hasCycle = true
                        cycleVertices.append(destination)
                    case .black:
                        visitor?.forwardEdge?(edge)
                    }
                }
                
            case .gray:
                // Mark as finished and add to sorted list
                propertyMap[current][colorProperty] = .black
                visitor?.finishVertex?(current)
                sortedVertices.insert(current, at: 0) // Insert at beginning for reverse finish time
                
            case .black:
                // Already processed
                break
            }
        }
        
        return (hasCycle, cycleVertices)
    }
}

extension DFSTopologicalSort: VisitorSupporting {}
