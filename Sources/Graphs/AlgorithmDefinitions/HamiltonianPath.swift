extension IncidenceGraph where Self: VertexListGraph, VertexDescriptor: Hashable {
    /// Finds a Hamiltonian path using the specified algorithm.
    ///
    /// - Parameter algorithm: The Hamiltonian path algorithm to use
    /// - Returns: A Hamiltonian path if one exists, nil otherwise
    @inlinable
    public func hamiltonianPath(
        using algorithm: some HamiltonianPathAlgorithm<Self>
    ) -> Path<VertexDescriptor, EdgeDescriptor>? {
        algorithm.hamiltonianPath(in: self, observation: nil)
    }

    /// Finds a Hamiltonian cycle using the specified algorithm.
    ///
    /// - Parameter algorithm: The Hamiltonian cycle algorithm to use
    /// - Returns: A Hamiltonian cycle if one exists, nil otherwise
    @inlinable
    public func hamiltonianCycle(
        using algorithm: some HamiltonianCycleAlgorithm<Self>
    ) -> Path<VertexDescriptor, EdgeDescriptor>? {
        algorithm.hamiltonianCycle(in: self, observation: nil)
    }

    /// Finds a Hamiltonian path from a specific source using the specified algorithm.
    ///
    /// - Parameters:
    ///   - source: The starting vertex
    ///   - algorithm: The Hamiltonian path algorithm to use
    /// - Returns: A Hamiltonian path if one exists, nil otherwise
    @inlinable
    public func hamiltonianPath(
        from source: VertexDescriptor,
        using algorithm: some HamiltonianPathAlgorithm<Self>
    ) -> Path<VertexDescriptor, EdgeDescriptor>? {
        algorithm.hamiltonianPath(from: source, in: self, observation: nil)
    }

    /// Finds a Hamiltonian path between two specific vertices using the specified algorithm.
    ///
    /// - Parameters:
    ///   - source: The starting vertex
    ///   - destination: The ending vertex
    ///   - algorithm: The Hamiltonian path algorithm to use
    /// - Returns: A Hamiltonian path if one exists, nil otherwise
    @inlinable
    public func hamiltonianPath(
        from source: VertexDescriptor,
        to destination: VertexDescriptor,
        using algorithm: some HamiltonianPathAlgorithm<Self>
    ) -> Path<VertexDescriptor, EdgeDescriptor>? {
        algorithm.hamiltonianPath(from: source, to: destination, in: self, observation: nil)
    }
}

// MARK: - Default Implementations

#if !GRAPHS_USES_TRAITS || GRAPHS_ADVANCED
    extension IncidenceGraph where Self: VertexListGraph, VertexDescriptor: Hashable {
        /// Finds a Hamiltonian path using backtracking algorithm as the default.
        /// This is a general-purpose algorithm that works for most graphs.
        ///
        /// - Returns: A Hamiltonian path if one exists, nil otherwise
        @inlinable
        public func hamiltonianPath() -> Path<VertexDescriptor, EdgeDescriptor>? {
            hamiltonianPath(using: .backtracking())
        }

        /// Finds a Hamiltonian cycle using backtracking algorithm as the default.
        /// This is a general-purpose algorithm that works for most graphs.
        ///
        /// - Returns: A Hamiltonian cycle if one exists, nil otherwise
        @inlinable
        public func hamiltonianCycle() -> Path<VertexDescriptor, EdgeDescriptor>? {
            hamiltonianCycle(using: .backtracking())
        }

        /// Finds a Hamiltonian path from a specific source using backtracking algorithm as the default.
        ///
        /// - Parameter source: The starting vertex
        /// - Returns: A Hamiltonian path if one exists, nil otherwise
        @inlinable
        public func hamiltonianPath(from source: VertexDescriptor) -> Path<VertexDescriptor, EdgeDescriptor>? {
            hamiltonianPath(from: source, using: .backtracking())
        }

        /// Finds a Hamiltonian path between two specific vertices using backtracking algorithm as the default.
        func hamiltonianPath(from source: VertexDescriptor, to destination: VertexDescriptor) -> Path<VertexDescriptor, EdgeDescriptor>? {
            hamiltonianPath(from: source, to: destination, using: .backtracking())
        }
    }
#endif

/// A protocol for Hamiltonian path algorithms.
public protocol HamiltonianPathAlgorithm<Graph>: AlgorithmObserving {
    /// The graph type that this algorithm operates on.
    associatedtype Graph: IncidenceGraph & VertexListGraph where Graph.VertexDescriptor: Hashable
    /// The event type published by the algorithm.
    associatedtype Event

    /// Finds a Hamiltonian path in the graph.
    ///
    /// - Parameters:
    ///   - graph: The graph to search in
    ///   - observation: An optional algorithm observation.
    /// - Returns: A Hamiltonian path if one exists, nil otherwise
    @inlinable
    func hamiltonianPath(in graph: Graph, observation: AlgorithmObservation<Event>?) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>?

    /// Finds a Hamiltonian path starting from a specific vertex.
    ///
    /// - Parameters:
    ///   - source: The starting vertex
    ///   - graph: The graph to search in
    ///   - observation: An optional algorithm observation.
    /// - Returns: A Hamiltonian path if one exists, nil otherwise
    @inlinable
    func hamiltonianPath(
        from source: Graph.VertexDescriptor,
        in graph: Graph,
        observation: AlgorithmObservation<Event>?
    ) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>?

    /// Finds a Hamiltonian path between two specific vertices.
    ///
    /// - Parameters:
    ///   - source: The starting vertex
    ///   - destination: The ending vertex
    ///   - graph: The graph to search in
    ///   - observation: An optional algorithm observation.
    /// - Returns: A Hamiltonian path if one exists, nil otherwise
    @inlinable
    func hamiltonianPath(
        from source: Graph.VertexDescriptor,
        to destination: Graph.VertexDescriptor,
        in graph: Graph,
        observation: AlgorithmObservation<Event>?
    ) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>?
}

/// A protocol for Hamiltonian cycle algorithms.
public protocol HamiltonianCycleAlgorithm<Graph>: AlgorithmObserving {
    /// The graph type that this algorithm operates on.
    associatedtype Graph: IncidenceGraph & VertexListGraph where Graph.VertexDescriptor: Hashable
    /// The event type published by the algorithm.
    associatedtype Event

    /// Finds a Hamiltonian cycle in the graph.
    ///
    /// - Parameters:
    ///   - graph: The graph to search in
    ///   - observation: An optional algorithm observation.
    /// - Returns: A Hamiltonian cycle if one exists, nil otherwise
    @inlinable
    func hamiltonianCycle(in graph: Graph, observation: AlgorithmObservation<Event>?) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>?
}

extension ObservedAlgorithm: HamiltonianPathAlgorithm
where Base: HamiltonianPathAlgorithm {
    public typealias Graph = Base.Graph

    @inlinable
    public func hamiltonianPath(
        in graph: Base.Graph,
        observation: AlgorithmObservation<Base.Event>?
    ) -> Path<Base.Graph.VertexDescriptor, Base.Graph.EdgeDescriptor>? {
        base.hamiltonianPath(in: graph, observation: self.observation.followed(by: observation))
    }

    @inlinable
    public func hamiltonianPath(
        from source: Base.Graph.VertexDescriptor,
        in graph: Base.Graph,
        observation: AlgorithmObservation<Base.Event>?
    ) -> Path<Base.Graph.VertexDescriptor, Base.Graph.EdgeDescriptor>? {
        base.hamiltonianPath(from: source, in: graph, observation: self.observation.followed(by: observation))
    }

    @inlinable
    public func hamiltonianPath(
        from source: Base.Graph.VertexDescriptor,
        to destination: Base.Graph.VertexDescriptor,
        in graph: Base.Graph,
        observation: AlgorithmObservation<Base.Event>?
    ) -> Path<Base.Graph.VertexDescriptor, Base.Graph.EdgeDescriptor>? {
        base.hamiltonianPath(from: source, to: destination, in: graph, observation: self.observation.followed(by: observation))
    }
}

extension ObservedAlgorithm: HamiltonianCycleAlgorithm
where Base: HamiltonianCycleAlgorithm {
    public typealias Graph = Base.Graph

    @inlinable
    public func hamiltonianCycle(
        in graph: Base.Graph,
        observation: AlgorithmObservation<Base.Event>?
    ) -> Path<Base.Graph.VertexDescriptor, Base.Graph.EdgeDescriptor>? {
        base.hamiltonianCycle(in: graph, observation: self.observation.followed(by: observation))
    }
}

extension HamiltonianPathAlgorithm {
    /// Finds a Hamiltonian path without observing algorithm events.
    @inlinable
    public func hamiltonianPath(in graph: Graph) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
        hamiltonianPath(in: graph, observation: nil)
    }

    /// Finds a Hamiltonian path from a source without observing algorithm events.
    @inlinable
    public func hamiltonianPath(
        from source: Graph.VertexDescriptor,
        in graph: Graph
    ) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
        hamiltonianPath(from: source, in: graph, observation: nil)
    }

    /// Finds a Hamiltonian path between two vertices without observing algorithm events.
    @inlinable
    public func hamiltonianPath(
        from source: Graph.VertexDescriptor,
        to destination: Graph.VertexDescriptor,
        in graph: Graph
    ) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
        hamiltonianPath(from: source, to: destination, in: graph, observation: nil)
    }
}

extension HamiltonianCycleAlgorithm {
    /// Finds a Hamiltonian cycle without observing algorithm events.
    @inlinable
    public func hamiltonianCycle(in graph: Graph) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
        hamiltonianCycle(in: graph, observation: nil)
    }
}
