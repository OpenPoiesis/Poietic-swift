//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 04/06/2023.
//


public class Node: ObjectSnapshot {
    public override func derive(snapshotID: SnapshotID,
                       objectID: ObjectID? = nil) -> ObjectSnapshot {
        return Node(id: objectID ?? self.id,
                    snapshotID: snapshotID,
                    type: self.type,
                    components: components.components)
    }

}

/// Edge represents a directed connection between two nodes in a graph.
///
/// The edges in the graph have an origin node and a target node associated
/// with it.
///
public class Edge: ObjectSnapshot {

    /// Origin node of the edge - a node from which the edge points from.
    ///
    public var origin: ObjectID {
        willSet {
            precondition(self.state.isMutable)
        }
    }
    /// Target node of the edge - a node to which the edge points to.
    ///
    public var target: ObjectID {
        willSet {
            precondition(self.state.isMutable)
        }
    }
    
    public init(id: ObjectID,
                snapshotID: SnapshotID,
                type: ObjectType? = nil,
                origin: ObjectID,
                target: ObjectID,
                components: [any Component] = []) {
        self.origin = origin
        self.target = target
        super.init(id: id,
                   snapshotID: snapshotID,
                   type: type,
                   components: components)
    }

    public override func derive(snapshotID: SnapshotID,
                       objectID: ObjectID? = nil) -> ObjectSnapshot {
        // FIXME: This breaks Edge
        return Edge(id: objectID ?? self.id,
                    snapshotID: snapshotID,
                    type: type,
                    origin: self.origin,
                    target: self.target,
                    components: components.components)
    }
    public override var description: String {
        return "Edge(id: \(id), sshot:\(snapshotID), \(origin) -> \(target), type: \(type?.name)"
    }

}

// TODO: Change node() and edge() to return non-optional
// REASON: ID is rather like an array index than a dictionary key, once we put
// an object into the graph, we usually expect it to be here, if it is not there
// it means that we made a programming error. We are rarely curious about
// the IDs presence in the graph.

/// Protocol for a graph structure.
///
public protocol Graph {
    /// List of indices of all nodes
    var nodeIDs: [ObjectID] { get }

    /// List of indices of all edges
    var edgeIDs: [ObjectID] { get }
    
    /// All nodes of the graph
    var nodes: [Node] { get }
    
    /// All edges of the graph
    var edges: [Edge] { get }

    /// Get a node by ID.
    ///
    func node(_ index: ObjectID) -> Node?

    /// Get an edge by ID.
    ///
    func edge(_ index: ObjectID) -> Edge?

    /// Check whether the graph contains a node and whether the node is valid.
    ///
    /// - Returns: `true` if the graph contains the node.
    ///
    /// - Note: Node comparison is based on its identity. Two nodes with the
    /// same attributes that are equatable are considered distinct nodes in the
    /// graph.
    ///
    ///
    func contains(node: ObjectID) -> Bool
    
    /// Check whether the graph contains an edge and whether the node is valid.
    ///
    /// - Returns: `true` if the graph contains the edge.
    ///
    /// - Note: Edge comparison is based on its identity.
    ///
    func contains(edge: ObjectID) -> Bool

    /// Get a list of outgoing edges from a node.
    ///
    /// - Parameters:
    ///     - origin: Node from which the edges originate - node is origin
    ///     node of the edge.
    ///
    /// - Returns: List of edges.
    ///
    /// - Complexity: O(n). All edges are traversed.
    ///
    /// - Note: If you want to get both outgoing and incoming edges of a node
    ///   then use ``neighbours(_:)-d13k``. Using ``outgoing(_:)`` + ``incoming(_:)-3rfqk`` might
    ///   result in duplicates for edges that are loops to and from the same
    ///   node.
    ///
    func outgoing(_ origin: ObjectID) -> [Edge]
    
    /// Get a list of edges incoming to a node.
    ///
    /// - Parameters:
    ///     - target: Node to which the edges are incoming – node is a target
    ///       node of the edge.
    ///
    /// - Returns: List of edges.
    ///
    /// - Complexity: O(n). All edges are traversed.
    ///
    /// - Note: If you want to get both outgoing and incoming edges of a node
    ///   then use ``neighbours``. Using ``outgoing`` + ``incoming`` might
    ///   result in duplicates for edges that are loops to and from the same
    ///   node.
    ///

    func incoming(_ target: ObjectID) -> [Edge]
    /// Get a list of edges that are related to the neighbours of the node. That
    /// is, list of edges where the node is either an origin or a target.
    ///
    /// - Returns: List of edges.
    ///
    /// - Complexity: O(n). All edges are traversed.
    ///

    func neighbours(_ node: ObjectID) -> [Edge]
    
    /// Returns edges that are related to the node and that match the given
    /// edge selector.
    ///
    // FIXME: Remove this
    func neighbours(_ node: ObjectID, selector: NeighborhoodSelector) -> [Edge]

    func selectNodes(_ predicate: NodePredicate) -> [Node]
    func selectEdges(_ predicate: EdgePredicate) -> [Edge]
    func selectNeighbors(nodeID: ObjectID, selector: NeighborhoodSelector) -> Neighborhood
}

extension Graph {
    public var nodeIDs: [ObjectID] {
        nodes.map { $0.id }
    }

    public var edgeIDs: [ObjectID] {
        edges.map { $0.id }
    }

    public func contains(node: ObjectID) -> Bool {
        return nodeIDs.contains { $0 == node }
    }

    public func contains(edge: ObjectID) -> Bool {
        return edgeIDs.contains { $0 == edge }
    }
    
    /// Get a node by ID.
    ///
    /// If id is `nil` then returns nil.
    ///
    public func node(_ oid: ObjectID) -> Node? {
        return nodes.first { $0.id == oid }
    }

    /// Get an edge by ID.
    ///
    /// If id is `nil` then returns nil.
    ///
    public func edge(_ oid: ObjectID) -> Edge? {
        return edges.first { $0.id == oid }
    }

    public func outgoing(_ origin: ObjectID) -> [Edge] {
        let result: [Edge]
        
        result = self.edges.filter {
            $0.origin == origin
        }

        return result
    }
    
    public func incoming(_ target: ObjectID) -> [Edge] {
        let result: [Edge]
        
        result = self.edges.filter {
            $0.target == target
        }

        return result
    }
    
    public func neighbours(_ node: ObjectID) -> [Edge] {
        let result: [Edge]
        
        result = self.edges.filter {
            $0.target == node || $0.origin == node
        }

        return result
    }
    
    public func selectNodes(_ predicate: NodePredicate) -> [Node] {
        return nodes.filter { predicate.match(graph: self, node: $0) }
    }
    public func selectEdges(_ predicate: EdgePredicate) -> [Edge] {
        return edges.filter { predicate.match(graph: self, edge: $0) }
    }
    
    public func selectNeighbors(nodeID: ObjectID, selector: NeighborhoodSelector) -> Neighborhood {
        let edges: [Edge]
        switch selector.direction {
        case .incoming: edges = incoming(nodeID)
        case .outgoing: edges = outgoing(nodeID)
        }
        let filtered: [Edge] = edges.filter {
            selector.predicate.match(graph: self, edge: $0)
        }
        
        return Neighborhood(graph: self,
                            nodeID: nodeID,
                            selector: selector,
                            edges: filtered)
    }

    
//    public func neighbours(_ node: NodeID, selector: EdgeSelector) -> [Edge] {
//        let edges: [Edge]
//        switch selector.direction {
//        case .incoming: edges = self.incoming(node)
//        case .outgoing: edges = self.outgoing(node)
//        }
//
//        return edges.filter { $0.contains(labels: selector.labels) }
//    }
}


/// Protocol
public protocol MutableGraph: Graph {
    /// Remove all nodes and edges from the graph.
    func removeAll()
    
    /// Add a node to the graph.
    ///
    func insert(_ node: Node)
    
    /// Add an edge to the graph.
    ///
    func insert(_ edge: Edge)
    
    /// Remove a node from the graph and return a list of edges that were
    /// removed together with the node.
    ///
    func remove(node nodeID: ObjectID)
    
    /// Remove an edge from the graph.
    ///
    func remove(edge edgeID: ObjectID)
    
    
    // Object creation
    @discardableResult
    func createNode(_ type: ObjectType,
                    components: [Component]) -> ObjectID

    @discardableResult
    func createEdge(_ type: ObjectType,
                    origin: ObjectID,
                    target: ObjectID,
                    components: [Component]) -> ObjectID
}

extension MutableGraph {
    public func removeAll() {
        for edge in edgeIDs {
            remove(edge: edge)
        }
        for node in nodeIDs {
            remove(node: node)
        }
    }
}

/// Graph contained within a mutable frame where the references to the nodes and
/// edges are not directly bound and are resolved at the time of querying.
public class MutableUnboudGraph: MutableGraph {
    let frame: MutableFrame
    
    public init(frame: MutableFrame) {
        self.frame = frame
    }
    
    /// Get a node by ID.
    ///
    public func node(_ index: ObjectID) -> Node? {
        return self.frame.object(index) as? Node
    }

    /// Get an edge by ID.
    ///
    public func edge(_ index: ObjectID) -> Edge? {
        return self.frame.object(index) as? Edge
    }

    public func contains(node: ObjectID) -> Bool {
        return self.node(node) != nil
    }

    public func contains(edge: ObjectID) -> Bool {
        return self.edge(edge) != nil
    }

    public func neighbours(_ node: ObjectID, selector: NeighborhoodSelector) -> [Edge] {
        fatalError("Neighbours of mutable graph not implemented")
    }
    
    public func insert(_ node: Node) {
        self.frame.insert(node)
    }
    
    public func insert(_ edge: Edge) {
        self.frame.insert(edge)
    }
    // Object creation
    public func createEdge(_ type: ObjectType,
                           origin: ObjectID,
                           target: ObjectID,
                           components: [any Component] = []) -> ObjectID {
        precondition(type.structuralType == Edge.self)
        precondition(frame.contains(origin),
                     "Trying to create an edge with unknown origin ID \(origin) in the frame")
        precondition(frame.contains(target),
                     "Trying to create an edge with unknown target ID \(target) in the frame")

        // TODO: This is not very clean: we create a template, then we derive the concrete object.
        // Frame is not aware of structural types, can only create plain objects.
        // See file Documentation/ObjectCreation.md for more discussion.
        let object = Edge(id:0,
                          snapshotID:0,
                          type: type,
                          origin: origin,
                          target: target,
                          components: components)
        for componentType in type.components {
            guard case let .defaultValue(componentType) = componentType else {
                continue
            }
            if !object.components.has(componentType) {
                object.components.set(componentType.init())
            }
        }
        
        let derived = frame.insertDerived(object)
        return derived
    }
    public func createNode(_ type: ObjectType,
                           components: [any Component] = []) -> ObjectID {
        precondition(type.structuralType == Node.self)

        // TODO: This is not very clean: we create a template, then we derive the concrete object.
        // Frame is not aware of structural types, can only create plain objects.
        // See file Documentation/ObjectCreation.md for more discussion.
        let object = Node(id:0,
                          snapshotID:0,
                          type: type,
                          components: components)
        for componentType in type.components {
            guard case let .defaultValue(componentType) = componentType else {
                continue
            }
            if !object.components.has(componentType) {
                object.components.set(componentType.init())
            }
        }
        
        return frame.insertDerived(object)
    }

    public func remove(node nodeID: ObjectID) {
        self.frame.removeCascading(nodeID)
    }
    
    public func remove(edge edgeID: ObjectID) {
        self.frame.removeCascading(edgeID)
    }
    
    public var nodes: [Node] {
        return self.frame.snapshots.compactMap {
            $0 as? Node
        }
    }
    
    public var edges: [Edge] {
        return self.frame.snapshots.compactMap {
            $0 as? Edge
        }
    }
    

    
}