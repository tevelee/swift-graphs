extension IncidenceGraph where Self: VertexListGraph, VertexDescriptor: Hashable {
    func stronglyConnectedComponents(
        using algorithm: some StronglyConnectedComponentsAlgorithm<Self>
    ) -> StronglyConnectedComponentsResult<VertexDescriptor> {
        algorithm.stronglyConnectedComponents(in: self, visitor: nil)
    }
}

extension BidirectionalGraph where Self: VertexListGraph, VertexDescriptor: Hashable {
    func stronglyConnectedComponents(
        using algorithm: some StronglyConnectedComponentsAlgorithm<Self>
    ) -> StronglyConnectedComponentsResult<VertexDescriptor> {
        algorithm.stronglyConnectedComponents(in: self, visitor: nil)
    }
}

protocol StronglyConnectedComponentsAlgorithm<Graph> {
    associatedtype Graph: IncidenceGraph where Graph.VertexDescriptor: Hashable
    associatedtype Visitor

    func stronglyConnectedComponents(
        in graph: Graph,
        visitor: Visitor?
    ) -> StronglyConnectedComponentsResult<Graph.VertexDescriptor>
}

extension VisitorWrapper: StronglyConnectedComponentsAlgorithm where Base: StronglyConnectedComponentsAlgorithm, Base.Visitor == Visitor, Visitor: Composable, Visitor.Other == Visitor {
    typealias Graph = Base.Graph
    
    func stronglyConnectedComponents(
        in graph: Base.Graph,
        visitor: Base.Visitor?
    ) -> StronglyConnectedComponentsResult<Base.Graph.VertexDescriptor> {
        base.stronglyConnectedComponents(in: graph, visitor: self.visitor.combined(with: visitor))
    }
}

// MARK: - Result Type

/// Represents the result of a strongly connected components algorithm.
public struct StronglyConnectedComponentsResult<Vertex: Hashable> {
    /// The strongly connected components, where each inner array represents one component.
    public let components: [[Vertex]]
    
    /// A mapping from each vertex to its component index.
    public let vertexToComponent: [Vertex: Int]
    
    /// The number of strongly connected components.
    public var componentCount: Int {
        components.count
    }
    
    /// Creates a new result with the given components.
    public init(components: [[Vertex]]) {
        self.components = components
        var mapping: [Vertex: Int] = [:]
        for (componentIndex, component) in components.enumerated() {
            for vertex in component {
                mapping[vertex] = componentIndex
            }
        }
        self.vertexToComponent = mapping
    }
    
    /// Returns the component index for the given vertex.
    public func componentIndex(for vertex: Vertex) -> Int? {
        vertexToComponent[vertex]
    }
    
    /// Returns the component containing the given vertex.
    public func component(containing vertex: Vertex) -> [Vertex]? {
        guard let index = componentIndex(for: vertex) else { return nil }
        return components[index]
    }
    
    /// Returns whether two vertices are in the same strongly connected component.
    public func areInSameComponent(_ vertex1: Vertex, _ vertex2: Vertex) -> Bool {
        guard let index1 = componentIndex(for: vertex1),
              let index2 = componentIndex(for: vertex2) else { return false }
        return index1 == index2
    }
}

extension StronglyConnectedComponentsResult: Equatable where Vertex: Equatable {
    public static func == (lhs: StronglyConnectedComponentsResult<Vertex>, rhs: StronglyConnectedComponentsResult<Vertex>) -> Bool {
        lhs.vertexToComponent == rhs.vertexToComponent
    }
}

extension StronglyConnectedComponentsResult: Hashable where Vertex: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(vertexToComponent)
    }
}
