import Collections

struct BreadthFirstSearchAlgorithm<Graph: IncidenceGraph & VertexListGraph> where Graph.VertexDescriptor: Hashable {
    enum Distance {
        case unreachable
        case reachable(UInt)
    }
    
    struct Visitor<Vertex, Edge> {
        var initializeVertex: ((Vertex) -> Void)?
        var discoverVertex: ((Vertex) -> Void)?
        var examineVertex: ((Vertex) -> Void)?
        var examineEdge: ((Edge) -> Void)?
        var treeEdge: ((Edge) -> Void)?
        var nonTreeEdge: ((Edge) -> Void)?
        var finishVertex: ((Vertex) -> Void)?
    }
    
    private enum Color {
        case white // Undiscovered
        case gray // Discovered but not fully processed
        case black // Fully processed
    }
    
    struct Result<Vertex, Edge> {
        fileprivate let source: Vertex
        let examinedVertex: Vertex
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
    
    private enum PredecessorEdgeProperty<Edge>: VertexProperty {
        static var defaultValue: Edge? { nil }
    }
    
    private let graph: Graph
    private let source: Graph.VertexDescriptor
    private let makeVisitor: (() -> Visitor<Graph.VertexDescriptor, Graph.EdgeDescriptor>)?
    private let makeQueue: () -> any QueueProtocol<Graph.VertexDescriptor>
    
    init(
        on graph: Graph,
        from source: Graph.VertexDescriptor,
        makeVisitor: (() -> Visitor<Graph.VertexDescriptor, Graph.EdgeDescriptor>)? = nil,
        makeQueue: @escaping () -> any QueueProtocol<Graph.VertexDescriptor> = { Deque<Graph.VertexDescriptor>() }
    ) {
        self.graph = graph
        self.source = source
        self.makeVisitor = makeVisitor
        self.makeQueue = makeQueue
    }
    
    struct Iterator {
        private let graph: Graph
        private let source: Graph.VertexDescriptor
        private let visitor: Visitor<Graph.VertexDescriptor, Graph.EdgeDescriptor>?
        private var queue: any QueueProtocol<Graph.VertexDescriptor>

        private var propertyMap: any MutablePropertyMap<Graph.VertexDescriptor, VertexPropertyValues>
        private let colorProperty: any VertexProperty<Color>.Type = ColorProperty.self
        private let distanceProperty: any VertexProperty<Distance>.Type = DistanceProperty.self
        private let predecessorEdgeProperty: any VertexProperty<Graph.EdgeDescriptor?>.Type = PredecessorEdgeProperty.self
        
        init(
            graph: Graph,
            source: Graph.VertexDescriptor,
            visitor: Visitor<Graph.VertexDescriptor, Graph.EdgeDescriptor>?,
            queue: any QueueProtocol<Graph.VertexDescriptor>
        ) {
            self.graph = graph
            self.source = source
            self.visitor = visitor
            self.propertyMap = graph.makeVertexPropertyMap()
            self.queue = queue
            
            // Initialize all vertices
            for vertex in graph.vertices() {
                propertyMap[vertex][colorProperty] = .white
                propertyMap[vertex][distanceProperty] = .unreachable
                propertyMap[vertex][predecessorEdgeProperty] = nil
                visitor?.initializeVertex?(vertex)
            }
            
            // Prepare queue with source
            propertyMap[source][colorProperty] = .gray
            propertyMap[source][distanceProperty] = .reachable(0)
            self.queue.enqueue(source)
        }
        
        mutating func next() -> Result<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
            guard let current = queue.dequeue() else {
                return nil
            }
            
            visitor?.examineVertex?(current)
            
            // Examine all outgoing edges
            for edge in graph.outEdges(of: current) {
                visitor?.examineEdge?(edge)
                
                guard let destination = graph.destination(of: edge) else { continue }
                
                let destinationColor = propertyMap[destination][colorProperty]
                
                if destinationColor == .white {
                    // Tree edge - first time discovering this vertex
                    propertyMap[destination][colorProperty] = .gray
                    propertyMap[destination][distanceProperty] = propertyMap[current][distanceProperty] + 1
                    propertyMap[destination][predecessorEdgeProperty] = edge
                    visitor?.discoverVertex?(destination)
                    queue.enqueue(destination)
                    visitor?.treeEdge?(edge)
                } else {
                    // Non-tree edge
                    visitor?.nonTreeEdge?(edge)
                }
            }
            
            propertyMap[current][colorProperty] = .black
            visitor?.finishVertex?(current)
            
            return Result(
                source: source,
                examinedVertex: current,
                distanceProperty: distanceProperty,
                predecessorEdgeProperty: predecessorEdgeProperty,
                propertyMap: propertyMap
            )
        }
    }
}

extension BreadthFirstSearchAlgorithm.Iterator: IteratorProtocol {}

extension BreadthFirstSearchAlgorithm: Sequence {
    func makeIterator() -> Iterator {
        Iterator(graph: graph, source: source, visitor: makeVisitor?(), queue: makeQueue())
    }
}

extension BreadthFirstSearchAlgorithm.Result {
    func distance(of vertex: Vertex) -> BreadthFirstSearchAlgorithm.Distance {
        propertyMap[vertex][distanceProperty]
    }
    
    func predecessor(of vertex: Vertex, in graph: some IncidenceGraph<Vertex, Edge>) -> Vertex? {
        predecessorEdge(of: vertex).flatMap(graph.source)
    }
    
    func predecessorEdge(of vertex: Vertex) -> Edge? {
        propertyMap[vertex][predecessorEdgeProperty]
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

extension BreadthFirstSearchAlgorithm.Distance: Equatable {}

extension BreadthFirstSearchAlgorithm.Distance: Comparable {
    static func < (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
            case (_, .unreachable): true
            case (.unreachable, _): false
            case (.reachable(let lhsValue), .reachable(let rhsValue)): lhsValue < rhsValue
        }
    }
}

extension BreadthFirstSearchAlgorithm.Distance {
    static func + (lhs: Self, rhs: UInt) -> Self {
        switch lhs {
            case .unreachable: .unreachable
            case .reachable(let lhsValue): .reachable(lhsValue + rhs)
        }
    }
}

extension BreadthFirstSearchAlgorithm.Distance: ExpressibleByIntegerLiteral {
    init(integerLiteral value: UInt) {
        self = .reachable(value)
    }
}

extension BreadthFirstSearchAlgorithm.Distance: ExpressibleByNilLiteral {
    init(nilLiteral: ()) {
        self = .unreachable
    }
}

// Convenience: preserve a compatibility API that fully runs BFS and returns the final state
extension BreadthFirstSearchAlgorithm {
    @discardableResult
    static func run(
        on graph: Graph,
        from source: Graph.VertexDescriptor,
        visitor: Visitor<Graph.VertexDescriptor, Graph.EdgeDescriptor>? = nil
    ) -> Result<Graph.VertexDescriptor, Graph.EdgeDescriptor> {
        var last: Result<Graph.VertexDescriptor, Graph.EdgeDescriptor>?
        for step in BreadthFirstSearchAlgorithm(on: graph, from: source, makeVisitor: visitor.map { visitor in
            { visitor }
        }) {
            last = step
        }
        return last!
    }
}
