/// Selects one payload from an algorithm's event stream.
///
/// Algorithms expose named selectors so callers can observe one event without
/// switching over the complete event enum.
public struct AlgorithmEventCase<Event, Payload> {
    @usableFromInline
    let extract: (Event) -> Payload?

    /// Creates an event selector.
    ///
    /// - Parameter extract: A closure that returns the selected payload, or
    ///   `nil` when an event does not match.
    @inlinable
    public init(_ extract: @escaping (Event) -> Payload?) {
        self.extract = extract
    }
}

/// An event stream that can project an examined vertex.
public protocol VertexExaminedEvent {
    /// The examined vertex type.
    associatedtype ExaminedVertex

    /// Returns the examined vertex carried by an event, when present.
    static func examinedVertex(from event: Self) -> ExaminedVertex?
}

/// An event stream that can project a discovered vertex.
public protocol VertexDiscoveredEvent {
    /// The discovered vertex type.
    associatedtype DiscoveredVertex

    /// Returns the discovered vertex carried by an event, when present.
    static func discoveredVertex(from event: Self) -> DiscoveredVertex?
}

/// An event stream that can project an examined edge.
public protocol EdgeExaminedEvent {
    /// The examined edge type.
    associatedtype ExaminedEdge

    /// Returns the examined edge carried by an event, when present.
    static func examinedEdge(from event: Self) -> ExaminedEdge?
}

/// Describes a successful edge relaxation.
public struct EdgeRelaxation<Edge, Cost> {
    /// The edge that improved its destination's cost.
    public let edge: Edge

    /// The destination's new best-known cost.
    public let newCost: Cost

    /// Creates an edge-relaxation payload.
    ///
    /// - Parameters:
    ///   - edge: The edge that improved its destination's cost.
    ///   - newCost: The destination's new best-known cost.
    @inlinable
    public init(edge: Edge, newCost: Cost) {
        self.edge = edge
        self.newCost = newCost
    }
}

extension EdgeRelaxation: Equatable where Edge: Equatable, Cost: Equatable {}
extension EdgeRelaxation: Hashable where Edge: Hashable, Cost: Hashable {}
extension EdgeRelaxation: Sendable where Edge: Sendable, Cost: Sendable {}

/// An event stream that can project a successful edge relaxation.
public protocol EdgeRelaxedEvent {
    /// The successful relaxation payload type.
    associatedtype Relaxation

    /// Returns the successful relaxation carried by an event, when present.
    static func relaxation(from event: Self) -> Relaxation?
}

extension AlgorithmEventCase where Event: VertexExaminedEvent, Payload == Event.ExaminedVertex {
    /// Selects examined vertices from any compatible algorithm event stream.
    public static var vertexExamined: Self {
        .init(Event.examinedVertex)
    }
}

extension AlgorithmEventCase where Event: VertexDiscoveredEvent, Payload == Event.DiscoveredVertex {
    /// Selects discovered vertices from any compatible algorithm event stream.
    public static var vertexDiscovered: Self {
        .init(Event.discoveredVertex)
    }
}

extension AlgorithmEventCase where Event: EdgeExaminedEvent, Payload == Event.ExaminedEdge {
    /// Selects examined edges from any compatible algorithm event stream.
    public static var edgeExamined: Self {
        .init(Event.examinedEdge)
    }
}

extension AlgorithmEventCase where Event: EdgeRelaxedEvent, Payload == Event.Relaxation {
    /// Selects successful edge relaxations from any compatible algorithm event stream.
    public static var edgeRelaxed: Self {
        .init(Event.relaxation)
    }
}

/// A synchronous observation attached to a graph algorithm.
public struct AlgorithmObservation<Event> {
    @usableFromInline
    let receiveEvent: (Event) -> Void

    /// Creates an observation that receives every event.
    ///
    /// - Parameter receiveEvent: The event handler.
    @inlinable
    public init(_ receiveEvent: @escaping (Event) -> Void) {
        self.receiveEvent = receiveEvent
    }

    /// Delivers an event to the observation.
    ///
    /// Algorithm implementations call this synchronously at event boundaries.
    ///
    /// - Parameter event: The event to deliver.
    @inlinable
    public func receive(_ event: Event) {
        receiveEvent(event)
    }

    @inlinable
    func followed(by later: Self?) -> Self {
        guard let later else { return self }
        return .init { event in
            receiveEvent(event)
            later.receiveEvent(event)
        }
    }
}

/// A graph algorithm that publishes a typed event stream.
public protocol AlgorithmObserving {
    /// The event type published by the algorithm.
    associatedtype Event
}

extension AlgorithmObserving {
    /// Observes every event emitted by this algorithm.
    ///
    /// Repeated observations run synchronously in attachment order.
    ///
    /// - Parameter receiveEvent: The event handler.
    /// - Returns: The observed algorithm.
    @inlinable
    public func observing(
        _ receiveEvent: @escaping (Event) -> Void
    ) -> ObservedAlgorithm<Self> {
        .init(base: self, observation: .init(receiveEvent))
    }

    /// Observes one selected event emitted by this algorithm.
    ///
    /// Repeated observations run synchronously in attachment order.
    ///
    /// - Parameters:
    ///   - eventCase: The event to observe.
    ///   - receivePayload: The selected event's payload handler.
    /// - Returns: The observed algorithm.
    @inlinable
    public func observing<Payload>(
        _ eventCase: AlgorithmEventCase<Event, Payload>,
        _ receivePayload: @escaping (Payload) -> Void
    ) -> ObservedAlgorithm<Self> {
        observing { event in
            guard let payload = eventCase.extract(event) else { return }
            receivePayload(payload)
        }
    }

    /// Observes one selected event that carries no payload.
    ///
    /// - Parameters:
    ///   - eventCase: The event to observe.
    ///   - receiveEvent: The event handler.
    /// - Returns: The observed algorithm.
    @inlinable
    public func observing(
        _ eventCase: AlgorithmEventCase<Event, Void>,
        _ receiveEvent: @escaping () -> Void
    ) -> ObservedAlgorithm<Self> {
        observing(eventCase) { _ in receiveEvent() }
    }
}

/// An algorithm paired with a synchronous observation.
///
/// Values of this type are produced by ``AlgorithmObserving/observing(_:)``.
public struct ObservedAlgorithm<Base: AlgorithmObserving>: AlgorithmObserving {
    /// The event type published by the base algorithm.
    public typealias Event = Base.Event

    @usableFromInline
    let base: Base
    @usableFromInline
    let observation: AlgorithmObservation<Event>

    @inlinable
    init(base: Base, observation: AlgorithmObservation<Event>) {
        self.base = base
        self.observation = observation
    }
}

/// A lazy algorithm sequence that accepts an observation when iteration starts.
public protocol AlgorithmObservationSequence: Sequence, AlgorithmObserving {
    /// Creates an iterator carrying the supplied observation.
    ///
    /// - Parameter observation: The observation, or `nil` for the unobserved fast path.
    /// - Returns: A new independent iterator.
    func makeIterator(observation: AlgorithmObservation<Event>?) -> Iterator
}

extension ObservedAlgorithm: AlgorithmObservationSequence where Base: AlgorithmObservationSequence {
    /// The base sequence's iterator type.
    public typealias Iterator = Base.Iterator

    /// Creates an iterator with all attached observations composed in lexical order.
    @inlinable
    public func makeIterator(observation: AlgorithmObservation<Event>?) -> Iterator {
        base.makeIterator(observation: self.observation.followed(by: observation))
    }

    /// Creates an observed iterator.
    @inlinable
    public func makeIterator() -> Iterator {
        makeIterator(observation: nil)
    }
}

extension ObservedAlgorithm: Sequence where Base: AlgorithmObservationSequence {}
