import Collections

/// Depth-First Search algorithm for traversing graphs.
///
/// Depth-First Search explores vertices by going as deep as possible along each branch
/// before backtracking. It can be used to detect cycles, find connected components,
/// and perform topological sorting.
///
/// - Complexity: O(V + E) where V is the number of vertices and E is the number of edges
public struct DepthFirstSearch<Graph: IncidenceGraph> where Graph.VertexDescriptor: Hashable {
    /// The vertex type of the graph.
    public typealias Vertex = Graph.VertexDescriptor
    /// The edge type of the graph.
    public typealias Edge = Graph.EdgeDescriptor

    /// The discovery and finish time of a vertex in DFS.
    public enum Time {
        /// The vertex has not been discovered yet.
        case undiscovered
        /// The vertex was discovered at the given time.
        case discovered(UInt)
        /// The vertex was finished at the given time.
        case finished(UInt)
    }

    /// A visitor that can be used to observe the depth-first search algorithm's progress.
    public struct Visitor {
        /// Called when discovering a new vertex.
        public var discoverVertex: ((Vertex) -> Void)?
        /// Called when examining a vertex.
        public var examineVertex: ((Vertex) -> Void)?
        /// Called when examining an edge.
        public var examineEdge: ((Edge) -> Void)?
        /// Called when traversing a tree edge.
        public var treeEdge: ((Edge) -> Void)?
        /// Called when traversing a back edge.
        public var backEdge: ((Edge) -> Void)?
        /// Called when traversing a forward edge.
        public var forwardEdge: ((Edge) -> Void)?
        /// Called when traversing a cross edge.
        public var crossEdge: ((Edge) -> Void)?
        /// Called when finishing a vertex.
        public var finishVertex: ((Vertex) -> Void)?
        /// Called to determine if an edge should be traversed.
        public var shouldTraverse: (((from: Vertex, to: Vertex, via: Edge, context: Result)) -> Bool)?
        
        @inlinable
        public init(
            discoverVertex: ((Vertex) -> Void)? = nil,
            examineVertex: ((Vertex) -> Void)? = nil,
            examineEdge: ((Edge) -> Void)? = nil,
            treeEdge: ((Edge) -> Void)? = nil,
            backEdge: ((Edge) -> Void)? = nil,
            forwardEdge: ((Edge) -> Void)? = nil,
            crossEdge: ((Edge) -> Void)? = nil,
            finishVertex: ((Vertex) -> Void)? = nil,
            shouldTraverse: (((from: Vertex, to: Vertex, via: Edge, context: Result)) -> Bool)? = nil
        ) {
            self.discoverVertex = discoverVertex
            self.examineVertex = examineVertex
            self.examineEdge = examineEdge
            self.treeEdge = treeEdge
            self.backEdge = backEdge
            self.forwardEdge = forwardEdge
            self.crossEdge = crossEdge
            self.finishVertex = finishVertex
            self.shouldTraverse = shouldTraverse
        }
    }

    /// The color of a vertex in DFS (used for cycle detection).
    public enum Color {
        /// Undiscovered vertex.
        case white
        /// Discovered but not fully processed vertex.
        case gray
        /// Fully processed vertex.
        case black
    }

    /// The result of a depth-first search iteration.
    public struct Result {
        public typealias Vertex = Graph.VertexDescriptor
        public typealias Edge = Graph.EdgeDescriptor
        @usableFromInline
        let source: Vertex
        public let currentVertex: Vertex
        @usableFromInline
        let discoveryTimeProperty: any VertexProperty<Time>.Type
        @usableFromInline
        let finishTimeProperty: any VertexProperty<Time>.Type
        @usableFromInline
        let predecessorEdgeProperty: any VertexProperty<Edge?>.Type
        @usableFromInline
        let depthProperty: any VertexProperty<UInt?>.Type
        @usableFromInline
        let propertyMap: any PropertyMap<Vertex, VertexPropertyValues>
        
        /// Creates a new result.
        ///
        /// - Parameters:
        ///   - source: The source vertex.
        ///   - currentVertex: The current vertex being examined.
        ///   - discoveryTimeProperty: The discovery time property type.
        ///   - finishTimeProperty: The finish time property type.
        ///   - predecessorEdgeProperty: The predecessor edge property type.
        ///   - depthProperty: The depth property type.
        ///   - propertyMap: The property map containing vertex data.
        @inlinable
        public init(
            source: Vertex,
            currentVertex: Vertex,
            discoveryTimeProperty: any VertexProperty<Time>.Type,
            finishTimeProperty: any VertexProperty<Time>.Type,
            predecessorEdgeProperty: any VertexProperty<Edge?>.Type,
            depthProperty: any VertexProperty<UInt?>.Type,
            propertyMap: any PropertyMap<Vertex, VertexPropertyValues>
        ) {
            self.source = source
            self.currentVertex = currentVertex
            self.discoveryTimeProperty = discoveryTimeProperty
            self.finishTimeProperty = finishTimeProperty
            self.predecessorEdgeProperty = predecessorEdgeProperty
            self.depthProperty = depthProperty
            self.propertyMap = propertyMap
        }
    }

    private enum ColorProperty: VertexProperty {
        static var defaultValue: Color { .white }
    }

    private enum DiscoveryTimeProperty: VertexProperty {
        static var defaultValue: Time { .undiscovered }
    }

    private enum FinishTimeProperty: VertexProperty {
        static var defaultValue: Time { .undiscovered }
    }

    private enum PredecessorEdgeProperty: VertexProperty {
        static var defaultValue: Edge? { nil }
    }

    private enum DepthProperty: VertexProperty {
        static var defaultValue: UInt? { nil }
    }

    /// A frame in the DFS stack.
    public struct DFSFrame {
        /// The vertex in this frame.
        @usableFromInline
        let vertex: Vertex
        /// Whether this is the first visit to the vertex.
        @usableFromInline
        let isFirstVisit: Bool
        /// The depth of the vertex in the DFS tree.
        @usableFromInline
        let depth: UInt
        
        @inlinable
        public init(vertex: Vertex, isFirstVisit: Bool, depth: UInt) {
            self.vertex = vertex
            self.isFirstVisit = isFirstVisit
            self.depth = depth
        }
    }

    /// The graph to search in.
    @usableFromInline
    let graph: Graph
    /// The source vertex.
    @usableFromInline
    let source: Vertex
    /// A factory for creating stacks.
    @usableFromInline
    let makeStack: () -> any StackProtocol<DFSFrame>

    /// Creates a new depth-first search algorithm instance.
    ///
    /// - Parameters:
    ///   - graph: The graph to search in.
    ///   - source: The source vertex.
    ///   - makeStack: A factory for creating stacks.
    @inlinable
    public init(
        on graph: Graph,
        from source: Vertex,
        makeStack: @escaping () -> any StackProtocol<DFSFrame> = {
            Array()
        }
    ) {
        self.graph = graph
        self.source = source
        self.makeStack = makeStack
    }

    /// Creates an iterator for the depth-first search.
    ///
    /// - Parameter visitor: An optional visitor to observe the algorithm's progress.
    /// - Returns: An iterator for the search.
    @inlinable
    public func makeIterator(visitor: Visitor?) -> Iterator {
        Iterator(graph: graph, source: source, visitor: visitor, stack: makeStack())
    }

    /// An iterator for depth-first search.
    public struct Iterator {
        /// The graph to search in.
        @usableFromInline
        let graph: Graph
        /// The source vertex.
        @usableFromInline
        let source: Vertex
        /// An optional visitor.
        @usableFromInline
        let visitor: Visitor?
        /// The DFS stack.
        @usableFromInline
        var stack: any StackProtocol<DFSFrame>
        /// The current time counter.
        @usableFromInline
        var time: UInt = 0

        @usableFromInline
        var propertyMap: any MutablePropertyMap<Vertex, VertexPropertyValues>
        @usableFromInline
        let colorProperty: any VertexProperty<Color>.Type = ColorProperty.self
        @usableFromInline
        let discoveryTimeProperty: any VertexProperty<Time>.Type = DiscoveryTimeProperty.self
        @usableFromInline
        let finishTimeProperty: any VertexProperty<Time>.Type = FinishTimeProperty.self
        @usableFromInline
        let predecessorEdgeProperty: any VertexProperty<Edge?>.Type = PredecessorEdgeProperty.self
        @usableFromInline
        let depthProperty: any VertexProperty<UInt?>.Type = DepthProperty.self

        /// Creates a new iterator.
        ///
        /// - Parameters:
        ///   - graph: The graph to search in.
        ///   - source: The source vertex.
        ///   - visitor: An optional visitor.
        ///   - stack: The stack to use.
        @inlinable
        public init(
            graph: Graph,
            source: Vertex,
            visitor: Visitor?,
            stack: any StackProtocol<DFSFrame>
        ) {
            self.graph = graph
            self.source = source
            self.visitor = visitor
            self.stack = stack
            self.propertyMap = graph.makeVertexPropertyMap()

            self.stack.push(DFSFrame(vertex: source, isFirstVisit: true, depth: 0))
        }

        /// Gets the next result from the search.
        ///
        /// - Returns: The next result, or `nil` if the search is complete.
        @inlinable
        public mutating func next() -> Result? {
            while !stack.isEmpty {
                guard let frame = stack.pop() else { break }
                let vertex = frame.vertex

                if frame.isFirstVisit {
                    time += 1
                    propertyMap[vertex][colorProperty] = .gray
                    propertyMap[vertex][discoveryTimeProperty] = .discovered(time)
                    propertyMap[vertex][depthProperty] = frame.depth

                    visitor?.discoverVertex?(vertex)
                    visitor?.examineVertex?(vertex)

                    stack.push(DFSFrame(vertex: vertex, isFirstVisit: false, depth: frame.depth))

                    var whiteNeighbors: [Vertex] = []
                    for edge in graph.outgoingEdges(of: vertex) {
                        visitor?.examineEdge?(edge)

                        guard let destination = graph.destination(of: edge) else { continue }

                        let destinationColor = propertyMap[destination][colorProperty]

                        switch destinationColor {
                            case .white:
                                let context = Result(
                                    source: source,
                                    currentVertex: vertex,
                                    discoveryTimeProperty: discoveryTimeProperty,
                                    finishTimeProperty: finishTimeProperty,
                                    predecessorEdgeProperty: predecessorEdgeProperty,
                                    depthProperty: depthProperty,
                                    propertyMap: propertyMap
                                )
                                if let veto = visitor?.shouldTraverse, veto((from: vertex, to: destination, via: edge, context: context)) == false { continue }
                                propertyMap[destination][predecessorEdgeProperty] = edge
                                visitor?.treeEdge?(edge)
                                whiteNeighbors.append(destination)
                            case .gray:
                                visitor?.backEdge?(edge)
                            case .black:
                                let sourceDiscoveryTime = propertyMap[vertex][discoveryTimeProperty]
                                let destinationDiscoveryTime = propertyMap[destination][discoveryTimeProperty]

                                if case .discovered(let sourceTime) = sourceDiscoveryTime,
                                case .discovered(let destTime) = destinationDiscoveryTime,
                                sourceTime < destTime {
                                    visitor?.forwardEdge?(edge)
                                } else {
                                    visitor?.crossEdge?(edge)
                                }
                        }
                    }

                    for neighbor in whiteNeighbors.reversed() {
                        stack.push(DFSFrame(vertex: neighbor, isFirstVisit: true, depth: frame.depth + 1))
                    }
                } else {
                    time += 1
                    propertyMap[vertex][colorProperty] = .black
                    propertyMap[vertex][finishTimeProperty] = .finished(time)
                    visitor?.finishVertex?(vertex)

                    return Result(
                        source: source,
                        currentVertex: vertex,
                        discoveryTimeProperty: discoveryTimeProperty,
                        finishTimeProperty: finishTimeProperty,
                        predecessorEdgeProperty: predecessorEdgeProperty,
                        depthProperty: depthProperty,
                        propertyMap: propertyMap
                    )
                }
            }

            return nil
        }
    }
}

extension DepthFirstSearch.Iterator: IteratorProtocol {}

extension DepthFirstSearch: Sequence {
    @inlinable
    public func makeIterator() -> Iterator {
        makeIterator(visitor: nil)
    }
}

extension DepthFirstSearch.Result {
    /// Gets the discovery time of a vertex.
    ///
    /// - Parameter vertex: The vertex.
    /// - Returns: The discovery time of the vertex.
    @inlinable
    public func discoveryTime(of vertex: Vertex) -> DepthFirstSearch<Graph>.Time {
        propertyMap[vertex][discoveryTimeProperty]
    }

    /// Gets the finish time of a vertex.
    ///
    /// - Parameter vertex: The vertex.
    /// - Returns: The finish time of the vertex.
    @inlinable
    public func finishTime(of vertex: Vertex) -> DepthFirstSearch<Graph>.Time {
        propertyMap[vertex][finishTimeProperty]
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

    /// Gets the current depth.
    ///
    /// - Returns: The current depth.
    @inlinable
    public func depth() -> UInt {
        propertyMap[currentVertex][depthProperty] ?? 0
    }

    /// Gets the depth of a vertex.
    ///
    /// - Parameter vertex: The vertex.
    /// - Returns: The depth of the vertex, if it has been visited.
    @inlinable
    public func depth(of vertex: Vertex) -> UInt? {
        propertyMap[vertex][depthProperty]
    }
}

extension DepthFirstSearch.Time: Equatable {}

extension DepthFirstSearch.Time: Comparable {
    @inlinable
    public static func < (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (_, .undiscovered): false
        case (.undiscovered, _): true
        case (.discovered(let lhsValue), .discovered(let rhsValue)): lhsValue < rhsValue
        case (.finished(let lhsValue), .finished(let rhsValue)): lhsValue < rhsValue
        case (.discovered(let lhsValue), .finished(let rhsValue)): lhsValue < rhsValue
        case (.finished(let lhsValue), .discovered(let rhsValue)): lhsValue < rhsValue
        }
    }
}

extension DepthFirstSearch.Time: ExpressibleByIntegerLiteral {
    public typealias IntegerLiteralType = UInt

    @inlinable
    public init(integerLiteral value: UInt) {
        self = .discovered(value)
    }
}

extension DepthFirstSearch.Time: ExpressibleByNilLiteral {
    @inlinable
    public init(nilLiteral: ()) {
        self = .undiscovered
    }
}

extension DepthFirstSearch: VisitorSupportingSequence {}
