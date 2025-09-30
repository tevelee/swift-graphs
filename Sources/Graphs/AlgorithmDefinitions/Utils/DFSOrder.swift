/// A configuration for depth-first search traversal order.
///
/// DFSOrder allows customizing the order in which vertices are visited during
/// depth-first search traversal. This is useful for implementing different
/// traversal strategies like preorder, postorder, and inorder.
public struct DFSOrder<Graph: IncidenceGraph> where Graph.VertexDescriptor: Hashable {
    @usableFromInline
    let makeVisitor: (Graph, SharedBuffer<Graph.VertexDescriptor>) -> DepthFirstSearch<Graph>.Visitor
    
    @inlinable
    public init(makeVisitor: @escaping (Graph, SharedBuffer<Graph.VertexDescriptor>) -> DepthFirstSearch<Graph>.Visitor) {
        self.makeVisitor = makeVisitor
    }
}

public final class SharedBuffer<Element> {
    public var elements: [Element] = []
    
    @inlinable
    public init() {}
    
    public func append(_ element: Element) {
        elements.append(element)
    }
}

extension DFSOrder {
    @inlinable
    public static var preorder: DFSOrder {
        DFSOrder { graph, buffer in
            .init(
                discoverVertex: { vertex in
                    buffer.append(vertex)
                }
            )
        }
    }
    
    @inlinable
    public static var postorder: DFSOrder {
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
    @inlinable
    public static var inorder: DFSOrder {
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
