#if !GRAPHS_USES_TRAITS || GRAPHS_GRAPH_FAMILIES

    import Testing

    @testable import Graphs

    // MARK: - PathGraph Tests

    struct PathGraphTests {
        @Test func vertexAndEdgeCounts() {
            let g = PathGraph(n: 5)
            #expect(g.vertexCount == 5)
            #expect(g.edgeCount == 4)
        }

        @Test func singleVertex() {
            let g = PathGraph(n: 1)
            #expect(g.vertexCount == 1)
            #expect(g.edgeCount == 0)
            #expect(Array(g.edges()).isEmpty)
        }

        @Test func edgesAreCorrect() {
            let g = PathGraph(n: 4)
            let edgeList = Array(g.edges())
            #expect(edgeList.count == 3)
            #expect(edgeList[0] == SimpleEdge(source: 0, destination: 1))
            #expect(edgeList[1] == SimpleEdge(source: 1, destination: 2))
            #expect(edgeList[2] == SimpleEdge(source: 2, destination: 3))
        }

        @Test func outgoingEdges() {
            let g = PathGraph(n: 5)
            #expect(Array(g.outgoingEdges(of: 0)) == [SimpleEdge(source: 0, destination: 1)])
            #expect(Array(g.outgoingEdges(of: 4)).isEmpty)
        }

        @Test func incomingEdges() {
            let g = PathGraph(n: 5)
            #expect(Array(g.incomingEdges(of: 0)).isEmpty)
            #expect(Array(g.incomingEdges(of: 3)) == [SimpleEdge(source: 2, destination: 3)])
        }

        @Test func edgeLookup() {
            let g = PathGraph(n: 5)
            #expect(g.edge(from: 1, to: 2) != nil)
            #expect(g.edge(from: 2, to: 1) == nil)  // no reverse edge
            #expect(g.edge(from: 0, to: 2) == nil)  // not adjacent
            #expect(g.edge(from: 4, to: 5) == nil)  // out of range
        }

        @Test func degrees() {
            let g = PathGraph(n: 5)
            #expect(g.outDegree(of: 0) == 1)
            #expect(g.outDegree(of: 4) == 0)
            #expect(g.inDegree(of: 0) == 0)
            #expect(g.inDegree(of: 4) == 1)
        }

        @Test func vertices() {
            let g = PathGraph(n: 5)
            #expect(Array(g.vertices()) == [0, 1, 2, 3, 4])
        }
    }

    // MARK: - CycleGraph Tests

    struct CycleGraphTests {
        @Test func vertexAndEdgeCounts() {
            let g = CycleGraph(n: 5)
            #expect(g.vertexCount == 5)
            #expect(g.edgeCount == 5)
        }

        @Test func wrapsAround() {
            let g = CycleGraph(n: 4)
            let edgeList = Array(g.edges())
            #expect(edgeList.count == 4)
            #expect(edgeList[3] == SimpleEdge(source: 3, destination: 0))
        }

        @Test func edgesAreCorrect() {
            let g = CycleGraph(n: 3)
            let edgeList = Array(g.edges())
            #expect(edgeList.count == 3)
            #expect(edgeList[0] == SimpleEdge(source: 0, destination: 1))
            #expect(edgeList[1] == SimpleEdge(source: 1, destination: 2))
            #expect(edgeList[2] == SimpleEdge(source: 2, destination: 0))
        }

        @Test func edgeLookup() {
            let g = CycleGraph(n: 5)
            #expect(g.edge(from: 4, to: 0) != nil)  // wrap-around edge
            #expect(g.edge(from: 0, to: 4) == nil)  // reverse not present
            #expect(g.edge(from: 0, to: 2) == nil)  // skip not present
        }

        @Test func degrees() {
            let g = CycleGraph(n: 5)
            for v in 0 ..< 5 {
                #expect(g.outDegree(of: v) == 1)
                #expect(g.inDegree(of: v) == 1)
            }
        }

        @Test func singleVertex() {
            let g = CycleGraph(n: 1)
            let edgeList = Array(g.edges())
            #expect(edgeList.count == 1)
            // Self-loop: 0→0
            #expect(edgeList[0] == SimpleEdge(source: 0, destination: 0))
        }
    }

    // MARK: - StarGraph Tests

    struct StarGraphTests {
        @Test func vertexAndEdgeCounts() {
            let g = StarGraph(n: 5)
            #expect(g.vertexCount == 6)  // 5 leaves + 1 hub
            #expect(g.edgeCount == 5)
        }

        @Test func hubIndex() {
            let g = StarGraph(n: 4)
            #expect(g.center == 4)
        }

        @Test func hubHasAllOutgoing() {
            let g = StarGraph(n: 4)
            let outgoing = Array(g.outgoingEdges(of: g.center))
            #expect(outgoing.count == 4)
            for i in 0 ..< 4 {
                #expect(outgoing[i] == SimpleEdge(source: 4, destination: i))
            }
        }

        @Test func leavesHaveNoOutgoing() {
            let g = StarGraph(n: 4)
            for leaf in 0 ..< 4 {
                #expect(Array(g.outgoingEdges(of: leaf)).isEmpty)
            }
        }

        @Test func leavesHaveOneIncoming() {
            let g = StarGraph(n: 4)
            for leaf in 0 ..< 4 {
                let incoming = Array(g.incomingEdges(of: leaf))
                #expect(incoming.count == 1)
                #expect(incoming[0] == SimpleEdge(source: 4, destination: leaf))
            }
        }

        @Test func hubHasNoIncoming() {
            let g = StarGraph(n: 4)
            #expect(Array(g.incomingEdges(of: g.center)).isEmpty)
        }

        @Test func edgeLookup() {
            let g = StarGraph(n: 5)
            #expect(g.edge(from: g.center, to: 0) != nil)
            #expect(g.edge(from: g.center, to: 4) != nil)
            #expect(g.edge(from: 0, to: g.center) == nil)
            #expect(g.edge(from: g.center, to: 5) == nil)  // hub to itself
        }

        @Test func degrees() {
            let g = StarGraph(n: 5)
            #expect(g.outDegree(of: g.center) == 5)
            for leaf in 0 ..< 5 {
                #expect(g.outDegree(of: leaf) == 0)
                #expect(g.inDegree(of: leaf) == 1)
            }
            #expect(g.inDegree(of: g.center) == 0)
        }
    }

    // MARK: - WheelGraph Tests

    struct WheelGraphTests {
        @Test func vertexAndEdgeCounts() {
            let g = WheelGraph(n: 5)
            #expect(g.vertexCount == 6)  // 5 rim + 1 hub
            #expect(g.edgeCount == 10)  // 5 spokes + 5 cycle
        }

        @Test func hubIndex() {
            let g = WheelGraph(n: 4)
            #expect(g.hub == 4)
        }

        @Test func hubHasNSpokes() {
            let g = WheelGraph(n: 5)
            let outgoing = Array(g.outgoingEdges(of: g.hub))
            #expect(outgoing.count == 5)
        }

        @Test func rimVertexHasOneCycleEdge() {
            let g = WheelGraph(n: 5)
            let outgoing = Array(g.outgoingEdges(of: 0))
            #expect(outgoing.count == 1)
            #expect(outgoing[0] == SimpleEdge(source: 0, destination: 1))
        }

        @Test func rimWrapAround() {
            let g = WheelGraph(n: 5)
            let outgoing = Array(g.outgoingEdges(of: 4))
            #expect(outgoing.count == 1)
            #expect(outgoing[0] == SimpleEdge(source: 4, destination: 0))
        }

        @Test func rimVertexHasTwoIncoming() {
            let g = WheelGraph(n: 5)
            for v in 0 ..< 5 {
                let incoming = Array(g.incomingEdges(of: v))
                #expect(incoming.count == 2)
            }
        }

        @Test func hubHasNoIncoming() {
            let g = WheelGraph(n: 5)
            #expect(Array(g.incomingEdges(of: g.hub)).isEmpty)
        }

        @Test func edgeLookup() {
            let g = WheelGraph(n: 5)
            #expect(g.edge(from: g.hub, to: 3) != nil)  // spoke
            #expect(g.edge(from: 2, to: 3) != nil)  // cycle edge
            #expect(g.edge(from: 3, to: 2) == nil)  // reverse not present
            #expect(g.edge(from: 0, to: g.hub) == nil)  // leaf to hub not present
        }

        @Test func edgeListCount() {
            let g = WheelGraph(n: 6)
            #expect(Array(g.edges()).count == g.edgeCount)
        }
    }

    // MARK: - LadderGraph Tests

    struct LadderGraphTests {
        @Test func vertexAndEdgeCounts() {
            let g = LadderGraph(n: 4)
            #expect(g.vertexCount == 8)
            #expect(g.edgeCount == 10)  // 3*4-2 = 10
        }

        @Test func edgeCountFormula() {
            for n in 1 ... 6 {
                let g = LadderGraph(n: n)
                let counted = Array(g.edges()).count
                #expect(counted == g.edgeCount)
            }
        }

        @Test func topPathEdges() {
            let g = LadderGraph(n: 3)
            // Top: 0→1, 1→2
            #expect(g.edge(from: 0, to: 1) != nil)
            #expect(g.edge(from: 1, to: 2) != nil)
        }

        @Test func bottomPathEdges() {
            let g = LadderGraph(n: 3)
            // Bottom: 3→4, 4→5
            #expect(g.edge(from: 3, to: 4) != nil)
            #expect(g.edge(from: 4, to: 5) != nil)
        }

        @Test func rungEdges() {
            let g = LadderGraph(n: 3)
            // Rungs: 0→3, 1→4, 2→5
            #expect(g.edge(from: 0, to: 3) != nil)
            #expect(g.edge(from: 1, to: 4) != nil)
            #expect(g.edge(from: 2, to: 5) != nil)
        }

        @Test func noReverseEdges() {
            let g = LadderGraph(n: 3)
            #expect(g.edge(from: 1, to: 0) == nil)
            #expect(g.edge(from: 3, to: 0) == nil)
        }

        @Test func outDegrees() {
            let g = LadderGraph(n: 4)
            // Top rail: first 3 have degree 2 (path + rung), last has degree 1 (rung only)
            #expect(g.outDegree(of: 0) == 2)
            #expect(g.outDegree(of: 3) == 1)
            // Bottom rail: first 3 have degree 1 (path only), last has degree 0
            #expect(g.outDegree(of: 4) == 1)
            #expect(g.outDegree(of: 7) == 0)
        }
    }

    // MARK: - HypercubeGraph Tests

    struct HypercubeGraphTests {
        @Test func dimension0() {
            let g = HypercubeGraph(dimension: 0)
            #expect(g.vertexCount == 1)
            #expect(g.edgeCount == 0)
        }

        @Test func dimension1() {
            let g = HypercubeGraph(dimension: 1)
            #expect(g.vertexCount == 2)
            #expect(g.edgeCount == 1)
            #expect(g.edge(from: 0, to: 1) != nil)
            #expect(g.edge(from: 1, to: 0) == nil)  // directed upward only
        }

        @Test func dimension2() {
            let g = HypercubeGraph(dimension: 2)
            #expect(g.vertexCount == 4)
            #expect(g.edgeCount == 4)
        }

        @Test func dimension3() {
            let g = HypercubeGraph(dimension: 3)
            #expect(g.vertexCount == 8)
            #expect(g.edgeCount == 12)  // 3 * 2^(3-1) = 12 directed edges
        }

        @Test func edgesAreBitFlips() {
            let g = HypercubeGraph(dimension: 3)
            // Vertex 0b000 should connect to 0b001, 0b010, 0b100
            let outgoing = Array(g.outgoingEdges(of: 0b000)).map(\.destination)
            #expect(outgoing.contains(0b001))
            #expect(outgoing.contains(0b010))
            #expect(outgoing.contains(0b100))
            #expect(outgoing.count == 3)
        }

        @Test func topVertexHasNoOutgoing() {
            let g = HypercubeGraph(dimension: 3)
            // Vertex 0b111 = 7 has all bits set, no upward edges
            #expect(Array(g.outgoingEdges(of: 7)).isEmpty)
        }

        @Test func outDegreeEqualsZeroBits() {
            let g = HypercubeGraph(dimension: 4)
            // Vertex 0b0110 = 6: has 2 zero-bits, so out-degree = 2
            #expect(g.outDegree(of: 0b0110) == 2)
            // Vertex 0b0000 = 0: 4 zero-bits, out-degree = 4
            #expect(g.outDegree(of: 0b0000) == 4)
        }

        @Test func edgeListCount() {
            for d in 0 ... 4 {
                let g = HypercubeGraph(dimension: d)
                let counted = Array(g.edges()).count
                #expect(counted == g.edgeCount)
            }
        }

        @Test func edgeLookupUpward() {
            let g = HypercubeGraph(dimension: 3)
            #expect(g.edge(from: 0b000, to: 0b001) != nil)
            #expect(g.edge(from: 0b001, to: 0b000) == nil)  // downward not valid
            #expect(g.edge(from: 0b000, to: 0b011) == nil)  // 2-bit difference
        }
    }

    // MARK: - CompleteBipartiteGraph Tests

    struct CompleteBipartiteGraphTests {
        @Test func vertexAndEdgeCounts() {
            let g = CompleteBipartiteGraph(m: 3, n: 4)
            #expect(g.vertexCount == 7)
            #expect(g.edgeCount == 12)
        }

        @Test func allEdgesFromLeftToRight() {
            let g = CompleteBipartiteGraph(m: 3, n: 4)
            let edgeList = Array(g.edges())
            #expect(edgeList.count == 12)
            for edge in edgeList {
                #expect(edge.source < 3)  // left vertex
                #expect(edge.destination >= 3)  // right vertex
                #expect(edge.destination < 7)
            }
        }

        @Test func leftOutDegree() {
            let g = CompleteBipartiteGraph(m: 3, n: 4)
            for left in 0 ..< 3 {
                #expect(g.outDegree(of: left) == 4)
            }
        }

        @Test func rightOutDegree() {
            let g = CompleteBipartiteGraph(m: 3, n: 4)
            for right in 3 ..< 7 {
                #expect(g.outDegree(of: right) == 0)
            }
        }

        @Test func rightInDegree() {
            let g = CompleteBipartiteGraph(m: 3, n: 4)
            for right in 3 ..< 7 {
                #expect(g.inDegree(of: right) == 3)
            }
        }

        @Test func edgeLookup() {
            let g = CompleteBipartiteGraph(m: 2, n: 3)
            #expect(g.edge(from: 0, to: 2) != nil)
            #expect(g.edge(from: 1, to: 4) != nil)
            #expect(g.edge(from: 2, to: 0) == nil)  // right to left not present
            #expect(g.edge(from: 0, to: 1) == nil)  // left to left not present
        }

        @Test func rightVerticesAreIndexedAfterLeft() {
            let g = CompleteBipartiteGraph(m: 3, n: 4)
            // Right vertices are m..<m+n
            let rightVertices = Array(g.incomingEdges(of: 3)).map(\.destination)
            #expect(rightVertices.allSatisfy { $0 == 3 })
        }

        @Test func edgeCountK22() {
            let g = CompleteBipartiteGraph(m: 2, n: 2)
            #expect(g.edgeCount == 4)
            #expect(Array(g.edges()).count == 4)
        }
    }

    // MARK: - PetersonGraph Tests

    struct PetersonGraphTests {
        @Test func vertexCount() {
            let g = PetersonGraph()
            #expect(g.vertexCount == 10)
        }

        @Test func edgeCount() {
            let g = PetersonGraph()
            // 15 undirected edges × 2 directions = 30 directed edges
            #expect(g.edgeCount == 30)
        }

        @Test func allVerticesHaveDegree3() {
            let g = PetersonGraph()
            for v in 0 ..< 10 {
                #expect(g.outDegree(of: v) == 3)
                #expect(g.inDegree(of: v) == 3)
            }
        }

        @Test func outerCycleEdgesPresent() {
            let g = PetersonGraph()
            // Outer cycle: 0-1-2-3-4-0
            #expect(g.edge(from: 0, to: 1) != nil)
            #expect(g.edge(from: 1, to: 2) != nil)
            #expect(g.edge(from: 2, to: 3) != nil)
            #expect(g.edge(from: 3, to: 4) != nil)
            #expect(g.edge(from: 4, to: 0) != nil)
        }

        @Test func innerPentagramEdgesPresent() {
            let g = PetersonGraph()
            // Inner pentagram: 5-7-9-6-8-5
            #expect(g.edge(from: 5, to: 7) != nil)
            #expect(g.edge(from: 7, to: 9) != nil)
            #expect(g.edge(from: 9, to: 6) != nil)
            #expect(g.edge(from: 6, to: 8) != nil)
            #expect(g.edge(from: 8, to: 5) != nil)
        }

        @Test func spokeEdgesPresent() {
            let g = PetersonGraph()
            // Spokes: 0-5, 1-6, 2-7, 3-8, 4-9
            for i in 0 ..< 5 {
                #expect(g.edge(from: i, to: i + 5) != nil)
                #expect(g.edge(from: i + 5, to: i) != nil)
            }
        }

        @Test func nonEdgesAbsent() {
            let g = PetersonGraph()
            // Outer cycle non-adjacencies
            #expect(g.edge(from: 0, to: 2) == nil)
            #expect(g.edge(from: 0, to: 3) == nil)
            // Inner non-adjacencies
            #expect(g.edge(from: 5, to: 6) == nil)
        }

        @Test func edgeListHasCorrectCount() {
            let g = PetersonGraph()
            let counted = Array(g.edges()).count
            #expect(counted == 30)
        }

        @Test func adjacentVerticesCount() {
            let g = PetersonGraph()
            for v in 0 ..< 10 {
                let adj = Array(g.adjacentVertices(of: v))
                #expect(adj.count == 3)
            }
        }
    }

#endif
