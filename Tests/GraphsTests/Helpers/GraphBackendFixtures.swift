import Testing

@testable import Graphs

/// Combined protocol constraint for graphs that support full algorithm testing with label and weight properties.
///
/// Use this in a local generic `check` function inside each `@Test` method to run the same
/// assertions against multiple concrete backends:
///
/// ```swift
/// @Test func myAlgorithm_allBackends() {
///     func check<G: TestablePropertyGraph>(_ graph: inout G, _ backend: String)
///     where G.VertexProperties == VertexPropertyValues, G.EdgeProperties == EdgePropertyValues,
///           G.VertexDescriptor: Hashable {        // add Hashable when the algorithm requires it
///         // build graph and assert...
///         #expect(someResult, "[\(backend)]")
///     }
///     var g1 = AdjacencyList();   check(&g1, "default")
///     var g4 = AdjacencyMatrix(); check(&g4, "Matrix")
///     #if !GRAPHS_USES_TRAITS || GRAPHS_SPECIALIZED_STORAGE
///     var g2 = AdjacencyList(edgeStore: CSREdgeStorage().cacheInOutEdges()); check(&g2, "CSR")
///     var g3 = AdjacencyList(edgeStore: COOEdgeStorage().cacheInOutEdges()); check(&g3, "COO")
///     #endif
/// }
/// ```
typealias TestablePropertyGraph =
    MutablePropertyGraph
    & VertexListGraph
    & IncidenceGraph
    & BidirectionalGraph
    & MutableGraph
