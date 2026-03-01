@testable import Graphs

#if !GRAPHS_USES_TRAITS || GRAPHS_SERIALIZATION
enum Label: VertexProperty, EdgeProperty, SerializableProperty {
    static let defaultValue = ""
}
#else
enum Label: VertexProperty, EdgeProperty {
    static let defaultValue = ""
}
#endif

extension VertexProperties {
    var label: String {
        get { self[Label.self] }
        set { self[Label.self] = newValue }
    }
}

extension EdgeProperties {
    var label: String {
        get { self[Label.self] }
        set { self[Label.self] = newValue }
    }
}


extension AdjacencyList {
    func traverse(
        from sourceLabel: String,
        using algorithm: some TraversalAlgorithm<Self>
    ) -> TraversalResult<VertexDescriptor, EdgeDescriptor> {
        let sourceVertex = vertices().first { self[$0].label == sourceLabel }!
        return algorithm.traverse(from: sourceVertex, in: self, visitor: nil)
    }
}

extension TraversalResult {
    func vertexLabels<G: PropertyGraph>(in graph: G) -> [String] where G.VertexDescriptor == Vertex {
        vertices.map { graph[$0].label }
    }
}
