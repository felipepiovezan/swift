#===--- CMakeLists.txt - Build the core standard library -----------------===#
#
# This source file is part of the Swift.org open source project
#
# Copyright (c) 2014 - 2022 Apple Inc. and the Swift project authors
# Licensed under Apache License v2.0 with Runtime Library Exception
#
# See https://swift.org/LICENSE.txt for license information
# See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
#
#===----------------------------------------------------------------------===#

function(split_embedded_sources)
  cmake_parse_arguments(SPLIT1 "" "OUT_LIST_EMBEDDED;OUT_LIST_NORMAL" "EMBEDDED;NORMAL" ${ARGN})
  string(REPLACE "EMBEDDED" "NORMAL" ARGN2 "${ARGN}")
  cmake_parse_arguments(SPLIT2 "" "OUT_LIST_EMBEDDED;OUT_LIST_NORMAL" "EMBEDDED;NORMAL" ${ARGN2})
  set(${SPLIT1_OUT_LIST_EMBEDDED} "${SPLIT1_EMBEDDED}" PARENT_SCOPE)
  set(${SPLIT1_OUT_LIST_NORMAL} "${SPLIT2_NORMAL}" PARENT_SCOPE)
endfunction()

# The complete list of sources in the core standard library. Each file is
# annotated with either "EMBEDDED" which means it contributes to both the
# embedded Swift stdlib and the regular stdlib, or "NORMAL" which means it only
# contributes to the regular stdlib. The split_embedded_sources splits this list
# into SWIFTLIB_EMBEDDED_SOURCES and SWIFTLIB_SOURCES accordingly.
split_embedded_sources(
  OUT_LIST_EMBEDDED SWIFTLIB_EMBEDDED_SOURCES
  OUT_LIST_NORMAL SWIFTLIB_SOURCES

  ### "ESSENTIAL" SOURCES
  ### -- PLEASE KEEP THIS LIST IN ALPHABETICAL ORDER ###
  # Some files can't be sorted alphabetically, see notes in the list below.
  EMBEDDED Algorithm.swift
  EMBEDDED ArrayBody.swift
  EMBEDDED ArrayBuffer.swift
  EMBEDDED ArrayBufferProtocol.swift
    NORMAL ArrayCast.swift
  EMBEDDED Array.swift
  EMBEDDED ArrayShared.swift
  EMBEDDED ArraySlice.swift
  EMBEDDED ArrayType.swift
    NORMAL ASCII.swift
  EMBEDDED Assert.swift
  EMBEDDED AssertCommon.swift
  EMBEDDED BidirectionalCollection.swift
    NORMAL Bitset.swift
  EMBEDDED Bool.swift
    NORMAL BridgeObjectiveC.swift
    NORMAL BridgeStorage.swift
    NORMAL BridgingBuffer.swift
  EMBEDDED Builtin.swift
    NORMAL BuiltinMath.swift
    NORMAL Character.swift
    NORMAL CocoaArray.swift
    NORMAL Codable.swift
  EMBEDDED Collection.swift
  EMBEDDED CollectionAlgorithms.swift
  EMBEDDED Comparable.swift
  EMBEDDED CompilerProtocols.swift
  EMBEDDED Sendable.swift
  EMBEDDED ContiguousArray.swift
    NORMAL ContiguouslyStored.swift
  EMBEDDED ClosedRange.swift
  EMBEDDED ContiguousArrayBuffer.swift
    NORMAL CString.swift
  EMBEDDED CTypes.swift
    NORMAL DebuggerSupport.swift
    NORMAL Dictionary.swift
    NORMAL DictionaryBridging.swift
    NORMAL DictionaryBuilder.swift
    NORMAL DictionaryCasting.swift
    NORMAL DictionaryStorage.swift
    NORMAL DictionaryVariant.swift
    NORMAL DropWhile.swift
    NORMAL Dump.swift
  EMBEDDED EmptyCollection.swift
  EMBEDDED Equatable.swift
  EMBEDDED ErrorType.swift
  EMBEDDED ExistentialCollection.swift
    NORMAL Filter.swift
    NORMAL FixedArray.swift
    NORMAL FlatMap.swift
    NORMAL Flatten.swift
  EMBEDDED FloatingPoint.swift
  EMBEDDED Hashable.swift
  # WORKAROUND: This file name is not sorted alphabetically in the list because
  # if we do so, the compiler crashes.
  EMBEDDED AnyHashable.swift
  # END WORKAROUND
  EMBEDDED Hasher.swift
    NORMAL Hashing.swift
    NORMAL HashTable.swift
  EMBEDDED Identifiable.swift
  EMBEDDED Indices.swift
    NORMAL InputStream.swift
    NORMAL IntegerParsing.swift
  EMBEDDED Integers.swift
    NORMAL Join.swift
    NORMAL KeyPath.swift
    NORMAL KeyValuePairs.swift
    NORMAL LazyCollection.swift
    NORMAL LazySequence.swift
    NORMAL LegacyABI.swift
  EMBEDDED LifetimeManager.swift
    NORMAL Macros.swift
  EMBEDDED ManagedBuffer.swift
    NORMAL Map.swift
  EMBEDDED MemoryLayout.swift
    NORMAL UnicodeScalar.swift # ORDER DEPENDENCY: Must precede Mirrors.swift
    NORMAL Mirrors.swift
  EMBEDDED Misc.swift
  EMBEDDED MutableCollection.swift
    NORMAL NativeDictionary.swift
    NORMAL NativeSet.swift
    NORMAL NewtypeWrapper.swift
    NORMAL NFC.swift
    NORMAL NFD.swift
  EMBEDDED ObjectIdentifier.swift
  EMBEDDED Optional.swift
  EMBEDDED OptionSet.swift
    NORMAL OutputStream.swift
  EMBEDDED Pointer.swift
  EMBEDDED Policy.swift
    NORMAL PrefixWhile.swift
    NORMAL Prespecialize.swift
    NORMAL Print.swift
    NORMAL PtrAuth.swift
  EMBEDDED Random.swift
  EMBEDDED RandomAccessCollection.swift
  EMBEDDED Range.swift
  EMBEDDED RangeReplaceableCollection.swift
    NORMAL ReflectionMirror.swift
  EMBEDDED Repeat.swift
    NORMAL REPL.swift
  EMBEDDED Result.swift
  EMBEDDED Reverse.swift
  EMBEDDED Runtime.swift
    NORMAL RuntimeFunctionCounters.swift
  EMBEDDED SipHash.swift
  EMBEDDED Sequence.swift
  EMBEDDED SequenceAlgorithms.swift
    NORMAL Set.swift
  EMBEDDED SetAlgebra.swift
    NORMAL SetAnyHashableExtensions.swift
    NORMAL SetBridging.swift
    NORMAL SetBuilder.swift
    NORMAL SetCasting.swift
    NORMAL SetStorage.swift
    NORMAL SetVariant.swift
    NORMAL ShadowProtocols.swift
    NORMAL Shims.swift
  EMBEDDED Slice.swift
    NORMAL SmallString.swift
  EMBEDDED Sort.swift
  EMBEDDED StaticString.swift
    NORMAL StaticPrint.swift
  EMBEDDED Stride.swift
    NORMAL StringHashable.swift  # ORDER DEPENDENCY: Must precede String.swift
    NORMAL String.swift
    NORMAL StringBreadcrumbs.swift
    NORMAL StringBridge.swift
    NORMAL StringCharacterView.swift
    NORMAL StringComparable.swift
    NORMAL StringComparison.swift
    NORMAL StringCreate.swift
    NORMAL StringGuts.swift
    NORMAL StringGutsSlice.swift
    NORMAL StringGutsRangeReplaceable.swift
    NORMAL StringObject.swift
    NORMAL StringProtocol.swift
    NORMAL StringIndex.swift
    NORMAL StringIndexConversions.swift
    NORMAL StringIndexValidation.swift
    NORMAL StringInterpolation.swift
    NORMAL StringLegacy.swift
    NORMAL StringNormalization.swift
    NORMAL StringRangeReplaceableCollection.swift
    NORMAL StringStorage.swift
    NORMAL StringStorageBridge.swift
    NORMAL StringSwitch.swift
    NORMAL StringTesting.swift
    NORMAL StringUnicodeScalarView.swift
    NORMAL StringUTF16View.swift
    NORMAL StringUTF8View.swift
    NORMAL StringUTF8Validation.swift
    NORMAL StringWordBreaking.swift
    NORMAL Substring.swift
  EMBEDDED SwiftNativeNSArray.swift
  EMBEDDED TemporaryAllocation.swift
    NORMAL ThreadLocalStorage.swift
    NORMAL UIntBuffer.swift
    NORMAL UnavailableStringAPIs.swift
    NORMAL UnicodeData.swift
    NORMAL UnicodeEncoding.swift
    NORMAL UnicodeBreakProperty.swift
    NORMAL UnicodeHelpers.swift
    NORMAL UnicodeParser.swift
    NORMAL UnicodeScalarProperties.swift
    NORMAL CharacterProperties.swift # ORDER DEPENDENCY: UnicodeScalarProperties.swift
    NORMAL UnicodeSPI.swift
  EMBEDDED Unmanaged.swift
    NORMAL UnmanagedOpaqueString.swift
    NORMAL UnmanagedString.swift
  EMBEDDED UnsafePointer.swift
  EMBEDDED UnsafeRawPointer.swift
    NORMAL UTFEncoding.swift
    NORMAL UTF8.swift
    NORMAL UTF16.swift
    NORMAL UTF32.swift
    NORMAL Unicode.swift # ORDER DEPENDENCY: must follow new unicode support
    NORMAL StringGraphemeBreaking.swift # ORDER DEPENDENCY: Must follow UTF16.swift
    NORMAL ValidUTF8Buffer.swift
  EMBEDDED WriteBackMutableSlice.swift
    NORMAL MigrationSupport.swift

    ### "NON-ESSENTIAL" SOURCES, LAYERED ON TOP OF THE "ESSENTIAL" ONES
    ### -- PLEASE KEEP THIS LIST IN ALPHABETICAL ORDER ###
  EMBEDDED Availability.swift
    NORMAL CollectionDifference.swift
  EMBEDDED CollectionOfOne.swift
    NORMAL Diffing.swift
  EMBEDDED Duration.swift
  EMBEDDED DurationProtocol.swift
  EMBEDDED FloatingPointRandom.swift
  EMBEDDED Instant.swift
    NORMAL Mirror.swift
    NORMAL PlaygroundDisplay.swift
    NORMAL CommandLine.swift
  EMBEDDED SliceBuffer.swift
    NORMAL StaticBigInt.swift
    NORMAL UnfoldSequence.swift
    NORMAL UnsafeBufferPointerSlice.swift
    NORMAL VarArgs.swift
  EMBEDDED Zip.swift
    NORMAL "${SWIFT_SOURCE_DIR}/stdlib/linker-support/magic-symbols-for-install-name.c"
  )

split_embedded_sources(
  OUT_LIST_EMBEDDED SWIFTLIB_EMBEDDED_GYB_SOURCES
  OUT_LIST_NORMAL SWIFTLIB_GYB_SOURCES

    NORMAL AtomicInt.swift.gyb
    NORMAL FloatingPointParsing.swift.gyb
  EMBEDDED FloatingPointTypes.swift.gyb
  EMBEDDED IntegerTypes.swift.gyb
  EMBEDDED UnsafeBufferPointer.swift.gyb
  EMBEDDED UnsafeRawBufferPointer.swift.gyb
  EMBEDDED Int128.swift.gyb
  EMBEDDED Tuple.swift.gyb
  )

if(SWIFT_STDLIB_ENABLE_VECTOR_TYPES)
  list(APPEND SWIFTLIB_SOURCES SIMDVector.swift)
  list(APPEND SWIFTLIB_GYB_SOURCES SIMDConcreteOperations.swift.gyb SIMDVectorTypes.swift.gyb)
endif()

list(APPEND SWIFTLIB_EMBEDDED_SOURCES
  EmbeddedRuntime.swift
  EmbeddedStubs.swift
  )

set(GROUP_INFO_JSON_FILE ${CMAKE_CURRENT_SOURCE_DIR}/GroupInfo.json)
set(swift_core_link_flags "${SWIFT_RUNTIME_SWIFT_LINK_FLAGS}")
set(swift_core_framework_depends)
set(swift_core_private_link_libraries)
set(swift_stdlib_compile_flags "${SWIFT_RUNTIME_SWIFT_COMPILE_FLAGS}")

if(SWIFT_PRIMARY_VARIANT_SDK STREQUAL "CYGWIN")
  # TODO(compnerd) cache this variable to permit re-configuration
  execute_process(COMMAND "cygpath" "-u" "$ENV{SYSTEMROOT}" OUTPUT_VARIABLE ENV_SYSTEMROOT)
  list(APPEND swift_core_private_link_libraries "${ENV_SYSTEMROOT}/system32/psapi.dll")
elseif(SWIFT_PRIMARY_VARIANT_SDK STREQUAL "FREEBSD")
  find_library(EXECINFO_LIBRARY execinfo)
  list(APPEND swift_core_private_link_libraries ${EXECINFO_LIBRARY})
elseif(SWIFT_PRIMARY_VARIANT_SDK STREQUAL "LINUX")
  if(SWIFT_BUILD_STATIC_STDLIB)
    list(APPEND swift_core_private_link_libraries)
  endif()
elseif(SWIFT_PRIMARY_VARIANT_SDK STREQUAL "WINDOWS")
  list(APPEND swift_core_private_link_libraries shell32;DbgHelp;Synchronization)
endif()

if(NOT "${CMAKE_BUILD_TYPE}" STREQUAL "MinSizeRel")
  list(APPEND swift_stdlib_compile_flags "-Xllvm" "-sil-inline-generics")
  list(APPEND swift_stdlib_compile_flags "-Xllvm" "-sil-partial-specialization")
endif()
if(SWIFT_STDLIB_ENABLE_STDLIBCORE_EXCLUSIVITY_CHECKING)
  list(APPEND swift_stdlib_compile_flags "-enforce-exclusivity=checked")
endif()
if(SWIFT_STDLIB_ENABLE_DEBUG_PRECONDITIONS_IN_RELEASE)
  list(APPEND swift_stdlib_compile_flags "-DSWIFT_STDLIB_ENABLE_DEBUG_PRECONDITIONS_IN_RELEASE")
endif()
set(compile_flags_for_final_build)
if(SWIFT_ENABLE_ARRAY_COW_CHECKS)
  list(APPEND compile_flags_for_final_build "-DCOW_CHECKS_ENABLED")
endif()

# STAGING: Temporarily avoids having to write #fileID in Swift.swiftinterface.
list(APPEND swift_stdlib_compile_flags "-Xfrontend" "-enable-experimental-concise-pound-file")

list(APPEND swift_stdlib_compile_flags "-enable-experimental-feature" "Macros")
list(APPEND swift_stdlib_compile_flags "-enable-experimental-feature" "FreestandingMacros")
list(APPEND swift_stdlib_compile_flags "-enable-experimental-feature" "Extern")

set(swift_core_incorporate_object_libraries)
list(APPEND swift_core_incorporate_object_libraries swiftRuntime)
list(APPEND swift_core_incorporate_object_libraries swiftLLVMSupport)
list(APPEND swift_core_incorporate_object_libraries swiftDemangling)
list(APPEND swift_core_incorporate_object_libraries swiftStdlibStubs)
list(APPEND swift_core_incorporate_object_libraries swiftThreading)
if(SWIFT_STDLIB_HAS_COMMANDLINE)
  list(APPEND swift_core_incorporate_object_libraries swiftCommandLineSupport)
endif()

set(swiftCore_common_options
                  IS_STDLIB IS_STDLIB_CORE
                    ${SWIFTLIB_SOURCES}
                  GYB_SOURCES
                    ${SWIFTLIB_GYB_SOURCES}
                  LINK_FLAGS
                    ${swift_core_link_flags}
                  PRIVATE_LINK_LIBRARIES
                    ${swift_core_private_link_libraries}
                  INCORPORATE_OBJECT_LIBRARIES
                    ${swift_core_incorporate_object_libraries}
                  FRAMEWORK_DEPENDS
                    ${swift_core_framework_depends}
                  SWIFT_COMPILE_FLAGS
                    ${swift_stdlib_compile_flags} -Xcc -DswiftCore_EXPORTS ${SWIFT_STANDARD_LIBRARY_SWIFT_FLAGS})

# The copy_shim_headers target dependency is required to let the
# build system know that there's a rule to produce the shims
# directory, but is not sufficient to cause the object file to be rebuilt
# when the shim header changes.  Therefore, we pass both the target
# and the generated directory as dependencies.
set(swiftCore_common_dependencies
    copy_shim_headers "${SWIFTLIB_DIR}/shims" ${GROUP_INFO_JSON_FILE})

if(BOOTSTRAPPING_MODE STREQUAL "BOOTSTRAPPING")

  set(b0_deps symlink-headers-bootstrapping0)
  set(b1_deps symlink-headers-bootstrapping1)

  list(FIND SWIFT_STDLIB_LIBRARY_BUILD_TYPES "SHARED" index_of_shared)
  if(index_of_shared EQUAL -1)
    message(FATAL_ERROR "bootstrapping requires SHARED stdlib build type")
  endif()

  set(swiftCore_common_bootstrapping_options
                    SHARED
                    ${swiftCore_common_options}
                    SDK ${SWIFT_HOST_VARIANT_SDK}
                    ARCHITECTURE ${SWIFT_HOST_VARIANT_ARCH}
                    INSTALL_IN_COMPONENT
                      "never_install")

  # Bootstrapping - stage 0

  add_swift_target_library_single(swiftCore-bootstrapping0 swiftCore
                    ${swiftCore_common_bootstrapping_options}
                    FILE_DEPENDS
                      ${b0_deps} ${swiftCore_common_dependencies}
                    BOOTSTRAPPING 0)

  # Bootstrapping - stage 1

  add_swift_target_library_single(swiftCore-bootstrapping1 swiftCore
                    ${swiftCore_common_bootstrapping_options}
                    FILE_DEPENDS
                      ${b1_deps} ${swiftCore_common_dependencies}
                    BOOTSTRAPPING 1)
endif()

add_swift_target_library(swiftCore
                  ${SWIFT_STDLIB_LIBRARY_BUILD_TYPES}
                  ${swiftCore_common_options}
                  ${compile_flags_for_final_build}
                  FILE_DEPENDS
                    ${swiftCore_common_dependencies}
                  INSTALL_IN_COMPONENT
                    stdlib
                  MACCATALYST_BUILD_FLAVOR
                    zippered
                 )

# Embedded standard library - embedded libraries are built as .swiftmodule only,
# i.e. there is no .o or .a file produced (no binary code is actually produced)
# and only users of a library are going to actually compile any needed code.
#
# For now, we build a hardcoded list of target triples of the embedded stdlib,
# and only when building Swift on macOS.
if(SWIFT_SHOULD_BUILD_EMBEDDED_STDLIB)
  add_custom_target(embedded-stdlib ALL)

  set(SWIFT_ENABLE_REFLECTION OFF)
  set(SWIFT_STDLIB_SUPPORT_BACK_DEPLOYMENT OFF)
  set(SWIFT_STDLIB_STABLE_ABI OFF)
  set(SWIFT_STDLIB_ENABLE_OBJC_INTEROP OFF)

  foreach(entry ${EMBEDDED_STDLIB_TARGET_TRIPLES})
    string(REGEX REPLACE "[ \t]+" ";" list "${entry}")
    list(GET list 0 arch)
    list(GET list 1 mod)
    list(GET list 2 triple)
    
    set(SWIFT_SDK_embedded_ARCH_${arch}_MODULE "${mod}")
    set(SWIFT_SDK_embedded_LIB_SUBDIR "embedded")
    set(SWIFT_SDK_embedded_ARCH_${arch}_TRIPLE "${triple}")
    add_swift_target_library_single(
      embedded-stdlib-${mod}
      swiftCore
      ONLY_SWIFTMODULE
      IS_STDLIB IS_STDLIB_CORE IS_FRAGILE
      ${SWIFTLIB_EMBEDDED_SOURCES}
      GYB_SOURCES ${SWIFTLIB_EMBEDDED_GYB_SOURCES}
      SWIFT_COMPILE_FLAGS
        ${swift_stdlib_compile_flags} -Xcc -D__MACH__ -Xcc -D__APPLE__ -Xcc -ffreestanding -enable-experimental-feature Embedded
        -Xfrontend -enable-ossa-modules
      MODULE_DIR "${CMAKE_BINARY_DIR}/lib/swift/embedded"
      SDK "embedded"
      ARCHITECTURE "${arch}"
      FILE_DEPENDS ${swiftCore_common_dependencies}
      INSTALL_IN_COMPONENT stdlib
      )
    add_dependencies(embedded-stdlib embedded-stdlib-${mod})
  endforeach()
endif()
