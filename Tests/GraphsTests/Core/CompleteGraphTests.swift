#if !GRAPHS_USES_TRAITS || GRAPHS_GRAPH_FAMILIES
    @testable import Graphs
    import Testing

    struct CompleteGraphTests {

        // MARK: - Structure

        @Test func verticesMatchInput() {
            let g = CompleteGraph(count: 5)
            #expect(Array(g.vertices()) == [0, 1, 2, 3, 4])
            #expect(g.vertexCount == 5)
        }

        @Test func duplicateVerticesIgnored() {
            let g = CompleteGraph(vertices: [1, 2, 2, 3])
            #expect(g.vertexCount == 3)
        }

        @Test func customVertexType() {
            let g = CompleteGraph(vertices: ["a", "b", "c"])
            #expect(g.vertexCount == 3)
            #expect(g.edgeCount == 6)
        }

        // MARK: - Edge counts

        @Test func edgeCount() {
            #expect(CompleteGraph(count: 0).edgeCount == 0)
            #expect(CompleteGraph(count: 1).edgeCount == 0)
            #expect(CompleteGraph(count: 2).edgeCount == 2)
            #expect(CompleteGraph(count: 5).edgeCount == 20)
        }

        @Test func allEdgesUnique() {
            let g = CompleteGraph(count: 4)
            let all = Array(g.edges())
            let unique = Set(all)
            #expect(all.count == 12)
            #expect(all.count == unique.count)
        }

        @Test func edgesContainNoSelfLoops() {
            let g = CompleteGraph(count: 4)
            for edge in g.edges() {
                #expect(edge.source != edge.destination)
            }
        }

        // MARK: - Degrees

        @Test func outDegreeIsNMinusOne() {
            let g = CompleteGraph(count: 4)
            for v in g.vertices() {
                #expect(g.outDegree(of: v) == 3)
            }
        }

        @Test func inDegreeIsNMinusOne() {
            let g = CompleteGraph(count: 4)
            for v in g.vertices() {
                #expect(g.inDegree(of: v) == 3)
            }
        }

        @Test func degreeOfUnknownVertexIsZero() {
            let g = CompleteGraph(count: 3)
            #expect(g.outDegree(of: 99) == 0)
            #expect(g.inDegree(of: 99) == 0)
        }

        // MARK: - Outgoing / Incoming edges

        @Test func outgoingEdgesExcludeSelf() {
            let g = CompleteGraph(count: 4)
            for v in g.vertices() {
                let dests = g.outgoingEdges(of: v).map(\.destination)
                #expect(!dests.contains(v))
                #expect(dests.count == 3)
            }
        }

        @Test func incomingEdgesExcludeSelf() {
            let g = CompleteGraph(count: 4)
            for v in g.vertices() {
                let srcs = g.incomingEdges(of: v).map(\.source)
                #expect(!srcs.contains(v))
                #expect(srcs.count == 3)
            }
        }

        @Test func outgoingSourceAndDestinationAccessors() {
            let g = CompleteGraph(count: 3)
            for edge in g.outgoingEdges(of: 0) {
                #expect(g.source(of: edge) == edge.source)
                #expect(g.destination(of: edge) == edge.destination)
            }
        }

        // MARK: - EdgeLookupGraph

        @Test func edgeLookupExists() {
            let g = CompleteGraph(count: 3)
            #expect(g.edge(from: 0, to: 1) != nil)
            #expect(g.edge(from: 1, to: 0) != nil)
            #expect(g.edge(from: 2, to: 0) != nil)
        }

        @Test func edgeLookupSelfLoopIsNil() {
            let g = CompleteGraph(count: 3)
            for v in g.vertices() {
                #expect(g.edge(from: v, to: v) == nil)
            }
        }

        @Test func edgeLookupUnknownVertexIsNil() {
            let g = CompleteGraph(count: 3)
            #expect(g.edge(from: 0, to: 99) == nil)
            #expect(g.edge(from: 99, to: 0) == nil)
        }

        // MARK: - AdjacencyGraph

        @Test func adjacentVerticesExcludeSelf() {
            let g = CompleteGraph(count: 4)
            for v in g.vertices() {
                let adj = Array(g.adjacentVertices(of: v))
                #expect(!adj.contains(v))
                #expect(adj.count == 3)
            }
        }

        // MARK: - Directed symmetry

        @Test func bothDirectionsExist() {
            let g = CompleteGraph(count: 4)
            for u in g.vertices() {
                for v in g.vertices() where u != v {
                    #expect(g.edge(from: u, to: v) != nil)
                    #expect(g.edge(from: v, to: u) != nil)
                }
            }
        }
    }
#endif
