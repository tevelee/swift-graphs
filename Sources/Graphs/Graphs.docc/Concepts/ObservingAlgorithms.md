# Observing Algorithms

Observe graph algorithms through typed, synchronous event streams.

## Overview

Algorithms publish an algorithm-specific `Event` enum. Attach an observation to
an algorithm value before passing it to a graph operation:

```swift
var examinedVertices: [AdjacencyList.VertexDescriptor] = []

let path = graph.shortestPath(
    from: source,
    to: destination,
    using: .dijkstra(weight: .property(\.weight))
        .observing(.vertexExamined) { vertex in
            examinedVertices.append(vertex)
        }
        .observing(.edgeRelaxed) { relaxation in
            print(relaxation.edge, relaxation.newCost)
        }
)
```

The selected-event form delivers only the selected payload. Use the full event
stream when one handler needs several event kinds:

```swift
let algorithm = BFSTraversal<AdjacencyList>()
    .observing { event in
        switch event {
            case .vertexDiscovered(let vertex):
                print("discovered", vertex)
            case .edgeExamined(let edge):
                print("examined", edge)
            default:
                break
        }
    }
```

## Composition

Attach multiple observations by chaining `observing`. Handlers run
synchronously in attachment order before the algorithm continues:

```swift
let algorithm = BFSTraversal<AdjacencyList>()
    .observing { metrics.record($0) }
    .observing { logger.log($0) }
```

Composition is implemented once by `AlgorithmObservation`; individual
algorithms only define their event vocabulary and emission sites.

## Observation and decisions

Observation is passive: attaching a handler never changes an algorithm result.
Behavior-changing decisions use a separate, explicitly named policy. Breadth-
and depth-first traversal expose `allowingTraversal`:

```swift
let result = graph.traverse(
    from: source,
    using: BFSTraversal<AdjacencyList>()
        .allowingTraversal { candidate in
            candidate.to != blockedVertex
        }
        .observing(.vertexDiscovered) {
            print($0)
        }
)
```

Repeated traversal policies are evaluated in attachment order with veto
semantics. Evaluation stops at the first `false` result.

## Lazy algorithms

Search sequences publish events only after iteration begins. Creating an
iterator may publish initialization events, such as discovery of a traversal's
source; subsequent events arrive as the iterator advances. Abandoning an
iterator does not synthesize completion events, and each new iterator starts
with independent algorithm state:

```swift
let search = BreadthFirstSearch(on: graph, from: source)
    .observing(.vertexExamined) {
        print($0)
    }

var iterator = search.makeIterator()
_ = iterator.next() // Publishes only the events needed for this result.
```

## Event contracts

- Events are delivered synchronously on the algorithm's executing thread.
- Handlers are nonthrowing. Handle fallible telemetry inside the handler.
- Event order follows algorithm state transitions and graph iteration order.
- An unobserved algorithm keeps a `nil` observation and does not construct
  event values.
- The observed algorithm value retains its handlers and can be reused across
  executions; each execution owns independent algorithm state.
- Reentrant execution from an observation is unsupported.

Each algorithm documents its `Event` enum and `EventCases` selectors beside the
implementation. Event payloads describe the algorithm state at the documented
emission boundary and do not expose mutable algorithm workspace.

## Defining observable algorithms

Algorithm protocols inherit `AlgorithmObserving` and accept an optional typed
observation:

```swift
public protocol ExampleAlgorithm<Graph>: AlgorithmObserving {
    associatedtype Graph: IncidenceGraph
    associatedtype Event

    func run(
        in graph: Graph,
        observation: AlgorithmObservation<Event>?
    ) -> Result
}
```

An implementation publishes semantic events at state-transition boundaries:

```swift
public enum Event {
    case vertexExamined(Vertex)
    case edgeRelaxed(EdgeRelaxation<Edge, Weight>)
    case vertexFinished(Vertex)
}

observation?.receive(.vertexExamined(vertex))
```

The shared `ObservedAlgorithm` wrapper forwards observations through graph-level
algorithm protocols. Algorithm implementations do not implement composition.

## See Also

- <doc:AlgorithmInterfaces>
- <doc:Architecture>
- <doc:AddingAnAlgorithm>
