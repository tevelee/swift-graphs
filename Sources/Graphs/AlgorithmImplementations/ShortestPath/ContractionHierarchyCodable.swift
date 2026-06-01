#if !GRAPHS_USES_TRAITS || GRAPHS_PATHFINDING

    // MARK: - Snapshot Type

    /// A serializable snapshot of preprocessed contraction hierarchy data.
    ///
    /// Encode with any `Encoder` (e.g. `JSONEncoder`), then restore the full
    /// `ContractionHierarchy` via `ContractionHierarchy.restore(from:graph:weight:)`.
    /// The original graph and weight function are not stored — callers re-supply them.
    public struct ContractionHierarchySnapshot<Vertex: Codable, W: Codable>: Codable {

        /// A single vertex-level entry.
        public struct VertexLevel: Codable {
            /// The vertex descriptor.
            public let vertex: Vertex
            /// The contraction level assigned during preprocessing.
            public let level: Int
        }

        /// A single shortcut entry (source, target, weight, via).
        public struct EncodedShortcut: Codable {
            /// The source vertex of the shortcut.
            public let source: Vertex
            /// The destination vertex of the shortcut.
            public let target: Vertex
            /// The total weight of the path this shortcut represents.
            public let weight: W
            /// The contracted vertex this shortcut bypasses.
            public let via: Vertex
        }

        /// Contraction levels for all vertices.
        public let vertexLevels: [VertexLevel]
        /// All shortcut edges added during preprocessing.
        public let shortcuts: [EncodedShortcut]
    }

    // MARK: - ContractionHierarchy ↔ Snapshot

    extension ContractionHierarchy where G.VertexDescriptor: Codable, W: Codable {

        /// Creates a serializable snapshot of the preprocessed hierarchy.
        ///
        /// Encode the snapshot with any `Encoder`, store it, and later restore via
        /// `ContractionHierarchy.restore(from:graph:weight:)`. The graph and weight
        /// function are not part of the snapshot — re-supply them at restore time.
        public func snapshot() -> ContractionHierarchySnapshot<Vertex, W> {
            let levels = vertexLevel.map {
                ContractionHierarchySnapshot<Vertex, W>.VertexLevel(vertex: $0.key, level: $0.value)
            }
            let scs = shortcuts.flatMap { source, list in
                list.map {
                    ContractionHierarchySnapshot<Vertex, W>.EncodedShortcut(
                        source: source,
                        target: $0.target,
                        weight: $0.weight,
                        via: $0.via
                    )
                }
            }
            return ContractionHierarchySnapshot(vertexLevels: levels, shortcuts: scs)
        }

        /// Restores a `ContractionHierarchy` from a previously created snapshot.
        ///
        /// - Parameters:
        ///   - snapshot: The snapshot produced by `snapshot()` and decoded from storage.
        ///   - graph: The original graph (must be the same graph used during preprocessing).
        ///   - weight: The edge weight function used during preprocessing.
        /// - Returns: A fully functional `ContractionHierarchy` ready for `shortestPath` queries.
        public static func restore(
            from snapshot: ContractionHierarchySnapshot<Vertex, W>,
            graph: G,
            weight: CostDefinition<G, W>
        ) -> ContractionHierarchy<G, W> {
            let vertexLevel = Dictionary(
                snapshot.vertexLevels.map { ($0.vertex, $0.level) },
                uniquingKeysWith: { _, new in new }
            )

            var shortcuts: [Vertex: [Shortcut]] = [:]
            var shortcutsByTarget: [Vertex: [IncomingShortcut]] = [:]
            var shortcutLookup: [Pair<Vertex, Vertex>: Shortcut] = [:]

            for entry in snapshot.shortcuts {
                let sc = Shortcut(target: entry.target, weight: entry.weight, via: entry.via)
                shortcuts[entry.source, default: []].append(sc)
                shortcutLookup[Pair(entry.source, entry.target)] = sc
                shortcutsByTarget[entry.target, default: []].append(
                    IncomingShortcut(source: entry.source, weight: entry.weight, via: entry.via)
                )
            }

            return ContractionHierarchy(
                graph: graph,
                weight: weight,
                vertexLevel: vertexLevel,
                shortcuts: shortcuts,
                shortcutsByTarget: shortcutsByTarget,
                shortcutLookup: shortcutLookup
            )
        }
    }

#endif
