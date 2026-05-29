#if !GRAPHS_USES_TRAITS || GRAPHS_GRID_GRAPH
import Testing
@testable import Graphs

struct GridGraphTests {

    // MARK: - Basic structure

    @Test func verticesAndNeighbors() {
        let g = GridGraph(width: 3, height: 3, allowedDirections: .orthogonal)
        #expect(g.vertexCount == 9)

        let vs = Array(g.vertices())
        #expect(vs.count == 9)
        #expect(vs.first == .init(x: 0, y: 0))
        #expect(vs.last == .init(x: 2, y: 2))

        // Corners have degree 2; edge centers have degree 3
        #expect(g.outDegree(of: .init(x: 0, y: 0)) == 2)   // corner
        #expect(g.outDegree(of: .init(x: 1, y: 0)) == 3)   // top edge center

        // Middle (if existed) would have degree 4; check outgoing edges count from (1,1)
        let degree = Array(g.outgoingEdges(of: .init(x: 1, y: 1))).count
        #expect(degree == 4)
    }

    // MARK: - Edge enumeration

    @Test func edgeCount_orthogonal3x3() {
        // 3×3 orthogonal grid: 12 horizontal + 12 vertical directed edges = 24
        let g = GridGraph(width: 3, height: 3, allowedDirections: .orthogonal)
        let allEdges = Array(g.edges())
        #expect(allEdges.count == 24, "3×3 orthogonal grid has 24 directed edges")
        #expect(g.edgeCount == 24)
    }

    @Test func edgeEndpointsAreCorrect() {
        let g = GridGraph(width: 2, height: 2, allowedDirections: .orthogonal)
        let allEdges = Array(g.edges())
        // Every edge source and destination must be within bounds
        for edge in allEdges {
            #expect(edge.source.x >= 0 && edge.source.x < 2)
            #expect(edge.source.y >= 0 && edge.source.y < 2)
            #expect(edge.destination.x >= 0 && edge.destination.x < 2)
            #expect(edge.destination.y >= 0 && edge.destination.y < 2)
            // Source and destination must differ
            #expect(edge.source != edge.destination)
        }
    }

    @Test func edgesAreAccessibleViaSourceAndDestination() {
        let g = GridGraph(width: 3, height: 3, allowedDirections: .orthogonal)
        for edge in g.edges() {
            #expect(g.source(of: edge) == edge.source)
            #expect(g.destination(of: edge) == edge.destination)
        }
    }

    // MARK: - Incoming edges and in-degree

    @Test func incomingEdges_cornerHasTwo() {
        let g = GridGraph(width: 3, height: 3, allowedDirections: .orthogonal)
        // Corner (0,0) can be reached from (1,0) and (0,1)
        let incoming = Array(g.incomingEdges(of: .init(x: 0, y: 0)))
        #expect(incoming.count == 2)
        #expect(incoming.allSatisfy { $0.destination == .init(x: 0, y: 0) })
    }

    @Test func incomingEdges_centerHasFour() {
        let g = GridGraph(width: 3, height: 3, allowedDirections: .orthogonal)
        let incoming = Array(g.incomingEdges(of: .init(x: 1, y: 1)))
        #expect(incoming.count == 4, "center cell has 4 incoming edges in orthogonal 3×3")
    }

    @Test func inDegreeMatchesIncomingEdgesCount() {
        let g = GridGraph(width: 4, height: 4, allowedDirections: .orthogonal)
        for v in g.vertices() {
            let expected = Array(g.incomingEdges(of: v)).count
            #expect(g.inDegree(of: v) == expected, "inDegree must match incomingEdges count for \(v)")
        }
    }

    @Test func inDegreeSymmetryWithOutDegree() {
        // For an orthogonal grid each cell's in-degree equals its out-degree
        let g = GridGraph(width: 3, height: 3, allowedDirections: .orthogonal)
        for v in g.vertices() {
            #expect(g.inDegree(of: v) == g.outDegree(of: v), "in-degree must equal out-degree in undirected orthogonal grid")
        }
    }

    // MARK: - Edge lookup

    @Test func edgeLookup_existingEdge() {
        let g = GridGraph(width: 3, height: 3, allowedDirections: .orthogonal)
        // (0,0) → (1,0) exists (move right)
        let e = g.edge(from: .init(x: 0, y: 0), to: .init(x: 1, y: 0))
        #expect(e != nil)
        #expect(e?.source == .init(x: 0, y: 0))
        #expect(e?.destination == .init(x: 1, y: 0))
    }

    @Test func edgeLookup_nonExistentEdge_outOfBounds() {
        let g = GridGraph(width: 3, height: 3, allowedDirections: .orthogonal)
        // Moving left from (0,0) would go out of bounds
        #expect(g.edge(from: .init(x: 0, y: 0), to: .init(x: -1, y: 0)) == nil)
    }

    @Test func edgeLookup_nonExistentEdge_disallowedDirection() {
        let g = GridGraph(width: 3, height: 3, allowedDirections: .orthogonal)
        // Diagonal moves are not allowed in orthogonal mode
        #expect(g.edge(from: .init(x: 0, y: 0), to: .init(x: 1, y: 1)) == nil)
    }

    @Test func edgeLookup_destinationOutOfBounds() {
        let g = GridGraph(width: 3, height: 3, allowedDirections: .orthogonal)
        // Moving right from (2,0) would go out of bounds
        #expect(g.edge(from: .init(x: 2, y: 0), to: .init(x: 3, y: 0)) == nil)
    }

    // MARK: - Diagonal and all-directions grids

    @Test func diagonalGrid_cornerDegreeIsTwo() {
        let g = GridGraph(width: 3, height: 3, allowedDirections: .diagonal)
        // Corner (0,0): only (1,1) is reachable diagonally within bounds
        #expect(g.outDegree(of: .init(x: 0, y: 0)) == 1, "top-left corner has only 1 diagonal neighbor")
        // Corner (1,1): all 4 diagonal neighbors are within 3×3
        #expect(g.outDegree(of: .init(x: 1, y: 1)) == 4, "center has 4 diagonal neighbors")
    }

    @Test func allDirectionsGrid_centerDegreeIsEight() {
        let g = GridGraph(width: 3, height: 3, allowedDirections: .all)
        #expect(g.outDegree(of: .init(x: 1, y: 1)) == 8, "center has 8 neighbors with all directions")
    }

    @Test func allDirectionsGrid_cornerDegreeIsThree() {
        let g = GridGraph(width: 3, height: 3, allowedDirections: .all)
        #expect(g.outDegree(of: .init(x: 0, y: 0)) == 3, "corner has 3 neighbors with all directions")
    }

    @Test func edgeCount_diagonalGrid() {
        // A 3×3 diagonal grid: each corner has 1, each edge cell has 2, center has 4
        let g = GridGraph(width: 3, height: 3, allowedDirections: .diagonal)
        // corners (4×1) + edge-centers (4×2) + center (1×4) = 4 + 8 + 4 = 16
        #expect(g.edgeCount == 16, "3×3 diagonal grid has 16 directed edges")
    }

    // MARK: - Direction delta

    @Test func deltaForAllDirections() {
        let cases: [(GridDirection, (Int, Int))] = [
            (.up, (0, -1)), (.down, (0, 1)), (.left, (-1, 0)), (.right, (1, 0)),
            (.upRight, (1, -1)), (.downRight, (1, 1)), (.downLeft, (-1, 1)), (.upLeft, (-1, -1))
        ]
        for (direction, expected) in cases {
            let delta = GridGraph.delta(for: direction)
            #expect(delta.0 == expected.0 && delta.1 == expected.1, "delta for \(direction)")
        }
    }

    // MARK: - BFS / A* on GridGraph

    @Test func bfsVisitsAllReachableVertices() {
        let g = GridGraph(width: 3, height: 3, allowedDirections: .orthogonal)
        var visited: Set<GridGraph.Vertex> = []
        let start = GridGraph.Vertex(x: 0, y: 0)

        for step in BreadthFirstSearch(on: g, from: start) {
            visited.insert(step.currentVertex)
        }

        #expect(visited.count == 9, "BFS from top-left corner must visit all 9 cells")
    }

    @Test func bfsOnHorizontalOnlyGrid_doesNotCrossRows() {
        // A grid that only allows horizontal movement: each row is a separate component
        let g = GridGraph(width: 4, height: 3, allowedDirections: .horizontal)
        var visited: Set<GridGraph.Vertex> = []
        for step in BreadthFirstSearch(on: g, from: .init(x: 0, y: 0)) {
            visited.insert(step.currentVertex)
        }
        // Should only visit row y=0 (4 cells)
        #expect(visited.count == 4, "horizontal-only grid: BFS stays in the same row")
        #expect(visited.allSatisfy { $0.y == 0 })
    }
}
#endif
