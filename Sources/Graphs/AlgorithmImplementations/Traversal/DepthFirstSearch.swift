import Collections

struct DepthFirstSearch<Graph: IncidenceGraph> where Graph.VertexDescriptor: Hashable {
    typealias Vertex = Graph.VertexDescriptor
    typealias Edge = Graph.EdgeDescriptor

    enum Time {
        case undiscovered
        case discovered(UInt)
        case finished(UInt)
    }

    struct Visitor {
        var discoverVertex: ((Vertex) -> Void)?
        var examineVertex: ((Vertex) -> Void)?
        var examineEdge: ((Edge) -> Void)?
        var treeEdge: ((Edge) -> Void)?
        var backEdge: ((Edge) -> Void)?
        var forwardEdge: ((Edge) -> Void)?
        var crossEdge: ((Edge) -> Void)?
        var finishVertex: ((Vertex) -> Void)?
        var shouldTraverse: (((from: Vertex, to: Vertex, via: Edge, context: Result)) -> Bool)?
    }

    private enum Color {
        case white // Undiscovered
        case gray // Discovered but not fully processed
        case black // Fully processed
    }

    struct Result {
        typealias Vertex = Graph.VertexDescriptor
        typealias Edge = Graph.EdgeDescriptor
        fileprivate let source: Vertex
        let currentVertex: Vertex
        let discoveryTimeProperty: any VertexProperty<Time>.Type
        let finishTimeProperty: any VertexProperty<Time>.Type
        let predecessorEdgeProperty: any VertexProperty<Edge?>.Type
        let depthProperty: any VertexProperty<UInt?>.Type
        let propertyMap: any PropertyMap<Vertex, VertexPropertyValues>
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

    struct DFSFrame {
        let vertex: Vertex
        let isFirstVisit: Bool
        let depth: UInt
    }

    private let graph: Graph
    private let source: Vertex
    private let makeStack: () -> any StackProtocol<DFSFrame>

    init(
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

    func makeIterator(visitor: Visitor?) -> Iterator {
        Iterator(graph: graph, source: source, visitor: visitor, stack: makeStack())
    }

    struct Iterator {
        private let graph: Graph
        private let source: Vertex
        private let visitor: Visitor?
        private var stack: any StackProtocol<DFSFrame>
        private var time: UInt = 0

        private var propertyMap: any MutablePropertyMap<Vertex, VertexPropertyValues>
        private let colorProperty: any VertexProperty<Color>.Type = ColorProperty.self
        private let discoveryTimeProperty: any VertexProperty<Time>.Type = DiscoveryTimeProperty.self
        private let finishTimeProperty: any VertexProperty<Time>.Type = FinishTimeProperty.self
        private let predecessorEdgeProperty: any VertexProperty<Edge?>.Type = PredecessorEdgeProperty.self
        private let depthProperty: any VertexProperty<UInt?>.Type = DepthProperty.self

        init(
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

        mutating func next() -> Result? {
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
    func makeIterator() -> Iterator {
        makeIterator(visitor: nil)
    }
}

extension DepthFirstSearch.Result {
    func discoveryTime(of vertex: Vertex) -> DepthFirstSearch<Graph>.Time {
        propertyMap[vertex][discoveryTimeProperty]
    }

    func finishTime(of vertex: Vertex) -> DepthFirstSearch<Graph>.Time {
        propertyMap[vertex][finishTimeProperty]
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

    func depth() -> UInt {
        propertyMap[currentVertex][depthProperty] ?? 0
    }

    func depth(of vertex: Vertex) -> UInt? {
        propertyMap[vertex][depthProperty]
    }
}

extension DepthFirstSearch.Time: Equatable {}

extension DepthFirstSearch.Time: Comparable {
    static func < (lhs: Self, rhs: Self) -> Bool {
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
    typealias IntegerLiteralType = UInt

    init(integerLiteral value: UInt) {
        self = .discovered(value)
    }
}

extension DepthFirstSearch.Time: ExpressibleByNilLiteral {
    init(nilLiteral: ()) {
        self = .undiscovered
    }
}

extension DepthFirstSearch: VisitorSupportingSequence {}
