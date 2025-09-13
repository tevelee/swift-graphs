import Foundation

protocol ColoringAlgorithm<Graph, Color> {
    associatedtype Graph: IncidenceGraph & VertexListGraph where Graph.VertexDescriptor: Hashable
    associatedtype Color: Hashable & Equatable
    
    func colorGraph(in graph: Graph) -> GraphColoring<Graph.VertexDescriptor, Color>
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
        algorithm.colorGraph(in: self)
    }
}
