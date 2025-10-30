/// A protocol for algorithms that perform graph coloring.
public protocol ColoringAlgorithm<Graph, Color> {
    /// The graph type that this algorithm operates on.
    associatedtype Graph: IncidenceGraph & VertexListGraph where Graph.VertexDescriptor: Hashable
    /// The color type used for coloring.
    associatedtype Color: Hashable & Equatable
    /// The visitor type for observing algorithm progress.
    associatedtype Visitor
    
    /// Colors the graph using this algorithm.
    ///
    /// - Parameters:
    ///   - graph: The graph to color.
    ///   - visitor: An optional visitor to observe the algorithm progress.
    /// - Returns: The graph coloring result.
    func color(graph: Graph, visitor: Visitor?) -> GraphColoring<Graph.VertexDescriptor, Color>
}

extension VisitorWrapper: ColoringAlgorithm where Base: ColoringAlgorithm, Base.Visitor == Visitor, Visitor: Composable, Visitor.Other == Visitor {
    @inlinable
    public func color(graph: Base.Graph, visitor: Base.Visitor?) -> GraphColoring<Base.Graph.VertexDescriptor, Base.Color> {
        base.color(graph: graph, visitor: self.visitor.combined(with: visitor))
    }
}

/// Represents the result of a graph coloring algorithm.
public struct GraphColoring<Vertex: Hashable, Color: Hashable & Equatable> {
    /// The mapping of vertices to their assigned colors.
    public let vertexColors: [Vertex: Color]
    /// The total number of colors used.
    public let colorCount: Int
    /// Whether the coloring is proper (no adjacent vertices have the same color).
    public let isProper: Bool
    
    /// Creates a new graph coloring result.
    ///
    /// - Parameters:
    ///   - vertexColors: The mapping of vertices to colors.
    ///   - isProper: Whether the coloring is proper.
    @inlinable
    public init(vertexColors: [Vertex: Color], isProper: Bool) {
        self.vertexColors = vertexColors
        self.colorCount = Set(vertexColors.values).count
        self.isProper = isProper
    }
    
    /// Gets the color assigned to a specific vertex.
    ///
    /// - Parameter vertex: The vertex to get the color for.
    /// - Returns: The color assigned to the vertex, or nil if not colored.
    @inlinable
    public func color(for vertex: Vertex) -> Color? {
        vertexColors[vertex]
    }
    
    /// Gets all vertices that are assigned a specific color.
    ///
    /// - Parameter color: The color to find vertices for.
    /// - Returns: An array of vertices with the specified color.
    @inlinable
    public func vertices(with color: Color) -> [Vertex] {
        vertexColors.compactMap { vertex, vertexColor in
            vertexColor == color ? vertex : nil
        }
    }
    
    /// The chromatic number of the graph (minimum number of colors needed).
    @inlinable
    public var chromaticNumber: Int {
        colorCount
    }
}

extension GraphColoring: Sendable where Vertex: Sendable, Color: Sendable {}

extension IncidenceGraph where Self: VertexListGraph, VertexDescriptor: Hashable {
    /// Colors the graph using the specified algorithm.
    ///
    /// - Parameter algorithm: The coloring algorithm to use.
    /// - Returns: The graph coloring result.
    @inlinable
    public func colorGraph<Color: Hashable & Equatable>(
        using algorithm: some ColoringAlgorithm<Self, Color>
    ) -> GraphColoring<VertexDescriptor, Color> {
        algorithm.color(graph: self, visitor: nil)
    }
}

// MARK: - Default Implementations

extension IncidenceGraph where Self: VertexListGraph, VertexDescriptor: Hashable {
    /// Colors the graph using the Greedy algorithm as the default.
    /// This is a simple and efficient algorithm that works well for most graphs.
    ///
    /// - Returns: The graph coloring result using integer colors.
    @inlinable
    public func colorGraph() -> GraphColoring<VertexDescriptor, Int> {
        colorGraph(using: .greedy())
    }
}

/// A protocol for color types that can be represented as integers.
public protocol IntegerBasedColor: Hashable & Equatable {
    /// Creates a color from an integer value.
    init(integerValue value: Int)
    /// The integer representation of this color.
    var integerValue: Int { get }
}

extension Int: IntegerBasedColor {
    @inlinable
    public init(integerValue value: Int) {
        self = value
    }
    
    @inlinable
    public var integerValue: Int {
        self
    }
}

extension IntegerBasedColor where Self: RawRepresentable, Self.RawValue == Int {
    @inlinable
    public init(integerValue value: Int) {
        self = Self(rawValue: value)!
    }
    
    @inlinable
    public var integerValue: Int {
        self.rawValue
    }
}

/// A named color enum for graph coloring.
public enum NamedColor: Int, CaseIterable, IntegerBasedColor {
    /// Red color.
    case red = 0
    /// Green color.
    case green = 1
    /// Blue color.
    case blue = 2
    /// Yellow color.
    case yellow = 3
}
