#if !GRAPHS_USES_TRAITS || GRAPHS_PATHFINDING

    /// A `ShortestPathAlgorithm` adapter for `ContractionHierarchy` that preprocesses lazily on first query.
    ///
    /// Use the `.contractionHierarchy(weight:)` static factory on `ShortestPathAlgorithm` to create one,
    /// then pass it to `graph.shortestPath(from:to:using:)` just like `.dijkstra(weight:)`.
    ///
    /// The hierarchy is built on the **first** call to `shortestPath(from:to:in:visitor:)` and cached
    /// for all subsequent calls. Copies of this struct share the same cache.
    ///
    /// ```swift
    /// let path = graph.shortestPath(from: a, to: b, using: .contractionHierarchy(weight: .property(\.cost)))
    /// ```
    public struct ContractionHierarchyAlgorithm<
        G: IncidenceGraph & BidirectionalGraph & VertexListGraph,
        W: Numeric & Comparable
    >: ShortestPathAlgorithm
    where G.VertexDescriptor: Hashable, W.Magnitude == W {

        public typealias Graph = G
        /// No visitor support — CH query events are not exposed via the algorithm protocol.
        public typealias Visitor = Never

        /// The edge weight function supplied at construction time.
        @usableFromInline let weight: CostDefinition<G, W>
        /// Optional vertex contraction order override.
        @usableFromInline let vertexRank: ((G.VertexDescriptor) -> Int)?
        /// Reference-typed cache so copies of this struct share one preprocessed hierarchy.
        @usableFromInline let cache: Cache

        /// Reference-typed mutable cache. Shared across struct copies.
        @usableFromInline
        final class Cache {
            /// The preprocessed hierarchy, set on first query.
            @usableFromInline var hierarchy: ContractionHierarchy<G, W>?
        }

        /// Creates a lazy contraction hierarchy algorithm.
        ///
        /// - Parameters:
        ///   - weight: Edge weight function. All weights must be non-negative.
        ///   - vertexRank: Optional contraction order override. When `nil`, the edge-difference
        ///     heuristic is used automatically.
        @usableFromInline
        init(
            weight: CostDefinition<G, W>,
            vertexRank: ((G.VertexDescriptor) -> Int)? = nil
        ) {
            self.weight = weight
            self.vertexRank = vertexRank
            self.cache = Cache()
        }

        /// Finds the shortest path, preprocessing the graph on the first invocation.
        ///
        /// - Note: `visitor` is ignored — `ContractionHierarchyAlgorithm` has no visitor support.
        /// - Note: The graph passed on the **first** call is the one that gets preprocessed.
        ///   Subsequent calls reuse the cached hierarchy regardless of the `graph` argument.
        @inlinable
        public func shortestPath(
            from source: G.VertexDescriptor,
            to destination: G.VertexDescriptor,
            in graph: G,
            visitor: Never?
        ) -> Path<G.VertexDescriptor, G.EdgeDescriptor>? {
            // Note: not thread-safe — concurrent first calls may race on cache.hierarchy.
            // Single-threaded repeated use (the intended pattern) is safe.
            if cache.hierarchy == nil {
                cache.hierarchy = ContractionHierarchy.prepare(
                    graph: graph,
                    weight: weight,
                    vertexRank: vertexRank
                )
            }
            guard let hierarchy = cache.hierarchy else { return nil }
            return hierarchy.shortestPath(from: source, to: destination)
        }
    }

    extension ShortestPathAlgorithm {

        /// Creates a lazy contraction hierarchy shortest-path algorithm.
        ///
        /// The hierarchy is preprocessed on the first query and cached for subsequent ones.
        /// Suitable as a drop-in replacement for `.dijkstra(weight:)` when repeated queries
        /// on the same graph justify the preprocessing cost.
        ///
        /// - Parameters:
        ///   - weight: Edge weight function. All weights must be non-negative.
        ///   - vertexRank: Optional contraction order override.
        /// - Returns: A `ContractionHierarchyAlgorithm` instance.
        @inlinable
        public static func contractionHierarchy<
            G: IncidenceGraph & BidirectionalGraph & VertexListGraph,
            W: Numeric & Comparable
        >(
            weight: CostDefinition<G, W>,
            vertexRank: ((G.VertexDescriptor) -> Int)? = nil
        ) -> Self
        where
            Self == ContractionHierarchyAlgorithm<G, W>,
            G.VertexDescriptor: Hashable,
            W.Magnitude == W
        {
            .init(weight: weight, vertexRank: vertexRank)
        }
    }

#endif
