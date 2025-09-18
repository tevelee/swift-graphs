import Collections

struct BreadthFirstSearch<Graph: IncidenceGraph> where Graph.VertexDescriptor: Hashable {
    typealias Vertex = Graph.VertexDescriptor
    typealias Edge = Graph.EdgeDescriptor
    
    enum Distance {
        case unreachable
        case reachable(depth: UInt)
    }
    
    struct Visitor {
        var discoverVertex: ((Vertex) -> Void)?
        var examineVertex: ((Vertex) -> Void)?
        var examineEdge: ((Edge) -> Void)?
        var treeEdge: ((Edge) -> Void)?
        var nonTreeEdge: ((Edge) -> Void)?
        var grayTargetEdge: ((Edge) -> Void)?
        var blackTargetEdge: ((Edge) -> Void)?
        var finishVertex: ((Vertex) -> Void)?
        var shouldTraverse: (((from: Vertex, to: Vertex, via: Edge, context: Result)) -> Bool)?
    }
    
    private enum Color: Equatable {
        case white // Undiscovered
        case gray // Discovered but not fully processed
        case black // Fully processed
    }
    
    struct Result {
        typealias Vertex = Graph.VertexDescriptor
        typealias Edge = Graph.EdgeDescriptor
        fileprivate let source: Vertex
        let currentVertex: Vertex
        let distanceProperty: any VertexProperty<Distance>.Type
        let predecessorEdgeProperty: any VertexProperty<Edge?>.Type
        let propertyMap: any PropertyMap<Vertex, VertexPropertyValues>
    }
    
    private enum ColorProperty: VertexProperty {
        static var defaultValue: Color { .white }
    }
    
    private enum DistanceProperty: VertexProperty {
        static var defaultValue: Distance { .unreachable }
    }
    
    private enum PredecessorEdgeProperty: VertexProperty {
        static var defaultValue: Edge? { nil }
    }
    
    private let graph: Graph
    private let source: Vertex
    private let makeQueue: () -> any QueueProtocol<Vertex>
    
    init(
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
    
    func makeIterator(visitor: Visitor?) -> Iterator {
        Iterator(graph: graph, source: source, visitor: visitor, queue: makeQueue())
    }
    
    struct Iterator {
        private let graph: Graph
        private let source: Vertex
        private let visitor: Visitor?
        private var queue: any QueueProtocol<Vertex>

        private var propertyMap: any MutablePropertyMap<Vertex, VertexPropertyValues>
        private let colorProperty: any VertexProperty<Color>.Type = ColorProperty.self
        private let distanceProperty: any VertexProperty<Distance>.Type = DistanceProperty.self
        private let predecessorEdgeProperty: any VertexProperty<Edge?>.Type = PredecessorEdgeProperty.self
        
        init(
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
        
        mutating func next() -> Result? {
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
    func makeIterator() -> Iterator {
        makeIterator(visitor: nil)
    }
}

extension BreadthFirstSearch.Result {
    func depth() -> UInt {
        switch depth(of: currentVertex) {
            case .reachable(let distance):
                return distance
            case .unreachable:
                assertionFailure("The currently examined vertex should always be reachable")
                return 0
        }
    }
    
    func predecessor(in graph: some IncidenceGraph<Vertex, Edge>) -> Vertex {
        predecessor(of: currentVertex, in: graph).unwrap(
            orReport: "The currently examined vertex should always have a predecessor"
        )
    }
    
    func predecessorEdge() -> Edge {
        predecessorEdge(of: currentVertex).unwrap(
            orReport: "The currently examined vertex should always have a predecessor edge"
        )
    }
    
    func vertices(in graph: some IncidenceGraph<Vertex, Edge>) -> [Vertex] {
        vertices(to: currentVertex, in: graph)
    }
    
    func edges(in graph: some IncidenceGraph<Vertex, Edge>) -> [Edge] {
        edges(to: currentVertex, in: graph)
    }
    
    func path(in graph: some IncidenceGraph<Vertex, Edge>) -> [(vertex: Vertex, edge: Edge)] {
        path(to: currentVertex, in: graph)
    }
    
    func depth(of vertex: Vertex) -> BreadthFirstSearch.Distance {
        propertyMap[vertex][distanceProperty]
    }
    
    func predecessor(of vertex: Vertex, in graph: some IncidenceGraph<Vertex, Edge>) -> Vertex? {
        predecessorEdge(of: vertex).flatMap(graph.source)
    }
    
    func predecessorEdge(of vertex: Vertex) -> Edge? {
        propertyMap[vertex][predecessorEdgeProperty]
    }
    
    func hasPath(to vertex: Vertex) -> Bool {
        propertyMap[vertex][distanceProperty] != .unreachable
    }
    
    func vertices(to destination: Vertex, in graph: some IncidenceGraph<Vertex, Edge>) -> [Vertex] {
        [source] + path(to: destination, in: graph).map(\.vertex)
    }
    
    func edges(to destination: Vertex, in graph: some IncidenceGraph<Vertex, Edge>) -> [Edge] {
        path(to: destination, in: graph).map(\.edge)
    }
    
    func path(to destination: Vertex, in graph: some IncidenceGraph<Vertex, Edge>) -> [(vertex: Vertex, edge: Edge)] {
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

extension BreadthFirstSearch.Distance: Equatable {}

extension BreadthFirstSearch.Distance: Comparable {
    static func < (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
            case (.unreachable, _): false
            case (_, .unreachable): true
            case (.reachable(let lhsValue), .reachable(let rhsValue)): lhsValue < rhsValue
        }
    }
}

extension BreadthFirstSearch.Distance {
    static func + (distance: Self, amount: UInt) -> Self {
        switch distance {
            case .unreachable: .unreachable
            case .reachable(let depth): .reachable(depth: depth + amount)
        }
    }
}

extension BreadthFirstSearch.Distance: ExpressibleByIntegerLiteral {
    init(integerLiteral value: UInt) {
        self = .reachable(depth: value)
    }
}

extension BreadthFirstSearch.Distance: ExpressibleByNilLiteral {
    init(nilLiteral: ()) {
        self = .unreachable
    }
}

extension BreadthFirstSearch: VisitorSupportingSequence {}
