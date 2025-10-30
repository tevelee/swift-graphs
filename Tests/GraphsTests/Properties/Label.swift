@testable import Graphs

enum Label: VertexProperty, EdgeProperty {
    static let defaultValue = ""
}

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
    mutating func addVertex(
        file: String = #file,
        line: Int = #line
    ) -> VertexDescriptor {
        addVertex { $0.label = "\(file):\(line)" }
    }

    @discardableResult
    mutating func addEdge(
        from source: VertexDescriptor,
        to destination: VertexDescriptor,
        file: String = #file,
        line: Int = #line
    ) -> EdgeDescriptor? {
        addEdge(from: source, to: destination) { $0.label = "\(file):\(line)" }
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
