/// Correct linear-time **Left-Right planarity test** (de Fraysseix-Rosenstiehl;
/// Brandes 2009) operating on an integer-indexed undirected simple graph.
///
/// This is the single source of truth for planarity correctness in the library: the
/// public `PlanarPropertyAlgorithm` testers and the `PlanarEmbeddingAlgorithm` family
/// all delegate to this engine. It performs two DFS passes (orientation then testing)
/// to decide planarity, and a third (embedding) pass to produce a planar rotation
/// system on success.
///
/// The graph is given as a 0-based adjacency list `adj` where each undirected edge `{u,v}`
/// appears once in `adj[u]` and once in `adj[v]`. Self-loops and parallel edges do not
/// affect planarity and must be removed by the caller.
final class LeftRightPlanarity {
    /// An oriented edge (dart) `u -> v` used as a dictionary key for per-edge state.
    struct Dart: Hashable {
        var u: Int
        var v: Int
        init(_ u: Int, _ v: Int) {
            self.u = u
            self.v = v
        }
    }

    /// An interval of return edges `[low, high]` along one side of a conflict pair.
    private struct Interval {
        var low: Dart?
        var high: Dart?
        var isEmpty: Bool { low == nil && high == nil }
    }

    /// A pair of left/right intervals constraining how return edges may be embedded.
    private struct ConflictPair {
        var left = Interval()
        var right = Interval()
        mutating func swap() {
            Swift.swap(&left, &right)
        }
    }

    private let n: Int
    private let adj: [[Int]]

    private var height: [Int]
    private var parentEdge: [Dart?]
    private var orientedAdj: [[Dart]]
    private var orderedAdj: [[Dart]] = []
    private var roots: [Int] = []

    private var lowpt: [Dart: Int] = [:]
    private var lowpt2: [Dart: Int] = [:]
    private var nestingDepth: [Dart: Int] = [:]
    private var ref: [Dart: Dart] = [:]
    private var side: [Dart: Int] = [:]
    private var lowptEdge: [Dart: Dart] = [:]
    private var stackBottom: [Dart: Int] = [:]
    private var orientedPairs: Set<Int> = []

    private var stack: [ConflictPair] = []

    private var decided = false
    private var planarResult = false

    // Embedding (rotation system) state, built lazily on a planar graph.
    private var embCW: [[Int: Int]] = []
    private var embCCW: [[Int: Int]] = []
    private var embFirst: [Int] = []
    private var leftRef: [Int: Int] = [:]
    private var rightRef: [Int: Int] = [:]

    init(n: Int, adj: [[Int]]) {
        self.n = n
        self.adj = adj
        self.height = Array(repeating: -1, count: n)
        self.parentEdge = Array(repeating: nil, count: n)
        self.orientedAdj = Array(repeating: [], count: n)
    }

    private func pairKey(_ a: Int, _ b: Int) -> Int {
        a < b ? a * n + b : b * n + a
    }

    /// Decides whether the graph is planar (orientation + testing). Cached.
    func isPlanar() -> Bool {
        if decided { return planarResult }
        decided = true

        if n >= 3 {
            var edgeCount = 0
            for list in adj { edgeCount += list.count }
            edgeCount /= 2
            if edgeCount > 3 * n - 6 {
                planarResult = false
                return false
            }
        }

        // Phase 1 - orientation.
        for v in 0 ..< n where height[v] == -1 {
            height[v] = 0
            roots.append(v)
            orient(v)
        }

        // Order each vertex's outgoing darts by nesting depth.
        orderedAdj = orientedAdj.map { darts in
            darts.sorted { nestingDepth[$0]! < nestingDepth[$1]! }
        }

        // Phase 2 - testing.
        for root in roots where !test(root) {
            planarResult = false
            return false
        }
        planarResult = true
        return true
    }

    /// Returns a planar rotation system (clockwise neighbor order per vertex index),
    /// or `nil` if the graph is non-planar.
    func planarEmbedding() -> [[Int]]? {
        guard isPlanar() else { return nil }
        buildEmbedding()
        return (0 ..< n).map { rotation(of: $0) }
    }

    private func orient(_ v: Int) {
        let parent = parentEdge[v]
        for w in adj[v] {
            let key = pairKey(v, w)
            if orientedPairs.contains(key) { continue }
            orientedPairs.insert(key)

            let vw = Dart(v, w)
            orientedAdj[v].append(vw)
            lowpt[vw] = height[v]
            lowpt2[vw] = height[v]

            if height[w] == -1 {  // tree edge
                parentEdge[w] = vw
                height[w] = height[v] + 1
                orient(w)
            } else {  // back edge
                lowpt[vw] = height[w]
            }

            nestingDepth[vw] = 2 * lowpt[vw]!
            if lowpt2[vw]! < height[v] {  // chordal
                nestingDepth[vw]! += 1
            }

            if let e = parent {
                if lowpt[vw]! < lowpt[e]! {
                    lowpt2[e] = min(lowpt[e]!, lowpt2[vw]!)
                    lowpt[e] = lowpt[vw]!
                } else if lowpt[vw]! > lowpt[e]! {
                    lowpt2[e] = min(lowpt2[e]!, lowpt[vw]!)
                } else {
                    lowpt2[e] = min(lowpt2[e]!, lowpt2[vw]!)
                }
            }
        }
    }

    private func test(_ v: Int) -> Bool {
        let parent = parentEdge[v]
        let firstEdge = orderedAdj[v].first
        for ei in orderedAdj[v] {
            stackBottom[ei] = stack.count

            if ei == parentEdge[ei.v] {  // tree edge
                if !test(ei.v) { return false }
            } else {  // back edge
                lowptEdge[ei] = ei
                stack.append(ConflictPair(left: Interval(), right: Interval(low: ei, high: ei)))
            }

            if lowpt[ei]! < height[v] {
                if ei == firstEdge {
                    if let e = parent { lowptEdge[e] = lowptEdge[ei]! }
                } else if !addConstraints(ei, parent!) {
                    return false
                }
            }
        }

        if let e = parent {
            let u = e.u
            trimBackEdges(u)
            if lowpt[e]! < height[u] {
                let top = stack[stack.count - 1]
                let hl = top.left.high
                let hr = top.right.high
                if let hl, hr == nil || lowpt[hl]! > lowpt[hr!]! {
                    ref[e] = hl
                } else {
                    ref[e] = hr
                }
            }
        }
        return true
    }

    private func conflicting(_ interval: Interval, _ b: Dart) -> Bool {
        guard let high = interval.high else { return false }
        return lowpt[high]! > lowpt[b]!
    }

    private func addConstraints(_ ei: Dart, _ e: Dart) -> Bool {
        var pair = ConflictPair()

        // Merge the return edges of ei into pair.right.
        while true {
            var q = stack.removeLast()
            if !q.left.isEmpty { q.swap() }
            if !q.left.isEmpty { return false }  // not planar
            if lowpt[q.right.low!]! > lowpt[e]! {
                if pair.right.isEmpty {
                    pair.right.high = q.right.high
                } else {
                    ref[pair.right.low!] = q.right.high
                }
                pair.right.low = q.right.low
            } else {
                ref[q.right.low!] = lowptEdge[e]
            }
            if stack.count == stackBottom[ei]! { break }
        }

        // Merge conflicting return edges of e_1..e_{i-1} into pair.left.
        while let top = stack.last, conflicting(top.left, ei) || conflicting(top.right, ei) {
            var q = stack.removeLast()
            if conflicting(q.right, ei) { q.swap() }
            if conflicting(q.right, ei) { return false }  // not planar
            ref[pair.right.low!] = q.right.high
            if q.right.low != nil { pair.right.low = q.right.low }
            if pair.left.isEmpty {
                pair.left.high = q.left.high
            } else {
                ref[pair.left.low!] = q.left.high
            }
            pair.left.low = q.left.low
        }

        if !(pair.left.isEmpty && pair.right.isEmpty) {
            stack.append(pair)
        }
        return true
    }

    private func lowest(_ pair: ConflictPair) -> Int {
        if pair.left.isEmpty { return lowpt[pair.right.low!]! }
        if pair.right.isEmpty { return lowpt[pair.left.low!]! }
        return min(lowpt[pair.left.low!]!, lowpt[pair.right.low!]!)
    }

    private func trimBackEdges(_ u: Int) {
        while let top = stack.last, lowest(top) == height[u] {
            let removed = stack.removeLast()
            if let low = removed.left.low { side[low] = -1 }
        }
        guard var pair = stack.popLast() else { return }

        // Trim the left interval.
        while let high = pair.left.high, high.v == u {
            pair.left.high = ref[high]
        }
        if pair.left.high == nil, let low = pair.left.low {
            ref[low] = pair.right.low
            side[low] = -1
            pair.left.low = nil
        }

        // Trim the right interval.
        while let high = pair.right.high, high.v == u {
            pair.right.high = ref[high]
        }
        if pair.right.high == nil, let low = pair.right.low {
            ref[low] = pair.left.low
            side[low] = -1
            pair.right.low = nil
        }

        stack.append(pair)
    }

    // MARK: - Embedding phase

    /// Resolves the absolute side (+1 / -1) of an oriented edge, memoizing the result.
    private func sign(_ startE: Dart) -> Int {
        // Iterative path-compression: walk the ref chain, then multiply back.
        var chain: [Dart] = []
        var e = startE
        while let r = ref[e] {
            chain.append(e)
            ref[e] = nil
            e = r
        }
        for dart in chain.reversed() {
            side[dart] = (side[dart] ?? 1) * (side[e] ?? 1)
            e = dart
        }
        return side[startE] ?? 1
    }

    private func buildEmbedding() {
        embCW = Array(repeating: [:], count: n)
        embCCW = Array(repeating: [:], count: n)
        embFirst = Array(repeating: -1, count: n)

        // Apply signs to nesting depths, then re-order each vertex's darts.
        for v in 0 ..< n {
            for ei in orientedAdj[v] {
                nestingDepth[ei] = sign(ei) * nestingDepth[ei]!
            }
        }
        orderedAdj = orientedAdj.map { darts in
            darts.sorted { nestingDepth[$0]! < nestingDepth[$1]! }
        }

        // Seed each vertex's rotation with its outgoing half-edges in signed order.
        for v in 0 ..< n {
            var previous: Int?
            for ei in orderedAdj[v] {
                addHalfEdgeCW(v, ei.v, after: previous)
                previous = ei.v
            }
        }

        for root in roots {
            embed(root)
        }
    }

    private func embed(_ v: Int) {
        for ei in orderedAdj[v] {
            let w = ei.v
            if ei == parentEdge[w] {  // tree edge
                addHalfEdgeFirst(w, v)
                leftRef[v] = w
                rightRef[v] = w
                embed(w)
            } else {  // back edge
                if (side[ei] ?? 1) == 1 {
                    addHalfEdgeCW(w, v, after: rightRef[w])
                } else {
                    addHalfEdgeCCW(w, v, of: leftRef[w])
                    leftRef[w] = v
                }
            }
        }
    }

    private func addHalfEdgeCW(_ v: Int, _ w: Int, after reference: Int?) {
        guard let r = reference else {
            embCW[v][w] = w
            embCCW[v][w] = w
            embFirst[v] = w
            return
        }
        let cwReference = embCW[v][r]!
        embCW[v][r] = w
        embCW[v][w] = cwReference
        embCCW[v][cwReference] = w
        embCCW[v][w] = r
    }

    private func addHalfEdgeCCW(_ v: Int, _ w: Int, of reference: Int?) {
        guard let r = reference else {
            addHalfEdgeCW(v, w, after: nil)
            return
        }
        addHalfEdgeCW(v, w, after: embCCW[v][r]!)
        if r == embFirst[v] { embFirst[v] = w }
    }

    private func addHalfEdgeFirst(_ v: Int, _ w: Int) {
        let reference: Int? = embFirst[v] != -1 ? embFirst[v] : nil
        addHalfEdgeCCW(v, w, of: reference)
    }

    /// The clockwise rotation (ordered neighbor list) around vertex `v`.
    private func rotation(of v: Int) -> [Int] {
        guard embFirst[v] != -1 else { return [] }
        var result: [Int] = []
        let start = embFirst[v]
        var current = start
        repeat {
            result.append(current)
            current = embCW[v][current]!
        } while current != start
        return result
    }
}
