import Testing
@testable import Graphs

struct LazyGraphMaterializeTests {
    
    @Test func materializeBasicGraph() {
        // Create a simple lazy graph: A -> B -> C, A -> C
        let lazyGraph = LazyIncidenceGraph { (vertex: String) in
            switch vertex {
            case "A":
                return ["B", "C"]
            case "B":
                return ["C"]
            case "C":
                return []
            default:
                return []
            }
        }
        
        // Materialize the graph - returns AdjacencyList
        let materializedGraph = lazyGraph.materialize(from: "A")
        
        // Verify that we got an AdjacencyList with the correct structure
        #expect(materializedGraph.vertexCount == 3)
        #expect(materializedGraph.edgeCount == 3)
    }
    
    @Test func materializeDisconnectedGraph() {
        // Create a disconnected graph: A -> B, C -> D
        let lazyGraph = LazyIncidenceGraph { (vertex: String) in
            switch vertex {
            case "A":
                return ["B"]
            case "B":
                return []
            case "C":
                return ["D"]
            case "D":
                return []
            default:
                return []
            }
        }
        
        // Materialize starting from "A" - should only discover A and B
        let materializedGraph = lazyGraph.materialize(from: "A")
        
        // Verify that only reachable vertices from "A" were discovered
        #expect(materializedGraph.vertexCount == 2)
        #expect(materializedGraph.edgeCount == 1)
    }
    
    @Test func materializeWithFloydWarshall() {
        // Create a simple graph structure first
        let lazyGraph = LazyIncidenceGraph { (vertex: String) in
            switch vertex {
            case "A":
                return ["B", "C"]
            case "B":
                return ["C"]
            case "C":
                return []
            default:
                return []
            }
        }
        
        // Materialize the graph - now returns AdjacencyList
        let materializedGraph = lazyGraph.materialize(from: "A")
        
        // Verify that the materialized graph is an AdjacencyList with correct structure
        #expect(materializedGraph.vertexCount == 3)
        #expect(materializedGraph.edgeCount == 3)
        
        // Test that we can iterate over vertices (required for Floyd-Warshall)
        let vertexList = Array(materializedGraph.vertices())
        #expect(vertexList.count == 3)
        
        // Test that we can iterate over edges (required for Floyd-Warshall)
        let edgeList = Array(materializedGraph.edges())
        #expect(edgeList.count == 3)
        
    }
}
