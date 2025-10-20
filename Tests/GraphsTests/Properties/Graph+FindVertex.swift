@testable import Graphs

extension VertexPropertyGraph where Self: VertexListGraph {
    func findVertex(labeled: String) -> VertexDescriptor? {
        vertices { $0.label == labeled }.first { _ in true }
    }
}
