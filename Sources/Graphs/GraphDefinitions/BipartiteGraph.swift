import Algorithms

/// A protocol for bipartite graphs that can be partitioned into two disjoint sets.
///
/// A bipartite graph is a graph whose vertices can be divided into two disjoint sets
/// such that every edge connects a vertex in one set to a vertex in the other set.
/// This property enables efficient matching algorithms and other specialized operations.
public protocol BipartiteGraph: Graph where VertexDescriptor: Hashable {
    /// The type of sequence returned when querying vertices in a partition.
    associatedtype PartitionVertices: Sequence<VertexDescriptor>
    
    /// Returns all vertices in the left partition.
    ///
    /// - Returns: A sequence of vertex descriptors in the left partition
    func leftPartition() -> PartitionVertices
    
    /// Returns all vertices in the right partition.
    ///
    /// - Returns: A sequence of vertex descriptors in the right partition
    func rightPartition() -> PartitionVertices
    
    /// Determines which partition a vertex belongs to.
    ///
    /// - Parameter vertex: The vertex to query
    /// - Returns: The partition the vertex belongs to, or `nil` if not found
    func partition(of vertex: VertexDescriptor) -> BipartitePartition?
    
}

/// Represents the two partitions of a bipartite graph.
public enum BipartitePartition: CaseIterable {
    /// The left partition of the bipartite graph.
    case left
    
    /// The right partition of the bipartite graph.
    case right
    
    /// Returns the opposite partition.
    ///
    /// - Returns: The opposite partition (left becomes right, right becomes left)
    @inlinable
    public var opposite: BipartitePartition {
        switch self {
        case .left: return .right
        case .right: return .left
        }
    }
}

extension BipartiteGraph {
    /// Returns all vertices in both partitions.
    ///
    /// - Returns: A sequence containing all vertices from both partitions
    @inlinable
    public func allVertices() -> some Sequence<VertexDescriptor> {
        chain(leftPartition(), rightPartition())
    }
}

/// A protocol for mutable bipartite graphs that support adding vertices to specific partitions.
public protocol MutableBipartiteGraph: BipartiteGraph, MutableGraph {
    /// Adds a new vertex to the specified partition.
    ///
    /// - Parameter partition: The partition to add the vertex to
    /// - Returns: The descriptor of the newly added vertex
    mutating func addVertex(to partition: BipartitePartition) -> VertexDescriptor
    
    /// Moves a vertex from one partition to another.
    ///
    /// - Parameters:
    ///   - vertex: The vertex to move
    ///   - newPartition: The partition to move the vertex to
    mutating func move(vertex: VertexDescriptor, to newPartition: BipartitePartition)
}

// MARK: - Bipartiteness Checking for IncidenceGraph

extension IncidenceGraph where Self: VertexListGraph, VertexDescriptor: Hashable {
    /// Determines if the graph is bipartite using a simple BFS approach.
    ///
    /// - Returns: `true` if the graph is bipartite, `false` otherwise
    @inlinable
    public func isBipartiteSimple() -> Bool {
        bipartition() != nil
    }
    
    /// Attempts to partition the graph into two sets if it's bipartite.
    ///
    /// - Returns: A bipartition if the graph is bipartite, `nil` otherwise
    @inlinable
    public func bipartition() -> (left: [VertexDescriptor], right: [VertexDescriptor])? {
        var color: [VertexDescriptor: BipartitePartition] = [:]
        var leftVertices: [VertexDescriptor] = []
        var rightVertices: [VertexDescriptor] = []
        
        // Try to color each connected component
        for vertex in vertices() {
            if color[vertex] == nil {
                // Start BFS from this vertex
                var queue: [VertexDescriptor] = [vertex]
                color[vertex] = .left
                leftVertices.append(vertex)
                
                while !queue.isEmpty {
                    let current = queue.removeFirst()
                    let currentColor = color[current]!
                    let nextColor = currentColor.opposite
                    
                    for edge in outgoingEdges(of: current) {
                        guard let neighbor = destination(of: edge) else { continue }
                        
                        if let existingColor = color[neighbor] {
                            // If neighbor is already colored with the same color, graph is not bipartite
                            if existingColor == currentColor {
                                return nil
                            }
                        } else {
                            // Color the neighbor with the opposite color
                            color[neighbor] = nextColor
                            queue.append(neighbor)
                            
                            if nextColor == .left {
                                leftVertices.append(neighbor)
                            } else {
                                rightVertices.append(neighbor)
                            }
                        }
                    }
                }
            }
        }
        
        return (left: leftVertices, right: rightVertices)
    }
}
