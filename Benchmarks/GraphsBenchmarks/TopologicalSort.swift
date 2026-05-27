import Benchmark
import Graphs

func registerTopologicalSortBenchmarks() {
    Benchmark("TopologicalSort/Kahn/DAG-10k-d8") { benchmark in
        let (graph, _) = makeDAG(n: 10_000, avgDegree: 8)
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            let result = graph.topologicalSort(using: .kahn())
            blackHole(result)
        }
    }

    Benchmark("TopologicalSort/DFS/DAG-10k-d8") { benchmark in
        let (graph, _) = makeDAG(n: 10_000, avgDegree: 8)
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            let result = graph.topologicalSort(using: .dfs())
            blackHole(result)
        }
    }
}
