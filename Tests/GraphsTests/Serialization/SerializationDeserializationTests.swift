#if !GRAPHS_USES_TRAITS || GRAPHS_SERIALIZATION
@testable import Graphs
import Testing
import Foundation

/// Tests for reading graphs back from serialized formats (string → graph).
///
/// A correctly-implemented deserializer must round-trip: serializing a graph,
/// reading it back, and re-serializing must reproduce the original output.
struct SerializationDeserializationTests {

    // MARK: - JSON

    /// JSON structural round-trip: serialize → read → re-serialize must reproduce the original.
    @Test func jsonStructuralRoundTrip() throws {
        var original = AdjacencyList()
        let a = original.addVertex()
        let b = original.addVertex()
        let c = original.addVertex()
        original.addEdge(from: a, to: b)
        original.addEdge(from: b, to: c)
        original.addEdge(from: a, to: c)

        let formatter = GraphFormatter()
        let json = try formatter.string(from: original, using: .json(prettyPrint: true, includeMetadata: true))

        var restored = AdjacencyList()
        try formatter.read(json, using: .json(), into: &restored)

        #expect(restored.vertexCount == 3, "round-trip must preserve vertex count")
        #expect(restored.edgeCount == 3, "round-trip must preserve edge count")

        let reserialized = try formatter.string(from: restored, using: .json(prettyPrint: true, includeMetadata: true))
        #expect(reserialized == json, "structural round-trip must reproduce the original serialization")
    }

    /// Reading malformed JSON (not an object) must throw rather than silently produce an empty graph.
    @Test func jsonInvalidFormatThrows() {
        let formatter = GraphFormatter()
        var graph = AdjacencyList()
        #expect(throws: SerializationError.self) {
            try formatter.read("[1, 2, 3]", using: .json(), into: &graph)
        }
    }

    /// An edge that references a vertex id not present in the `vertices` array must throw.
    @Test func jsonUnknownVertexReferenceThrows() {
        let formatter = GraphFormatter()
        var graph = AdjacencyList()
        let json = """
        { "vertices": [ { "id": "v0" } ], "edges": [ { "source": "v0", "target": "v9" } ] }
        """
        #expect(throws: SerializationError.self) {
            try formatter.read(json, using: .json(), into: &graph)
        }
    }

    // MARK: - GraphML

    /// GraphML structural round-trip: serialize → read → re-serialize must reproduce the original.
    @Test func graphMLStructuralRoundTrip() throws {
        var original = AdjacencyList()
        let a = original.addVertex()
        let b = original.addVertex()
        let c = original.addVertex()
        original.addEdge(from: a, to: b)
        original.addEdge(from: b, to: c)

        let formatter = GraphFormatter()
        let xml = try formatter.string(from: original, using: .graphML(directed: true, includeSchema: true))

        var restored = AdjacencyList()
        try formatter.read(xml, using: .graphML(), into: &restored)

        #expect(restored.vertexCount == 3, "round-trip must preserve vertex count")
        #expect(restored.edgeCount == 2, "round-trip must preserve edge count")

        let reserialized = try formatter.string(from: restored, using: .graphML(directed: true, includeSchema: true))
        #expect(reserialized == xml, "GraphML round-trip must reproduce the original serialization")
    }

    /// Reading malformed XML must throw.
    @Test func graphMLInvalidFormatThrows() {
        let formatter = GraphFormatter()
        var graph = AdjacencyList()
        #expect(throws: SerializationError.self) {
            try formatter.read("<graphml><graph><node id=", using: .graphML(), into: &graph)
        }
    }

    // MARK: - DOT

    /// DOT structural round-trip: serialize → read → re-serialize must reproduce the original.
    @Test func dotStructuralRoundTrip() throws {
        var original = AdjacencyList()
        let a = original.addVertex()
        let b = original.addVertex()
        let c = original.addVertex()
        original.addEdge(from: a, to: b)
        original.addEdge(from: b, to: c)
        original.addEdge(from: a, to: c)

        let formatter = GraphFormatter()
        let dot = try formatter.string(from: original, using: .dot(directed: true, graphName: "G"))

        var restored = AdjacencyList()
        try formatter.read(dot, using: .dot(), into: &restored)

        #expect(restored.vertexCount == 3, "round-trip must preserve vertex count")
        #expect(restored.edgeCount == 3, "round-trip must preserve edge count")

        let reserialized = try formatter.string(from: restored, using: .dot(directed: true, graphName: "G"))
        #expect(reserialized == dot, "DOT round-trip must reproduce the original serialization")
    }

    /// The DOT parser must treat a quoted identifier with spaces as a single token,
    /// and match the same quoted id used as a node and as an edge endpoint.
    @Test func dotParsesQuotedIdentifiers() throws {
        let dot = """
        digraph G {
          "New York";
          "Los Angeles";
          "New York" -> "Los Angeles";
        }
        """
        var graph = AdjacencyList()
        let formatter = GraphFormatter()
        try formatter.read(dot, using: .dot(), into: &graph)

        #expect(graph.vertexCount == 2, "quoted ids must produce two distinct vertices")
        #expect(graph.edgeCount == 1, "quoted-id endpoints must resolve to the declared nodes")
    }
}
#endif
