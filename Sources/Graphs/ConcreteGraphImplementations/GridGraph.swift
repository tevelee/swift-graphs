import Collections
struct GridGraph: Graph {
    struct Vertex: Hashable {
        let x: Int
        let y: Int
    }

    struct Edge: Hashable {
        let source: Vertex
        let destination: Vertex
    }

    typealias VertexDescriptor = Vertex
    typealias EdgeDescriptor = Edge

    let width: Int
    let height: Int
    let allowedDirections: OrderedSet<GridDirection>

    init(width: Int, height: Int, allowedDirections: OrderedSet<GridDirection> = .orthogonal) {
        self.width = width
        self.height = height
        self.allowedDirections = allowedDirections
    }
}

extension GridGraph: VertexListGraph {
    struct Vertices: Sequence {
        let width: Int
        let height: Int
        func makeIterator() -> Iterator {
            Iterator(width: width, height: height)
        }

        struct Iterator: IteratorProtocol {
            let width: Int
            let height: Int
            var x: Int = 0
            var y: Int = 0
            mutating func next() -> GridGraph.Vertex? {
                guard y < height else { return nil }
                let v = GridGraph.Vertex(x: x, y: y)
                x += 1
                if x >= width { x = 0; y += 1 }
                return v
            }
        }
    }

    func vertices() -> Vertices { .init(width: width, height: height) }
    var vertexCount: Int { width * height }
}

extension GridGraph: IncidenceGraph {
    struct OutgoingEdges: Sequence {
        let v: GridGraph.Vertex
        let width: Int
        let height: Int
        let directions: OrderedSet<GridDirection>
        func makeIterator() -> Iterator { Iterator(v: v, width: width, height: height, directions: directions) }

        struct Iterator: IteratorProtocol {
            let v: GridGraph.Vertex
            let width: Int
            let height: Int
            let directions: OrderedSet<GridDirection>
            var idx: Int = 0
            mutating func next() -> GridGraph.Edge? {
                while idx < directions.count {
                    defer { idx += 1 }
                    let dir = directions[directions.index(directions.startIndex, offsetBy: idx)]
                    let (dx, dy) = GridGraph.delta(for: dir)
                    let nx = v.x + dx
                    let ny = v.y + dy
                    if nx >= 0 && nx < width && ny >= 0 && ny < height {
                        return GridGraph.Edge(source: v, destination: .init(x: nx, y: ny))
                    }
                }
                return nil
            }
        }
    }

    func outgoingEdges(of vertex: VertexDescriptor) -> OutgoingEdges {
        .init(v: vertex, width: width, height: height, directions: allowedDirections)
    }

    func source(of edge: EdgeDescriptor) -> VertexDescriptor? { edge.source }
    func destination(of edge: EdgeDescriptor) -> VertexDescriptor? { edge.destination }
    func outDegree(of vertex: VertexDescriptor) -> Int {
        var d = 0
        for dir in allowedDirections {
            let (dx, dy) = GridGraph.delta(for: dir)
            let nx = vertex.x + dx
            let ny = vertex.y + dy
            if nx >= 0 && nx < width && ny >= 0 && ny < height { d += 1 }
        }
        return d
    }
}

extension GridGraph: BidirectionalGraph {
    struct IncomingEdges: Sequence {
        let v: GridGraph.Vertex
        let width: Int
        let height: Int
        let directions: OrderedSet<GridDirection>
        func makeIterator() -> Iterator { Iterator(v: v, width: width, height: height, directions: directions) }

        struct Iterator: IteratorProtocol {
            let v: GridGraph.Vertex
            let width: Int
            let height: Int
            let directions: OrderedSet<GridDirection>
            var idx: Int = 0
            mutating func next() -> GridGraph.Edge? {
                while idx < directions.count {
                    defer { idx += 1 }
                    let dir = directions[directions.index(directions.startIndex, offsetBy: idx)]
                    let (dx, dy) = GridGraph.delta(for: dir)
                    let px = v.x - dx
                    let py = v.y - dy
                    if px >= 0 && px < width && py >= 0 && py < height {
                        return GridGraph.Edge(source: .init(x: px, y: py), destination: v)
                    }
                }
                return nil
            }
        }
    }

    func incomingEdges(of vertex: VertexDescriptor) -> IncomingEdges {
        .init(v: vertex, width: width, height: height, directions: allowedDirections)
    }

    func inDegree(of vertex: VertexDescriptor) -> Int {
        var d = 0
        for dir in allowedDirections {
            let (dx, dy) = GridGraph.delta(for: dir)
            let px = vertex.x - dx
            let py = vertex.y - dy
            if px >= 0 && px < width && py >= 0 && py < height { d += 1 }
        }
        return d
    }
}

extension GridGraph: EdgeListGraph {
    struct Edges: Sequence {
        let width: Int
        let height: Int
        let directions: OrderedSet<GridDirection>
        func makeIterator() -> Iterator { Iterator(width: width, height: height, directions: directions) }

        struct Iterator: IteratorProtocol {
            let width: Int
            let height: Int
            let directions: OrderedSet<GridDirection>
            var x: Int = 0
            var y: Int = 0
            var edgeIter: GridGraph.OutgoingEdges.Iterator? = nil

            mutating func next() -> GridGraph.Edge? {
                while true {
                    if var it = edgeIter {
                        if let e = it.next() {
                            edgeIter = it
                            return e
                        } else {
                            edgeIter = nil
                        }
                    }
                    guard y < height else { return nil }
                    let v = GridGraph.Vertex(x: x, y: y)
                    edgeIter = GridGraph.OutgoingEdges(v: v, width: width, height: height, directions: directions).makeIterator()
                    x += 1
                    if x >= width { x = 0; y += 1 }
                }
            }
        }
    }

    func edges() -> Edges { .init(width: width, height: height, directions: allowedDirections) }

    var edgeCount: Int {
        var total = 0
        for v in vertices() {
            total += outDegree(of: v)
        }
        return total
    }
}

extension GridGraph: EdgeLookupGraph {
    func edge(from source: VertexDescriptor, to destination: VertexDescriptor) -> EdgeDescriptor? {
        let dx = destination.x - source.x
        let dy = destination.y - source.y
        var allowed = false
        for dir in allowedDirections {
            let (adx, ady) = GridGraph.delta(for: dir)
            if adx == dx && ady == dy { allowed = true; break }
        }
        if !allowed { return nil }
        if destination.x < 0 || destination.x >= width { return nil }
        if destination.y < 0 || destination.y >= height { return nil }
        return Edge(source: source, destination: destination)
    }
}

private extension GridGraph {
    static func delta(for direction: GridDirection) -> (Int, Int) {
        switch direction {
        case .up: return (0, -1)
        case .right: return (1, 0)
        case .down: return (0, 1)
        case .left: return (-1, 0)
        case .upRight: return (1, -1)
        case .downRight: return (1, 1)
        case .downLeft: return (-1, 1)
        case .upLeft: return (-1, -1)
        }
    }
}

enum GridDirection: CaseIterable, Hashable, Sendable {
    case up, right, down, left
    case upRight, downRight, downLeft, upLeft
}

extension OrderedSet<GridDirection> {
    static let horizontal: Self = [.left, .right]
    static let vertical: Self = [.up, .down]
    static let orthogonal: Self = horizontal + vertical
    static let diagonal: Self = [.upRight, .downRight, .downLeft, .upLeft]
    static let all: Self = orthogonal + diagonal

    static func + (lhs: Self, rhs: Self) -> Self {
        lhs.union(rhs)
    }

    static func - (lhs: Self, rhs: Self) -> Self {
        lhs.subtracting(rhs)
    }
}
