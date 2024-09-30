extension MaximumMatchingAlgorithm {
    /// Creates a new instance of the Hopcroft-Karp algorithm.
    @inlinable public static func hopcroftKarp<Node, Edge>() -> Self where Self == HopcroftKarpAlgorithm<Node, Edge> {
        HopcroftKarpAlgorithm()
    }
}

/// An implementation of the Hopcroft-Karp algorithm for finding the maximum matching in a bipartite graph.
public struct HopcroftKarpAlgorithm<Node: Hashable, Edge>: MaximumMatchingAlgorithm {
    /// Initializes a new `HopcroftKarpAlgorithm` instance.
    @inlinable public init() {}

    /// Finds the maximum matching in the graph using the Hopcroft-Karp algorithm.
    @inlinable public func maximumMatching(
        in graph: some BipartiteGraph<Node, Edge>
    ) -> [Node: Node] {
        let leftPartition = graph.leftPartition
        let rightPartition = graph.rightPartition

        var pairU: [Node: Node?] = [:] // Matching for left nodes (U)
        var pairV: [Node: Node?] = [:] // Matching for right nodes (V)
        var dist: [Node: Int] = [:]

        // Initialize pairings to nil
        for u in leftPartition {
            pairU[u] = nil
        }
        for v in rightPartition {
            pairV[v] = nil
        }

        while bfs(graph: graph, pairU: &pairU, pairV: &pairV, dist: &dist) {
            for u in leftPartition {
                if pairU[u] == nil {
                    _ = dfs(u: u, graph: graph, pairU: &pairU, pairV: &pairV, dist: &dist)
                }
            }
        }

        // Build the matching from pairU
        var matching: [Node: Node] = [:]
        for (u, vOpt) in pairU {
            if let v = vOpt {
                matching[u] = v
            }
        }

        return matching
    }

    /// Breadth-first search for finding augmenting paths.
    @usableFromInline func bfs(
        graph: some BipartiteGraph<Node, Edge>,
        pairU: inout [Node: Node?],
        pairV: inout [Node: Node?],
        dist: inout [Node: Int]
    ) -> Bool {
        var queue: [Node] = []
        var distNil = Int.max

        for u in graph.leftPartition {
            if pairU[u] == nil {
                dist[u] = 0
                queue.append(u)
            } else {
                dist[u] = Int.max
            }
        }

        while !queue.isEmpty {
            let u = queue.removeFirst()
            if dist[u]! < distNil {
                for edge in graph.edges(from: u) {
                    let v = edge.destination
                    if let pairVv = pairV[v] ?? nil {
                        // v is matched
                        if dist[pairVv] == nil || dist[pairVv]! == Int.max {
                            dist[pairVv] = dist[u]! + 1
                            queue.append(pairVv)
                        }
                    } else {
                        // v is unmatched
                        distNil = dist[u]! + 1
                    }
                }
            }
        }

        return distNil != Int.max
    }

    /// Depth-first search for finding augmenting paths.
    @usableFromInline func dfs(
        u: Node,
        graph: some BipartiteGraph<Node, Edge>,
        pairU: inout [Node: Node?],
        pairV: inout [Node: Node?],
        dist: inout [Node: Int]
    ) -> Bool {
        for edge in graph.edges(from: u) {
            let v = edge.destination
            if let pairVv = pairV[v] ?? nil {
                // v is matched
                if dist[pairVv] == dist[u]! + 1 {
                    if dfs(u: pairVv, graph: graph, pairU: &pairU, pairV: &pairV, dist: &dist) {
                        pairU[u] = v
                        pairV[v] = u
                        return true
                    }
                }
            } else {
                // v is unmatched
                pairU[u] = v
                pairV[v] = u
                return true
            }
        }
        dist[u] = Int.max
        return false
    }
}
