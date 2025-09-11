struct DFSOrder<Graph: IncidenceGraph> where Graph.VertexDescriptor: Hashable {
    let makeVisitor: (Graph, SharedBuffer<Graph.VertexDescriptor>) -> DepthFirstSearch<Graph>.Visitor
}

extension DFSOrder {
    static var preorder: DFSOrder {
        DFSOrder { graph, buffer in
            .init(
                discoverVertex: { vertex in
                    buffer.append(vertex)
                }
            )
        }
    }
    
    static var postorder: DFSOrder {
        DFSOrder { graph, buffer in
            .init(
                finishVertex: { vertex in
                    buffer.append(vertex)
                }
            )
        }
    }
}

extension DFSOrder where Graph: BinaryIncidenceGraph {
    static var inorder: DFSOrder {
        DFSOrder { graph, buffer in
            var emitted = Set<Graph.VertexDescriptor>()
            var parent: [Graph.VertexDescriptor: Graph.VertexDescriptor] = [:]
            
            func emit(_ v: Graph.VertexDescriptor) {
                if emitted.insert(v).inserted {
                    buffer.append(v)
                }
            }
            
            return .init(
                discoverVertex: { v in
                    if graph.leftNeighbor(of: v) == nil {
                        emit(v)
                    }
                },
                treeEdge: { e in
                    if let p = graph.source(of: e), let c = graph.destination(of: e) {
                        parent[c] = p
                    }
                },
                finishVertex: { u in
                    if let p = parent[u],
                       let leftChild = graph.leftNeighbor(of: p),
                       leftChild == u {
                        emit(p)
                    }
                }
            )
        }
    }
}
