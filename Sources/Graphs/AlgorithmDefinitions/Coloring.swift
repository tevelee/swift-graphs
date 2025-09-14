import Foundation

protocol ColoringAlgorithm<Graph, Color> {
    associatedtype Graph: IncidenceGraph & VertexListGraph where Graph.VertexDescriptor: Hashable
    associatedtype Color: Hashable & Equatable
    
    func color(graph: Graph) -> GraphColoring<Graph.VertexDescriptor, Color>
}

struct GraphColoring<Vertex: Hashable, Color: Hashable & Equatable> {
    let vertexColors: [Vertex: Color]
    let colorCount: Int
    let isProper: Bool
    
    init(vertexColors: [Vertex: Color], isProper: Bool) {
        self.vertexColors = vertexColors
        self.colorCount = Set(vertexColors.values).count
        self.isProper = isProper
    }
    
    func color(for vertex: Vertex) -> Color? {
        vertexColors[vertex]
    }
    
    func vertices(with color: Color) -> [Vertex] {
        vertexColors.compactMap { vertex, vertexColor in
            vertexColor == color ? vertex : nil
        }
    }
    
    var chromaticNumber: Int {
        colorCount
    }
}

extension IncidenceGraph where Self: VertexListGraph, VertexDescriptor: Hashable {
    func colorGraph<Color: Hashable & Equatable>(
        using algorithm: some ColoringAlgorithm<Self, Color>
    ) -> GraphColoring<VertexDescriptor, Color> {
        algorithm.color(graph: self)
    }
}

protocol IntegerBasedColor: Hashable & Equatable {
    init(integerValue value: Int)
    var integerValue: Int { get }
}

extension Int: IntegerBasedColor {
    init(integerValue value: Int) {
        self = value
    }
    
    var integerValue: Int {
        self
    }
}

extension IntegerBasedColor where Self: RawRepresentable, Self.RawValue == Int {
    init(integerValue value: Int) {
        self = Self(rawValue: value)!
    }
    
    var integerValue: Int {
        self.rawValue
    }
}

enum NamedColor: Int, CaseIterable, IntegerBasedColor {
    case red = 0
    case green = 1
    case blue = 2
    case yellow = 3
}
