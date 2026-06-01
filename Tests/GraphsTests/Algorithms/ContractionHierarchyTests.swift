#if !GRAPHS_USES_TRAITS || GRAPHS_PATHFINDING
    @testable import Graphs
    import Foundation
    import Testing

    struct ContractionHierarchyTests {

        // MARK: - Helpers

        typealias G = DefaultAdjacencyList

        /// A↔B↔C, weights A-B=1, B-C=2 (bidirectional).
        func makeLinearGraph() -> (graph: G, a: G.VertexDescriptor, b: G.VertexDescriptor, c: G.VertexDescriptor) {
            var g = G()
            let a = g.addVertex { $0.label = "A" }
            let b = g.addVertex { $0.label = "B" }
            let c = g.addVertex { $0.label = "C" }
            g.addEdge(from: a, to: b) { $0.weight = 1.0 }
            g.addEdge(from: b, to: a) { $0.weight = 1.0 }
            g.addEdge(from: b, to: c) { $0.weight = 2.0 }
            g.addEdge(from: c, to: b) { $0.weight = 2.0 }
            return (g, a, b, c)
        }

        /// Triangle: A↔B=4, A↔C=2, B↔C=1.
        func makeTriangleGraph() -> (graph: G, a: G.VertexDescriptor, b: G.VertexDescriptor, c: G.VertexDescriptor) {
            var g = G()
            let a = g.addVertex { $0.label = "A" }
            let b = g.addVertex { $0.label = "B" }
            let c = g.addVertex { $0.label = "C" }
            g.addEdge(from: a, to: b) { $0.weight = 4.0 }
            g.addEdge(from: b, to: a) { $0.weight = 4.0 }
            g.addEdge(from: a, to: c) { $0.weight = 2.0 }
            g.addEdge(from: c, to: a) { $0.weight = 2.0 }
            g.addEdge(from: b, to: c) { $0.weight = 1.0 }
            g.addEdge(from: c, to: b) { $0.weight = 1.0 }
            return (g, a, b, c)
        }

        // MARK: - Struct Skeleton

        @Test func structCanBeInitializedWithKnownData() {
            let (g, a, b, _) = makeLinearGraph()
            let ch = ContractionHierarchy<G, Double>(
                graph: g,
                weight: .uniform(1.0),
                vertexLevel: [a: 0, b: 1],
                shortcuts: [:],
                shortcutsByTarget: [:],
                shortcutLookup: [:]
            )
            #expect(ch.vertexLevel[a] == 0)
            #expect(ch.vertexLevel[b] == 1)
            #expect(ch.shortcuts.isEmpty)
            #expect(ch.shortcutLookup.isEmpty)
        }
        // MARK: - Witness Search

        @Test func witnessSearchFindsDirectPathWitness() {
            // Graph: A→B (1), B→C (1), A→C (3)
            // Witness search from A to C excluding B, maxCost=2
            // Path A→B→C costs 2 but B is excluded.
            // Direct A→C costs 3 > maxCost=2, so no witness within cost 2.
            var g = G()
            let a = g.addVertex()
            let b = g.addVertex()
            let c = g.addVertex()
            g.addEdge(from: a, to: b) { $0.weight = 1.0 }
            g.addEdge(from: b, to: a) { $0.weight = 1.0 }
            g.addEdge(from: b, to: c) { $0.weight = 1.0 }
            g.addEdge(from: c, to: b) { $0.weight = 1.0 }
            g.addEdge(from: a, to: c) { $0.weight = 3.0 }
            g.addEdge(from: c, to: a) { $0.weight = 3.0 }

            let result = ContractionHierarchy<G, Double>.witnessSearch(
                from: a,
                to: [c],
                excluding: b,
                maxCost: 2.0,
                hopLimit: 5,
                in: g,
                weight: .property(\.weight),
                additionalEdges: [:]
            )
            #expect(result[c] == nil)  // no witness within cost 2
        }

        @Test func witnessSearchFindsWitnessAtExactCost() {
            var g = G()
            let a = g.addVertex()
            let b = g.addVertex()
            let c = g.addVertex()
            g.addEdge(from: a, to: b) { $0.weight = 1.0 }
            g.addEdge(from: b, to: c) { $0.weight = 1.0 }
            g.addEdge(from: a, to: c) { $0.weight = 3.0 }

            // With maxCost=3.0: direct A→C (cost 3) is a witness
            let result = ContractionHierarchy<G, Double>.witnessSearch(
                from: a,
                to: [c],
                excluding: b,
                maxCost: 3.0,
                hopLimit: 5,
                in: g,
                weight: .property(\.weight),
                additionalEdges: [:]
            )
            #expect(result[c] == 3.0)
        }

        @Test func witnessSearchRespectsHopLimit() {
            // A→B→C→D with weights 1,1,1 and hop limit 1
            var g = G()
            let a = g.addVertex()
            let b = g.addVertex()
            let c = g.addVertex()
            let d = g.addVertex()
            g.addEdge(from: a, to: b) { $0.weight = 1.0 }
            g.addEdge(from: b, to: c) { $0.weight = 1.0 }
            g.addEdge(from: c, to: d) { $0.weight = 1.0 }

            // With hop limit 1, cannot reach C from A in one hop (B is excluded, no direct A→C edge)
            let result = ContractionHierarchy<G, Double>.witnessSearch(
                from: a,
                to: [c],
                excluding: b,
                maxCost: 100.0,
                hopLimit: 1,
                in: g,
                weight: .property(\.weight),
                additionalEdges: [:]
            )
            #expect(result[c] == nil)
        }

        @Test func witnessSearchUsesAdditionalShortcuts() {
            // A→B (1), B→C (1). No direct A→C edge.
            // Add shortcut A→C (2) as an additional edge.
            // Witness from A to C excluding B with maxCost=2: shortcut A→C (cost 2) is a witness.
            var g = G()
            let a = g.addVertex()
            let b = g.addVertex()
            let c = g.addVertex()
            g.addEdge(from: a, to: b) { $0.weight = 1.0 }
            g.addEdge(from: b, to: c) { $0.weight = 1.0 }

            let fakeShortcut = ContractionHierarchy<G, Double>.Shortcut(target: c, weight: 2.0, via: b)
            let result = ContractionHierarchy<G, Double>.witnessSearch(
                from: a,
                to: [c],
                excluding: b,
                maxCost: 2.0,
                hopLimit: 5,
                in: g,
                weight: .property(\.weight),
                additionalEdges: [a: [fakeShortcut]]
            )
            #expect(result[c] == 2.0)
        }

        // MARK: - Preprocessing Helpers

        @Test func contractVertexAddsCorrectShortcuts() {
            // Linear: A↔B↔C (weights 1, 2). Contracting B should add A→C (3) and C→A (3).
            let (g, a, b, c) = makeLinearGraph()

            var shortcuts: [G.VertexDescriptor: [ContractionHierarchy<G, Double>.Shortcut]] = [:]
            var shortcutsByTarget: [G.VertexDescriptor: [ContractionHierarchy<G, Double>.IncomingShortcut]] = [:]
            var shortcutLookup: [Pair<G.VertexDescriptor, G.VertexDescriptor>: ContractionHierarchy<G, Double>.Shortcut] = [:]

            ContractionHierarchy<G, Double>.contractVertex(
                b,
                in: g,
                weight: .property(\.weight),
                contractedVertices: [],
                shortcuts: &shortcuts,
                shortcutsByTarget: &shortcutsByTarget,
                shortcutLookup: &shortcutLookup
            )

            // Should add A→C (weight 3, via B) and C→A (weight 3, via B)
            #expect(shortcutLookup[Pair(a, c)]?.weight == 3.0)
            #expect(shortcutLookup[Pair(a, c)]?.via == b)
            #expect(shortcutLookup[Pair(c, a)]?.weight == 3.0)
            #expect(shortcutLookup[Pair(c, a)]?.via == b)
        }

        @Test func contractVertexSkipsWitnessedPairs() {
            // Triangle: A→B (4), B→C (1), A→C (2).
            // Contracting B: potential shortcut A→C via B costs 5. But direct A→C = 2 < 5 → witness found.
            let (g, a, b, c) = makeTriangleGraph()

            var shortcuts: [G.VertexDescriptor: [ContractionHierarchy<G, Double>.Shortcut]] = [:]
            var shortcutsByTarget: [G.VertexDescriptor: [ContractionHierarchy<G, Double>.IncomingShortcut]] = [:]
            var shortcutLookup: [Pair<G.VertexDescriptor, G.VertexDescriptor>: ContractionHierarchy<G, Double>.Shortcut] = [:]

            ContractionHierarchy<G, Double>.contractVertex(
                b,
                in: g,
                weight: .property(\.weight),
                contractedVertices: [],
                shortcuts: &shortcuts,
                shortcutsByTarget: &shortcutsByTarget,
                shortcutLookup: &shortcutLookup
            )

            // A→C and C→A already have direct edges cheaper than through B — no shortcuts needed
            #expect(shortcutLookup[Pair(a, c)] == nil)
            #expect(shortcutLookup[Pair(c, a)] == nil)
        }

        // MARK: - Preprocessing

        @Test func preprocessingContractsAllVertices() {
            let (g, a, b, c) = makeLinearGraph()
            let ch = ContractionHierarchy.prepare(graph: g, weight: .property(\.weight))
            // All vertices must be assigned a level
            #expect(ch.vertexLevel[a] != nil)
            #expect(ch.vertexLevel[b] != nil)
            #expect(ch.vertexLevel[c] != nil)
            // All three levels must be distinct
            let levels = [ch.vertexLevel[a]!, ch.vertexLevel[b]!, ch.vertexLevel[c]!]
            #expect(Set(levels).count == 3)
        }

        @Test func preprocessingAutoOrderAssignsDistinctLevels() {
            // Auto-order preprocessing must assign a unique contraction level to every vertex.
            // Shortcut correctness is verified end-to-end in the integration tests.
            let (g, a, b, c) = makeLinearGraph()
            let ch = ContractionHierarchy.prepare(graph: g, weight: .property(\.weight))
            let levels = [ch.vertexLevel[a], ch.vertexLevel[b], ch.vertexLevel[c]].compactMap { $0 }
            #expect(levels.count == 3)
            #expect(Set(levels).count == 3)  // all distinct
        }

        @Test func preprocessingWithUserRankOrder() {
            // Force B to be contracted first (rank 0), then A (rank 1), then C (rank 2)
            let (g, a, b, c) = makeLinearGraph()
            let ranks: [G.VertexDescriptor: Int] = [b: 0, a: 1, c: 2]
            let ch = ContractionHierarchy.prepare(
                graph: g,
                weight: .property(\.weight),
                vertexRank: { ranks[$0, default: 0] }
            )
            // B has the lowest rank so it must have the lowest level
            #expect(ch.vertexLevel[b]! < ch.vertexLevel[a]!)
            #expect(ch.vertexLevel[b]! < ch.vertexLevel[c]!)
        }

        @Test func preprocessingTriangleShortcutAdded() {
            // Triangle A↔B=4, A↔C=2, B↔C=1.
            // Force C to be contracted first. Potential shortcut A→B via C costs 3 < direct A→B=4 → shortcut needed.
            let (g, a, b, _) = makeTriangleGraph()
            let c = g.findVertex(labeled: "C")!
            let ranks: [G.VertexDescriptor: Int] = [c: 0, a: 1, b: 2]
            let ch = ContractionHierarchy.prepare(
                graph: g,
                weight: .property(\.weight),
                vertexRank: { ranks[$0, default: 0] }
            )
            // Shortcut A→B via C should be added (cost 3 < direct 4)
            let sc = ch.shortcutLookup[Pair(a, b)]
            #expect(sc?.weight == 3.0)
        }
        // MARK: - Query

        @Test func queryReturnsNilForUnreachableDestination() {
            // A→B (no edge back), query B→A should return nil
            var g = G()
            let a = g.addVertex { $0.label = "A" }
            let b = g.addVertex { $0.label = "B" }
            g.addEdge(from: a, to: b) { $0.weight = 1.0 }
            let ch = ContractionHierarchy.prepare(graph: g, weight: .property(\.weight))
            #expect(ch.shortestPath(from: b, to: a) == nil)
        }

        @Test func queryReturnsTrivialPathForSameVertex() {
            let (g, a, _, _) = makeLinearGraph()
            let ch = ContractionHierarchy.prepare(graph: g, weight: .property(\.weight))
            let path = ch.shortestPath(from: a, to: a)
            #expect(path?.edges.isEmpty == true)
            #expect(path?.vertices == [a])
        }

        @Test func queryMatchesDijkstraCostLinear() {
            let (g, a, _, c) = makeLinearGraph()
            let ch = ContractionHierarchy.prepare(graph: g, weight: .property(\.weight))
            let chPath = ch.shortestPath(from: a, to: c)
            let dijkPath = g.shortestPath(from: a, to: c, using: .dijkstra(weight: .property(\.weight)))
            #expect(chPath != nil)
            #expect(dijkPath != nil)
            // Both should find cost 3 (A→B→C = 1+2)
            let chCost = chPath!.edges.reduce(0.0) { $0 + g[$1].weight }
            let dijkCost = dijkPath!.edges.reduce(0.0) { $0 + g[$1].weight }
            #expect(chCost == dijkCost)
            #expect(chCost == 3.0)
        }

        @Test func queryMatchesDijkstraCostTriangle() {
            // Triangle A↔B=4, A↔C=2, B↔C=1. Shortest A→B = A→C→B = 3.
            let (g, a, b, _) = makeTriangleGraph()
            let ch = ContractionHierarchy.prepare(graph: g, weight: .property(\.weight))
            let chPath = ch.shortestPath(from: a, to: b)
            let dijkPath = g.shortestPath(from: a, to: b, using: .dijkstra(weight: .property(\.weight)))
            #expect(chPath != nil)
            let chCost = chPath!.edges.reduce(0.0) { $0 + g[$1].weight }
            let dijkCost = dijkPath!.edges.reduce(0.0) { $0 + g[$1].weight }
            #expect(chCost == dijkCost)
            #expect(chCost == 3.0)
        }

        // MARK: - Path Unpacking

        @Test func unpackedPathUsesOnlyOriginalEdges() {
            // Ensure shortcuts are fully expanded and returned path edges exist in the original graph
            let (g, a, _, c) = makeLinearGraph()
            let ch = ContractionHierarchy.prepare(graph: g, weight: .property(\.weight))
            let path = ch.shortestPath(from: a, to: c)
            #expect(path != nil)
            // Every edge in the path must be a real edge in the original graph
            for edge in path!.edges {
                let src = g.source(of: edge)
                let dst = g.destination(of: edge)
                #expect(src != nil)
                #expect(dst != nil)
            }
        }

        @Test func unpackedPathVerticesAreConnected() {
            let (g, a, _, c) = makeLinearGraph()
            let ch = ContractionHierarchy.prepare(graph: g, weight: .property(\.weight))
            let path = ch.shortestPath(from: a, to: c)!
            #expect(path.source == a)
            #expect(path.destination == c)
            // Consecutive vertices must be connected by the corresponding edge
            for i in 0 ..< path.edges.count {
                let edgeSrc = g.source(of: path.edges[i])
                let edgeDst = g.destination(of: path.edges[i])
                #expect(edgeSrc == path.vertices[i])
                #expect(edgeDst == path.vertices[i + 1])
            }
        }

        // MARK: - Persistence

        @Test func snapshotRoundtripsVertexLevels() throws {
            let (g, a, b, c) = makeLinearGraph()
            let ch = g.contractionHierarchy(weight: .property(\.weight))

            let snapshot = ch.snapshot()
            let data = try JSONEncoder().encode(snapshot)
            let decoded = try JSONDecoder().decode(
                ContractionHierarchySnapshot<G.VertexDescriptor, Double>.self,
                from: data
            )
            let ch2 = ContractionHierarchy<G, Double>.restore(from: decoded, graph: g, weight: .property(\.weight))

            #expect(ch2.vertexLevel[a] == ch.vertexLevel[a])
            #expect(ch2.vertexLevel[b] == ch.vertexLevel[b])
            #expect(ch2.vertexLevel[c] == ch.vertexLevel[c])
        }

        @Test func restoredHierarchyQueriesCorrectly() throws {
            let (g, a, _, c) = makeLinearGraph()
            let ch = g.contractionHierarchy(weight: .property(\.weight))

            let data = try JSONEncoder().encode(ch.snapshot())
            let decoded = try JSONDecoder().decode(
                ContractionHierarchySnapshot<G.VertexDescriptor, Double>.self,
                from: data
            )
            let ch2 = ContractionHierarchy<G, Double>.restore(from: decoded, graph: g, weight: .property(\.weight))

            let path = ch2.shortestPath(from: a, to: c)
            let cost = path?.edges.reduce(0.0) { $0 + g[$1].weight }
            #expect(cost == 3.0)
        }

        @Test func snapshotPreservesShortcutCount() throws {
            let (g, a, b, _) = makeLinearGraph()
            let ranks: [G.VertexDescriptor: Int] = [b: 0, a: 1]
            let ch = g.contractionHierarchy(
                weight: .property(\.weight),
                vertexRank: { ranks[$0, default: 2] }
            )
            let snapshot = ch.snapshot()
            let data = try JSONEncoder().encode(snapshot)
            let decoded = try JSONDecoder().decode(
                ContractionHierarchySnapshot<G.VertexDescriptor, Double>.self,
                from: data
            )
            let ch2 = ContractionHierarchy<G, Double>.restore(from: decoded, graph: g, weight: .property(\.weight))
            #expect(ch2.shortcutLookup.count == ch.shortcutLookup.count)
        }

        // MARK: - Convenience API + Integration

        @Test func convenienceAPIMatchesDijkstra() {
            let (g, a, _, c) = makeLinearGraph()
            // Use graph.contractionHierarchy(weight:) convenience method
            let ch = g.contractionHierarchy(weight: .property(\.weight))
            let chPath = ch.shortestPath(from: a, to: c)
            let dijkPath = g.shortestPath(from: a, to: c, using: .dijkstra(weight: .property(\.weight)))
            #expect(chPath?.edges.count == dijkPath?.edges.count)
            let chCost = chPath!.edges.reduce(0.0) { $0 + g[$1].weight }
            #expect(chCost == 3.0)
        }

        @Test func integrationCHvsAllDijkstraPairs() {
            // Build a 5-vertex graph and verify CH matches Dijkstra for all pairs
            var g = G()
            let v0 = g.addVertex { $0.label = "0" }
            let v1 = g.addVertex { $0.label = "1" }
            let v2 = g.addVertex { $0.label = "2" }
            let v3 = g.addVertex { $0.label = "3" }
            let v4 = g.addVertex { $0.label = "4" }
            let edgeDefs: [(G.VertexDescriptor, G.VertexDescriptor, Double)] = [
                (v0, v1, 2.0), (v1, v0, 2.0),
                (v1, v2, 3.0), (v2, v1, 3.0),
                (v2, v3, 1.0), (v3, v2, 1.0),
                (v0, v3, 8.0), (v3, v0, 8.0),
                (v3, v4, 2.0), (v4, v3, 2.0),
                (v1, v4, 7.0), (v4, v1, 7.0),
            ]
            for (u, w, wt) in edgeDefs {
                g.addEdge(from: u, to: w) { $0.weight = wt }
            }

            let ch = g.contractionHierarchy(weight: .property(\.weight))
            let verts = [v0, v1, v2, v3, v4]

            for src in verts {
                for dst in verts where dst != src {
                    let chPath = ch.shortestPath(from: src, to: dst)
                    let dijkPath = g.shortestPath(from: src, to: dst, using: .dijkstra(weight: .property(\.weight)))

                    if dijkPath == nil {
                        #expect(chPath == nil)
                    } else {
                        #expect(chPath != nil)
                        let chCost = chPath!.edges.reduce(0.0) { $0 + g[$1].weight }
                        let dijkCost = dijkPath!.edges.reduce(0.0) { $0 + g[$1].weight }
                        #expect(chCost == dijkCost)
                    }
                }
            }
        }
        // MARK: - Distance-Only Query

        @Test func shortestDistanceMatchesDijkstraCost() {
            let (g, a, _, c) = makeLinearGraph()
            let ch = g.contractionHierarchy(weight: .property(\.weight))
            let dist = ch.shortestDistance(from: a, to: c)
            let dijkPath = g.shortestPath(from: a, to: c, using: .dijkstra(weight: .property(\.weight)))
            let dijkCost = dijkPath?.edges.reduce(0.0) { $0 + g[$1].weight }
            #expect(dist == dijkCost)
            #expect(dist == 3.0)
        }

        @Test func shortestDistanceReturnsZeroForSameVertex() {
            let (g, a, _, _) = makeLinearGraph()
            let ch = g.contractionHierarchy(weight: .property(\.weight))
            #expect(ch.shortestDistance(from: a, to: a) == 0.0)
        }

        @Test func shortestDistanceReturnsNilWhenUnreachable() {
            var g = G()
            let a = g.addVertex { $0.label = "A" }
            let b = g.addVertex { $0.label = "B" }
            g.addEdge(from: a, to: b) { $0.weight = 1.0 }
            let ch = ContractionHierarchy.prepare(graph: g, weight: .property(\.weight))
            #expect(ch.shortestDistance(from: b, to: a) == nil)
        }

        @Test func shortestDistanceMatchesAllPairsDijkstra() {
            var g = G()
            let v0 = g.addVertex { $0.label = "0" }
            let v1 = g.addVertex { $0.label = "1" }
            let v2 = g.addVertex { $0.label = "2" }
            let v3 = g.addVertex { $0.label = "3" }
            let v4 = g.addVertex { $0.label = "4" }
            let edgeDefs: [(G.VertexDescriptor, G.VertexDescriptor, Double)] = [
                (v0, v1, 2.0), (v1, v0, 2.0),
                (v1, v2, 3.0), (v2, v1, 3.0),
                (v2, v3, 1.0), (v3, v2, 1.0),
                (v0, v3, 8.0), (v3, v0, 8.0),
                (v3, v4, 2.0), (v4, v3, 2.0),
                (v1, v4, 7.0), (v4, v1, 7.0),
            ]
            for (u, w, wt) in edgeDefs { g.addEdge(from: u, to: w) { $0.weight = wt } }

            let ch = g.contractionHierarchy(weight: .property(\.weight))
            let verts = [v0, v1, v2, v3, v4]

            for src in verts {
                for dst in verts where dst != src {
                    let dist = ch.shortestDistance(from: src, to: dst)
                    let path = g.shortestPath(from: src, to: dst, using: .dijkstra(weight: .property(\.weight)))
                    let dijkCost = path?.edges.reduce(0.0) { $0 + g[$1].weight }
                    #expect(dist == dijkCost)
                }
            }
        }

        // MARK: - Lazy ShortestPathAlgorithm Conformance

        @Test func lazyAlgorithmIntegratesWithShortestPathAPI() {
            // Drop-in replacement for .dijkstra at the call site
            let (g, a, _, c) = makeLinearGraph()
            let path = g.shortestPath(from: a, to: c, using: .contractionHierarchy(weight: .property(\.weight)))
            let cost = path?.edges.reduce(0.0) { $0 + g[$1].weight }
            #expect(cost == 3.0)
        }

        @Test func lazyAlgorithmMatchesDijkstraOnTriangle() {
            let (g, a, b, _) = makeTriangleGraph()
            let chPath = g.shortestPath(from: a, to: b, using: .contractionHierarchy(weight: .property(\.weight)))
            let dijkPath = g.shortestPath(from: a, to: b, using: .dijkstra(weight: .property(\.weight)))
            let chCost = chPath?.edges.reduce(0.0) { $0 + g[$1].weight }
            let dijkCost = dijkPath?.edges.reduce(0.0) { $0 + g[$1].weight }
            #expect(chCost == dijkCost)
        }

        @Test func lazyAlgorithmCachesAfterFirstCall() {
            let (g, a, _, c) = makeLinearGraph()
            let algo = ContractionHierarchyAlgorithm<G, Double>(weight: .property(\.weight))
            // Before first call: cache is empty
            #expect(algo.cache.hierarchy == nil)
            let path1 = algo.shortestPath(from: a, to: c, in: g, visitor: nil)
            // After first call: cache is populated
            #expect(algo.cache.hierarchy != nil)
            let path2 = algo.shortestPath(from: a, to: c, in: g, visitor: nil)
            let cost1 = path1?.edges.reduce(0.0) { $0 + g[$1].weight }
            let cost2 = path2?.edges.reduce(0.0) { $0 + g[$1].weight }
            #expect(cost1 == 3.0)
            #expect(cost1 == cost2)
        }

        @Test func lazyAlgorithmSharedCacheAcrossCopies() {
            // Copying the algorithm struct shares the cache (reference semantics on Cache)
            let (g, a, _, c) = makeLinearGraph()
            let algo1 = ContractionHierarchyAlgorithm<G, Double>(weight: .property(\.weight))
            _ = algo1.shortestPath(from: a, to: c, in: g, visitor: nil)  // triggers preprocessing
            let algo2 = algo1  // copy shares same Cache object
            // Both struct values hold the identical Cache reference
            #expect(algo1.cache === algo2.cache)
            let path = algo2.shortestPath(from: a, to: c, in: g, visitor: nil)
            let cost = path?.edges.reduce(0.0) { $0 + g[$1].weight }
            #expect(cost == 3.0)
        }
    }
#endif
