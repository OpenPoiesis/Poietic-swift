//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 08/06/2023.
//

import XCTest
@testable import PoieticFlows
@testable import PoieticCore


final class TestSolver: XCTestCase {
    var db: ObjectMemory!
    var frame: MutableFrame!
    var graph: MutableGraph!
    var compiler: Compiler!
    
    override func setUp() {
        db = ObjectMemory()
        
        // TODO: This should be passed as an argument to the memory
        for constraint in FlowsMetamodel.constraints {
            try! db.addConstraint(constraint)
        }
        
        frame = db.deriveFrame()
        graph = frame.mutableGraph
        compiler = Compiler(frame: frame)
    }
    func testInitializeStocks() throws {
        
        let a = graph.createNode(FlowsMetamodel.Auxiliary,
                                 components: [FormulaComponent(name: "a",
                                                                  expression: "1")])
        let b = graph.createNode(FlowsMetamodel.Auxiliary,
                                 components: [FormulaComponent(name: "b",
                                                                  expression: "a + 1")])
        let c =  graph.createNode(FlowsMetamodel.Stock,
                                  components: [FormulaComponent(name: "const",
                                                                   expression: "100")])
        let s_a = graph.createNode(FlowsMetamodel.Stock,
                                   components: [FormulaComponent(name: "use_a",
                                                                    expression: "a")])
        let s_b = graph.createNode(FlowsMetamodel.Stock,
                                   components: [FormulaComponent(name: "use_b",
                                                                    expression: "b")])
        
        graph.createEdge(FlowsMetamodel.Parameter, origin: a, target: b, components: [])
        graph.createEdge(FlowsMetamodel.Parameter, origin: a, target: s_a, components: [])
        graph.createEdge(FlowsMetamodel.Parameter, origin: b, target: s_b, components: [])
        
        let compiled = try compiler.compile()
        let solver = Solver(compiled)
        
        let vector = solver.initialize()
        
        XCTAssertEqual(vector[a], 1)
        XCTAssertEqual(vector[b], 2)
        XCTAssertEqual(vector[c], 100)
        XCTAssertEqual(vector[s_a], 1)
        XCTAssertEqual(vector[s_b], 2)
    }
    func testOrphanedInitialize() throws {
        
        let a = graph.createNode(FlowsMetamodel.Auxiliary,
                                 components: [FormulaComponent(name: "a",
                                                                  expression: "1")])
        let compiled = try compiler.compile()
        let solver = Solver(compiled)
        
        let vector = solver.initialize()
        
        XCTAssertNotNil(vector[a])
    }
    func testEverythingInitialized() throws {
        let aux = graph.createNode(FlowsMetamodel.Auxiliary,
                                   components: [FormulaComponent(name: "a",
                                                                    expression: "10")])
        let stock = graph.createNode(FlowsMetamodel.Stock,
                                     components: [FormulaComponent(name: "b",
                                                                      expression: "20")])
        let flow = graph.createNode(FlowsMetamodel.Flow,
                                    components: [FormulaComponent(name:"c",
                                                                     expression: "30")])
        
        let compiled = try compiler.compile()
        let solver = Solver(compiled)
        
        let vector = solver.initialize()
        
        XCTAssertEqual(vector[aux], 10)
        XCTAssertEqual(vector[stock], 20)
        XCTAssertEqual(vector[flow], 30)
    }
   
    func testNegativeStock() throws {
        let stock = graph.createNode(FlowsMetamodel.Stock,
                                     components: [FormulaComponent(name: "stock",
                                                                      expression: "5")])
        let obj = graph.node(stock)!
        obj[StockComponent.self]!.allowsNegative = true
        
        let flow = graph.createNode(FlowsMetamodel.Flow,
                                     components: [FormulaComponent(name: "flow",
                                                                      expression: "10")])

        graph.createEdge(FlowsMetamodel.Drains, origin: stock, target: flow, components: [])
        
        let compiled = try compiler.compile()
        
        let solver = Solver(compiled)
        let initial = solver.initialize()
        let diff = try solver.difference(at: 1.0, with: initial)

        XCTAssertEqual(diff[stock]!, -10)
    }

    func testNonNegativeStock() throws {
        let stock = graph.createNode(FlowsMetamodel.Stock,
                                     components: [FormulaComponent(name: "stock",
                                                                      expression: "5")])
        let obj = graph.node(stock)!
        obj[StockComponent.self]!.allowsNegative = false
        
        let flow = graph.createNode(FlowsMetamodel.Flow,
                                     components: [FormulaComponent(name: "flow",
                                                                      expression: "10")])

        graph.createEdge(FlowsMetamodel.Drains, origin: stock, target: flow, components: [])
        
        let compiled = try compiler.compile()
        
        let solver = Solver(compiled)
        let initial = solver.initialize()
        let diff = try solver.difference(at: 1.0, with: initial)

        XCTAssertEqual(diff[stock]!, -5)
    }
    func testNonNegativeToTwo() throws {
        // TODO: Break this into multiple tests
        let source = graph.createNode(FlowsMetamodel.Stock,
                                     components: [FormulaComponent(name: "stock",
                                                                      expression: "5")])
        let sourceNode = graph.node(source)!
        sourceNode[StockComponent.self]!.allowsNegative = false

        let happy = graph.createNode(FlowsMetamodel.Stock,
                                     components: [FormulaComponent(name: "happy",
                                                                      expression: "0")])
        let sad = graph.createNode(FlowsMetamodel.Stock,
                                     components: [FormulaComponent(name: "sad",
                                                                      expression: "0")])
        let happyFlow = graph.createNode(FlowsMetamodel.Flow,
                                     components: [FormulaComponent(name: "happy_flow",
                                                                      expression: "10")])
        let happyFlowNode = graph.node(happyFlow)!
        happyFlowNode[FlowComponent.self]!.priority = 1

        graph.createEdge(FlowsMetamodel.Drains,
                         origin: source, target: happyFlow, components: [])
        graph.createEdge(FlowsMetamodel.Fills,
                         origin: happyFlow, target: happy, components: [])

        let sadFlow = graph.createNode(FlowsMetamodel.Flow,
                                     components: [FormulaComponent(name: "sad_flow",
                                                                      expression: "10")])
        let sadFlowNode = graph.node(sadFlow)!
        sadFlowNode[FlowComponent.self]!.priority = 2

        graph.createEdge(FlowsMetamodel.Drains,
                         origin: source, target: sadFlow, components: [])
        graph.createEdge(FlowsMetamodel.Fills,
                         origin: sadFlow, target: sad, components: [])

        let compiled: CompiledModel = try compiler.compile()
        // TODO: Needed?
        // let outflows = compiled.outflows[source]
        
        // We require that the stocks will be computed in the following order:
        // 1. source
        // 2. happy
        // 3. sad

        let solver = Solver(compiled)
        
        // Test compute()
        
        let initial: StateVector = solver.initialize()

        print(">> BEGIN")
        // Compute test
        var state: StateVector = initial

        XCTAssertEqual(state[happyFlow]!, 10)
        XCTAssertEqual(state[sadFlow]!, 10)

        let sourceDiff = solver.computeStock(stock: source, at: 0, with: &state)
        // Adjusted flow to actual outflow
        XCTAssertEqual(state[happyFlow]!,  5.0)
        XCTAssertEqual(state[sadFlow]!,    0.0)
        XCTAssertEqual(sourceDiff,         -5.0)

        let happyDiff = solver.computeStock(stock: happy, at: 0, with: &state)
        // Remains the same as above
        XCTAssertEqual(state[happyFlow]!,  5.0)
        XCTAssertEqual(state[sadFlow]!,    0.0)
        XCTAssertEqual(happyDiff,          +5.0)

        let sadDiff = solver.computeStock(stock: sad, at: 0, with: &state)
        // Remains the same as above
        XCTAssertEqual(state[happyFlow]!,  5.0)
        XCTAssertEqual(state[sadFlow]!,    0.0)
        XCTAssertEqual(sadDiff,             0.0)

        // Sanity check
        XCTAssertEqual(initial[happyFlow]!, 10)
        XCTAssertEqual(initial[sadFlow]!, 10)


        let diff = try solver.difference(at: 1.0, with: initial)

        XCTAssertEqual(diff[source]!, -5)
        XCTAssertEqual(diff[happy]!,  +5)
        XCTAssertEqual(diff[sad]!,     0)
    }

}
