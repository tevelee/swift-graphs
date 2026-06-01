#if !GRAPHS_USES_TRAITS || GRAPHS_PATHFINDING

    /// A preprocessing structure for fast repeated shortest-path queries using Contraction Hierarchies.
    ///
    /// Build once with `prepare(graph:weight:vertexRank:)`, then query many times with
    /// `shortestPath(from:to:)`. Queries are typically orders of magnitude faster than Dijkstra
    /// on large sparse graphs (road networks, transit networks).
    ///
    /// - Complexity: Preprocessing O((V + E) log V) amortized; query O(k log k) where k << V.
    public struct ContractionHierarchy<
        G: IncidenceGraph & BidirectionalGraph & VertexListGraph,
        W: Numeric & Comparable
    >
    where G.VertexDescriptor: Hashable, W.Magnitude == W {

        public typealias Vertex = G.VertexDescriptor
        public typealias Edge = G.EdgeDescriptor

        // MARK: - Nested Types

        /// A virtual edge added during preprocessing, bypassing one or more contracted vertices.
        ///
        /// Each shortcut represents a shortest path through a contracted vertex. The `via` property
        /// stores the bypassed vertex, enabling recursive path unpacking into original edges.
        public struct Shortcut {
            /// The destination vertex of this shortcut.
            public let target: Vertex
            /// The total weight of the path this shortcut represents.
            public let weight: W
            /// The contracted vertex this shortcut bypasses (used for path unpacking).
            public let via: Vertex
        }

        /// A shortcut as seen from the destination side (used in backward CH query).
        @usableFromInline
        struct IncomingShortcut {
            /// The source vertex this shortcut originates from.
            let source: Vertex
            /// The total weight of the path this shortcut represents.
            let weight: W
            /// The contracted vertex this shortcut bypasses.
            let via: Vertex
        }

        /// A priority queue item used during witness search.
        struct WitnessItem: Comparable {
            let cost: W
            let vertex: Vertex
            let hops: Int
            static func < (lhs: Self, rhs: Self) -> Bool { lhs.cost < rhs.cost }
            static func == (lhs: Self, rhs: Self) -> Bool {
                lhs.cost == rhs.cost && lhs.vertex == rhs.vertex
            }
        }

        /// A priority queue item used during the automatic vertex ordering phase.
        struct ImportanceEntry: Comparable {
            let importance: Int
            let vertex: Vertex
            static func < (lhs: Self, rhs: Self) -> Bool { lhs.importance < rhs.importance }
            static func == (lhs: Self, rhs: Self) -> Bool {
                lhs.importance == rhs.importance && lhs.vertex == rhs.vertex
            }
        }

        // MARK: - Stored State

        /// The original graph, kept for edge traversal and weight lookups.
        @usableFromInline let graph: G
        /// The edge weight function over the original graph.
        @usableFromInline let weight: CostDefinition<G, W>
        /// Contraction order: higher level = more important = contracted later.
        /// All vertices appear as keys after preprocessing.
        @usableFromInline let vertexLevel: [Vertex: Int]
        /// Forward shortcuts keyed by source vertex, for fast query-time expansion.
        @usableFromInline let shortcuts: [Vertex: [Shortcut]]
        /// Backward shortcuts keyed by target vertex, for the backward CH query.
        @usableFromInline let shortcutsByTarget: [Vertex: [IncomingShortcut]]
        /// Shortcut lookup by (source, target) pair for O(1) path unpacking.
        /// Stores the minimum-weight shortcut for each (source, target) pair.
        @usableFromInline let shortcutLookup: [Pair<Vertex, Vertex>: Shortcut]

        // MARK: - Internal Init

        @usableFromInline
        init(
            graph: G,
            weight: CostDefinition<G, W>,
            vertexLevel: [Vertex: Int],
            shortcuts: [Vertex: [Shortcut]],
            shortcutsByTarget: [Vertex: [IncomingShortcut]],
            shortcutLookup: [Pair<Vertex, Vertex>: Shortcut]
        ) {
            self.graph = graph
            self.weight = weight
            self.vertexLevel = vertexLevel
            self.shortcuts = shortcuts
            self.shortcutsByTarget = shortcutsByTarget
            self.shortcutLookup = shortcutLookup
        }

        // MARK: - Internal Helpers

        /// Finds an original graph edge from `u` to `v` by iterating outgoing edges of `u`.
        ///
        /// Returns `nil` if no direct edge exists in the original graph.
        /// Used during path unpacking to convert shortcut references back to real edges.
        func findOriginalEdge(from u: Vertex, to v: Vertex) -> Edge? {
            graph.outgoingEdges(of: u).first { graph.destination(of: $0) == v }
        }

        // MARK: - Witness Search

        /// Runs a cost- and hop-limited Dijkstra from `source`, skipping `excluded`,
        /// to find the shortest paths to each vertex in `targets`.
        ///
        /// Used during preprocessing to check whether a potential shortcut is necessary:
        /// if a witness path (cost ≤ `maxCost`) exists from source to a target without
        /// going through the vertex being contracted, no shortcut is needed.
        ///
        /// - Parameters:
        ///   - source: Start vertex of the search.
        ///   - targets: The set of destination vertices to reach.
        ///   - excluded: The vertex currently being contracted — never relaxed through.
        ///   - maxCost: Prune any path costing more than this.
        ///   - hopLimit: Maximum number of edges to traverse.
        ///   - graph: The original graph.
        ///   - weight: Edge weight function.
        ///   - additionalEdges: Shortcuts added so far (keyed by source vertex).
        /// - Returns: A dictionary mapping each reachable target to its cost from `source`.
        @usableFromInline
        static func witnessSearch(
            from source: Vertex,
            to targets: Set<Vertex>,
            excluding excluded: Vertex,
            maxCost: W,
            hopLimit: Int,
            in graph: G,
            weight: CostDefinition<G, W>,
            additionalEdges: [Vertex: [Shortcut]]
        ) -> [Vertex: W] {
            guard !targets.isEmpty else { return [:] }

            var distances: [Vertex: W] = [source: W.zero]
            var queue = PriorityQueue<WitnessItem>()
            queue.enqueue(WitnessItem(cost: W.zero, vertex: source, hops: 0))
            var found: [Vertex: W] = [:]

            while let item = queue.dequeue() {
                let v = item.vertex
                let d = item.cost

                guard v != excluded else { continue }
                // Skip if a better path to v was already settled
                if let existing = distances[v], d > existing { continue }
                // Prune if cost exceeds budget
                guard d <= maxCost else { continue }

                if targets.contains(v) && found[v] == nil {
                    found[v] = d
                    if found.count == targets.count { break }
                }

                guard item.hops < hopLimit else { continue }

                // Explore original outgoing edges
                for e in graph.outgoingEdges(of: v) {
                    guard let neighbor = graph.destination(of: e), neighbor != excluded else { continue }
                    let edgeCost = weight.costToExplore(e, graph)
                    let newCost = d + edgeCost
                    guard newCost <= maxCost else { continue }
                    if distances[neighbor].map({ newCost < $0 }) ?? true {
                        distances[neighbor] = newCost
                        queue.enqueue(WitnessItem(cost: newCost, vertex: neighbor, hops: item.hops + 1))
                    }
                }

                // Explore shortcuts added so far
                for sc in additionalEdges[v, default: []] {
                    guard sc.target != excluded else { continue }
                    let newCost = d + sc.weight
                    guard newCost <= maxCost else { continue }
                    if distances[sc.target].map({ newCost < $0 }) ?? true {
                        distances[sc.target] = newCost
                        queue.enqueue(WitnessItem(cost: newCost, vertex: sc.target, hops: item.hops + 1))
                    }
                }
            }

            return found
        }

        // MARK: - Preprocessing Internals

        /// Contracts vertex `v`: adds shortcut edges between all uncontracted predecessor/successor
        /// pairs of `v` whenever contracting `v` would destroy a unique shortest path.
        ///
        /// - Parameters:
        ///   - v: The vertex to contract.
        ///   - graph: The original graph.
        ///   - weight: Edge weight function.
        ///   - contractedVertices: The set of vertices already contracted (excluded from searches).
        ///   - shortcuts: Accumulated forward shortcuts (mutated in place).
        ///   - shortcutsByTarget: Accumulated backward shortcuts (mutated in place).
        ///   - shortcutLookup: (source, target) → best Shortcut map (mutated in place).
        @usableFromInline
        static func contractVertex(
            _ v: Vertex,
            in graph: G,
            weight: CostDefinition<G, W>,
            contractedVertices: Set<Vertex>,
            shortcuts: inout [Vertex: [Shortcut]],
            shortcutsByTarget: inout [Vertex: [IncomingShortcut]],
            shortcutLookup: inout [Pair<Vertex, Vertex>: Shortcut]
        ) {
            // Build minimum-weight predecessor map (original edges + incoming shortcuts)
            var predMap: [Vertex: W] = [:]
            for e in graph.incomingEdges(of: v) {
                guard let u = graph.source(of: e), !contractedVertices.contains(u) else { continue }
                let w = weight.costToExplore(e, graph)
                predMap[u] = predMap[u].map { Swift.min($0, w) } ?? w
            }
            for sc in shortcutsByTarget[v, default: []] {
                guard !contractedVertices.contains(sc.source) else { continue }
                predMap[sc.source] = predMap[sc.source].map { Swift.min($0, sc.weight) } ?? sc.weight
            }

            // Build minimum-weight successor map (original edges + outgoing shortcuts)
            var succMap: [Vertex: W] = [:]
            for e in graph.outgoingEdges(of: v) {
                guard let w = graph.destination(of: e), !contractedVertices.contains(w) else { continue }
                let wt = weight.costToExplore(e, graph)
                succMap[w] = succMap[w].map { Swift.min($0, wt) } ?? wt
            }
            for sc in shortcuts[v, default: []] {
                guard !contractedVertices.contains(sc.target) else { continue }
                succMap[sc.target] = succMap[sc.target].map { Swift.min($0, sc.weight) } ?? sc.weight
            }

            // For each (u, w) pair, check whether a shortcut is needed
            for (u, uvWeight) in predMap {
                let targets = Set(succMap.keys.filter { $0 != u })
                guard !targets.isEmpty else { continue }

                let maxCost = targets.reduce(uvWeight) { result, w in
                    Swift.max(result, uvWeight + succMap[w]!)
                }

                let witnesses = witnessSearch(
                    from: u,
                    to: targets,
                    excluding: v,
                    maxCost: maxCost,
                    hopLimit: 5,
                    in: graph,
                    weight: weight,
                    additionalEdges: shortcuts
                )

                for (w, vwWeight) in succMap where w != u {
                    let shortcutCost = uvWeight + vwWeight
                    let witnessed = witnesses[w].map { $0 <= shortcutCost } ?? false
                    guard !witnessed else { continue }

                    let key = Pair(u, w)
                    // Only add if better than any existing shortcut for this (u, w) pair
                    if let existing = shortcutLookup[key], existing.weight <= shortcutCost { continue }

                    let sc = Shortcut(target: w, weight: shortcutCost, via: v)
                    shortcuts[u, default: []].append(sc)
                    shortcutLookup[key] = sc
                    shortcutsByTarget[w, default: []].append(
                        IncomingShortcut(source: u, weight: shortcutCost, via: v)
                    )
                }
            }
        }

        /// Estimates the importance of contracting vertex `v` using the edge-difference heuristic.
        ///
        /// Lower importance = should be contracted sooner.
        /// `importance = shortcuts_that_would_be_added − (in_degree + out_degree)` among uncontracted neighbors.
        @usableFromInline
        static func computeImportance(
            of v: Vertex,
            in graph: G,
            weight: CostDefinition<G, W>,
            contractedVertices: Set<Vertex>,
            shortcuts: [Vertex: [Shortcut]],
            shortcutsByTarget: [Vertex: [IncomingShortcut]]
        ) -> Int {
            var predMap: [Vertex: W] = [:]
            for e in graph.incomingEdges(of: v) {
                guard let u = graph.source(of: e), !contractedVertices.contains(u) else { continue }
                let w = weight.costToExplore(e, graph)
                predMap[u] = predMap[u].map { Swift.min($0, w) } ?? w
            }
            for sc in shortcutsByTarget[v, default: []] {
                guard !contractedVertices.contains(sc.source) else { continue }
                predMap[sc.source] = predMap[sc.source].map { Swift.min($0, sc.weight) } ?? sc.weight
            }

            var succMap: [Vertex: W] = [:]
            for e in graph.outgoingEdges(of: v) {
                guard let w = graph.destination(of: e), !contractedVertices.contains(w) else { continue }
                let wt = weight.costToExplore(e, graph)
                succMap[w] = succMap[w].map { Swift.min($0, wt) } ?? wt
            }
            for sc in shortcuts[v, default: []] {
                guard !contractedVertices.contains(sc.target) else { continue }
                succMap[sc.target] = succMap[sc.target].map { Swift.min($0, sc.weight) } ?? sc.weight
            }

            var shortcutsAdded = 0
            for (u, uvWeight) in predMap {
                let targets = Set(succMap.keys.filter { $0 != u })
                guard !targets.isEmpty else { continue }
                let maxCost = targets.reduce(uvWeight) { Swift.max($0, uvWeight + succMap[$1]!) }
                let witnesses = witnessSearch(
                    from: u,
                    to: targets,
                    excluding: v,
                    maxCost: maxCost,
                    hopLimit: 5,
                    in: graph,
                    weight: weight,
                    additionalEdges: shortcuts
                )
                for (w, vwWeight) in succMap where w != u {
                    let shortcutCost = uvWeight + vwWeight
                    let witnessed = witnesses[w].map { $0 <= shortcutCost } ?? false
                    if !witnessed { shortcutsAdded += 1 }
                }
            }

            let edgesRemoved = predMap.count + succMap.count
            return shortcutsAdded - edgesRemoved
        }

        // MARK: - Public Factory

        /// Preprocesses `graph` into a `ContractionHierarchy` for fast repeated shortest-path queries.
        ///
        /// - Parameters:
        ///   - graph: The graph to preprocess. Must be bidirectional and support vertex enumeration.
        ///   - weight: Edge weight function. All weights must be non-negative.
        ///   - vertexRank: Optional override for vertex contraction order. When `nil`, the
        ///     edge-difference heuristic determines order automatically. When provided, vertices
        ///     are contracted in ascending rank order (lowest rank first).
        /// - Returns: A `ContractionHierarchy` ready for repeated `shortestPath` queries.
        public static func prepare(
            graph: G,
            weight: CostDefinition<G, W>,
            vertexRank: ((Vertex) -> Int)? = nil
        ) -> ContractionHierarchy<G, W> {
            var contractedVertices: Set<Vertex> = []
            var shortcuts: [Vertex: [Shortcut]] = [:]
            var shortcutsByTarget: [Vertex: [IncomingShortcut]] = [:]
            var shortcutLookup: [Pair<Vertex, Vertex>: Shortcut] = [:]
            var vertexLevel: [Vertex: Int] = [:]
            var level = 0

            if let vertexRank {
                // User-provided order: contract in ascending rank
                let ordered = graph.vertices().sorted { vertexRank($0) < vertexRank($1) }
                for v in ordered {
                    contractVertex(
                        v,
                        in: graph,
                        weight: weight,
                        contractedVertices: contractedVertices,
                        shortcuts: &shortcuts,
                        shortcutsByTarget: &shortcutsByTarget,
                        shortcutLookup: &shortcutLookup
                    )
                    contractedVertices.insert(v)
                    vertexLevel[v] = level
                    level += 1
                }
            } else {
                // Automatic: priority queue with lazy importance re-evaluation
                var queue = PriorityQueue<ImportanceEntry>()
                for v in graph.vertices() {
                    let imp = computeImportance(
                        of: v,
                        in: graph,
                        weight: weight,
                        contractedVertices: contractedVertices,
                        shortcuts: shortcuts,
                        shortcutsByTarget: shortcutsByTarget
                    )
                    queue.enqueue(ImportanceEntry(importance: imp, vertex: v))
                }

                while let entry = queue.dequeue() {
                    let v = entry.vertex
                    guard !contractedVertices.contains(v) else { continue }

                    // Lazy re-evaluation: recompute and re-insert if importance increased
                    let currentImp = computeImportance(
                        of: v,
                        in: graph,
                        weight: weight,
                        contractedVertices: contractedVertices,
                        shortcuts: shortcuts,
                        shortcutsByTarget: shortcutsByTarget
                    )
                    if currentImp > entry.importance {
                        queue.enqueue(ImportanceEntry(importance: currentImp, vertex: v))
                        continue
                    }

                    contractVertex(
                        v,
                        in: graph,
                        weight: weight,
                        contractedVertices: contractedVertices,
                        shortcuts: &shortcuts,
                        shortcutsByTarget: &shortcutsByTarget,
                        shortcutLookup: &shortcutLookup
                    )
                    contractedVertices.insert(v)
                    vertexLevel[v] = level
                    level += 1
                }
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
