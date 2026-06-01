#if !GRAPHS_USES_TRAITS || GRAPHS_PATHFINDING

    extension IncidenceGraph
    where Self: BidirectionalGraph & VertexListGraph, VertexDescriptor: Hashable {

        /// Preprocesses this graph into a `ContractionHierarchy` for fast repeated shortest-path queries.
        ///
        /// Call this once, then use the returned hierarchy for many queries.
        ///
        /// - Parameters:
        ///   - weight: Edge weight function. All weights must be non-negative.
        ///   - vertexRank: Optional contraction order override. When `nil`, the edge-difference
        ///     heuristic determines order. When provided, vertices are contracted in ascending rank order.
        /// - Returns: A `ContractionHierarchy` ready for `shortestPath(from:to:)` queries.
        @inlinable
        public func contractionHierarchy<W: Numeric & Comparable>(
            weight: CostDefinition<Self, W>,
            vertexRank: ((VertexDescriptor) -> Int)? = nil
        ) -> ContractionHierarchy<Self, W> where W.Magnitude == W {
            ContractionHierarchy.prepare(graph: self, weight: weight, vertexRank: vertexRank)
        }
    }

#endif
