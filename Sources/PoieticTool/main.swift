//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 27/06/2023.
//

import PoieticCore

import ArgumentParser

// The Command
// ------------------------------------------------------------------------

struct PoieticTool: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "poietic",
        abstract: "Poietic design utility.",
        subcommands: [
            CreateDB.self,
            Info.self,
//            CreateNode.self,
//            Remove.self,
//            SetAttribute.self,
//            Undo.self,
//            Redo.self,
//            Connect.self,
            List.self,
            Describe.self,
            Edit.self,
//            Print.self,
//            Import.self,
//            Export.self,
            Run.self,
            WriteDOT.self,
            Metamodel.self,
        ]
//        defaultSubcommand: List.self
    )
}

struct Options: ParsableArguments {
    @Option(name: [.long, .customShort("d")], help: "Path to a poietic design")
    var database: String?
}


PoieticTool.main()