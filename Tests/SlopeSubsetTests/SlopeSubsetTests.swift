import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import SlopeSubsetMacros


let testMacros: [String: Macro.Type] = [
    "SlopeSubset": SlopeSubsetMacro.self
]

final class SlopeSubsetTests: XCTestCase {
    func testSlopeSubset() {
        assertMacroExpansion(
            """
            @SlopeSubset
            enum EasySlope {
                case begginerParadise
                case practiceRun
            }
            """, expandedSource:
            """
            
            enum EasySlope {
                case begginerParadise
                case practiceRun
                init?(_ slope: Slope) {
                    switch slope {
                    case .begginerParadise:
                        self = .begginerParadise
                    case .practiceRun:
                        self = .practiceRun
                    default:
                        return nil
                    }
                }
                var slope: Slope {
                    switch self {
                    case .begginerParadise:
                        return Slope.begginerParadise
                    case .practiceRun:
                        return Slope.practiceRun
                    }
                }
            }
            """, macros: testMacros
        )
    }
    
    func testSlopeSubsetOnStruct() throws {
        assertMacroExpansion(
            """
            @SlopeSubset
            struct Skier {
            }
            """,
            expandedSource: """

            struct Skier {
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "@SlopeSubset can only be applied to an enum", line: 1, column: 1)
            ],
            macros: testMacros
        )
    }
}
