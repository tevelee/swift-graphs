/// A mutable, integer-indexed combinatorial embedding (rotation system) supporting the
/// half-edge operations needed by the Chrobak-Payne straight-line drawing algorithm.
///
/// This mirrors the `cw` / `ccw` / `first_nbr` half-edge data structure of NetworkX's
/// `PlanarEmbedding`, restricted to `Int` vertex indices.
final class MutablePlanarRotation {
    let n: Int
    private var cwLink: [[Int: Int]]
    private var ccwLink: [[Int: Int]]
    private var firstNbr: [Int]

    /// Builds a mutable embedding from a clockwise rotation system over indices `0..<n`.
    init(rotation: [[Int]]) {
        n = rotation.count
        cwLink = Array(repeating: [:], count: n)
        ccwLink = Array(repeating: [:], count: n)
        firstNbr = Array(repeating: -1, count: n)
        for v in 0 ..< n {
            let order = rotation[v]
            let degree = order.count
            guard degree > 0 else { continue }
            firstNbr[v] = order[0]
            for i in 0 ..< degree {
                cwLink[v][order[i]] = order[(i + 1) % degree]
                ccwLink[v][order[i]] = order[(i - 1 + degree) % degree]
            }
        }
    }

    func hasEdge(_ v: Int, _ w: Int) -> Bool { cwLink[v][w] != nil }

    func ccw(_ v: Int, _ w: Int) -> Int { ccwLink[v][w]! }

    /// The clockwise-ordered neighbors of `v`.
    func neighborsCW(_ v: Int) -> [Int] {
        guard firstNbr[v] != -1 else { return [] }
        var result: [Int] = []
        let start = firstNbr[v]
        var current = start
        repeat {
            result.append(current)
            current = cwLink[v][current]!
        } while current != start
        return result
    }

    /// The next half-edge along the face to the left of `(v -> w)`.
    func nextFaceHalfEdge(_ v: Int, _ w: Int) -> (Int, Int) {
        (w, ccwLink[w][v]!)
    }

    /// Inserts the half-edge `start -> end` clockwise next to `start -> reference`.
    func addHalfEdgeCW(_ start: Int, _ end: Int, _ reference: Int?) {
        guard let r = reference else {
            cwLink[start][end] = end
            ccwLink[start][end] = end
            firstNbr[start] = end
            return
        }
        let cwReference = cwLink[start][r]!
        cwLink[start][r] = end
        cwLink[start][end] = cwReference
        ccwLink[start][cwReference] = end
        ccwLink[start][end] = r
    }

    /// Inserts the half-edge `start -> end` counter-clockwise next to `start -> reference`.
    func addHalfEdgeCCW(_ start: Int, _ end: Int, _ reference: Int?) {
        guard let r = reference else {
            addHalfEdgeCW(start, end, nil)
            return
        }
        addHalfEdgeCW(start, end, ccwLink[start][r]!)
        if r == firstNbr[start] { firstNbr[start] = end }
    }

    /// Inserts `end` as the first (leftmost) neighbor of `start`.
    func addHalfEdgeFirst(_ start: Int, _ end: Int) {
        addHalfEdgeCCW(start, end, firstNbr[start] != -1 ? firstNbr[start] : nil)
    }

    /// Connects two components by adding an edge between `v` and `w`.
    func connectComponents(_ v: Int, _ w: Int) {
        addHalfEdgeFirst(v, w)
        addHalfEdgeFirst(w, v)
    }
}

/// Chrobak-Payne (de Fraysseix-Pach-Pollack) straight-line grid drawing, ported from
/// NetworkX's `combinatorial_embedding_to_pos`.
enum PlanarDrawingCore {
    /// Computes integer grid coordinates for a planar rotation system over indices `0..<n`.
    /// Returns one `(x, y)` per index. The edges of the embedding draw as straight,
    /// non-crossing segments.
    static func positions(rotation: [[Int]]) -> [(x: Int, y: Int)] {
        let n = rotation.count
        if n < 4 {
            let defaults: [(Int, Int)] = [(0, 0), (2, 0), (1, 1)]
            return (0 ..< n).map { defaults[$0] }
        }

        let embedding = MutablePlanarRotation(rotation: rotation)
        let outerFace = triangulate(embedding)
        let ordering = canonicalOrdering(embedding, outerFace: outerFace)

        var leftChild = [Int: Int?]()
        var rightChild = [Int: Int?]()
        var deltaX = [Int: Int]()
        var yCoord = [Int: Int]()

        let v1 = ordering[0].vertex
        let v2 = ordering[1].vertex
        let v3 = ordering[2].vertex

        deltaX[v1] = 0
        yCoord[v1] = 0
        rightChild[v1] = v3
        leftChild[v1] = Int?.none

        deltaX[v2] = 1
        yCoord[v2] = 0
        rightChild[v2] = Int?.none
        leftChild[v2] = Int?.none

        deltaX[v3] = 1
        yCoord[v3] = 1
        rightChild[v3] = v2
        leftChild[v3] = Int?.none

        for k in 3 ..< ordering.count {
            let vk = ordering[k].vertex
            let contour = ordering[k].outerFace
            let wp = contour[0]
            let wp1 = contour[1]
            let wq = contour[contour.count - 1]
            let wq1 = contour[contour.count - 2]
            let addsMultiTriangle = contour.count > 2

            deltaX[wp1, default: 0] += 1
            deltaX[wq, default: 0] += 1

            let deltaXWpWq = contour[1...].reduce(0) { $0 + deltaX[$1]! }

            deltaX[vk] = (-yCoord[wp]! + deltaXWpWq + yCoord[wq]!) / 2
            yCoord[vk] = (yCoord[wp]! + deltaXWpWq + yCoord[wq]!) / 2
            deltaX[wq] = deltaXWpWq - deltaX[vk]!
            if addsMultiTriangle {
                deltaX[wp1]! -= deltaX[vk]!
            }

            rightChild[wp] = vk
            rightChild[vk] = wq
            if addsMultiTriangle {
                leftChild[vk] = wp1
                rightChild[wq1] = Int?.none
            } else {
                leftChild[vk] = Int?.none
            }
        }

        // Accumulate absolute positions by walking the two binary trees.
        var pos = [Int: (Int, Int)]()
        pos[v1] = (0, yCoord[v1]!)
        var remaining = [v1]
        while let parent = remaining.popLast() {
            setPosition(parent, tree: leftChild, deltaX: deltaX, yCoord: yCoord, pos: &pos, remaining: &remaining)
            setPosition(parent, tree: rightChild, deltaX: deltaX, yCoord: yCoord, pos: &pos, remaining: &remaining)
        }

        return (0 ..< n).map { pos[$0] ?? (0, 0) }
    }

    private static func setPosition(
        _ parent: Int,
        tree: [Int: Int?],
        deltaX: [Int: Int],
        yCoord: [Int: Int],
        pos: inout [Int: (Int, Int)],
        remaining: inout [Int]
    ) {
        guard let childOptional = tree[parent], let child = childOptional else { return }
        let childX = pos[parent]!.0 + deltaX[child]!
        pos[child] = (childX, yCoord[child]!)
        remaining.append(child)
    }

    // MARK: - Triangulation

    /// Triangulates the embedding in place and returns the three outer-face vertices.
    private static func triangulate(_ embedding: MutablePlanarRotation) -> [Int] {
        let componentReps = connectedComponentRepresentatives(embedding)
        for i in 0 ..< (componentReps.count - 1) {
            embedding.connectComponents(componentReps[i], componentReps[i + 1])
        }

        var outerFace: [Int] = []
        var faces: [[Int]] = []
        var visited = Set<Int>()  // packed half-edge keys
        let n = embedding.n
        func key(_ a: Int, _ b: Int) -> Int { a * n + b }

        for v in 0 ..< n {
            for w in embedding.neighborsCW(v) {
                let face = makeBiconnected(embedding, v, w, &visited, key)
                if !face.isEmpty {
                    faces.append(face)
                    if face.count > outerFace.count { outerFace = face }
                }
            }
        }

        for face in faces where face != outerFace {
            triangulateFace(embedding, face[0], face[1])
        }
        // Also triangulate the outer face for a fully-triangulated drawing.
        triangulateFace(embedding, outerFace[0], outerFace[1])

        let a = outerFace[0]
        let b = outerFace[1]
        let c = embedding.ccw(b, a)
        return [a, b, c]
    }

    private static func triangulateFace(_ embedding: MutablePlanarRotation, _ start1: Int, _ start2: Int) {
        var v1 = start1
        var v2 = start2
        var (_, v3) = embedding.nextFaceHalfEdge(v1, v2)
        var (_, v4) = embedding.nextFaceHalfEdge(v2, v3)
        if v1 == v2 || v1 == v3 { return }
        while v1 != v4 {
            if embedding.hasEdge(v1, v3) {
                // Edge already exists — can't triangulate here; advance along the face.
                v1 = v2
                v2 = v3
                v3 = v4
            } else {
                // Add diagonal v1-v3 to triangulate this face.
                embedding.addHalfEdgeCW(v1, v3, v2)
                embedding.addHalfEdgeCCW(v3, v1, v2)
                v2 = v3
                v3 = v4
            }
            (_, v4) = embedding.nextFaceHalfEdge(v2, v3)
        }
    }

    private static func makeBiconnected(
        _ embedding: MutablePlanarRotation,
        _ startingNode: Int,
        _ outgoingNode: Int,
        _ visited: inout Set<Int>,
        _ key: (Int, Int) -> Int
    ) -> [Int] {
        if visited.contains(key(startingNode, outgoingNode)) { return [] }
        visited.insert(key(startingNode, outgoingNode))

        var v1 = startingNode
        var v2 = outgoingNode
        var faceList = [startingNode]
        var faceSet: Set<Int> = [startingNode]
        var (_, v3) = embedding.nextFaceHalfEdge(v1, v2)

        while v2 != startingNode || v3 != outgoingNode {
            if v1 == v2 { break }  // invalid half-edge guard
            if faceSet.contains(v2) {
                embedding.addHalfEdgeCW(v1, v3, v2)
                embedding.addHalfEdgeCCW(v3, v1, v2)
                visited.insert(key(v2, v3))
                visited.insert(key(v3, v1))
                v2 = v1
            } else {
                faceSet.insert(v2)
                faceList.append(v2)
            }
            v1 = v2
            let next = embedding.nextFaceHalfEdge(v2, v3)
            v2 = v3
            v3 = next.1
            visited.insert(key(v1, v2))
        }
        return faceList
    }

    // MARK: - Canonical ordering

    private struct OrderingEntry {
        var vertex: Int
        var outerFace: [Int]
    }

    private static func canonicalOrdering(_ embedding: MutablePlanarRotation, outerFace: [Int]) -> [OrderingEntry] {
        let n = embedding.n
        let v1 = outerFace[0]
        let v2 = outerFace[1]
        var chords = [Int: Int]()
        var marked = Set<Int>()
        var ready = Set(outerFace)

        var ccwNbr = [Int: Int]()
        var cwNbr = [Int: Int]()

        var prev = v2
        for idx in 2 ..< outerFace.count {
            ccwNbr[prev] = outerFace[idx]
            prev = outerFace[idx]
        }
        ccwNbr[prev] = v1

        prev = v1
        for idx in stride(from: outerFace.count - 1, through: 1, by: -1) {
            cwNbr[prev] = outerFace[idx]
            prev = outerFace[idx]
        }

        func isOuterFaceNbr(_ x: Int, _ y: Int) -> Bool {
            if ccwNbr[x] == nil { return cwNbr[x] == y }
            if cwNbr[x] == nil { return ccwNbr[x] == y }
            return ccwNbr[x] == y || cwNbr[x] == y
        }
        func isOnOuterFace(_ x: Int) -> Bool {
            !marked.contains(x) && (ccwNbr[x] != nil || x == v1)
        }

        for v in outerFace {
            for nbr in embedding.neighborsCW(v) where isOnOuterFace(nbr) && !isOuterFaceNbr(v, nbr) {
                chords[v, default: 0] += 1
                ready.remove(v)
            }
        }

        var ordering = [OrderingEntry](repeating: OrderingEntry(vertex: -1, outerFace: []), count: n)
        ordering[0] = OrderingEntry(vertex: v1, outerFace: [])
        ordering[1] = OrderingEntry(vertex: v2, outerFace: [])
        ready.remove(v1)
        ready.remove(v2)

        for k in stride(from: n - 1, through: 2, by: -1) {
            let v = ready.removeFirst()
            marked.insert(v)

            var wp = -1
            var wq = -1
            for nbr in embedding.neighborsCW(v) {
                if marked.contains(nbr) { continue }
                if isOnOuterFace(nbr) {
                    if nbr == v1 {
                        wp = v1
                    } else if nbr == v2 {
                        wq = v2
                    } else if cwNbr[nbr] == v {
                        wp = nbr
                    } else {
                        wq = nbr
                    }
                }
                if wp != -1 && wq != -1 { break }
            }

            var wpWq = [wp]
            var nbr = wp
            while nbr != wq {
                let nextNbr = embedding.ccw(v, nbr)
                wpWq.append(nextNbr)
                cwNbr[nbr] = nextNbr
                ccwNbr[nextNbr] = nbr
                nbr = nextNbr
            }
            // DO NOT add cwNbr[wp]=wq here — the walk loop already set the chain correctly.

            let newFaceNodes = Set(wpWq.dropFirst().dropLast())

            if wpWq.count == 2 {
                // wp and wq were connected by a chord through v; removing v resolves it.
                for w in [wp, wq] {
                    chords[w, default: 0] -= 1
                    if chords[w, default: 0] == 0 { ready.insert(w) }
                }
            } else {
                // Interior nodes are freshly added to the outer face; compute chord counts.
                for w in newFaceNodes {
                    ready.insert(w)
                    for candidate in embedding.neighborsCW(w) {
                        guard isOnOuterFace(candidate) && !isOuterFaceNbr(w, candidate) else { continue }
                        chords[w, default: 0] += 1
                        ready.remove(w)
                        if !newFaceNodes.contains(candidate) {
                            chords[candidate, default: 0] += 1
                            ready.remove(candidate)
                        }
                    }
                }
            }

            ordering[k] = OrderingEntry(vertex: v, outerFace: wpWq)
        }

        return ordering
    }

    // MARK: - Connectivity

    private static func connectedComponentRepresentatives(_ embedding: MutablePlanarRotation) -> [Int] {
        var seen = Array(repeating: false, count: embedding.n)
        var reps: [Int] = []
        for start in 0 ..< embedding.n where !seen[start] {
            reps.append(start)
            var stack = [start]
            seen[start] = true
            while let v = stack.popLast() {
                for w in embedding.neighborsCW(v) where !seen[w] {
                    seen[w] = true
                    stack.append(w)
                }
            }
        }
        return reps
    }
}
