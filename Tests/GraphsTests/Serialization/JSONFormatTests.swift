#if !GRAPHS_USES_TRAITS || GRAPHS_SERIALIZATION
@testable import Graphs
import Testing
import Foundation

struct JSONFormatTests {
    @Test func emptyGraph() throws {
        let graph = AdjacencyList()
        let formatter = GraphFormatter()
        
        let result = try formatter.string(
            from: graph,
            using: .json(prettyPrint: true, includeMetadata: true)
        )
        
        let expected = """
        {
          "edgeCount" : 0,
          "edges" : [
        
          ],
          "vertexCount" : 0,
          "vertices" : [
        
          ]
        }
        """
        
        #expect(result == expected)
    }
    
    @Test func simpleGraphWithoutProperties() throws {
        var graph = AdjacencyList()
        let v1 = graph.addVertex()
        let v2 = graph.addVertex()
        graph.addEdge(from: v1, to: v2)
        
        let formatter = GraphFormatter()
        let result = try formatter.string(
            from: graph,
            using: .json(prettyPrint: true, includeMetadata: true)
        )
        
        let expected = """
        {
          "edgeCount" : 1,
          "edges" : [
            {
              "source" : "v0",
              "target" : "v1"
            }
          ],
          "vertexCount" : 2,
          "vertices" : [
            {
              "id" : "v0"
            },
            {
              "id" : "v1"
            }
          ]
        }
        """
        
        #expect(result == expected)
    }
    
    @Test func graphWithVertexProperties() throws {
        var graph = AdjacencyList()
        let v1 = graph.addVertex { $0.label = "A" }
        let v2 = graph.addVertex { $0.label = "B" }
        graph.addEdge(from: v1, to: v2)
        
        let formatter = GraphFormatter()
        let result = try formatter.string(
            from: graph,
            using: .json(prettyPrint: true, includeMetadata: true),
            vertexProperties: [Label.self]
        )
        
        let expected = """
        {
          "edgeCount" : 1,
          "edges" : [
            {
              "source" : "v0",
              "target" : "v1"
            }
          ],
          "vertexCount" : 2,
          "vertices" : [
            {
              "id" : "v0",
              "properties" : {
                "Label" : "A"
              }
            },
            {
              "id" : "v1",
              "properties" : {
                "Label" : "B"
              }
            }
          ]
        }
        """
        
        #expect(result == expected)
    }
    
    @Test func graphWithEdgeProperties() throws {
        var graph = AdjacencyList()
        let v1 = graph.addVertex()
        let v2 = graph.addVertex()
        graph.addEdge(from: v1, to: v2) { $0.weight = 5.0 }
        
        let formatter = GraphFormatter()
        let result = try formatter.string(
            from: graph,
            using: .json(prettyPrint: true, includeMetadata: true),
            edgeProperties: [Weight.self]
        )
        
        let expected = """
        {
          "edgeCount" : 1,
          "edges" : [
            {
              "properties" : {
                "Weight" : 5
              },
              "source" : "v0",
              "target" : "v1"
            }
          ],
          "vertexCount" : 2,
          "vertices" : [
            {
              "id" : "v0"
            },
            {
              "id" : "v1"
            }
          ]
        }
        """
        
        #expect(result == expected)
    }
    
    @Test func graphWithBothProperties() throws {
        var graph = AdjacencyList()
        let v1 = graph.addVertex { $0.label = "Start" }
        let v2 = graph.addVertex { $0.label = "End" }
        graph.addEdge(from: v1, to: v2) { 
            $0.label = "connects"
            $0.weight = 2.5
        }
        
        let formatter = GraphFormatter()
        let result = try formatter.string(
            from: graph,
            using: .json(prettyPrint: true, includeMetadata: true),
            vertexProperties: [Label.self],
            edgeProperties: [Label.self, Weight.self]
        )
        
        // Parse JSON to verify structure (properties may be in any order)
        let data = result.data(using: .utf8)!
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        
        #expect(json["vertexCount"] as? Int == 2)
        #expect(json["edgeCount"] as? Int == 1)
        
        let vertices = json["vertices"] as! [[String: Any]]
        #expect(vertices.count == 2)
        
        let edges = json["edges"] as! [[String: Any]]
        #expect(edges.count == 1)
        #expect(edges[0]["source"] as? String == "v0")
        #expect(edges[0]["target"] as? String == "v1")
        
        let edgeProps = edges[0]["properties"] as! [String: Any]
        #expect(edgeProps["Label"] as? String == "connects")
        #expect(edgeProps["Weight"] as? Double == 2.5)
    }
    
    @Test func graphWithSelectiveVertexProperties() throws {
        var graph = AdjacencyList()
        let v1 = graph.addVertex { 
            $0.label = "A"
            $0.weight = 10.0
        }
        let v2 = graph.addVertex { 
            $0.label = "B"
            $0.weight = 20.0
        }
        graph.addEdge(from: v1, to: v2)
        
        let formatter = GraphFormatter()
        // Only serialize label, not weight
        let result = try formatter.string(
            from: graph,
            using: .json(prettyPrint: true, includeMetadata: false),
            vertexProperties: [Label.self]
        )
        
        let expected = """
        {
          "edges" : [
            {
              "source" : "v0",
              "target" : "v1"
            }
          ],
          "vertices" : [
            {
              "id" : "v0",
              "properties" : {
                "Label" : "A"
              }
            },
            {
              "id" : "v1",
              "properties" : {
                "Label" : "B"
              }
            }
          ]
        }
        """
        
        #expect(result == expected)
    }
    
    @Test func graphWithSelectiveEdgeProperties() throws {
        var graph = AdjacencyList()
        let v1 = graph.addVertex()
        let v2 = graph.addVertex()
        graph.addEdge(from: v1, to: v2) { 
            $0.label = "edge1"
            $0.weight = 3.0
        }
        
        let formatter = GraphFormatter()
        // Only serialize weight, not label
        let result = try formatter.string(
            from: graph,
            using: .json(prettyPrint: true, includeMetadata: false),
            edgeProperties: [Weight.self]
        )
        
        let expected = """
        {
          "edges" : [
            {
              "properties" : {
                "Weight" : 3
              },
              "source" : "v0",
              "target" : "v1"
            }
          ],
          "vertices" : [
            {
              "id" : "v0"
            },
            {
              "id" : "v1"
            }
          ]
        }
        """
        
        #expect(result == expected)
    }
    
    @Test func graphWithoutMetadata() throws {
        var graph = AdjacencyList()
        let v1 = graph.addVertex { $0.label = "A" }
        let v2 = graph.addVertex { $0.label = "B" }
        graph.addEdge(from: v1, to: v2)
        
        let formatter = GraphFormatter()
        let result = try formatter.string(
            from: graph,
            using: .json(prettyPrint: true, includeMetadata: false),
            vertexProperties: [Label.self]
        )
        
        let expected = """
        {
          "edges" : [
            {
              "source" : "v0",
              "target" : "v1"
            }
          ],
          "vertices" : [
            {
              "id" : "v0",
              "properties" : {
                "Label" : "A"
              }
            },
            {
              "id" : "v1",
              "properties" : {
                "Label" : "B"
              }
            }
          ]
        }
        """
        
        #expect(result == expected)
    }
    
    @Test func compactJSON() throws {
        var graph = AdjacencyList()
        let v1 = graph.addVertex { $0.label = "A" }
        let v2 = graph.addVertex { $0.label = "B" }
        graph.addEdge(from: v1, to: v2)
        
        let formatter = GraphFormatter()
        let result = try formatter.string(
            from: graph,
            using: .json(prettyPrint: false, includeMetadata: false),
            vertexProperties: [Label.self]
        )
        
        let expected = "{\"edges\":[{\"source\":\"v0\",\"target\":\"v1\"}],\"vertices\":[{\"id\":\"v0\",\"properties\":{\"Label\":\"A\"}},{\"id\":\"v1\",\"properties\":{\"Label\":\"B\"}}]}"
        
        #expect(result == expected)
    }
    
    @Test func disconnectedGraph() throws {
        var graph = AdjacencyList()
        let v1 = graph.addVertex()
        let v2 = graph.addVertex()
        let _ = graph.addVertex()  // v3 is disconnected
        graph.addEdge(from: v1, to: v2)
        
        let formatter = GraphFormatter()
        let result = try formatter.string(
            from: graph,
            using: .json(prettyPrint: true, includeMetadata: true)
        )
        
        let data = result.data(using: .utf8)!
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        
        let vertices = json["vertices"] as! [[String: Any]]
        #expect(vertices.count == 3)
        
        let edges = json["edges"] as! [[String: Any]]
        #expect(edges.count == 1)
    }
}
#endif
