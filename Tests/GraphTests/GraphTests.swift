import Graphs
import Testing

struct GraphStrategy {
    @Test func graph() {
        let graph = Graph(edges: [
            "Root": ["A", "B", "C"],
            "B": ["X", "Y", "Z"],
            "Y": ["N", "M"]
        ])

        let bfs = ["Root", "A", "B", "C", "X", "Y", "Z", "N", "M"]
        #expect(graph.traverse(from: "Root", strategy: .bfs()) == bfs)
        #expect(graph.traverse(from: "Root", strategy: .bfs(.onlyNodes())) == bfs)

        let preorder = ["Root", "A", "B", "X", "Y", "N", "M", "Z", "C"]
        #expect(graph.traverse(from: "Root", strategy: .dfs()) == preorder)
        #expect(graph.traverse(from: "Root", strategy: .dfs(.onlyNodes())) == preorder)

        #expect(graph.traverse(from: "Root", strategy: .dfs(order: .preorder())) == preorder)
        #expect(graph.traverse(from: "Root", strategy: .dfs(.onlyNodes(), order: .preorder())) == preorder)

        let postorder = ["A", "X", "N", "M", "Y", "Z", "B", "C", "Root"]
        #expect(graph.traverse(from: "Root", strategy: .dfs(order: .postorder())) == postorder)
        #expect(graph.traverse(from: "Root", strategy: .dfs(.onlyNodes(), order: .postorder())) == postorder)
    }

    @Test func binaryGraph() {
        let graph = BinaryGraph(edges: [
            "Root": (lhs: "A", rhs: "B"),
            "A": (lhs: "X", rhs: "Y"),
            "Y": (lhs: nil, rhs: "N")
        ])

        let bfs = ["Root", "A", "B", "X", "Y", "N"]
        #expect(graph.traverse(from: "Root", strategy: .bfs()) == bfs)
        #expect(graph.traverse(from: "Root", strategy: .bfs(.onlyNodes())) == bfs)

        let preorder = ["Root", "A", "X", "Y", "N", "B"]
        #expect(graph.traverse(from: "Root", strategy: .dfs()) == preorder)
        #expect(graph.traverse(from: "Root", strategy: .dfs(.onlyNodes())) == preorder)

        #expect(graph.traverse(from: "Root", strategy: .dfs(order: .preorder())) == preorder)
        #expect(graph.traverse(from: "Root", strategy: .dfs(.onlyNodes(), order: .preorder())) == preorder)

        let inorder = ["X", "A", "Y", "N", "Root", "B"]
        #expect(graph.traverse(from: "Root", strategy: .dfs(order: .inorder())) == inorder)
        #expect(graph.traverse(from: "Root", strategy: .dfs(.onlyNodes(), order: .inorder())) == inorder)

        let postorder = ["X", "N", "Y", "A", "B", "Root"]
        #expect(graph.traverse(from: "Root", strategy: .dfs(order: .postorder())) == postorder)
        #expect(graph.traverse(from: "Root", strategy: .dfs(.trackDepth(), order: .postorder())).compactMap(\.node) == postorder)
    }

    @Test func unique() {
        let graph = Graph(edges: [
            "Root": ["A", "B", "C"],
            "B": ["X", "Y", "A"]
        ])

        #expect(graph.traverse(from: "Root", strategy: .bfs()) == ["Root", "A", "B", "C", "X", "Y", "A"])
        #expect(graph.traverse(from: "Root", strategy: .bfs().visitEachNodeOnce()) == ["Root", "A", "B", "C", "X", "Y"])
    }

    @Test func trace() {
        let graph = Graph(edges: [
            "Root": ["A", "B", "C"],
            "B": ["X", "Y", "A"]
        ])

        #expect(graph.traverse(from: "Root", strategy: .bfs(.trackDepth())).map(\.node) == ["Root", "A", "B", "C", "X", "Y", "A"])
        #expect(graph.traversal(from: "Root", strategy: .bfs(.trackDepth())).map(\.depth) == [0, 1, 1, 1, 2, 2, 2])
        #expect(graph.traversal(from: "Root", strategy: .bfs(.trackPath())).map(\.path) == [
            ["Root"],
            ["Root", "A"],
            ["Root", "B"],
            ["Root", "C"],
            ["Root", "B", "X"],
            ["Root", "B", "Y"],
            ["Root", "B", "A"]
        ])
    }

    @Test func shortestPath() {
        let graph = Graph(edges: [
            "Root": ["A": 2 as UInt, "B": 2, "C": 2],
            "B": ["X": 2, "Y": 2, "Z": 20, "A": 2],
            "Y": ["N": 2, "M": 2, "Z": 2]
        ])

        #expect(graph.shortestPath(from: "Root", to: "Z", using: .dijkstra())?.path == ["Root", "B", "Y", "Z"])
        #expect(graph.shortestPath(from: "Root", to: "Z", using: .dijkstra())?.cost == 6)
    }

    @Test func shortestPathGrid() {
        let graph = GridGraph(grid: [
            ["A", "B", "C", "D", "E"],
            ["F", "G", "H", "I", "J"],
            ["K", "L", "M", "N", "O"],
            ["P", "Q", "R", "S", "T"],
            ["U", "V", "W", "X", "Y"]
        ], availableDirections: .orthogonal).weightedByDistance()

        #expect(
            graph.shortestPath(
                from: GridPosition(x: 0, y: 0),
                to: GridPosition(x: 4, y: 4),
                using: .dijkstra()
            )?.path.map { graph[$0] } == ["A", "B", "G", "L", "Q", "V", "W", "X", "Y"]
        )

        #expect(
            graph.shortestPath(
                from: GridPosition(x: 0, y: 0),
                to: GridPosition(x: 4, y: 4),
                using: .aStar(heuristic: .euclideanDistance(of: \.coordinates))
            )?.path.map { graph[$0] } == ["A", "B", "G", "L", "Q", "V", "W", "X", "Y"]
        )

        #expect(
            graph.shortestPath(
                from: GridPosition(x: 0, y: 0),
                to: GridPosition(x: 4, y: 4),
                using: .aStar(heuristic: .manhattanDistance(of: \.coordinates))
            )?.path.map { graph[$0] } == ["A", "B", "G", "L", "Q", "V", "W", "X", "Y"]
        )
    }

    @Test func shortestPaths() {
        let graph = GridGraph(grid: [[1, 2, 3], [4, 5, 6], [7, 8, 9]]).weightedByDistance()
        #expect(
            Set(graph.shortestPaths(from: GridPosition(x: 0, y: 0)).map { $0.value.path.map { graph[$0] } }) == [
                [1],
                [1, 2],
                [1, 2, 3],
                [1, 4],
                [1, 5],
                [1, 2, 6],
                [1, 5, 7],
                [1, 5, 8],
                [1, 5, 9]
            ]
        )
    }

    @Test func minimumSpanningTree() {
        let graph = Graph(edges: [
            "A": ["B": 1, "C": 3],
            "B": ["A": 1, "C": 1, "D": 4],
            "C": ["A": 3, "B": 1, "D": 1],
            "D": ["B": 4, "C": 1]
        ])

        #expect(graph.minimumSpanningTree(using: .kruskal()).sortedDescription() == ["A-B", "B-C", "C-D"])
        #expect(graph.minimumSpanningTree(using: .prim()).sortedDescription() == ["A-B", "B-C", "C-D"])
    }

    @Test func maxFlowMinCut() {
        let graph = Graph(edges: [
            "S": ["A": 10, "B": 5],
            "A": ["B": 15, "C": 10],
            "B": ["D": 10],
            "C": ["T": 10],
            "D": ["C": 10, "T": 10]
        ])

//        #expect(graph.maximumFlow(from: "S", to: "T", using: .fordFulkerson()) == 15)
//        #expect(graph.minimumCut(from: "S", to: "T", using: .fordFulkerson()).cutValue == 15)
//        #expect(graph.minimumCut(from: "S", to: "T", using: .fordFulkerson()).cutEdges.sortedDescription() == ["A-S", "B-S"])

        #expect(graph.maximumFlow(from: "S", to: "T", using: .edmondsKarp()) == 15)
        #expect(graph.minimumCut(from: "S", to: "T", using: .edmondsKarp()).cutValue == 15)
        #expect(graph.minimumCut(from: "S", to: "T", using: .edmondsKarp()).cutEdges.sortedDescription() == ["A-S", "B-S"])
    }

    @Test func hamiltonianPath() {
        let small = GridGraph(grid: [
            ["A", "B"],
            ["C", "D"]
        ], availableDirections: .orthogonal)
        #expect(small.hamiltonianPath(from: GridPosition(x: 0, y: 0))?.path.map { small[$0] } == ["A", "B", "D", "C"])
        #expect(small.hamiltonianCycle(from: GridPosition(x: 0, y: 0))?.path.map { small[$0] } == ["A", "B", "D", "C", "A"])

        #expect(small.hamiltonianPath(from: GridPosition(x: 0, y: 0), using: .heuristic(.degree()))?.path.map { small[$0] } == ["A", "B", "D", "C"])
        #expect(small.hamiltonianCycle(from: GridPosition(x: 0, y: 0), using: .heuristic(.degree()))?.path.map { small[$0] } == ["A", "B", "D", "C", "A"])

        let large = GridGraph(grid: [
            ["A", "B", "C", "D"],
            ["E", "F", "G", "H"],
            ["I", "J", "K", "L"],
            ["M", "N", "O", "P"]
        ], availableDirections: .orthogonal)

        #expect(large.hamiltonianPath()?.path.map { large[$0] } == ["A", "B", "C", "D", "H", "L", "P", "O", "N", "M", "I", "J", "K", "G", "F", "E"])
        #expect(large.hamiltonianPath(from: GridPosition(x: 0, y: 0))?.path.map { large[$0] } == ["A", "B", "C", "D", "H", "L", "P", "O", "N", "M", "I", "J", "K", "G", "F", "E"])
        #expect(large.hamiltonianPath(from: GridPosition(x: 0, y: 0), to: GridPosition(x: 3, y: 0))?.path.map { large[$0] } == ["A", "B", "C", "D", "H", "L", "P", "O", "N", "M", "I", "J", "K", "G", "F", "E"])

        #expect(large.hamiltonianCycle()?.path.map { large[$0] } == ["A", "B", "C", "D", "H", "L", "P", "O", "N", "M", "I", "J", "K", "G", "F", "E", "A"])
        #expect(large.hamiltonianCycle(from: GridPosition(x: 1, y: 1))?.path.map { large[$0] } == ["F", "G", "H", "D", "C", "B", "A", "E", "I", "M", "N", "O", "P", "L", "K", "J", "F"])

        #expect(large.hamiltonianPath(using: .heuristic(.degree()))?.path.map { large[$0] } == ["A", "B", "F", "E", "I", "M", "N", "J", "K", "O", "P", "L", "H", "G", "C", "D"])
        #expect(large.hamiltonianPath(from: GridPosition(x: 0, y: 0), using: .heuristic(.degree()))?.path.map { large[$0] } == ["A", "B", "F", "E", "I", "M", "N", "J", "K", "O", "P", "L", "H", "G", "C", "D"])
        #expect(large.hamiltonianPath(from: GridPosition(x: 0, y: 0), to: GridPosition(x: 3, y: 0), using: .heuristic(.degree()))?.path.map { large[$0] } == ["A", "B", "F", "E", "I", "M", "N", "J", "K", "O", "P", "L", "H", "G", "C", "D"])

        #expect(large.hamiltonianCycle(using: .heuristic(.degree()))?.path.map { large[$0] } == ["A", "B", "F", "G", "C", "D", "H", "L", "P", "O", "K", "J", "N", "M", "I", "E", "A"])
        #expect(large.hamiltonianCycle(from: GridPosition(x: 1, y: 1), using: .heuristic(.degree()))?.path.map { large[$0] } == ["F", "J", "I", "M", "N", "O", "P", "L", "K", "G", "H", "D", "C", "B", "A", "E", "F"])
    }

    @Test func eulerianPath() {
        let triangle = Graph(edges: [
            "A": ["B", "C"],
            "B": ["A", "C"],
            "C": ["A", "B"]
        ]).weighted(constant: 1)

        #expect(triangle.eulerianCycle(from: "A")?.path == ["A", "B", "A", "C", "B", "C", "A"])
        #expect(triangle.eulerianCycle(from: "A", using: .hierholzer())?.path == ["A", "C", "B", "C", "A", "B", "A"])

        let graph = Graph(edges: [
            "S": ["A"],
            "A": ["B"],
            "B": ["C"],
            "C": ["D"]
        ]).weighted(constant: 1)

        #expect(graph.eulerianPath()?.path == ["S", "A", "B", "C", "D"])
        #expect(graph.eulerianPath(from: "S")?.path == ["S", "A", "B", "C", "D"])
        #expect(graph.eulerianPath(from: "S", to: "D")?.path == ["S", "A", "B", "C", "D"])
    }

    @Test func coloring() {
        let graph = Graph(edges: [
            "Root": ["A", "B", "C"],
            "B": ["X", "Y", "Z"]
        ])
        let coloring = [
            "Root": 1,
            "A": 0,
            "B": 0,
            "C": 0,
            "Z": 1,
            "X": 1,
            "Y": 1
        ]
        #expect(graph.colorNodes(using: .greedy()) == coloring)
        #expect(graph.colorNodes(using: .welshPowell()) == coloring)
        #expect(graph.colorNodes(using: .dsatur()) == coloring)
    }

    @Test func bipartite() {
        let graph = Graph(edges: [
            GraphEdge(source: "u1", destination: "v1"),
            GraphEdge(source: "u1", destination: "v2"),
            GraphEdge(source: "u2", destination: "v1"),
            GraphEdge(source: "u3", destination: "v2"),
            GraphEdge(source: "u3", destination: "v3"),
        ]).bipartite(leftPartition: ["u1", "u2", "u3"], rightPartition: ["v1", "v2", "v3"])

        #expect(graph.maximumMatching(using: .hopcroftKarp()) == ["u1": "v2", "u2": "v1", "u3": "v3"])
    }
}

extension Sequence {
    func sortedDescription<Node: CustomStringConvertible, Edge>() -> [String] where Element == GraphEdge<Node, Edge> {
        map { [$0.source.description, $0.destination.description].sorted().joined(separator: "-") }.sorted()
    }
}
