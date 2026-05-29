#if !GRAPHS_USES_TRAITS || GRAPHS_SERIALIZATION
@testable import Graphs
import Testing

/// Tests that verify serialization correctness beyond exact string matching.
///
/// Full structural round-trips (serialize → deserialize → re-serialize) live in
/// `SerializationDeserializationTests`. The tests here instead check properties that hold
/// across any correctly-implemented *serialization*, independent of deserialization:
///
/// 1. **Idempotency** — serializing the same graph twice yields identical output.
///    Non-determinism (e.g., HashMap iteration order) would break this.
/// 2. **Property presence** — when vertex/edge properties are included, the
///    serialized output must contain the property values as text.
/// 3. **Structural reflection** — metadata (vertex/edge counts) in the output must
///    match the actual graph structure.
struct SerializationRoundTripTests {

    // MARK: - Idempotency

    /// Serializing the same graph to DOT twice must produce bit-for-bit identical output.
    @Test func dotSerializationIsIdempotent() throws {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: a, to: c)

        let formatter = GraphFormatter()
        let first  = try formatter.string(from: graph, using: .dot(directed: true, graphName: "G"),
                                          vertexProperties: [Label.self])
        let second = try formatter.string(from: graph, using: .dot(directed: true, graphName: "G"),
                                          vertexProperties: [Label.self])
        #expect(first == second, "DOT serialization must be deterministic")
    }

    /// Serializing the same graph to GraphML twice must produce bit-for-bit identical output.
    @Test func graphMLSerializationIsIdempotent() throws {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        graph.addEdge(from: a, to: b) { $0.weight = 1.5 }
        graph.addEdge(from: b, to: c) { $0.weight = 2.5 }

        let formatter = GraphFormatter()
        let first  = try formatter.string(from: graph, using: .graphML(),
                                          vertexProperties: [Label.self],
                                          edgeProperties: [Weight.self])
        let second = try formatter.string(from: graph, using: .graphML(),
                                          vertexProperties: [Label.self],
                                          edgeProperties: [Weight.self])
        #expect(first == second, "GraphML serialization must be deterministic")
    }

    /// Serializing the same graph to JSON twice must produce bit-for-bit identical output.
    @Test func jsonSerializationIsIdempotent() throws {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        graph.addEdge(from: a, to: b) { $0.weight = 3.14 }

        let formatter = GraphFormatter()
        let first  = try formatter.string(from: graph, using: .json(prettyPrint: true, includeMetadata: true),
                                          vertexProperties: [Label.self],
                                          edgeProperties: [Weight.self])
        let second = try formatter.string(from: graph, using: .json(prettyPrint: true, includeMetadata: true),
                                          vertexProperties: [Label.self],
                                          edgeProperties: [Weight.self])
        #expect(first == second, "JSON serialization must be deterministic")
    }

    // MARK: - Property Presence

    /// When vertex labels are included in serialization, the label values must appear in the output.
    @Test func vertexLabelsAppearInJsonOutput() throws {
        var graph = AdjacencyList()
        graph.addVertex { $0.label = "Tokyo" }
        graph.addVertex { $0.label = "Osaka" }

        let formatter = GraphFormatter()
        let json = try formatter.string(from: graph,
                                        using: .json(prettyPrint: true, includeMetadata: false),
                                        vertexProperties: [Label.self])
        #expect(json.contains("Tokyo"), "Vertex label 'Tokyo' must appear in JSON output")
        #expect(json.contains("Osaka"), "Vertex label 'Osaka' must appear in JSON output")
    }

    /// When edge weights are included in serialization, the weight values must appear in the output.
    @Test func edgeWeightsAppearInGraphMLOutput() throws {
        var graph = AdjacencyList()
        let a = graph.addVertex()
        let b = graph.addVertex()
        graph.addEdge(from: a, to: b) { $0.weight = 42.0 }

        let formatter = GraphFormatter()
        let xml = try formatter.string(from: graph, using: .graphML(),
                                       edgeProperties: [Weight.self])
        #expect(xml.contains("42"), "Edge weight 42 must appear in GraphML output")
    }

    /// DOT output with label properties must contain the label text.
    @Test func vertexLabelsAppearInDotOutput() throws {
        var graph = AdjacencyList()
        graph.addVertex { $0.label = "Berlin" }
        graph.addVertex { $0.label = "Paris" }

        let formatter = GraphFormatter()
        let dot = try formatter.string(from: graph,
                                       using: .dot(directed: true, graphName: "Cities"),
                                       vertexProperties: [Label.self])
        #expect(dot.contains("Berlin"), "Vertex label 'Berlin' must appear in DOT output")
        #expect(dot.contains("Paris"), "Vertex label 'Paris' must appear in DOT output")
    }

    // MARK: - Structural Reflection (JSON metadata)

    /// JSON with metadata must report vertex and edge counts matching the actual graph.
    @Test func jsonMetadataReflectsGraphStructure() throws {
        var graph = AdjacencyList()
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)

        let formatter = GraphFormatter()
        let json = try formatter.string(from: graph,
                                        using: .json(prettyPrint: true, includeMetadata: true))

        // The JSON metadata block reports counts as integer literals in the output
        #expect(json.contains("\"vertexCount\" : 3"),
                "JSON metadata must report vertexCount = 3")
        #expect(json.contains("\"edgeCount\" : 2"),
                "JSON metadata must report edgeCount = 2")
    }

    /// Empty graph serialization reports zero vertices and edges in JSON metadata.
    @Test func emptyGraphJsonMetadataIsZero() throws {
        let graph = AdjacencyList()
        let formatter = GraphFormatter()
        let json = try formatter.string(from: graph,
                                        using: .json(prettyPrint: true, includeMetadata: true))
        #expect(json.contains("\"vertexCount\" : 0"),
                "Empty graph JSON must report vertexCount = 0")
        #expect(json.contains("\"edgeCount\" : 0"),
                "Empty graph JSON must report edgeCount = 0")
    }

    // MARK: - SerializationError descriptions

    @Test func serializationErrorDescriptions() {
        let e1 = SerializationError.missingDescriptorIdentifier
        #expect(e1.description.contains("SerializableDescriptor"), "missingDescriptorIdentifier description must name the protocol")

        let e2 = SerializationError.unsupportedPropertyType("MyType")
        #expect(e2.description.contains("MyType"), "unsupportedPropertyType description must include the type name")

        struct TestError: Error {}
        let e3 = SerializationError.encodingFailed(TestError())
        #expect(e3.description.contains("Encoding"), "encodingFailed description must describe the failure")
    }

    // MARK: - AdjacencyMatrix descriptor identifiers

    @Test func adjacencyMatrixDescriptorIdentifiers() throws {
        var graph = AdjacencyMatrix()
        let a = graph.addVertex()   // AdjacencyMatrix.Vertex — covers AdjacencyMatrix.Vertex.serializedIdentifier
        let b = graph.addVertex()
        _ = graph.addEdge(from: a, to: b)   // AdjacencyMatrix.Edge — covers AdjacencyMatrix.Edge.serializedIdentifier

        let formatter = GraphFormatter()
        let dot = try formatter.string(from: graph, using: .dot(directed: true))
        #expect(dot.contains("v0"), "AdjacencyMatrix vertex serialized id starts with 'v'")
    }

    // MARK: - GridGraph descriptor identifiers

    #if !GRAPHS_USES_TRAITS || GRAPHS_GRID_GRAPH
    @Test func gridGraphDescriptorIdentifiers() throws {
        let g = GridGraph(width: 2, height: 2, allowedDirections: .orthogonal)

        // GridGraph.Vertex.serializedIdentifier: "x_y"
        let v = GridGraph.Vertex(x: 1, y: 2)
        #expect(v.serializedIdentifier == "1_2")

        // GridGraph.Edge.serializedIdentifier: "src_to_dst"
        let e = GridGraph.Edge(source: .init(x: 0, y: 0), destination: .init(x: 1, y: 0))
        #expect(e.serializedIdentifier.contains("0_0") && e.serializedIdentifier.contains("1_0"))

        // Serializing a GridGraph exercises both GridGraph.Vertex and GridGraph.Edge conformances
        let formatter = GraphFormatter()
        let dot = try formatter.string(from: g, using: .dot(directed: true))
        #expect(dot.contains("0_0"), "GridGraph vertex ids use x_y format")
    }
    #endif

    // MARK: - Descriptor identifiers not reachable via formats

    /// `OrderedEdgeStorage.Edge`, `AdjacencyMatrix.Edge`, `String`, and `Int` all conform to
    /// `SerializableDescriptor`. Their `serializedIdentifier` properties are never called by
    /// any serialization format (formats use vertex ids for edge endpoints, not edge ids).
    /// Test them directly to cover the conformances.
    @Test func remainingDescriptorIdentifiers() throws {
        // OrderedEdgeStorage.Edge
        var adjList = AdjacencyList()
        let u = adjList.addVertex()
        let v = adjList.addVertex()
        let edge = adjList.addEdge(from: u, to: v)!
        #expect(edge.serializedIdentifier.hasPrefix("e"), "OrderedEdgeStorage.Edge id starts with 'e'")

        // AdjacencyMatrix.Edge
        var matrix = AdjacencyMatrix()
        let a = matrix.addVertex()
        let b = matrix.addVertex()
        let matEdge = matrix.addEdge(from: a, to: b)!
        #expect(matEdge.serializedIdentifier.hasPrefix("e"), "AdjacencyMatrix.Edge id starts with 'e'")

        // String conformance — vertex descriptors in InlineGraph
        let s: String = "hello"
        #expect(s.serializedIdentifier == "hello", "String.serializedIdentifier returns self")

        // Int conformance
        let n: Int = 42
        #expect(n.serializedIdentifier == "42", "Int.serializedIdentifier returns string representation")
    }

    // MARK: - Non-property GraphFormatter.format

    @Test func graphFormatterFormatWithoutProperties() throws {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        graph.addEdge(from: a, to: b)

        let formatter = GraphFormatter()
        // format(_:using:) without properties — exercises the non-property overload
        let data = try formatter.format(graph, using: .dot(directed: true))
        #expect(!data.isEmpty, "format(_:using:) must produce non-empty output")

        // string(from:using:) without properties — exercises that non-property overload
        let str = try formatter.string(from: graph, using: .dot(directed: true))
        #expect(str.contains("digraph"), "DOT output must contain 'digraph'")
    }
}
#endif
