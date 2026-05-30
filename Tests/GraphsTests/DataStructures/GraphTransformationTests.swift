import Testing

@testable import Graphs

struct GraphTransformationTests {

    @Test func reversedGraphFlipsEdgeDirection() {
        var graph = DefaultAdjacencyList()

        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()

        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: c, to: a)

        // Test reversed() method
        let reversed = graph.reversed()

        // In reversed graph, edges should be reversed
        #expect(reversed.outDegree(of: a) == 1)  // c -> a
        #expect(reversed.outDegree(of: b) == 1)  // a -> b
        #expect(reversed.outDegree(of: c) == 1)  // b -> c

        // Test that we can traverse the reversed graph
        let aNeighbors = Array(reversed.outgoingEdges(of: a).compactMap { reversed.destination(of: $0) })
        #expect(aNeighbors.count == 1)
        #expect(aNeighbors.contains(c))
    }

    @Test func transposeGraphFlipsEdgeDirection() {
        var graph = DefaultAdjacencyList()

        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()

        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)

        // Test transpose() method (alias for reversed)
        let transposed = graph.transpose()

        // In transposed graph, edges should be reversed
        #expect(transposed.outDegree(of: a) == 0)  // no outgoing edges
        #expect(transposed.outDegree(of: b) == 1)  // a -> b becomes b -> a
        #expect(transposed.outDegree(of: c) == 1)  // b -> c becomes c -> b

        let bNeighbors = Array(transposed.outgoingEdges(of: b).compactMap { transposed.destination(of: $0) })
        #expect(bNeighbors.count == 1)
        #expect(bNeighbors.contains(a))
    }

    @Test func complementGraphInvertsAdjacency() {
        // ComplementGraphView requires EdgeLookupGraph — use AdjacencyMatrix
        var graph = AdjacencyMatrix()

        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()

        graph.addEdge(from: a, to: b)

        // 3 vertices: 3×2 = 6 possible directed edges (no self-loops)
        // Original has 1 edge, so complement has 5
        let comp = graph.complement()
        #expect(comp.edgeCount == 5)

        // Complement must not contain the original edge A→B
        #expect(comp.outDegree(of: a) == 1)  // only A→C (not A→B and not A→A)
        let aNeighbors = Array(comp.outgoingEdges(of: a).compactMap { comp.destination(of: $0) })
        #expect(aNeighbors == [c])

        // Complement must contain all other directed edges
        #expect(comp.outDegree(of: b) == 2)  // B→A and B→C
        #expect(comp.outDegree(of: c) == 2)  // C→A and C→B
    }

    @Test func filteredGraphExcludesMatchingVertices() {
        var graph = DefaultAdjacencyList()

        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()
        let d = graph.addVertex()

        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: c, to: d)
        graph.addEdge(from: d, to: a)

        // Test filtered() method with vertex predicate
        let filtered = graph.filtered { vertex in
            // Only include vertices a and c
            vertex == a || vertex == c
        }

        #expect(filtered.vertexCount == 2)
        #expect(filtered.outDegree(of: a) == 0)  // a -> b, but b is filtered out
        #expect(filtered.outDegree(of: c) == 0)  // c -> d, but d is filtered out
    }

    @Test func undirectedGraphMakesEdgesBidirectional() {
        var graph = DefaultAdjacencyList()

        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()

        // Add directed edges
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)

        // Test undirected() method
        let undirected = graph.undirected()

        // In undirected view, each edge can be traversed both ways
        #expect(undirected.outDegree(of: a) == 1)  // a -> b
        #expect(undirected.outDegree(of: b) == 2)  // b -> a and b -> c
        #expect(undirected.outDegree(of: c) == 1)  // c -> b

        // Test that we can traverse in both directions
        let aNeighbors = Array(undirected.outgoingEdges(of: a).compactMap { undirected.destination(of: $0) })
        #expect(aNeighbors.contains(b))

        let bNeighbors = Array(undirected.outgoingEdges(of: b).compactMap { undirected.destination(of: $0) })
        #expect(bNeighbors.contains(a))
        #expect(bNeighbors.contains(c))
    }

    @Test func chainingTransformationsCompose() {
        var graph = DefaultAdjacencyList()

        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()

        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)

        // Test chaining: reverse -> reverse should give original
        let reversed = graph.reversed()
        let backToOriginal = reversed.reversed()

        // Should be equivalent to original graph
        #expect(backToOriginal.outDegree(of: a) == 1)  // a -> b
        #expect(backToOriginal.outDegree(of: b) == 1)  // b -> c
        #expect(backToOriginal.outDegree(of: c) == 0)  // c has no outgoing edges

        // complement().complement() on AdjacencyMatrix round-trips back to the original
        var matrix = AdjacencyMatrix()
        let ma = matrix.addVertex()
        let mb = matrix.addVertex()
        matrix.addEdge(from: ma, to: mb)
        let doubleComplement = matrix.complement().complement()
        #expect(doubleComplement.edgeCount == matrix.edgeCount)
        #expect(doubleComplement.outDegree(of: ma) == matrix.outDegree(of: ma))
        #expect(doubleComplement.outDegree(of: mb) == matrix.outDegree(of: mb))
    }

    @Test func convenienceFilteringMethods() {
        var graph = DefaultAdjacencyList()

        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()

        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: c, to: a)

        // Test filterVertices(where:) method
        let filteredVertices = graph.filterVertices { $0 == a || $0 == c }
        #expect(filteredVertices.vertexCount == 2)

        // Test filterEdges(where:) method - this would need edge properties to be meaningful
        // For now, just test that the method exists and returns a filtered view
        let filteredEdges = graph.filterEdges(where: { _ in true })  // include all edges
        #expect(filteredEdges.edgeCount == 3)
    }

    @Test func transposeWorksWithAdjacencyMatrix() {
        var matrix = AdjacencyMatrix()

        let a = matrix.addVertex()
        let b = matrix.addVertex()
        let c = matrix.addVertex()

        matrix.addEdge(from: a, to: b)
        matrix.addEdge(from: b, to: c)

        // Test transpose with adjacency matrix
        let transposed = matrix.transpose()

        // Verify the transpose
        #expect(transposed.outDegree(of: a) == 0)
        #expect(transposed.outDegree(of: b) == 1)
        #expect(transposed.outDegree(of: c) == 1)

        // Test that we can get the original back
        let backToOriginal = transposed.transpose()
        #expect(backToOriginal.outDegree(of: a) == 1)
        #expect(backToOriginal.outDegree(of: b) == 1)
        #expect(backToOriginal.outDegree(of: c) == 0)
    }
}
