add_pure_swift_host_library(swiftLLVMJSON STATIC EMIT_MODULE
  Sources/LLVMJSON/LLVMJSON.swift

  DEPENDENCIES
    swiftBasic
)

set(ASTGen_Swift_dependencies)

# If requested, build the regular expression parser into the compiler itself.
if(SWIFT_BUILD_REGEX_PARSER_IN_COMPILER)
  file(GLOB_RECURSE _COMPILER_REGEX_PARSER_SOURCES
    "${SWIFT_PATH_TO_STRING_PROCESSING_SOURCE}/Sources/_RegexParser/*.swift")
  set(COMPILER_REGEX_PARSER_SOURCES)
  foreach(source ${_COMPILER_REGEX_PARSER_SOURCES})
    file(TO_CMAKE_PATH "${source}" source)
    list(APPEND COMPILER_REGEX_PARSER_SOURCES ${source})
  endforeach()
  message(STATUS "Using Experimental String Processing library for _CompilerRegexParser (${SWIFT_PATH_TO_STRING_PROCESSING_SOURCE}).")

  add_pure_swift_host_library(_CompilerRegexParser STATIC EMIT_MODULE
    "${COMPILER_REGEX_PARSER_SOURCES}"
  )

  list(APPEND ASTGen_Swift_dependencies _CompilerRegexParser)
endif()

add_pure_swift_host_library(swiftASTGen STATIC
  Sources/ASTGen/ASTGen.swift
  Sources/ASTGen/Bridge.swift
  Sources/ASTGen/Decls.swift
  Sources/ASTGen/Diagnostics.swift
  Sources/ASTGen/DiagnosticsBridge.swift
  Sources/ASTGen/Exprs.swift
  Sources/ASTGen/Generics.swift
  Sources/ASTGen/LegacyParse.swift
  Sources/ASTGen/Literals.swift
  Sources/ASTGen/Macros.swift
  Sources/ASTGen/ParameterClause.swift
  Sources/ASTGen/Patterns.swift
  Sources/ASTGen/PluginHost.swift
  Sources/ASTGen/Regex.swift
  Sources/ASTGen/SourceFile.swift
  Sources/ASTGen/SourceManager.swift
  Sources/ASTGen/SourceManager+MacroExpansionContext.swift
  Sources/ASTGen/Stmts.swift
  Sources/ASTGen/Types.swift

  DEPENDENCIES
    swiftAST
  SWIFT_DEPENDENCIES
    SwiftBasicFormat
    SwiftCompilerPluginMessageHandling
    SwiftDiagnostics
    SwiftOperators
    SwiftParser
    SwiftParserDiagnostics
    SwiftSyntax
    SwiftSyntaxBuilder
    SwiftSyntaxMacros
    SwiftSyntaxMacroExpansion
    swiftLLVMJSON
    ${ASTGen_Swift_dependencies}
)

set(c_include_paths
  # LLVM modules and headers.
  "${LLVM_MAIN_INCLUDE_DIR}"
  # Generated LLVM headers.
  "${LLVM_INCLUDE_DIR}"
  # Clang modules and headers.
  ${CLANG_INCLUDE_DIRS}
  # Bridging modules and headers.
  "${SWIFT_MAIN_INCLUDE_DIR}"
  # Generated C headers.
  "${CMAKE_CURRENT_BINARY_DIR}/../../include")
set(c_include_paths_args)
foreach(c_include_path ${c_include_paths})
  list(APPEND c_include_paths_args "SHELL: -Xcc -I -Xcc ${c_include_path}")
endforeach()

# Prior to 5.9, we have to use the experimental flag for C++ interop.
if (CMAKE_Swift_COMPILER_VERSION VERSION_LESS 5.9)
  set(cxx_interop_flag "-enable-experimental-cxx-interop")
else()
  set(cxx_interop_flag "-cxx-interoperability-mode=default")
endif()

set(compile_options
  ${c_include_paths_args}
  "SHELL: ${cxx_interop_flag}"
  "SHELL: -Xcc -std=c++17 -Xcc -DCOMPILED_WITH_SWIFT"

  # FIXME: Needed to work around an availability issue with CxxStdlib
  "SHELL: -Xfrontend -disable-target-os-checking"

  # Necessary to avoid treating IBOutlet and IBAction as keywords
  "SHELL:-Xcc -UIBOutlet -Xcc -UIBAction -Xcc -UIBInspectable"
)

if(SWIFT_BUILD_SWIFT_SYNTAX)
  foreach(target swiftASTGen swiftLLVMJSON)
    target_compile_options(${target} PRIVATE ${compile_options})
  endforeach()
endif()
