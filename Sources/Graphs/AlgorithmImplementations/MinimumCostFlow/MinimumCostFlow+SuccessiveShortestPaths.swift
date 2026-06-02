#if !GRAPHS_USES_TRAITS || GRAPHS_OPTIMIZATION
    extension MinCostFlowAlgorithm {
        /// Creates a Successive Shortest Paths minimum cost flow algorithm.
        ///
        /// The algorithm finds minimum cost augmenting paths via SPFA and augments along
        /// them until maximum flow or the specified demand is reached. It correctly handles
        /// flow rerouting via backward edges in the residual graph.
        ///
        /// - Parameters:
        ///   - capacity: A definition of how to extract each edge's capacity.
        ///   - unitCost: A definition of how to extract each edge's per-unit-flow cost.
        /// - Returns: A `SuccessiveShortestPaths` algorithm instance.
        @inlinable
        public static func successiveShortestPaths<Graph, Value>(
            capacity: CostDefinition<Graph, Value>,
            unitCost: CostDefinition<Graph, Value>
        ) -> SuccessiveShortestPaths<Graph, Value>
        where
            Graph: IncidenceGraph & EdgeListGraph & VertexListGraph,
            Value: AdditiveArithmetic & Comparable & SignedNumeric,
            Graph.VertexDescriptor: Hashable,
            Graph.EdgeDescriptor: Hashable,
            Self == SuccessiveShortestPaths<Graph, Value>
        {
            .init(capacity: capacity, unitCost: unitCost)
        }
    }

    extension SuccessiveShortestPaths: MinCostFlowAlgorithm {}
#endif
