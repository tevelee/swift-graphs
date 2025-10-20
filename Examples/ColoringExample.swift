import Foundation
import Graphs

// Example demonstrating graph coloring algorithms
func coloringExample() {
    print("Graph Coloring Algorithms Example")
    print("=================================")
    
    // Create a sample graph
    var graph = AdjacencyList()
    
    // Add vertices
    let a = graph.addVertex { $0.label = "A" }
    let b = graph.addVertex { $0.label = "B" }
    let c = graph.addVertex { $0.label = "C" }
    let d = graph.addVertex { $0.label = "D" }
    let e = graph.addVertex { $0.label = "E" }
    
    // Add edges to create a pentagon
    graph.addEdge(from: a, to: b)
    graph.addEdge(from: b, to: a)
    graph.addEdge(from: b, to: c)
    graph.addEdge(from: c, to: b)
    graph.addEdge(from: c, to: d)
    graph.addEdge(from: d, to: c)
    graph.addEdge(from: d, to: e)
    graph.addEdge(from: e, to: d)
    graph.addEdge(from: e, to: a)
    graph.addEdge(from: a, to: e)
    
    print("Graph: A-B-C-D-E-A (pentagon)")
    print()
    
    // Test Greedy coloring
    print("Greedy Coloring:")
    let greedyColoring = graph.colorGraph(using: .greedy(on: graph))
    print("Chromatic number: \(greedyColoring.chromaticNumber)")
    print("Is proper: \(greedyColoring.isProper)")
    for vertex in [a, b, c, d, e] {
        let label = graph[vertex].label
        let color = greedyColoring.color(for: vertex)!
        print("  \(label): color \(color)")
    }
    print()
    
    // Test DSatur coloring
    print("DSatur Coloring:")
    let dsaturColoring = graph.colorGraph(using: .dsatur(on: graph))
    print("Chromatic number: \(dsaturColoring.chromaticNumber)")
    print("Is proper: \(dsaturColoring.isProper)")
    for vertex in [a, b, c, d, e] {
        let label = graph[vertex].label
        let color = dsaturColoring.color(for: vertex)!
        print("  \(label): color \(color)")
    }
    print()
    
    // Test Welsh-Powell coloring
    print("Welsh-Powell Coloring:")
    let welshPowellColoring = graph.colorGraph(using: .welshPowell(on: graph))
    print("Chromatic number: \(welshPowellColoring.chromaticNumber)")
    print("Is proper: \(welshPowellColoring.isProper)")
    for vertex in [a, b, c, d, e] {
        let label = graph[vertex].label
        let color = welshPowellColoring.color(for: vertex)!
        print("  \(label): color \(color)")
    }
    print()
    
    // Test with a complete graph K4
    print("Complete Graph K4:")
    var k4Graph = AdjacencyList()
    let v1 = k4Graph.addVertex { $0.label = "V1" }
    let v2 = k4Graph.addVertex { $0.label = "V2" }
    let v3 = k4Graph.addVertex { $0.label = "V3" }
    let v4 = k4Graph.addVertex { $0.label = "V4" }
    
    // Add all possible edges
    let vertices = [v1, v2, v3, v4]
    for i in 0..<vertices.count {
        for j in (i+1)..<vertices.count {
            k4Graph.addEdge(from: vertices[i], to: vertices[j])
            k4Graph.addEdge(from: vertices[j], to: vertices[i])
        }
    }
    
    let k4Coloring = k4Graph.colorGraph(using: .greedy(on: k4Graph))
    print("Chromatic number: \(k4Coloring.chromaticNumber)")
    print("Is proper: \(k4Coloring.isProper)")
    for vertex in vertices {
        let label = k4Graph[vertex].label
        let color = k4Coloring.color(for: vertex)!
        print("  \(label): color \(color)")
    }
}

// Run the example
coloringExample()