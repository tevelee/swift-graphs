# Test Organization

This directory contains all tests for the Swift Graphs library, organized by functionality with consistent naming conventions.

## Directory Structure

### `/Algorithms/`
Contains tests for graph algorithms (all files follow `[Algorithm]Tests.swift` pattern):
- **AStarAlgorithmTests.swift** - A* search algorithm tests
- **BestFirstSearchTests.swift** - Best-first search algorithm tests  
- **BreadthFirstSearchTests.swift** - Breadth-first search algorithm tests
- **BinaryInorderTraversalTests.swift** - Binary tree inorder traversal tests
- **DepthFirstSearchOrderTests.swift** - DFS order-specific search tests
- **DepthFirstSearchTests.swift** - Depth-first search algorithm tests
- **DepthLimitedSearchTests.swift** - Depth-limited search algorithm tests
- **DijkstraAlgorithmTests.swift** - Dijkstra's shortest path algorithm tests
- **SearchAlgorithmTests.swift** - General search algorithm tests
- **ShortestPathAlgorithmTests.swift** - Comprehensive shortest path algorithms tests (Floyd-Warshall, Bellman-Ford, Yen, etc.)

### `/DataStructures/`
Contains tests for graph data structures (all files follow `[Structure]Tests.swift` pattern):
- **AdjacencyMatrixTests.swift** - Adjacency matrix graph implementation tests
- **BinaryAdjacencyListTests.swift** - Binary tree adjacency list tests
- **GridGraphTests.swift** - Grid graph implementation tests
- **LazyGraphTests.swift** - Lazy graph implementation tests

### `/Core/`
Contains tests for core functionality and utilities (all files follow `[Component]Tests.swift` pattern):
- **ComputedPropertiesTests.swift** - Computed property tests
- **EdgeStorageBackendTests.swift** - Edge storage backend tests
- **GraphBasicTests.swift** - Basic graph operations tests
- **PropertyMapTests.swift** - Property map functionality tests

### `/Properties/`
Contains test property definitions and utilities:
- **Coordinates.swift** - Coordinate-related test properties
- **Label.swift** - Label-related test properties  
- **Weight.swift** - Weight-related test properties

## Naming Convention

All test files follow a consistent naming pattern:
- **Algorithm tests**: `[AlgorithmName]Tests.swift` (e.g., `AStarAlgorithmTests.swift`)
- **Data structure tests**: `[StructureName]Tests.swift` (e.g., `AdjacencyMatrixTests.swift`)
- **Core functionality tests**: `[ComponentName]Tests.swift` (e.g., `GraphBasicTests.swift`)
- **Property files**: `[PropertyName].swift` (e.g., `Coordinates.swift`)

## Running Tests

To run all tests:
```bash
swift test
```

To run tests for a specific category:
```bash
swift test --filter Algorithms
swift test --filter DataStructures  
swift test --filter Core
```

To run a specific test file:
```bash
swift test --filter ShortestPathAlgorithmTests
```
