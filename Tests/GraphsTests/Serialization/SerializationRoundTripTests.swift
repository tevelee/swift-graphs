#if !GRAPHS_USES_TRAITS || GRAPHS_SERIALIZATION
@testable import Graphs
import Testing

/// Tests that verify serialization correctness beyond exact string matching.
///
/// The library currently supports serialization (graph → string) but not deserialization
/// (string → graph), so full structural round-trips are not possible. These tests instead
/// check properties that hold across any correctly-implemented serialization:
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
}
#endif
