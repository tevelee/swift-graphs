import Benchmark
import Graphs

func registerConnectivityBenchmarks() {
    // MARK: Connected components (DFS-based)

    Benchmark("Connectivity/ConnectedComponents/undirected-10k-d8") { benchmark in
        let (graph, _) = makeUndirectedSparseGraph(n: 10_000, avgDegree: 8)
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            let result = graph.connectedComponents(using: .dfs())
            blackHole(result)
        }
    }

    // MARK: Strongly connected components

    Benchmark("Connectivity/SCC/Kosaraju/sparse-10k-d8") { benchmark in
        let (graph, _) = makeSparseGraph(n: 10_000, avgDegree: 8)
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            let result = graph.stronglyConnectedComponents(using: .kosaraju())
            blackHole(result)
        }
    }

    Benchmark("Connectivity/SCC/Tarjan/sparse-10k-d8") { benchmark in
        let (graph, _) = makeSparseGraph(n: 10_000, avgDegree: 8)
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            let result = graph.stronglyConnectedComponents(using: .tarjan())
            blackHole(result)
        }
    }

    // MARK: Articulation points

    Benchmark("Connectivity/ArticulationPoints/undirected-5k-d8") { benchmark in
        let (graph, _) = makeUndirectedSparseGraph(n: 5_000, avgDegree: 8)
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            let result = graph.articulationPoints(using: .tarjan())
            blackHole(result)
        }
    }
}
