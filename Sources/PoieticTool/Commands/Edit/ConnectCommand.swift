//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 04/07/2023.
//

import ArgumentParser
import PoieticCore
import PoieticFlows

extension PoieticTool {
    struct NewConnection: ParsableCommand {
        static var configuration
            = CommandConfiguration(
                commandName: "connect",
                abstract: "Create a new connection (edge) between two nodes"
            )

        @OptionGroup var options: Options

        @Argument(help: "Type of the connection to be created")
        var typeName: String

        @Argument(help: "Reference to the connection's origin node")
        var origin: String

        @Argument(help: "Reference to the connection's target node")
        var target: String

        
        mutating func run() throws {
            let memory = try openMemory(options: options)
            let frame = memory.deriveFrame()
            let graph = frame.mutableGraph
            
            guard let type = FlowsMetamodel.objectType(name: typeName) else {
                throw ToolError.unknownObjectType(typeName)
            }
            
            guard type.structuralType == .edge else {
                throw ToolError.structuralTypeMismatch(StructuralType.edge.rawValue,
                                                       type.structuralType.rawValue)
            }
            
            guard !type.isSystemOwned else {
                throw ToolError.creatingSystemOwnedType(type.name)
            }

            guard let originObject = frame.object(stringReference: self.origin) else {
                throw ToolError.unknownObject( self.origin)
            }
            
            guard let origin = originObject as? Node else {
                throw ToolError.nodeExpected(self.origin)

            }
            
            guard let targetObject = frame.object(stringReference: self.target) else {
                throw ToolError.unknownObject(self.target)
            }

            guard let target = targetObject as? Node else {
                throw ToolError.nodeExpected(target)

            }

            let id = graph.createEdge(type,
                                      origin: origin.id,
                                      target: target.id,
                                      components: [])
            
            try acceptFrame(frame, in: memory)
            try closeMemory(memory: memory, options: options)

            print("Created edge \(id)")
            print("Current frame: \(memory.currentFrame.id)")
        }
    }

}


