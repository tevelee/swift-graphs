@testable import Graphs

enum Label: VertexProperty, EdgeProperty {
    static let defaultValue = ""
}

extension VertexPropertyValues {
    var label: String {
        get { self[Label.self] }
        set { self[Label.self] = newValue }
    }
}

extension EdgePropertyValues {
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
    
    mutating func addEdge(
        from source: VertexDescriptor,
        to destination: VertexDescriptor,
        file: String = #file,
        line: Int = #line
    ) -> EdgeDescriptor? {
        addEdge(from: source, to: destination) { $0.label = "\(file):\(line)" }
    }
}

extension MutablePropertyGraph {
    mutating func add(edges: [(String, String)]) {
        let labels: [String: VertexDescriptor] = Dictionary(
            grouping: edges.flatMap { [$0, $1] },
            by: \.self
        )
        .compactMapValues(\.first)
        .mapValues { label in
            self.addVertex { $0.label = label }
        }

        for (sourceLabel, destinationLabel) in edges {
            let source = labels[sourceLabel]!
            let destination = labels[destinationLabel]!
            addEdge(from: source, to: destination)
        }
    }
    
    mutating func add(edges: [(String, String, weight: Double)]) {
        let labels: [String: VertexDescriptor] = Dictionary(
            grouping: edges.flatMap { source, destination, _ in
                [source, destination]
            },
            by: \.self
        )
        .compactMapValues(\.first)
        .mapValues { label in
            self.addVertex { $0.label = label }
        }

        for (sourceLabel, destinationLabel, weight) in edges {
            let source = labels[sourceLabel]!
            let destination = labels[destinationLabel]!
            addEdge(from: source, to: destination) {
                $0.weight = weight
            }
        }
    }
}

extension AdjacencyList {
    func traverse(
        from source: String,
        using algorithm: some TraversalAlgorithm<Self>
    ) -> TraversalResult<VertexDescriptor, EdgeDescriptor> {
        let source = vertices().first { self[$0].label == source }!
        return algorithm.traverse(from: source, in: self)
    }
}

extension TraversalResult {
    func verticeLabels<G: PropertyGraph>(in graph: G) -> [String] where G.VertexDescriptor == Vertex {
        vertices.map { graph[$0].label }
    }
}
