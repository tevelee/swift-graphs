#if !GRAPHS_USES_TRAITS || GRAPHS_SERIALIZATION
@testable import Graphs
import Testing

struct FormatFactoriesTests {
    @Test func simplifiedDOTSyntax() throws {
        var graph = AdjacencyList()
        let v1 = graph.addVertex { $0.label = "A" }
        let v2 = graph.addVertex { $0.label = "B" }
        graph.addEdge(from: v1, to: v2)
        
        let formatter = GraphFormatter()
        
        // Simplified syntax using factory methods
        let result = try formatter.string(
            from: graph,
            using: .dot(directed: true, graphName: "Simple"),
            vertexProperties: [Label.self]
        )
        
        let expected = """
        digraph Simple {
          v0 [Label="A"];
          v1 [Label="B"];
          v0 -> v1;
        }
        """
        
        #expect(result == expected)
    }
    
    @Test func simplifiedJSONSyntax() throws {
        var graph = AdjacencyList()
        let v1 = graph.addVertex { $0.label = "A" }
        let v2 = graph.addVertex { $0.label = "B" }
        graph.addEdge(from: v1, to: v2)
        
        let formatter = GraphFormatter()
        
        // Simplified syntax using factory methods
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
    
    @Test func simplifiedGraphMLSyntax() throws {
        var graph = AdjacencyList()
        let v1 = graph.addVertex { $0.label = "A" }
        let v2 = graph.addVertex { $0.label = "B" }
        graph.addEdge(from: v1, to: v2)
        
        let formatter = GraphFormatter()
        
        // Simplified syntax using factory methods
        let result = try formatter.string(
            from: graph,
            using: .graphML(directed: false, includeSchema: false),
            vertexProperties: [Label.self]
        )
        
        let expected = """
        <?xml version="1.0" encoding="UTF-8"?>
        <graphml>
          <graph edgedefault="undirected">
            <key id="d0" for="node" attr.name="Label" attr.type="string"/>
            <node id="v0">
              <data key="d0">A</data>
            </node>
            <node id="v1">
              <data key="d0">B</data>
            </node>
            <edge source="v0" target="v1">
            </edge>
          </graph>
        </graphml>
        """
        
        #expect(result == expected)
    }
    
    @Test func defaultOptionsWork() throws {
        var graph = AdjacencyList()
        let v1 = graph.addVertex()
        let v2 = graph.addVertex()
        graph.addEdge(from: v1, to: v2)
        
        let formatter = GraphFormatter()
        
        // Using defaults (no parameters)
        let dotResult = try formatter.string(from: graph, using: .dot())
        let dotExpected = """
        digraph G {
          v0;
          v1;
          v0 -> v1;
        }
        """
        #expect(dotResult == dotExpected)
        
        let jsonResult = try formatter.string(from: graph, using: .json())
        let jsonExpected = """
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
        #expect(jsonResult == jsonExpected)
        
        let graphMLResult = try formatter.string(from: graph, using: .graphML())
        let graphMLExpected = """
        <?xml version="1.0" encoding="UTF-8"?>
        <graphml xmlns="http://graphml.graphdrawing.org/xmlns" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://graphml.graphdrawing.org/xmlns http://graphml.graphdrawing.org/xmlns/1.0/graphml.xsd">
          <graph edgedefault="directed">
            <node id="v0"/>
            <node id="v1"/>
            <edge source="v0" target="v1"/>
          </graph>
        </graphml>
        """
        #expect(graphMLResult == graphMLExpected)
    }
}
#endif
