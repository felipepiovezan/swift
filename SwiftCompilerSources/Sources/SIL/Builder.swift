//===--- Builder.swift -  Building and modifying SIL ----------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Basic
import SILBridging

/// A utility to create new instructions at a given insertion point.
public struct Builder {

  public enum InsertionPoint {
    case before(Instruction)
    case atEndOf(BasicBlock)
    case staticInitializer(GlobalVariable)
  }

  let insertAt: InsertionPoint
  let location: Location
  private let notificationHandler: BridgedChangeNotificationHandler
  private let notifyNewInstruction: (Instruction) -> ()

  public var bridged: BridgedBuilder {
    switch insertAt {
    case .before(let inst):
      return BridgedBuilder(insertAt: .beforeInst, insertionObj: inst.bridged.obj,
                            loc: location.bridged)
    case .atEndOf(let block):
      return BridgedBuilder(insertAt: .endOfBlock, insertionObj: block.bridged.obj,
                            loc: location.bridged)
    case .staticInitializer(let global):
      return BridgedBuilder(insertAt: .intoGlobal, insertionObj: global.bridged.obj,
                            loc: location.bridged)
    }
  }

  private func notifyNew<I: Instruction>(_ instruction: I) -> I {
    notificationHandler.notifyChanges(.instructionsChanged)
    if instruction is FullApplySite {
      notificationHandler.notifyChanges(.callsChanged)
    }
    if instruction is TermInst {
      notificationHandler.notifyChanges(.branchesChanged)
    }
    notifyNewInstruction(instruction)
    return instruction
  }

  public init(insertAt: InsertionPoint, location: Location,
              _ notifyNewInstruction: @escaping (Instruction) -> (),
              _ notificationHandler: BridgedChangeNotificationHandler) {
    self.insertAt = insertAt
    self.location = location;
    self.notifyNewInstruction = notifyNewInstruction
    self.notificationHandler = notificationHandler
  }

  public func createBuiltinBinaryFunction(name: String,
      operandType: Type, resultType: Type, arguments: [Value]) -> BuiltinInst {
    return arguments.withBridgedValues { valuesRef in
      return name._withBridgedStringRef { nameStr in
        let bi = bridged.createBuiltinBinaryFunction(
          nameStr, operandType.bridged, resultType.bridged, valuesRef)
        return notifyNew(bi.getAs(BuiltinInst.self))
      }
    }
  }

  public func createCondFail(condition: Value, message: String) -> CondFailInst {
    return message._withBridgedStringRef { messageStr in
      let cf = bridged.createCondFail(condition.bridged, messageStr)
      return notifyNew(cf.getAs(CondFailInst.self))
    }
  }

  public func createIntegerLiteral(_ value: Int, type: Type) -> IntegerLiteralInst {
    let literal = bridged.createIntegerLiteral(type.bridged, value)
    return notifyNew(literal.getAs(IntegerLiteralInst.self))
  }

  public func createAllocStack(_ type: Type, hasDynamicLifetime: Bool = false,
                               isLexical: Bool = false, usesMoveableValueDebugInfo: Bool = false) -> AllocStackInst {
    let dr = bridged.createAllocStack(type.bridged, hasDynamicLifetime, isLexical, usesMoveableValueDebugInfo)
    return notifyNew(dr.getAs(AllocStackInst.self))
  }

  @discardableResult
  public func createDeallocStack(_ operand: Value) -> DeallocStackInst {
    let dr = bridged.createDeallocStack(operand.bridged)
    return notifyNew(dr.getAs(DeallocStackInst.self))
  }

  @discardableResult
  public func createDeallocStackRef(_ operand: Value) -> DeallocStackRefInst {
    let dr = bridged.createDeallocStackRef(operand.bridged)
    return notifyNew(dr.getAs(DeallocStackRefInst.self))
  }

  public func createUncheckedRefCast(from value: Value, to type: Type) -> UncheckedRefCastInst {
    let cast = bridged.createUncheckedRefCast(value.bridged, type.bridged)
    return notifyNew(cast.getAs(UncheckedRefCastInst.self))
  }

  public func createUpcast(from value: Value, to type: Type) -> UpcastInst {
    let cast = bridged.createUpcast(value.bridged, type.bridged)
    return notifyNew(cast.getAs(UpcastInst.self))
  }

  public func createLoad(fromAddress: Value, ownership: LoadInst.LoadOwnership) -> LoadInst {
    let load = bridged.createLoad(fromAddress.bridged, ownership.rawValue)
    return notifyNew(load.getAs(LoadInst.self))
  }

  public func createBeginDeallocRef(reference: Value, allocation: AllocRefInstBase) -> BeginDeallocRefInst {
    let beginDealloc = bridged.createBeginDeallocRef(reference.bridged, allocation.bridged)
    return notifyNew(beginDealloc.getAs(BeginDeallocRefInst.self))
  }

  public func createEndInitLetRef(operand: Value) -> EndInitLetRefInst {
    let endInit = bridged.createEndInitLetRef(operand.bridged)
    return notifyNew(endInit.getAs(EndInitLetRefInst.self))
  }

  @discardableResult
  public func createStrongRetain(operand: Value) -> StrongRetainInst {
    let retain = bridged.createStrongRetain(operand.bridged)
    return notifyNew(retain.getAs(StrongRetainInst.self))
  }

  @discardableResult
  public func createStrongRelease(operand: Value) -> StrongReleaseInst {
    let release = bridged.createStrongRelease(operand.bridged)
    return notifyNew(release.getAs(StrongReleaseInst.self))
  }

  @discardableResult
  public func createUnownedRetain(operand: Value) -> UnownedRetainInst {
    let retain = bridged.createUnownedRetain(operand.bridged)
    return notifyNew(retain.getAs(UnownedRetainInst.self))
  }

  @discardableResult
  public func createUnownedRelease(operand: Value) -> UnownedReleaseInst {
    let release = bridged.createUnownedRelease(operand.bridged)
    return notifyNew(release.getAs(UnownedReleaseInst.self))
  }

  public func createFunctionRef(_ function: Function) -> FunctionRefInst {
    let functionRef = bridged.createFunctionRef(function.bridged)
    return notifyNew(functionRef.getAs(FunctionRefInst.self))
  }

  public func createCopyValue(operand: Value) -> CopyValueInst {
    return notifyNew(bridged.createCopyValue(operand.bridged).getAs(CopyValueInst.self))
  }

  public func createBeginBorrow(of value: Value) -> BeginBorrowInst {
    return notifyNew(bridged.createBeginBorrow(value.bridged).getAs(BeginBorrowInst.self))
  }

  @discardableResult
  public func createEndBorrow(of beginBorrow: Value) -> EndBorrowInst {
    return notifyNew(bridged.createEndBorrow(beginBorrow.bridged).getAs(EndBorrowInst.self))
  }

  @discardableResult
  public func createCopyAddr(from fromAddr: Value, to toAddr: Value,
                             takeSource: Bool = false, initializeDest: Bool = false) -> CopyAddrInst {
    return notifyNew(bridged.createCopyAddr(fromAddr.bridged, toAddr.bridged,
                                            takeSource, initializeDest).getAs(CopyAddrInst.self))
  }

  @discardableResult
  public func createDestroyValue(operand: Value) -> DestroyValueInst {
    return notifyNew(bridged.createDestroyValue(operand.bridged).getAs(DestroyValueInst.self))
  }

  @discardableResult
  public func createDestroyAddr(address: Value) -> DestroyAddrInst {
    return notifyNew(bridged.createDestroyAddr(address.bridged).getAs(DestroyAddrInst.self))
  }

  @discardableResult
  public func createEndLifetime(of value: Value) -> EndLifetimeInst {
    return notifyNew(bridged.createEndLifetime(value.bridged).getAs(EndLifetimeInst.self))
  }

  @discardableResult
  public func createDebugStep() -> DebugStepInst {
    return notifyNew(bridged.createDebugStep().getAs(DebugStepInst.self))
  }

  @discardableResult
  public func createApply(
    function: Value,
    _ substitutionMap: SubstitutionMap,
    arguments: [Value],
    isNonThrowing: Bool = false,
    isNonAsync: Bool = false,
    specializationInfo: ApplyInst.SpecializationInfo = ApplyInst.SpecializationInfo()
  ) -> ApplyInst {
    let apply = arguments.withBridgedValues { valuesRef in
      bridged.createApply(function.bridged, substitutionMap.bridged, valuesRef,
                          isNonThrowing, isNonAsync, specializationInfo)
    }
    return notifyNew(apply.getAs(ApplyInst.self))
  }
  
  public func createUncheckedEnumData(enum enumVal: Value,
                                      caseIndex: Int,
                                      resultType: Type) -> UncheckedEnumDataInst {
    let ued = bridged.createUncheckedEnumData(enumVal.bridged, caseIndex, resultType.bridged)
    return notifyNew(ued.getAs(UncheckedEnumDataInst.self))
  }

  public func createUncheckedTakeEnumDataAddr(enumAddress: Value,
                                              caseIndex: Int) -> UncheckedTakeEnumDataAddrInst {
    let uteda = bridged.createUncheckedTakeEnumDataAddr(enumAddress.bridged, caseIndex)
    return notifyNew(uteda.getAs(UncheckedTakeEnumDataAddrInst.self))
  }

  public func createEnum(caseIndex: Int, payload: Value?, enumType: Type) -> EnumInst {
    let enumInst = bridged.createEnum(caseIndex, payload.bridged, enumType.bridged)
    return notifyNew(enumInst.getAs(EnumInst.self))
  }

  public func createThinToThickFunction(thinFunction: Value, resultType: Type) -> ThinToThickFunctionInst {
    let tttf = bridged.createThinToThickFunction(thinFunction.bridged, resultType.bridged)
    return notifyNew(tttf.getAs(ThinToThickFunctionInst.self))
  }

  @discardableResult
  public func createSwitchEnum(enum enumVal: Value,
                               cases: [(Int, BasicBlock)],
                               defaultBlock: BasicBlock? = nil) -> SwitchEnumInst {
    let se = cases.withUnsafeBufferPointer { caseBuffer in
      bridged.createSwitchEnumInst(enumVal.bridged, defaultBlock.bridged,
                                   caseBuffer.baseAddress, caseBuffer.count)
    }
    return notifyNew(se.getAs(SwitchEnumInst.self))
  }
  
  @discardableResult
  public func createSwitchEnumAddr(enumAddress: Value,
                                   cases: [(Int, BasicBlock)],
                                   defaultBlock: BasicBlock? = nil) -> SwitchEnumAddrInst {
    let se = cases.withUnsafeBufferPointer { caseBuffer in
      bridged.createSwitchEnumAddrInst(enumAddress.bridged, defaultBlock.bridged,
                                       caseBuffer.baseAddress, caseBuffer.count)
    }
    return notifyNew(se.getAs(SwitchEnumAddrInst.self))
  }

  @discardableResult
  public func createBranch(to destBlock: BasicBlock, arguments: [Value] = []) -> BranchInst {
    return arguments.withBridgedValues { valuesRef in
      let bi = bridged.createBranch(destBlock.bridged, valuesRef)
      return notifyNew(bi.getAs(BranchInst.self))
    }
  }

  @discardableResult
  public func createUnreachable() -> UnreachableInst {
    let ui = bridged.createUnreachable()
    return notifyNew(ui.getAs(UnreachableInst.self))
  }

  @discardableResult
  public func createObject(type: Type, arguments: [Value], numBaseElements: Int) -> ObjectInst {
    let objectInst = arguments.withBridgedValues { valuesRef in
      return bridged.createObject(type.bridged, valuesRef, numBaseElements)
    }
    return notifyNew(objectInst.getAs(ObjectInst.self))
  }

  public func createGlobalAddr(global: GlobalVariable) -> GlobalAddrInst {
    return notifyNew(bridged.createGlobalAddr(global.bridged).getAs(GlobalAddrInst.self))
  }

  public func createGlobalValue(global: GlobalVariable, isBare: Bool) -> GlobalValueInst {
    return notifyNew(bridged.createGlobalValue(global.bridged, isBare).getAs(GlobalValueInst.self))
  }

  public func createStruct(type: Type, elements: [Value]) -> StructInst {
    let structInst = elements.withBridgedValues { valuesRef in
      return bridged.createStruct(type.bridged, valuesRef)
    }
    return notifyNew(structInst.getAs(StructInst.self))
  }

  public func createStructExtract(struct: Value, fieldIndex: Int) -> StructExtractInst {
    return notifyNew(bridged.createStructExtract(`struct`.bridged, fieldIndex).getAs(StructExtractInst.self))
  }

  public func createStructElementAddr(structAddress: Value, fieldIndex: Int) -> StructElementAddrInst {
    return notifyNew(bridged.createStructElementAddr(structAddress.bridged, fieldIndex).getAs(StructElementAddrInst.self))
  }

  public func createDestructureStruct(struct: Value) -> DestructureStructInst {
    return notifyNew(bridged.createDestructureStruct(`struct`.bridged).getAs(DestructureStructInst.self))
  }

  public func createTuple(type: Type, elements: [Value]) -> TupleInst {
    let tuple = elements.withBridgedValues { valuesRef in
      return bridged.createTuple(type.bridged, valuesRef)
    }
    return notifyNew(tuple.getAs(TupleInst.self))
  }

  public func createTupleExtract(tuple: Value, elementIndex: Int) -> TupleExtractInst {
    return notifyNew(bridged.createTupleExtract(tuple.bridged, elementIndex).getAs(TupleExtractInst.self))
  }

  public func createTupleElementAddr(tupleAddress: Value, elementIndex: Int) -> TupleElementAddrInst {
    return notifyNew(bridged.createTupleElementAddr(tupleAddress.bridged, elementIndex).getAs(TupleElementAddrInst.self))
  }

  public func createDestructureTuple(tuple: Value) -> DestructureTupleInst {
    return notifyNew(bridged.createDestructureTuple(tuple.bridged).getAs(DestructureTupleInst.self))
  }

  @discardableResult
  public func createStore(source: Value, destination: Value, ownership: StoreInst.StoreOwnership) -> StoreInst {
    let store = bridged.createStore(source.bridged, destination.bridged, ownership.rawValue)
    return notifyNew(store.getAs(StoreInst.self))
  }

  public func createInitExistentialRef(instance: Value,
                                       existentialType: Type,
                                       useConformancesOf: InitExistentialRefInst) -> InitExistentialRefInst {
    let initExistential = bridged.createInitExistentialRef(instance.bridged,
                                                           existentialType.bridged,
                                                           useConformancesOf.bridged)
    return notifyNew(initExistential.getAs(InitExistentialRefInst.self))
  }

  public func createMetatype(of type: Type, representation: Type.MetatypeRepresentation) -> MetatypeInst {
    let metatype = bridged.createMetatype(type.bridged, representation)
    return notifyNew(metatype.getAs(MetatypeInst.self))
  }

  public func createEndCOWMutation(instance: Value, keepUnique: Bool = false) -> EndCOWMutationInst {
    let endMutation = bridged.createEndCOWMutation(instance.bridged, keepUnique)
    return notifyNew(endMutation.getAs(EndCOWMutationInst.self))
  }
}
