import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

enum SlopeSubsetError: CustomStringConvertible, Error {
    case onlyApplicableToEnum
    
    var description: String {
        switch self {
        case .onlyApplicableToEnum:
            return "@SlopeSubset can only be applied to an enum"
        }
    }
}

// Implementation of the `SlopeSubset` macro

public struct SlopeSubsetMacro: MemberMacro {
    public static func expansion<Declaration, Context>(
        of node: SwiftSyntax.AttributeSyntax,
        providingMembersOf declaration: Declaration,
        in context: Context
    ) throws -> [SwiftSyntax.DeclSyntax] where Declaration : SwiftSyntax.DeclGroupSyntax, Context : SwiftSyntaxMacros.MacroExpansionContext {
        
        // enum declaration
        guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
            // TODO: Emitt an error here
            throw SlopeSubsetError.onlyApplicableToEnum
        }
        
        // the declerations inside of the enum
        let members = enumDecl.memberBlock.members
        let caseDecls = members.compactMap {
            $0.decl.as(EnumCaseDeclSyntax.self)
        }
        // because of single line declarations with multiple cases e.g. `case foo, bar`
        let elements = caseDecls.flatMap { $0.elements }
        
        // creating initalizer
        let initalizer = try InitializerDeclSyntax("init?(_ slope: Slope)") {
            try SwitchExprSyntax("switch slope") {
                for element in elements {
                    SwitchCaseSyntax(
                        """
                        case .\(element.identifier):
                            self = .\(element.identifier)
                        """
                    )
                }
                SwitchCaseSyntax("default: return nil")
            }
        }
        
        let slopeDecl = try VariableDeclSyntax("var slope: Slope") {
            try SwitchExprSyntax("switch self") {
                for element in elements {
                    SwitchCaseSyntax(
                        """
                        case .\(element.identifier):
                            return Slope.\(element.identifier)
                        """
                    )
                }
            }
        }
        
        return [DeclSyntax(initalizer), DeclSyntax(slopeDecl)]
    }
    
    
}

@main
struct SlopeSubsetPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        SlopeSubsetMacro.self
    ]
}
