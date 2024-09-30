import Collections

/// A graph structure representing a grid where each cell holds a value and edges can be defined between nodes.
public struct GridGraph<Value, Edge> {
    /// A node in the grid graph, representing a cell with a position
    public typealias Node = GridPosition

    /// The grid of values representing the graph.
    public let grid: [[Value]]
    /// The set of available directions for edges in the grid.
    public let availableDirections: OrderedSet<GridDirection>
    /// A closure to determine the edge between two nodes.
    @usableFromInline let edge: (Node, Node) -> Edge

    /// Initializes a new grid graph with the given grid, available directions, and edge function.
    /// - Parameters:
    ///   - grid: A 2D array representing the grid of values.
    ///   - availableDirections: The set of directions in which edges can be created. Defaults to orthogonal and diagonal directions.
    ///   - edge: A closure that takes two nodes and returns the edge between them.
    @inlinable public init(
        grid: [some Sequence<Value>],
        availableDirections: OrderedSet<GridDirection> = .orthogonal + .diagonal,
        edge: @escaping (Node, Node) -> Edge
    ) {
        self.grid = grid.map(Array.init)
        self.availableDirections = availableDirections
        self.edge = edge
    }

    /// Initializes a new grid graph with the given grid and available directions, assuming edges have no value.
    /// - Parameters:
    ///   - grid: A 2D array representing the grid of values.
    ///   - availableDirections: The set of directions in which edges can be created. Defaults to orthogonal and diagonal directions.
    @inlinable public init(
        grid: [some Sequence<Value>],
        availableDirections: OrderedSet<GridDirection> = .orthogonal + .diagonal
    ) where Edge == Void {
        self.init(grid: grid, availableDirections: availableDirections) { _, _ in () }
    }

    /// Accesses the value at the specified position in the grid.
    /// - Parameter position: The position in the grid.
    /// - Returns: The value at the specified position.
    @inlinable public subscript(position: GridPosition) -> Value {
        grid[position]
    }
}

extension GridGraph: ConnectedGraph {
    /// Returns the edges originating from the specified node.
    /// - Parameter node: The node from which to get the edges.
    /// - Returns: An array of `GraphEdge` instances representing the edges from the specified node.
    @inlinable public func edges(from node: Node) -> [GraphEdge<Node, Edge>] {
        grid.neighbors(of: node, in: availableDirections).map {
            GraphEdge(source: node, destination: $0, value: edge(node, $0))
        }
    }
}

extension GridGraph: Graph {
    /// Returns all nodes in the grid.
    public var allNodes: [Node] {
        grid.positions.compactMap(\.self)
    }
}

/// Represents a position in the grid with x and y coordinates.
public struct GridPosition: Hashable {
    /// The x-coordinate of the position.
    public let x: Int
    /// The y-coordinate of the position.
    public let y: Int

    /// Initializes a new `GridPosition` with the given coordinates.
    /// - Parameters:
    ///   - x: The x-coordinate.
    ///   - y: The y-coordinate.
    @inlinable public init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }

    /// Moves the position by the given movement.
    /// - Parameter movement: The movement to apply.
    /// - Returns: A new `GridPosition` after applying the movement.
    @inlinable public func move(_ movement: GridMovement) -> Self {
        GridPosition(
            x: x + movement.x,
            y: y + movement.y
        )
    }

    /// The coordinates of the position as a SIMD2 vector.
    @inlinable public var coordinates: SIMD2<Double> {
        SIMD2(Double(x), Double(y))
    }
}

/// Represents movement in a 2D grid.
public struct GridMovement: Hashable {
    /// The x offset of the movement.
    public let x: Int
    /// The y offset of the movement.
    public let y: Int

    /// Initializes a new `GridMovement` with the given offsets.
    /// - Parameters:
    ///   - x: The x-offset.
    ///   - y: The y-offset.
    @inlinable public init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }

    /// Repeats the movement a given number of times.
    /// - Parameter count: The number of times to repeat the movement.
    /// - Returns: A new `GridMovement` with the repeated offsets.
    @inlinable public func repeated(times count: Int) -> GridMovement {
        GridMovement(
            x: x * count,
            y: y * count
        )
    }
}

/// Represents a direction in the 2D space.
public enum GridDirection: CaseIterable, Hashable, Sendable {
    case up, right, down, left
    case upRight, downRight, downLeft, upLeft

    /// The movement associated with the direction.
    @inlinable public var movement: GridMovement {
        switch self {
        case .up: GridMovement(x: 0, y: -1)
        case .down: GridMovement(x: 0, y: 1)
        case .left: GridMovement(x: -1, y: 0)
        case .right: GridMovement(x: 1, y: 0)
        case .upLeft: GridMovement(x: -1, y: -1)
        case .upRight: GridMovement(x: 1, y: -1)
        case .downLeft: GridMovement(x: -1, y: 1)
        case .downRight: GridMovement(x: 1, y: 1)
        }
    }
}

extension OrderedSet<GridDirection> {
    /// A set of horizontal directions (left and right).
    public static let horizontal: Self = [.left, .right]

    /// A set of vertical directions (up and down).
    public static let vertical: Self = [.up, .down]

    /// A set of orthogonal directions (right, down, left, up).
    public static let orthogonal: Self = [.right, .down, .left, .up]

    /// A set of diagonal directions (up-right, down-right, down-left, up-left).
    public static let diagonal: Self = [.upRight, .downRight, .downLeft, .upLeft]

    /// Combines two sets of directions.
    /// - Parameters:
    ///   - lhs: The first set of directions.
    ///   - rhs: The second set of directions.
    /// - Returns: A new set containing all directions from both sets.
    public static func + (lhs: Self, rhs: Self) -> Self {
        lhs.union(rhs)
    }

    /// Subtracts one set of directions from another.
    /// - Parameters:
    ///   - lhs: The first set of directions.
    ///   - rhs: The second set of directions.
    /// - Returns: A new set containing the directions from the first set that are not in the second set.
    public static func - (lhs: Self, rhs: Self) -> Self {
        lhs.subtracting(rhs)
    }
}

extension Array where Element: Collection, Element.Index == Int {
    /// Returns a sequence of all positions in the grid.
    @inlinable public var positions: some Sequence<GridPosition> {
        self.lazy.enumerated().flatMap { x, line in
            line.indices.lazy.map { GridPosition(x: x, y: $0) }
        }
    }

    /// Accesses the element at the specified grid position.
    /// - Parameter position: The position in the grid.
    /// - Returns: The element at the specified position.
    @inlinable public subscript(position: GridPosition) -> Element.Element {
        self[position.y][position.x]
    }

    /// Accesses the element at the specified grid position, wrapping around if the position is out of bounds.
    /// - Parameter position: The position in the grid.
    /// - Returns: The element at the specified position, wrapping around if necessary.
    @inlinable public subscript(infinite position: GridPosition) -> Element.Element {
        let row = nonNegativeModulo(of: position.y, by: count)
        let column = nonNegativeModulo(of: position.x, by: self[row].count)
        return self[row][column]
    }

    /// Accesses the element at the specified grid position, returning nil if the position is out of bounds.
    /// - Parameter position: The position in the grid.
    /// - Returns: The element at the specified position, or nil if the position is out of bounds.
    @inlinable public subscript(safe position: GridPosition) -> Element.Element? {
        self[safe: position.y]?[safe: position.x]
    }

    /// Returns the neighboring positions of the specified grid position in the given directions.
    /// - Parameters:
    ///   - position: The position in the grid.
    ///   - directions: The directions in which to find neighbors.
    /// - Returns: A sequence of neighboring positions.
    @inlinable public func neighbors(of position: GridPosition, in directions: some Sequence<GridDirection>) -> some Sequence<GridPosition> {
        directions.lazy.map(\.movement).map(position.move).filter(contains)
    }

    /// Checks if the grid contains the specified position.
    /// - Parameter position: The position to check.
    /// - Returns: True if the grid contains the position, false otherwise.
    @inlinable public func contains(position: GridPosition) -> Bool {
        indices.contains(position.y) && self[position.y].indices.contains(position.x)
    }
}
