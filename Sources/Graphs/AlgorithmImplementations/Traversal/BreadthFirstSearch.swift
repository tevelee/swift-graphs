import Collections

/// Breadth-First Search algorithm for traversing graphs.
///
/// Breadth-First Search explores vertices level by level, visiting all vertices
/// at distance k before visiting vertices at distance k+1.
///
/// - Complexity: O(V + E) where V is the number of vertices and E is the number of edges
public struct BreadthFirstSearch<Graph: IncidenceGraph> where Graph.VertexDescriptor: Hashable {
    /// The vertex type of the graph.
    public typealias Vertex = Graph.VertexDescriptor
    /// The edge type of the graph.
    public typealias Edge = Graph.EdgeDescriptor
    
    /// The distance from the source vertex.
    public enum Distance {
        /// The vertex is unreachable.
        case unreachable
        /// The vertex is reachable at the given depth.
        case reachable(depth: UInt)
    }
    
    /// A visitor that can be used to observe the breadth-first search algorithm's progress.
    public struct Visitor {
        /// Called when discovering a new vertex.
        public var discoverVertex: ((Vertex) -> Void)?
        /// Called when examining a vertex.
        public var examineVertex: ((Vertex) -> Void)?
        /// Called when examining an edge.
        public var examineEdge: ((Edge) -> Void)?
        /// Called when traversing a tree edge.
        public var treeEdge: ((Edge) -> Void)?
        /// Called when traversing a non-tree edge.
        public var nonTreeEdge: ((Edge) -> Void)?
        /// Called when traversing an edge to a gray vertex.
        public var grayTargetEdge: ((Edge) -> Void)?
        /// Called when traversing an edge to a black vertex.
        public var blackTargetEdge: ((Edge) -> Void)?
        /// Called when finishing a vertex.
        public var finishVertex: ((Vertex) -> Void)?
        /// Called to determine if an edge should be traversed.
        public var shouldTraverse: (((from: Vertex, to: Vertex, via: Edge, context: Result)) -> Bool)?
        
        /// Creates a new visitor.
        @inlinable
        public init(
            discoverVertex: ((Vertex) -> Void)? = nil,
            examineVertex: ((Vertex) -> Void)? = nil,
            examineEdge: ((Edge) -> Void)? = nil,
            treeEdge: ((Edge) -> Void)? = nil,
            nonTreeEdge: ((Edge) -> Void)? = nil,
            grayTargetEdge: ((Edge) -> Void)? = nil,
            blackTargetEdge: ((Edge) -> Void)? = nil,
            finishVertex: ((Vertex) -> Void)? = nil,
            shouldTraverse: (((from: Vertex, to: Vertex, via: Edge, context: Result)) -> Bool)? = nil
        ) {
            self.discoverVertex = discoverVertex
            self.examineVertex = examineVertex
            self.examineEdge = examineEdge
            self.treeEdge = treeEdge
            self.nonTreeEdge = nonTreeEdge
            self.grayTargetEdge = grayTargetEdge
            self.blackTargetEdge = blackTargetEdge
            self.finishVertex = finishVertex
            self.shouldTraverse = shouldTraverse
        }
    }
    
    @usableFromInline
    enum Color: Equatable {
        case white // Undiscovered
        case gray // Discovered but not fully processed
        case black // Fully processed
    }
    
    /// The result of a breadth-first search iteration.
    public struct Result {
        /// The vertex type of the graph.
        public typealias Vertex = Graph.VertexDescriptor
        /// The edge type of the graph.
        public typealias Edge = Graph.EdgeDescriptor
        @usableFromInline
        let source: Vertex
        /// The current vertex being examined.
        public let currentVertex: Vertex
        /// The distance property type.
        public let distanceProperty: any VertexProperty<Distance>.Type
        /// The predecessor edge property type.
        public let predecessorEdgeProperty: any VertexProperty<Edge?>.Type
        /// The property map containing distances and predecessors.
        public let propertyMap: any PropertyMap<Vertex, VertexPropertyValues>
        
        /// Creates a new result.
        @inlinable
        public init(
            source: Vertex,
            currentVertex: Vertex,
            distanceProperty: any VertexProperty<Distance>.Type,
            predecessorEdgeProperty: any VertexProperty<Edge?>.Type,
            propertyMap: any PropertyMap<Vertex, VertexPropertyValues>
        ) {
            self.source = source
            self.currentVertex = currentVertex
            self.distanceProperty = distanceProperty
            self.predecessorEdgeProperty = predecessorEdgeProperty
            self.propertyMap = propertyMap
        }
    }
    
    @usableFromInline
    enum ColorProperty: VertexProperty {
        @usableFromInline
        static var defaultValue: Color { .white }
    }

    @usableFromInline
    enum DistanceProperty: VertexProperty {
        @usableFromInline
        static var defaultValue: Distance { .unreachable }
    }

    @usableFromInline
    enum PredecessorEdgeProperty: VertexProperty {
        @usableFromInline
        static var defaultValue: Edge? { nil }
    }
    
    @usableFromInline
    let graph: Graph
    @usableFromInline
    let source: Vertex
    @usableFromInline
    let makeQueue: () -> any QueueProtocol<Vertex>
    
    /// Creates a new breadth-first search algorithm instance.
    ///
    /// - Parameters:
    ///   - graph: The graph to search in.
    ///   - source: The source vertex.
    ///   - makeQueue: A factory for creating queues.
    @inlinable
    public init(
        on graph: Graph,
        from source: Vertex, // TODO: multi source with a set/sequence of vertices
        makeQueue: @escaping () -> any QueueProtocol<Vertex> = {
            Deque()
        }
    ) {
        self.graph = graph
        self.source = source
        self.makeQueue = makeQueue
    }
    
    /// Creates an iterator for the breadth-first search.
    ///
    /// - Parameter visitor: An optional visitor to observe the algorithm's progress.
    /// - Returns: An iterator for the search.
    @inlinable
    public func makeIterator(visitor: Visitor?) -> Iterator {
        Iterator(graph: graph, source: source, visitor: visitor, queue: makeQueue())
    }
    
    /// An iterator for breadth-first search.
    public struct Iterator {
        @usableFromInline
        let graph: Graph
        @usableFromInline
        let source: Vertex
        @usableFromInline
        let visitor: Visitor?
        @usableFromInline
        var queue: any QueueProtocol<Vertex>

        @usableFromInline
        var propertyMap: any MutablePropertyMap<Vertex, VertexPropertyValues>
        @usableFromInline
        let colorProperty: any VertexProperty<Color>.Type = ColorProperty.self
        @usableFromInline
        let distanceProperty: any VertexProperty<Distance>.Type = DistanceProperty.self
        @usableFromInline
        let predecessorEdgeProperty: any VertexProperty<Edge?>.Type = PredecessorEdgeProperty.self
        
        /// Creates a new iterator.
        ///
        /// - Parameters:
        ///   - graph: The graph to search in.
        ///   - source: The source vertex.
        ///   - visitor: An optional visitor.
        ///   - queue: The queue to use.
        @inlinable
        public init(
            graph: Graph,
            source: Vertex,
            visitor: Visitor?,
            queue: any QueueProtocol<Vertex>
        ) {
            self.graph = graph
            self.source = source
            self.visitor = visitor
            self.propertyMap = graph.makeVertexPropertyMap()
            self.queue = queue
            
            propertyMap[source][colorProperty] = .gray
            propertyMap[source][distanceProperty] = .reachable(depth: 0)
            self.queue.enqueue(source)
        }
        
        /// Gets the next result from the search.
        ///
        /// - Returns: The next result, or `nil` if the search is complete.
        @inlinable
        public mutating func next() -> Result? {
            guard let current = queue.dequeue() else {
                return nil
            }
            
            visitor?.examineVertex?(current)
            
            for edge in graph.outgoingEdges(of: current) {
                visitor?.examineEdge?(edge)
                
                guard let destination = graph.destination(of: edge) else { continue }
                
                let destinationColor = propertyMap[destination][colorProperty]
                
                switch destinationColor {
                    case .white:
                        // Tree edge - first time discovering this vertex
                        let context = Result(
                            source: source,
                            currentVertex: current,
                            distanceProperty: distanceProperty,
                            predecessorEdgeProperty: predecessorEdgeProperty,
                            propertyMap: propertyMap
                        )
                        if let veto = visitor?.shouldTraverse, veto((from: current, to: destination, via: edge, context: context)) == false { continue }
                        propertyMap[destination][colorProperty] = .gray
                        propertyMap[destination][distanceProperty] = propertyMap[current][distanceProperty] + 1
                        propertyMap[destination][predecessorEdgeProperty] = edge
                        visitor?.discoverVertex?(destination)
                        queue.enqueue(destination)
                        visitor?.treeEdge?(edge)
                    case .gray:
                        // Non-tree edge to an in-progress vertex
                        visitor?.grayTargetEdge?(edge)
                        visitor?.nonTreeEdge?(edge)
                    case .black:
                        // Non-tree edge to a finished vertex
                        visitor?.blackTargetEdge?(edge)
                        visitor?.nonTreeEdge?(edge)
                }
            }
            
            propertyMap[current][colorProperty] = .black
            visitor?.finishVertex?(current)
            
            return Result(
                source: source,
                currentVertex: current,
                distanceProperty: distanceProperty,
                predecessorEdgeProperty: predecessorEdgeProperty,
                propertyMap: propertyMap
            )
        }
    }
}

extension BreadthFirstSearch.Iterator: IteratorProtocol {}

extension BreadthFirstSearch: Sequence {
    @inlinable
    public func makeIterator() -> Iterator {
        makeIterator(visitor: nil)
    }
}

extension BreadthFirstSearch.Result {
    /// Gets the current depth.
    ///
    /// - Returns: The current depth.
    @inlinable
    public func depth() -> UInt {
        switch depth(of: currentVertex) {
            case .reachable(let distance):
                return distance
            case .unreachable:
                assertionFailure("The currently examined vertex should always be reachable")
                return 0
        }
    }
    
    /// Gets the predecessor vertex.
    ///
    /// - Parameter graph: The graph.
    /// - Returns: The predecessor vertex.
    @inlinable
    public func predecessor(in graph: some IncidenceGraph<Vertex, Edge>) -> Vertex {
        predecessor(of: currentVertex, in: graph).unwrap(
            orReport: "The currently examined vertex should always have a predecessor"
        )
    }
    
    /// Gets the predecessor edge.
    ///
    /// - Returns: The predecessor edge.
    @inlinable
    public func predecessorEdge() -> Edge {
        predecessorEdge(of: currentVertex).unwrap(
            orReport: "The currently examined vertex should always have a predecessor edge"
        )
    }
    
    /// Gets the vertices in the current path.
    ///
    /// - Parameter graph: The graph.
    /// - Returns: The vertices in the current path.
    @inlinable
    public func vertices(in graph: some IncidenceGraph<Vertex, Edge>) -> [Vertex] {
        vertices(to: currentVertex, in: graph)
    }
    
    /// Gets the edges in the current path.
    ///
    /// - Parameter graph: The graph.
    /// - Returns: The edges in the current path.
    @inlinable
    public func edges(in graph: some IncidenceGraph<Vertex, Edge>) -> [Edge] {
        edges(to: currentVertex, in: graph)
    }
    
    /// Gets the current path.
    ///
    /// - Parameter graph: The graph.
    /// - Returns: The current path.
    @inlinable
    public func path(in graph: some IncidenceGraph<Vertex, Edge>) -> [(vertex: Vertex, edge: Edge)] {
        path(to: currentVertex, in: graph)
    }
    
    /// Gets the depth of a vertex.
    ///
    /// - Parameter vertex: The vertex.
    /// - Returns: The depth of the vertex.
    @inlinable
    public func depth(of vertex: Vertex) -> BreadthFirstSearch.Distance {
        propertyMap[vertex][distanceProperty]
    }
    
    /// Gets the predecessor of a vertex.
    ///
    /// - Parameters:
    ///   - vertex: The vertex.
    ///   - graph: The graph.
    /// - Returns: The predecessor vertex, if one exists.
    @inlinable
    public func predecessor(of vertex: Vertex, in graph: some IncidenceGraph<Vertex, Edge>) -> Vertex? {
        predecessorEdge(of: vertex).flatMap(graph.source)
    }
    
    /// Gets the predecessor edge of a vertex.
    ///
    /// - Parameter vertex: The vertex.
    /// - Returns: The predecessor edge, if one exists.
    @inlinable
    public func predecessorEdge(of vertex: Vertex) -> Edge? {
        propertyMap[vertex][predecessorEdgeProperty]
    }
    
    /// Checks if there is a path to a vertex.
    ///
    /// - Parameter vertex: The vertex.
    /// - Returns: `true` if there is a path, `false` otherwise.
    @inlinable
    public func hasPath(to vertex: Vertex) -> Bool {
        propertyMap[vertex][distanceProperty] != .unreachable
    }
    
    /// Gets the vertices to a destination.
    ///
    /// - Parameters:
    ///   - destination: The destination vertex.
    ///   - graph: The graph.
    /// - Returns: The vertices to the destination.
    @inlinable
    public func vertices(to destination: Vertex, in graph: some IncidenceGraph<Vertex, Edge>) -> [Vertex] {
        [source] + path(to: destination, in: graph).map(\.vertex)
    }
    
    /// Gets the edges to a destination.
    ///
    /// - Parameters:
    ///   - destination: The destination vertex.
    ///   - graph: The graph.
    /// - Returns: The edges to the destination.
    @inlinable
    public func edges(to destination: Vertex, in graph: some IncidenceGraph<Vertex, Edge>) -> [Edge] {
        path(to: destination, in: graph).map(\.edge)
    }
    
    /// Gets the path to a destination.
    ///
    /// - Parameters:
    ///   - destination: The destination vertex.
    ///   - graph: The graph.
    /// - Returns: The path to the destination.
    @inlinable
    public func path(to destination: Vertex, in graph: some IncidenceGraph<Vertex, Edge>) -> [(vertex: Vertex, edge: Edge)] {
        var current = destination
        var result: [(Vertex, Edge)] = []
        while let predecessorEdge = predecessorEdge(of: current) {
            result.insert((current, predecessorEdge), at: 0)
            guard let predecessor = graph.source(of: predecessorEdge) else { break }
            current = predecessor
        }
        return result
    }
}

extension BreadthFirstSearch.Distance: Equatable {
    @inlinable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.unreachable, .unreachable):
            return true
        case (.reachable(let lhsDepth), .reachable(let rhsDepth)):
            return lhsDepth == rhsDepth
        default:
            return false
        }
    }
}

extension BreadthFirstSearch.Distance: Comparable {
    @inlinable
    public static func < (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
            case (.unreachable, _): false
            case (_, .unreachable): true
            case (.reachable(let lhsValue), .reachable(let rhsValue)): lhsValue < rhsValue
        }
    }
}

extension BreadthFirstSearch.Distance {
    /// Adds an amount to a distance.
    ///
    /// - Parameters:
    ///   - distance: The distance.
    ///   - amount: The amount to add.
    /// - Returns: The new distance.
    @inlinable
    public static func + (distance: Self, amount: UInt) -> Self {
        switch distance {
            case .unreachable: .unreachable
            case .reachable(let depth): .reachable(depth: depth + amount)
        }
    }
}

extension BreadthFirstSearch.Distance: ExpressibleByIntegerLiteral {
    @inlinable
    public init(integerLiteral value: UInt) {
        self = .reachable(depth: value)
    }
}

extension BreadthFirstSearch.Distance: ExpressibleByNilLiteral {
    @inlinable
    public init(nilLiteral: ()) {
        self = .unreachable
    }
}

extension BreadthFirstSearch: VisitorSupportingSequence {}
