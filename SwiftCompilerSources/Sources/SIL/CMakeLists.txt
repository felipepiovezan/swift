# This source file is part of the Swift.org open source project
#
# Copyright (c) 2014 - 2021 Apple Inc. and the Swift project authors
# Licensed under Apache License v2.0 with Runtime Library Exception
#
# See http://swift.org/LICENSE.txt for license information
# See http://swift.org/CONTRIBUTORS.txt for Swift project authors

add_swift_compiler_module(SIL
  DEPENDS
    Basic
  SOURCES
    ApplySite.swift
    Argument.swift
    BasicBlock.swift
    Builder.swift
    Effects.swift
    ForwardingInstruction.swift
    Function.swift
    GlobalVariable.swift
    Instruction.swift
    Location.swift
    Operand.swift
    Registration.swift
    SmallProjectionPath.swift
    SubstitutionMap.swift
    Type.swift
    Utils.swift
    Value.swift
    VTable.swift
    WitnessTable.swift)
