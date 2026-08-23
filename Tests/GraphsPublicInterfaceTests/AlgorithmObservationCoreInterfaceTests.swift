import Graphs
import Testing

private enum ProbeEvent: Equatable {
    case ignored(Int)
    case value(Int)
    case finished
}

private enum ProbeEventCases {
    static var value: AlgorithmEventCase<ProbeEvent, Int> {
        AlgorithmEventCase { event in
            guard case .value(let value) = event else { return nil }
            return value
        }
    }

    static var finished: AlgorithmEventCase<ProbeEvent, Void> {
        AlgorithmEventCase { event in
            guard case .finished = event else { return nil }
            return ()
        }
    }
}

private struct ProbeSequence: AlgorithmObservationSequence {
    typealias Event = ProbeEvent
    typealias Iterator = AnyIterator<Int>

    let values: [Int]

    func makeIterator(observation: AlgorithmObservation<Event>?) -> Iterator {
        var iterator = values.makeIterator()
        var didFinish = false

        return AnyIterator {
            guard let value = iterator.next() else {
                if !didFinish {
                    didFinish = true
                    observation?.receive(.finished)
                }
                return nil
            }

            observation?.receive(.ignored(value))
            observation?.receive(.value(value))
            return value
        }
    }

    func makeIterator() -> Iterator {
        makeIterator(observation: nil)
    }
}

struct AlgorithmObservationCoreInterfaceTests {
    @Test func publicObservationReceivesEvents() {
        var events: [ProbeEvent] = []
        let observation = AlgorithmObservation<ProbeEvent> {
            events.append($0)
        }

        observation.receive(.value(42))

        #expect(events == [.value(42)])
    }

    @Test func publicSelectorsAndEveryObservingOverloadDispatchCorrectly() {
        var allEvents: [ProbeEvent] = []
        var selectedValues: [Int] = []
        var finishedCount = 0

        let values = Array(
            ProbeSequence(values: [1, 2])
                .observing { event in
                    allEvents.append(event)
                }
                .observing(ProbeEventCases.value) { value in
                    selectedValues.append(value)
                }
                .observing(ProbeEventCases.finished) {
                    finishedCount += 1
                }
        )

        #expect(values == [1, 2])
        #expect(
            allEvents == [
                .ignored(1), .value(1),
                .ignored(2), .value(2),
                .finished,
            ]
        )
        #expect(selectedValues == [1, 2])
        #expect(finishedCount == 1)
    }

    @Test func attachedObservationsRunLexicallyBeforeLaterObservation() {
        var calls: [String] = []
        let observed = ProbeSequence(values: [7])
            .observing { event in
                if case .value = event { calls.append("first") }
            }
            .observing { event in
                if case .value = event { calls.append("second") }
            }

        let iterator = observed.makeIterator(
            observation: AlgorithmObservation { event in
                if case .value = event { calls.append("later") }
            }
        )

        #expect(calls.isEmpty)
        #expect(iterator.next() == 7)
        #expect(calls == ["first", "second", "later"])
    }

    @Test func iteratorsAreLazyIndependentAndPreserveValues() {
        var selectedValues: [Int] = []
        let observed = ProbeSequence(values: [3, 4])
            .observing(ProbeEventCases.value) {
                selectedValues.append($0)
            }

        let first = observed.makeIterator()
        let second = observed.makeIterator()

        #expect(selectedValues.isEmpty)
        #expect(first.next() == 3)
        #expect(second.next() == 3)
        #expect(selectedValues == [3, 3])
        #expect(Array(observed) == Array(ProbeSequence(values: [3, 4])))
        #expect(selectedValues == [3, 3, 3, 4])
    }
}
