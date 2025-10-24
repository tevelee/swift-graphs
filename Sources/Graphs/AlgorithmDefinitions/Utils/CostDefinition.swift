/// A definition of how to compute the cost of exploring an edge.
///
/// This type encapsulates the logic for determining the cost (weight) of an edge
/// in a graph, which is used by shortest path algorithms and other cost-based
/// graph algorithms.
public struct CostDefinition<Graph: Graphs.Graph, Cost> {
    /// A function that computes the cost of exploring an edge.
    public let costToExplore: (Graph.EdgeDescriptor, Graph) -> Cost
    
    /// Creates a new cost definition.
    ///
    /// - Parameter costToExplore: A function that computes the cost of an edge
    @inlinable
    public init(costToExplore: @escaping (Graph.EdgeDescriptor, Graph) -> Cost) {
        self.costToExplore = costToExplore
    }
}

extension CostDefinition {
    /// Creates a cost definition that returns a uniform cost for all edges.
    ///
    /// - Parameter value: The uniform cost value
    /// - Returns: A cost definition that returns the same cost for all edges
    @inlinable
    public static func uniform(_ value: Cost) -> Self {
        .init { _, _ in value }
    }
}

extension CostDefinition where Cost == UInt {
    /// A cost definition that returns a unit cost (1) for all edges.
    @inlinable
    public static var unit: Self {
        .uniform(1)
    }
}

extension CostDefinition where Graph: EdgePropertyGraph {
    /// Creates a cost definition that extracts the cost from edge properties.
    ///
    /// - Parameter extract: A function that extracts the cost from edge properties
    /// - Returns: A cost definition that uses edge properties to determine cost
    @inlinable
    public static func property(_ extract: @escaping (EdgeProperties) -> Cost) -> Self {
        .init { edge, graph in
            extract(graph[edge])
        }
    }
}
