//===--- Devirtualization.swift -------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import SIL

/// Devirtualizes all value-type deinitializers of a `destroy_value`.
///
/// This may be a no-op if the destroy doesn't call any deinitializers.
/// Returns true if all deinitializers could be devirtualized.
func devirtualizeDeinits(of destroy: DestroyValueInst, _ context: some MutatingContext) -> Bool {
  return devirtualize(destroy: destroy, context)
}

/// Devirtualizes all value-type deinitializers of a `destroy_addr`.
///
/// This may be a no-op if the destroy doesn't call any deinitializers.
/// Returns true if all deinitializers could be devirtualized.
func devirtualizeDeinits(of destroy: DestroyAddrInst, _ context: some MutatingContext) -> Bool {
  return devirtualize(destroy: destroy, context)
}

private func devirtualize(destroy: some DevirtualizableDestroy, _ context: some MutatingContext) -> Bool {
  let type = destroy.type
  guard type.isMoveOnly && type.selfOrAnyFieldHasValueDeinit(in: destroy.parentFunction) else {
    return true
  }
  precondition(type.isNominal, "non-copyable non-nominal types not supported, yet")

  let result: Bool
  if type.nominal.hasValueDeinit && !destroy.hasDropDeinit {
    guard let deinitFunc = context.lookupDeinit(ofNominal: type.nominal) else {
      return false
    }
    destroy.createDeinitCall(to: deinitFunc, context)
    result = true
  } else {
    // If there is no deinit to be called for the original type we have to recursively visit
    // the struct fields or enum cases.
    if type.isStruct {
      result = destroy.devirtualizeStructFields(context)
    } else {
      precondition(type.isEnum, "unknown nominal value type")
      result = destroy.devirtualizeEnumPayloads(context)
    }
  }
  context.erase(instruction: destroy)
  return result
}

// Used to dispatch devirtualization tasks to `destroy_value` and `destroy_addr`.
private protocol DevirtualizableDestroy : UnaryInstruction {
  func createDeinitCall(to deinitializer: Function, _ context: some MutatingContext)
  func devirtualizeStructFields(_ context: some MutatingContext) -> Bool
  func devirtualizeEnumPayload(enumCase: EnumCase, in block: BasicBlock, _ context: some MutatingContext) -> Bool
  func createSwitchEnum(atEndOf block: BasicBlock, cases: [(Int, BasicBlock)], _ context: some MutatingContext)
}

private extension DevirtualizableDestroy {
  var type: Type { operand.value.type }

  var hasDropDeinit: Bool { operand.value.lookThoughOwnershipInstructions is DropDeinitInst }

  func devirtualizeEnumPayloads(_ context: some MutatingContext) -> Bool {
    guard let cases = type.getEnumCases(in: parentFunction) else {
      return false
    }
    if cases.allPayloadsAreTrivial(in: parentFunction) {
      let builder = Builder(before: self, context)
      builder.createEndLifetime(of: operand.value)
      return true
    }

    var caseBlocks: [(caseIndex: Int, targetBlock: BasicBlock)] = []
    let switchBlock = parentBlock
    let endBlock = context.splitBlock(before: self)
    var result = true

    for enumCase in cases {
      let caseBlock = context.createBlock(after: switchBlock)
      caseBlocks.append((enumCase.index, caseBlock))
      let builder = Builder(atEndOf: caseBlock, location: location, context)
      builder.createBranch(to: endBlock)
      if !devirtualizeEnumPayload(enumCase: enumCase, in: caseBlock, context) {
        result = false
      }
    }
    createSwitchEnum(atEndOf: switchBlock, cases: caseBlocks, context)
    return result
  }
}

extension DestroyValueInst : DevirtualizableDestroy {
  fileprivate func createDeinitCall(to deinitializer: Function, _ context: some MutatingContext) {
    let builder = Builder(before: self, context)
    let subs = context.getContextSubstitutionMap(for: type)
    let deinitRef = builder.createFunctionRef(deinitializer)
    if deinitializer.getArgumentConvention(for: deinitializer.selfArgumentIndex).isIndirect {
      let allocStack = builder.createAllocStack(type)
      builder.createStore(source: destroyedValue, destination: allocStack, ownership: .initialize)
      builder.createApply(function: deinitRef, subs, arguments: [allocStack])
      builder.createDeallocStack(allocStack)
    } else {
      builder.createApply(function: deinitRef, subs, arguments: [destroyedValue])
    }
  }

  fileprivate func devirtualizeStructFields(_ context: some MutatingContext) -> Bool {
    let builder = Builder(before: self, context)

    guard let fields = type.getNominalFields(in: parentFunction) else {
      return false
    }
    if fields.allFieldsAreTrivial(in: parentFunction) {
      builder.createEndLifetime(of: operand.value)
      return true
    }
    let destructure = builder.createDestructureStruct(struct: destroyedValue)
    var result = true

    for fieldValue in destructure.results where !fieldValue.type.isTrivial(in: parentFunction) {
      let destroyField = builder.createDestroyValue(operand: fieldValue)
      if !devirtualizeDeinits(of: destroyField, context) {
        result = false
      }
    }
    return result
  }

  fileprivate func devirtualizeEnumPayload(
    enumCase: EnumCase,
    in block: BasicBlock,
    _ context: some MutatingContext
  ) -> Bool {
    let builder = Builder(atBeginOf: block, location: location, context)
    if let payloadTy = enumCase.payload {
      let payload = block.addArgument(type: payloadTy, ownership: .owned, context)
      if !payloadTy.isTrivial(in: parentFunction) {
        let destroyPayload = builder.createDestroyValue(operand: payload)
        return devirtualizeDeinits(of: destroyPayload, context)
      }
    }
    return true
  }

  fileprivate func createSwitchEnum(
    atEndOf block: BasicBlock,
    cases: [(Int, BasicBlock)],
    _ context: some MutatingContext
  ) {
    let builder = Builder(atEndOf: block, location: location, context)
    builder.createSwitchEnum(enum: destroyedValue, cases: cases)
  }
}

extension DestroyAddrInst : DevirtualizableDestroy {
  fileprivate func createDeinitCall(to deinitializer: Function, _ context: some MutatingContext) {
    let builder = Builder(before: self, context)
    let subs = context.getContextSubstitutionMap(for: destroyedAddress.type)
    let deinitRef = builder.createFunctionRef(deinitializer)
    if !deinitializer.getArgumentConvention(for: deinitializer.selfArgumentIndex).isIndirect {
      let value = builder.createLoad(fromAddress: destroyedAddress, ownership: .take)
      builder.createApply(function: deinitRef, subs, arguments: [value])
    } else {
      builder.createApply(function: deinitRef, subs, arguments: [destroyedAddress])
    }
  }

  fileprivate func devirtualizeStructFields(_ context: some MutatingContext) -> Bool {
    let builder = Builder(before: self, context)

    guard let fields = type.getNominalFields(in: parentFunction) else {
      return false
    }
    if fields.allFieldsAreTrivial(in: parentFunction) {
      builder.createEndLifetime(of: operand.value)
      return true
    }
    var result = true
    for (fieldIdx, fieldTy) in fields.enumerated()
      where !fieldTy.isTrivial(in: parentFunction)
    {
      let fieldAddr = builder.createStructElementAddr(structAddress: destroyedAddress, fieldIndex: fieldIdx)
      let destroyField = builder.createDestroyAddr(address: fieldAddr)
      if !devirtualizeDeinits(of: destroyField, context) {
        result = false
      }
    }
    return result
  }

  fileprivate func devirtualizeEnumPayload(
    enumCase: EnumCase,
    in block: BasicBlock,
    _ context: some MutatingContext
  ) -> Bool {
    let builder = Builder(atBeginOf: block, location: location, context)
    if let payloadTy = enumCase.payload,
       !payloadTy.isTrivial(in: parentFunction)
    {
      let caseAddr = builder.createUncheckedTakeEnumDataAddr(enumAddress: destroyedAddress, caseIndex: enumCase.index)
      let destroyPayload = builder.createDestroyAddr(address: caseAddr)
      return devirtualizeDeinits(of: destroyPayload, context)
    }
    return true
  }

  fileprivate func createSwitchEnum(
    atEndOf block: BasicBlock,
    cases: [(Int, BasicBlock)],
    _ context: some MutatingContext
  ) {
    let builder = Builder(atEndOf: block, location: location, context)
    builder.createSwitchEnumAddr(enumAddress: destroyedAddress, cases: cases)
  }
}

private extension EnumCases {
  func allPayloadsAreTrivial(in function: Function) -> Bool {
    allSatisfy({ $0.payload?.isTrivial(in: function) ?? true })
  }
}

private extension NominalFieldsArray {
  func allFieldsAreTrivial(in function: Function) -> Bool {
    allSatisfy({ $0.isTrivial(in: function)})
  }
}
