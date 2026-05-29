@testable import Graphs
import DequeModule
import Testing

struct GraphBasicTests {
    @Test func addsVerticesAndEdges_countsAndAdjacency() {
        var graph = AdjacencyList()

        let root = graph.addVertex()
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()
        let d = graph.addVertex()
        let x = graph.addVertex()

        graph.addEdge(from: root, to: a)
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: a, to: c)
        graph.addEdge(from: a, to: d)
        graph.addEdge(from: root, to: x)

        #expect(graph.vertices().count == 6)
        #expect(graph.edges().count == 5)
        #expect(graph.adjacentVertices(of: a) == [b, c, d, root])
    }

    @Test func inAndoutgoingEdgesRespectInsertionOrder() {
        var graph = AdjacencyList()
        let u = graph.addVertex()
        let v = graph.addVertex()
        let w = graph.addVertex()

        let uv = graph.addEdge(from: u, to: v)!
        let uw = graph.addEdge(from: u, to: w)!

        #expect(graph.outgoingEdges(of: u) == [uv, uw])
        #expect(graph.incomingEdges(of: v) == [uv])
        #expect(graph.incomingEdges(of: w) == [uw])
    }

    /// Exercises the `BidirectionalGraph` protocol-extension convenience methods:
    /// `predecessors(of:)`, `degree(of:)`, `isIsolated(vertex:)`, `isSource(vertex:)`, `isLeaf(vertex:)`.
    /// These default implementations live in `BidirectionalGraph.swift` and are only reachable
    /// when the concrete type does not override them.
    @Test func bidirectionalGraphExtensionMethods() {
        var graph = AdjacencyList()
        // Directed: A → B → C, with A also → C; isolated vertex D
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()
        let d = graph.addVertex()
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: a, to: c)

        // predecessors(of:) — walks incomingEdges lazily
        let predsOfC = Array(graph.predecessors(of: c))
        #expect(predsOfC.contains(b), "b has edge to c")
        #expect(predsOfC.contains(a), "a has edge to c")
        #expect(Array(graph.predecessors(of: a)).isEmpty, "a has no incoming edges")

        // degree(of:) = inDegree + outDegree
        #expect(graph.degree(of: a) == 2, "a: outDegree 2, inDegree 0 → degree 2")
        #expect(graph.degree(of: b) == 2, "b: outDegree 1, inDegree 1 → degree 2")
        #expect(graph.degree(of: c) == 2, "c: outDegree 0, inDegree 2 → degree 2")
        #expect(graph.degree(of: d) == 0, "d isolated → degree 0")

        // isIsolated — degree == 0
        #expect(graph.isIsolated(vertex: d),  "d has no edges")
        #expect(!graph.isIsolated(vertex: a), "a has outgoing edges")

        // isSource — inDegree == 0
        #expect(graph.isSource(vertex: a),  "a has no incoming edges")
        #expect(!graph.isSource(vertex: b), "b has one incoming edge from a")
        #expect(!graph.isSource(vertex: c), "c has incoming edges from a and b")

        // isLeaf — degree == 1 (exactly one edge total, in or out)
        var leafGraph = AdjacencyList()  // prevent unused-var warning
        let root2 = leafGraph.addVertex()
        let leaf1 = leafGraph.addVertex()
        let leaf2 = leafGraph.addVertex()
        let isolated2 = leafGraph.addVertex()
        leafGraph.addEdge(from: root2, to: leaf1)
        leafGraph.addEdge(from: root2, to: leaf2)
        // root2: outDegree=2, inDegree=0 → degree=2 → NOT a leaf
        // leaf1: outDegree=0, inDegree=1 → degree=1 → IS a leaf
        // isolated2: degree=0 → NOT a leaf
        #expect(leafGraph.isLeaf(vertex: leaf1),     "leaf with one incoming edge has degree 1")
        #expect(!leafGraph.isLeaf(vertex: root2),    "root with two outgoing edges has degree 2")
        #expect(!leafGraph.isLeaf(vertex: isolated2), "isolated vertex has degree 0, not 1")
    }

    /// `remove(vertex:)` removes the vertex and all its incident edges (via `VertexStorageBackedGraph`).
    /// After removal, the vertex count decreases and the removed vertex's edges disappear.
    @Test func vertexRemovalAlsoRemovesEdges() {
        var graph = AdjacencyList()
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: a, to: c)

        #expect(graph.vertexCount == 3)
        #expect(graph.edgeCount == 3)

        // Remove b: should remove both edges incident to b (a→b and b→c)
        graph.remove(vertex: b)

        #expect(graph.vertexCount == 2, "vertex count decreases by 1")
        #expect(graph.edgeCount == 1, "both edges to/from b are removed; only a→c remains")
        #expect(Array(graph.outgoingEdges(of: a)).count == 1, "only a→c remains from a")
    }

    /// `addEdges(providing:edges:)` with an `@ArrayBuilder` closure covers `buildExpression`,
    /// `buildBlock`, `buildOptional`, `buildEither`, and `buildArray`.
    @Test func addEdgesBuilderCoversAllArrayBuilderBranches() {
        var graph = AdjacencyList()
        let shouldAdd = true

        graph.addEdges(providing: \.label) {
            // buildExpression + buildBlock
            ("A", "B")
            ("B", "C")
            // buildOptional — value present
            if shouldAdd { ("C", "D") }
            // buildOptional — value absent
            if !shouldAdd { ("X", "Y") }
            // buildEither(first:)
            if shouldAdd { ("A", "C") } else { ("X", "Z") }
            // buildEither(second:)
            if !shouldAdd { ("X", "Z") } else { ("A", "D") }
        }

        // A, B, C, D deduped; X, Y, Z never appear (shouldAdd is true)
        let labels = Set(graph.vertices().map { graph[$0].label })
        #expect(labels.contains("A") && labels.contains("B") && labels.contains("C") && labels.contains("D"))
        #expect(!labels.contains("X") && !labels.contains("Y") && !labels.contains("Z"),
                "false branches must not add vertices")
        // 5 edges: A→B, B→C, C→D, A→C, A→D
        #expect(graph.edgeCount == 5)
    }

    /// `buildArray` in `ArrayBuilder` is triggered by `for` loops inside builder closures.
    @Test func addEdgesBuilderLoopTriggersBuildArray() {
        var graph = AdjacencyList()
        let pairs = [("P", "Q"), ("Q", "R")]

        graph.addEdges(providing: \.label) {
            for (src, dst) in pairs {
                (src, dst)
            }
        }

        #expect(graph.vertexCount == 3, "P, Q, R are added")
        #expect(graph.edgeCount == 2)
    }

    /// `addEdges(providing:edges:[(source:destination:configure:)])` creates vertices from
    /// labels AND configures each edge with a closure, covering the edge-with-configure overload.
    @Test func addEdgesWithEdgeConfigureClosures() {
        var graph = AdjacencyList()

        graph.addEdges(
            providing: \.label,
            edges: [
                (source: "A", destination: "B", configure: { $0.weight = 1.0 }),
                (source: "B", destination: "C", configure: { $0.weight = 2.0 })
            ]
        )

        #expect(graph.vertexCount == 3)
        #expect(graph.edgeCount == 2)

        // Verify edge weights were set via the configure closure
        let ab = graph.edges().first(where: { graph.source(of: $0).map { graph[$0].label } == "A" })!
        #expect(graph[ab].weight == 1.0, "a→b edge weight set by configure closure")
    }

    /// `Deque.push(_:)` and `Deque.pop()` implement `StackProtocol`.
    /// These are distinct from Array's conformance and cover the `Deque` extension.
    @Test func dequeStackProtocolPushAndPop() {
        var stack: Deque<Int> = []
        #expect(stack.isEmpty)
        stack.push(1)
        stack.push(2)
        stack.push(3)
        #expect(!stack.isEmpty)
        #expect(stack.pop() == 3, "LIFO: last pushed is first popped")
        #expect(stack.pop() == 2)
        #expect(stack.pop() == 1)
        #expect(stack.pop() == nil, "pop on empty returns nil")
    }
}


