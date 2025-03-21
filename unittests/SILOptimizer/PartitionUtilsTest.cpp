//===--- PartitionUtilsTest.cpp -------------------------------------------===//
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

#include "swift/SILOptimizer/Utils/PartitionUtils.h"

#include "gtest/gtest.h"

#include <array>

using namespace swift;
using namespace swift::PartitionPrimitives;

//===----------------------------------------------------------------------===//
//                                 Utilities
//===----------------------------------------------------------------------===//

struct Partition::PartitionTester {
  const Partition &p;

  PartitionTester(const Partition &p) : p(p) {}

  unsigned getRegion(unsigned elt) const {
    return unsigned(p.elementToRegionMap.at(Element(elt)));
  }
};

namespace {
using PartitionTester = Partition::PartitionTester;
} // namespace

//===----------------------------------------------------------------------===//
//                                   Tests
//===----------------------------------------------------------------------===//

// When we transfer we need a specific transfer instruction. We do not ever
// actually dereference the instruction, so just use some invalid ptr values so
// we can compare.
Operand *transferSingletons[5] = {
    (Operand *)0xDEAD0000, (Operand *)0xFEAD0000, (Operand *)0xAEDF0000,
    (Operand *)0xFEDA0000, (Operand *)0xFBDA0000,
};

SILInstruction *instSingletons[5] = {
    (SILInstruction *)0xBEAD0000, (SILInstruction *)0xBEAD0000,
    (SILInstruction *)0xBEDF0000, (SILInstruction *)0xBEDA0000,
    (SILInstruction *)0xBBDA0000,
};

// This test tests that if a series of merges is split between two partitions
// p1 and p2, but also applied in its entirety to p3, then joining p1 and p2
// yields p3.
TEST(PartitionUtilsTest, TestMergeAndJoin) {
  Partition p1;
  Partition p2;
  Partition p3;

  {
    PartitionOpEvaluator eval(p1);
    eval.apply({PartitionOp::AssignFresh(Element(0)),
                PartitionOp::AssignFresh(Element(1)),
                PartitionOp::AssignFresh(Element(2)),
                PartitionOp::AssignFresh(Element(3))});
  }

  {
    PartitionOpEvaluator eval(p2);
    eval.apply({PartitionOp::AssignFresh(Element(5)),
                PartitionOp::AssignFresh(Element(6)),
                PartitionOp::AssignFresh(Element(7)),
                PartitionOp::AssignFresh(Element(0))});
  }

  {
    PartitionOpEvaluator eval(p3);
    eval.apply({PartitionOp::AssignFresh(Element(2)),
                PartitionOp::AssignFresh(Element(3)),
                PartitionOp::AssignFresh(Element(4)),
                PartitionOp::AssignFresh(Element(5))});
  }

  EXPECT_FALSE(Partition::equals(p1, p2));
  EXPECT_FALSE(Partition::equals(p2, p3));
  EXPECT_FALSE(Partition::equals(p1, p3));

  {
    PartitionOpEvaluator eval(p1);
    eval.apply({PartitionOp::AssignFresh(Element(4)),
                PartitionOp::AssignFresh(Element(5)),
                PartitionOp::AssignFresh(Element(6)),
                PartitionOp::AssignFresh(Element(7)),
                PartitionOp::AssignFresh(Element(8))});
  }

  {
    PartitionOpEvaluator eval(p2);
    eval.apply({PartitionOp::AssignFresh(Element(1)),
                PartitionOp::AssignFresh(Element(2)),
                PartitionOp::AssignFresh(Element(3)),
                PartitionOp::AssignFresh(Element(4)),
                PartitionOp::AssignFresh(Element(8))});
  }

  {
    PartitionOpEvaluator eval(p3);
    eval.apply({PartitionOp::AssignFresh(Element(6)),
                PartitionOp::AssignFresh(Element(7)),
                PartitionOp::AssignFresh(Element(0)),
                PartitionOp::AssignFresh(Element(1)),
                PartitionOp::AssignFresh(Element(8))});
  }

  EXPECT_TRUE(Partition::equals(p1, p2));
  EXPECT_TRUE(Partition::equals(p2, p3));
  EXPECT_TRUE(Partition::equals(p1, p3));

  auto expect_join_eq = [&]() {
    Partition joined = Partition::join(p1, p2);
    EXPECT_TRUE(Partition::equals(p3, joined));
  };

  auto apply_to_p1_and_p3 = [&](PartitionOp op) {
    {
      PartitionOpEvaluator eval(p1);
      eval.apply(op);
    }

    {
      PartitionOpEvaluator eval(p3);
      eval.apply(op);
    }
    expect_join_eq();
  };

  auto apply_to_p2_and_p3 = [&](PartitionOp op) {
    {
      PartitionOpEvaluator eval(p2);
      eval.apply(op);
    }

    {
      PartitionOpEvaluator eval(p3);
      eval.apply(op);
    }
    expect_join_eq();
  };

  apply_to_p1_and_p3(PartitionOp::Merge(Element(1), Element(2)));
  apply_to_p2_and_p3(PartitionOp::Merge(Element(7), Element(8)));
  apply_to_p1_and_p3(PartitionOp::Merge(Element(2), Element(7)));
  apply_to_p2_and_p3(PartitionOp::Merge(Element(1), Element(3)));
  apply_to_p1_and_p3(PartitionOp::Merge(Element(3), Element(4)));

  EXPECT_FALSE(Partition::equals(p1, p2));
  EXPECT_FALSE(Partition::equals(p2, p3));
  EXPECT_FALSE(Partition::equals(p1, p3));

  apply_to_p2_and_p3(PartitionOp::Merge(Element(2), Element(5)));
  apply_to_p1_and_p3(PartitionOp::Merge(Element(5), Element(6)));
  apply_to_p2_and_p3(PartitionOp::Merge(Element(1), Element(6)));
  apply_to_p1_and_p3(PartitionOp::Merge(Element(2), Element(6)));
  apply_to_p2_and_p3(PartitionOp::Merge(Element(3), Element(7)));
  apply_to_p1_and_p3(PartitionOp::Merge(Element(7), Element(8)));
}

TEST(PartitionUtilsTest, Join1) {
  Element data1[] = {Element(0), Element(1), Element(2),
                     Element(3), Element(4), Element(5)};
  Partition p1 = Partition::separateRegions(llvm::makeArrayRef(data1));

  {
    PartitionOpEvaluator eval(p1);
    eval.apply({PartitionOp::Assign(Element(0), Element(0)),
                PartitionOp::Assign(Element(1), Element(0)),
                PartitionOp::Assign(Element(2), Element(2)),
                PartitionOp::Assign(Element(3), Element(3)),
                PartitionOp::Assign(Element(4), Element(3)),
                PartitionOp::Assign(Element(5), Element(2))});
  }

  Partition p2 = Partition::separateRegions(llvm::makeArrayRef(data1));
  {
    PartitionOpEvaluator eval(p2);
    eval.apply({PartitionOp::Assign(Element(0), Element(0)),
                PartitionOp::Assign(Element(1), Element(0)),
                PartitionOp::Assign(Element(2), Element(2)),
                PartitionOp::Assign(Element(3), Element(3)),
                PartitionOp::Assign(Element(4), Element(3)),
                PartitionOp::Assign(Element(5), Element(5))});
  }

  auto result = Partition::join(p1, p2);
  PartitionTester tester(result);
  ASSERT_EQ(tester.getRegion(0), 0);
  ASSERT_EQ(tester.getRegion(1), 0);
  ASSERT_EQ(tester.getRegion(2), 2);
  ASSERT_EQ(tester.getRegion(3), 3);
  ASSERT_EQ(tester.getRegion(4), 3);
  ASSERT_EQ(tester.getRegion(5), 2);
}

TEST(PartitionUtilsTest, Join2) {
  Element data1[] = {Element(0), Element(1), Element(2),
                     Element(3), Element(4), Element(5)};
  Partition p1 = Partition::separateRegions(llvm::makeArrayRef(data1));

  {
    PartitionOpEvaluator eval(p1);
    eval.apply({PartitionOp::Assign(Element(0), Element(0)),
                PartitionOp::Assign(Element(1), Element(0)),
                PartitionOp::Assign(Element(2), Element(2)),
                PartitionOp::Assign(Element(3), Element(3)),
                PartitionOp::Assign(Element(4), Element(3)),
                PartitionOp::Assign(Element(5), Element(2))});
  }

  Element data2[] = {Element(4), Element(5), Element(6),
                     Element(7), Element(8), Element(9)};
  Partition p2 = Partition::separateRegions(llvm::makeArrayRef(data2));
  {
    PartitionOpEvaluator eval(p2);
    eval.apply({PartitionOp::Assign(Element(4), Element(4)),
                PartitionOp::Assign(Element(5), Element(5)),
                PartitionOp::Assign(Element(6), Element(4)),
                PartitionOp::Assign(Element(7), Element(7)),
                PartitionOp::Assign(Element(8), Element(7)),
                PartitionOp::Assign(Element(9), Element(4))});
  }

  auto result = Partition::join(p1, p2);
  PartitionTester tester(result);
  ASSERT_EQ(tester.getRegion(0), 0);
  ASSERT_EQ(tester.getRegion(1), 0);
  ASSERT_EQ(tester.getRegion(2), 2);
  ASSERT_EQ(tester.getRegion(3), 3);
  ASSERT_EQ(tester.getRegion(4), 3);
  ASSERT_EQ(tester.getRegion(5), 2);
  ASSERT_EQ(tester.getRegion(6), 3);
  ASSERT_EQ(tester.getRegion(7), 7);
  ASSERT_EQ(tester.getRegion(8), 7);
  ASSERT_EQ(tester.getRegion(9), 3);
}

TEST(PartitionUtilsTest, Join2Reversed) {
  Element data1[] = {Element(0), Element(1), Element(2),
                     Element(3), Element(4), Element(5)};
  Partition p1 = Partition::separateRegions(llvm::makeArrayRef(data1));

  {
    PartitionOpEvaluator eval(p1);
    eval.apply({PartitionOp::Assign(Element(0), Element(0)),
                PartitionOp::Assign(Element(1), Element(0)),
                PartitionOp::Assign(Element(2), Element(2)),
                PartitionOp::Assign(Element(3), Element(3)),
                PartitionOp::Assign(Element(4), Element(3)),
                PartitionOp::Assign(Element(5), Element(2))});
  }

  Element data2[] = {Element(4), Element(5), Element(6),
                     Element(7), Element(8), Element(9)};
  Partition p2 = Partition::separateRegions(llvm::makeArrayRef(data2));
  {
    PartitionOpEvaluator eval(p2);
    eval.apply({PartitionOp::Assign(Element(4), Element(4)),
                PartitionOp::Assign(Element(5), Element(5)),
                PartitionOp::Assign(Element(6), Element(4)),
                PartitionOp::Assign(Element(7), Element(7)),
                PartitionOp::Assign(Element(8), Element(7)),
                PartitionOp::Assign(Element(9), Element(4))});
  }

  auto result = Partition::join(p2, p1);
  PartitionTester tester(result);
  ASSERT_EQ(tester.getRegion(0), 0);
  ASSERT_EQ(tester.getRegion(1), 0);
  ASSERT_EQ(tester.getRegion(2), 2);
  ASSERT_EQ(tester.getRegion(3), 3);
  ASSERT_EQ(tester.getRegion(4), 3);
  ASSERT_EQ(tester.getRegion(5), 2);
  ASSERT_EQ(tester.getRegion(6), 3);
  ASSERT_EQ(tester.getRegion(7), 7);
  ASSERT_EQ(tester.getRegion(8), 7);
  ASSERT_EQ(tester.getRegion(9), 3);
}

TEST(PartitionUtilsTest, JoinLarge) {
  Element data1[] = {
      Element(0),  Element(1),  Element(2),  Element(3),  Element(4),
      Element(5),  Element(6),  Element(7),  Element(8),  Element(9),
      Element(10), Element(11), Element(12), Element(13), Element(14),
      Element(15), Element(16), Element(17), Element(18), Element(19),
      Element(20), Element(21), Element(22), Element(23), Element(24),
      Element(25), Element(26), Element(27), Element(28), Element(29)};
  Partition p1 = Partition::separateRegions(llvm::makeArrayRef(data1));
  {
    PartitionOpEvaluator eval(p1);
    eval.apply({PartitionOp::Assign(Element(0), Element(29)),
                PartitionOp::Assign(Element(1), Element(17)),
                PartitionOp::Assign(Element(2), Element(0)),
                PartitionOp::Assign(Element(3), Element(12)),
                PartitionOp::Assign(Element(4), Element(13)),
                PartitionOp::Assign(Element(5), Element(9)),
                PartitionOp::Assign(Element(6), Element(15)),
                PartitionOp::Assign(Element(7), Element(27)),
                PartitionOp::Assign(Element(8), Element(3)),
                PartitionOp::Assign(Element(9), Element(3)),
                PartitionOp::Assign(Element(10), Element(3)),
                PartitionOp::Assign(Element(11), Element(21)),
                PartitionOp::Assign(Element(12), Element(14)),
                PartitionOp::Assign(Element(13), Element(25)),
                PartitionOp::Assign(Element(14), Element(1)),
                PartitionOp::Assign(Element(15), Element(25)),
                PartitionOp::Assign(Element(16), Element(12)),
                PartitionOp::Assign(Element(17), Element(3)),
                PartitionOp::Assign(Element(18), Element(25)),
                PartitionOp::Assign(Element(19), Element(13)),
                PartitionOp::Assign(Element(20), Element(19)),
                PartitionOp::Assign(Element(21), Element(7)),
                PartitionOp::Assign(Element(22), Element(19)),
                PartitionOp::Assign(Element(23), Element(27)),
                PartitionOp::Assign(Element(24), Element(1)),
                PartitionOp::Assign(Element(25), Element(9)),
                PartitionOp::Assign(Element(26), Element(18)),
                PartitionOp::Assign(Element(27), Element(29)),
                PartitionOp::Assign(Element(28), Element(28)),
                PartitionOp::Assign(Element(29), Element(13))});
  }

  Element data2[] = {
      Element(15), Element(16), Element(17), Element(18), Element(19),
      Element(20), Element(21), Element(22), Element(23), Element(24),
      Element(25), Element(26), Element(27), Element(28), Element(29),
      Element(30), Element(31), Element(32), Element(33), Element(34),
      Element(35), Element(36), Element(37), Element(38), Element(39),
      Element(40), Element(41), Element(42), Element(43), Element(44)};
  Partition p2 = Partition::separateRegions(llvm::makeArrayRef(data2));
  {
    PartitionOpEvaluator eval(p2);
    eval.apply({PartitionOp::Assign(Element(15), Element(31)),
                PartitionOp::Assign(Element(16), Element(34)),
                PartitionOp::Assign(Element(17), Element(35)),
                PartitionOp::Assign(Element(18), Element(41)),
                PartitionOp::Assign(Element(19), Element(15)),
                PartitionOp::Assign(Element(20), Element(32)),
                PartitionOp::Assign(Element(21), Element(17)),
                PartitionOp::Assign(Element(22), Element(31)),
                PartitionOp::Assign(Element(23), Element(21)),
                PartitionOp::Assign(Element(24), Element(33)),
                PartitionOp::Assign(Element(25), Element(25)),
                PartitionOp::Assign(Element(26), Element(31)),
                PartitionOp::Assign(Element(27), Element(16)),
                PartitionOp::Assign(Element(28), Element(35)),
                PartitionOp::Assign(Element(29), Element(40)),
                PartitionOp::Assign(Element(30), Element(33)),
                PartitionOp::Assign(Element(31), Element(34)),
                PartitionOp::Assign(Element(32), Element(22)),
                PartitionOp::Assign(Element(33), Element(42)),
                PartitionOp::Assign(Element(34), Element(37)),
                PartitionOp::Assign(Element(35), Element(34)),
                PartitionOp::Assign(Element(36), Element(18)),
                PartitionOp::Assign(Element(37), Element(32)),
                PartitionOp::Assign(Element(38), Element(22)),
                PartitionOp::Assign(Element(39), Element(44)),
                PartitionOp::Assign(Element(40), Element(20)),
                PartitionOp::Assign(Element(41), Element(37)),
                PartitionOp::Assign(Element(43), Element(29)),
                PartitionOp::Assign(Element(44), Element(25))});
  }

  auto result = Partition::join(p1, p2);
  PartitionTester tester(result);
  ASSERT_EQ(tester.getRegion(0), 0);
  ASSERT_EQ(tester.getRegion(1), 1);
  ASSERT_EQ(tester.getRegion(2), 0);
  ASSERT_EQ(tester.getRegion(3), 3);
  ASSERT_EQ(tester.getRegion(4), 4);
  ASSERT_EQ(tester.getRegion(5), 5);
  ASSERT_EQ(tester.getRegion(6), 6);
  ASSERT_EQ(tester.getRegion(7), 3);
  ASSERT_EQ(tester.getRegion(8), 3);
  ASSERT_EQ(tester.getRegion(9), 3);
  ASSERT_EQ(tester.getRegion(10), 3);
  ASSERT_EQ(tester.getRegion(11), 11);
  ASSERT_EQ(tester.getRegion(12), 0);
  ASSERT_EQ(tester.getRegion(13), 13);
  ASSERT_EQ(tester.getRegion(14), 1);
  ASSERT_EQ(tester.getRegion(15), 13);
  ASSERT_EQ(tester.getRegion(16), 0);
  ASSERT_EQ(tester.getRegion(17), 3);
  ASSERT_EQ(tester.getRegion(18), 13);
  ASSERT_EQ(tester.getRegion(19), 13);
  ASSERT_EQ(tester.getRegion(20), 13);
  ASSERT_EQ(tester.getRegion(21), 3);
  ASSERT_EQ(tester.getRegion(22), 13);
  ASSERT_EQ(tester.getRegion(23), 3);
  ASSERT_EQ(tester.getRegion(24), 1);
  ASSERT_EQ(tester.getRegion(25), 3);
  ASSERT_EQ(tester.getRegion(26), 13);
  ASSERT_EQ(tester.getRegion(27), 0);
  ASSERT_EQ(tester.getRegion(28), 3);
  ASSERT_EQ(tester.getRegion(29), 13);
  ASSERT_EQ(tester.getRegion(30), 1);
  ASSERT_EQ(tester.getRegion(31), 0);
  ASSERT_EQ(tester.getRegion(32), 13);
  ASSERT_EQ(tester.getRegion(33), 33);
  ASSERT_EQ(tester.getRegion(34), 34);
  ASSERT_EQ(tester.getRegion(35), 34);
  ASSERT_EQ(tester.getRegion(36), 13);
  ASSERT_EQ(tester.getRegion(37), 13);
  ASSERT_EQ(tester.getRegion(38), 13);
  ASSERT_EQ(tester.getRegion(39), 39);
  ASSERT_EQ(tester.getRegion(40), 13);
  ASSERT_EQ(tester.getRegion(41), 13);
  ASSERT_EQ(tester.getRegion(42), 33);
  ASSERT_EQ(tester.getRegion(43), 13);
  ASSERT_EQ(tester.getRegion(44), 3);
}

// This test tests the semantics of assignment.
TEST(PartitionUtilsTest, TestAssign) {
  Partition p1;
  Partition p2;
  Partition p3;

  PartitionOpEvaluator evalP1(p1);
  evalP1.apply({PartitionOp::AssignFresh(Element(0)),
                PartitionOp::AssignFresh(Element(1)),
                PartitionOp::AssignFresh(Element(2)),
                PartitionOp::AssignFresh(Element(3))});

  PartitionOpEvaluator evalP2(p2);
  evalP2.apply({PartitionOp::AssignFresh(Element(0)),
                PartitionOp::AssignFresh(Element(1)),
                PartitionOp::AssignFresh(Element(2)),
                PartitionOp::AssignFresh(Element(3))});

  PartitionOpEvaluator evalP3(p3);
  evalP3.apply({PartitionOp::AssignFresh(Element(0)),
                PartitionOp::AssignFresh(Element(1)),
                PartitionOp::AssignFresh(Element(2)),
                PartitionOp::AssignFresh(Element(3))});

  // expected: p1: ((Element(0)) (Element(1)) (Element(2)) (Element(3))), p2:
  // ((Element(0)) (Element(1)) (Element(2)) (Element(3))), p3: ((Element(0))
  // (Element(1)) (Element(2)) (Element(3)))

  EXPECT_TRUE(Partition::equals(p1, p2));
  EXPECT_TRUE(Partition::equals(p2, p3));
  EXPECT_TRUE(Partition::equals(p1, p3));

  evalP1.apply(PartitionOp::Assign(Element(0), Element(1)));
  evalP2.apply(PartitionOp::Assign(Element(1), Element(0)));
  evalP3.apply(PartitionOp::Assign(Element(2), Element(1)));

  // expected: p1: ((0 1) (Element(2)) (Element(3))), p2: ((0 1) (Element(2))
  // (Element(3))), p3: ((Element(0)) (1 2) (Element(3)))

  EXPECT_TRUE(Partition::equals(p1, p2));
  EXPECT_FALSE(Partition::equals(p2, p3));
  EXPECT_FALSE(Partition::equals(p1, p3));

  evalP1.apply(PartitionOp::Assign(Element(2), Element(0)));
  evalP2.apply(PartitionOp::Assign(Element(2), Element(1)));
  evalP3.apply(PartitionOp::Assign(Element(0), Element(2)));

  // expected: p1: ((0 1 2) (Element(3))), p2: ((0 1 2) (Element(3))), p3: ((0 1
  // 2) (Element(3)))

  EXPECT_TRUE(Partition::equals(p1, p2));
  EXPECT_TRUE(Partition::equals(p2, p3));
  EXPECT_TRUE(Partition::equals(p1, p3));

  evalP1.apply(PartitionOp::Assign(Element(0), Element(3)));
  evalP2.apply(PartitionOp::Assign(Element(1), Element(3)));
  evalP3.apply(PartitionOp::Assign(Element(2), Element(3)));

  // expected: p1: ((1 2) (0 3)), p2: ((0 2) (1 3)), p3: ((0 1) (2 3))

  EXPECT_FALSE(Partition::equals(p1, p2));
  EXPECT_FALSE(Partition::equals(p2, p3));
  EXPECT_FALSE(Partition::equals(p1, p3));

  evalP1.apply(PartitionOp::Assign(Element(1), Element(0)));
  evalP2.apply(PartitionOp::Assign(Element(2), Element(1)));
  evalP3.apply(PartitionOp::Assign(Element(0), Element(2)));

  // expected: p1: ((Element(2)) (0 1 3)), p2: ((Element(0)) (1 2 3)), p3:
  // ((Element(1)) (0 2 3))

  EXPECT_FALSE(Partition::equals(p1, p2));
  EXPECT_FALSE(Partition::equals(p2, p3));
  EXPECT_FALSE(Partition::equals(p1, p3));

  evalP1.apply(PartitionOp::Assign(Element(2), Element(3)));
  evalP2.apply(PartitionOp::Assign(Element(0), Element(3)));
  evalP3.apply(PartitionOp::Assign(Element(1), Element(3)));

  // expected: p1: ((0 1 2 3)), p2: ((0 1 2 3)), p3: ((0 1 2 3))

  EXPECT_TRUE(Partition::equals(p1, p2));
  EXPECT_TRUE(Partition::equals(p2, p3));
  EXPECT_TRUE(Partition::equals(p1, p3));
}

// This test tests that consumption consumes entire regions as expected
TEST(PartitionUtilsTest, TestConsumeAndRequire) {
  Partition p;

  {
    PartitionOpEvaluator eval(p);
    eval.apply({PartitionOp::AssignFresh(Element(0)),
                PartitionOp::AssignFresh(Element(1)),
                PartitionOp::AssignFresh(Element(2)),
                PartitionOp::AssignFresh(Element(3)),
                PartitionOp::AssignFresh(Element(4)),
                PartitionOp::AssignFresh(Element(5)),
                PartitionOp::AssignFresh(Element(6)),
                PartitionOp::AssignFresh(Element(7)),
                PartitionOp::AssignFresh(Element(8)),
                PartitionOp::AssignFresh(Element(9)),
                PartitionOp::AssignFresh(Element(10)),
                PartitionOp::AssignFresh(Element(11)),

                PartitionOp::Assign(Element(1), Element(0)),
                PartitionOp::Assign(Element(2), Element(1)),

                PartitionOp::Assign(Element(4), Element(3)),
                PartitionOp::Assign(Element(5), Element(4)),

                PartitionOp::Assign(Element(7), Element(6)),
                PartitionOp::Assign(Element(9), Element(8)),

                // expected: p: ((0 1 2) (3 4 5) (6 7) (8 9) (Element(10))
                // (Element(11)))

                PartitionOp::Transfer(Element(2), transferSingletons[0]),
                PartitionOp::Transfer(Element(7), transferSingletons[1]),
                PartitionOp::Transfer(Element(10), transferSingletons[2])});
  }

  // expected: p: ({0 1 2 6 7 10} (3 4 5) (8 9) (Element(11)))

  auto never_called = [](const PartitionOp &, unsigned, Operand *) {
    EXPECT_TRUE(false);
  };

  int times_called = 0;
  auto increment_times_called = [&](const PartitionOp &, unsigned, Operand *) {
    times_called++;
  };

  {
    PartitionOpEvaluator eval(p);
    eval.failureCallback = increment_times_called;
    eval.apply({PartitionOp::Require(Element(0)),
                PartitionOp::Require(Element(1)),
                PartitionOp::Require(Element(2))});
  }

  {
    PartitionOpEvaluator eval(p);
    eval.failureCallback = never_called;
    eval.apply({PartitionOp::Require(Element(3)),
                PartitionOp::Require(Element(4)),
                PartitionOp::Require(Element(5))});
  }

  {
    PartitionOpEvaluator eval(p);
    eval.failureCallback = increment_times_called;
    eval.apply(
        {PartitionOp::Require(Element(6)), PartitionOp::Require(Element(7))});
  }

  {
    PartitionOpEvaluator eval(p);
    eval.failureCallback = never_called;
    eval.apply(
        {PartitionOp::Require(Element(8)), PartitionOp::Require(Element(9))});
  }

  {
    PartitionOpEvaluator eval(p);
    eval.failureCallback = increment_times_called;
    eval.apply(PartitionOp::Require(Element(10)));
  }

  {
    PartitionOpEvaluator eval(p);
    eval.failureCallback = never_called;
    eval.apply(PartitionOp::Require(Element(11)));
  }

  EXPECT_TRUE(times_called == 6);
}

// This test tests that the copy constructor is usable to create fresh
// copies of partitions
TEST(PartitionUtilsTest, TestCopyConstructor) {
  Partition p1;
  {
    PartitionOpEvaluator eval(p1);
    eval.apply(PartitionOp::AssignFresh(Element(0)));
  }

  // Make copy.
  Partition p2 = p1;

  // Change p1 again.
  {
    PartitionOpEvaluator eval(p1);
    eval.apply(PartitionOp::Transfer(Element(0), transferSingletons[0]));
  }

  {
    bool failure = false;
    PartitionOpEvaluator eval(p1);
    eval.failureCallback = [&](const PartitionOp &, unsigned, Operand *) {
      failure = true;
    };
    eval.apply(PartitionOp::Require(Element(0)));
    EXPECT_TRUE(failure);
  }

  {
    PartitionOpEvaluator eval(p2);
    eval.failureCallback = [](const PartitionOp &, unsigned, Operand *) {
      EXPECT_TRUE(false);
    };
    eval.apply(PartitionOp::Require(Element(0)));
  }
}

TEST(PartitionUtilsTest, TestUndoTransfer) {
  Partition p;
  PartitionOpEvaluator eval(p);
  eval.failureCallback = [&](const PartitionOp &, unsigned, Operand *) {
    EXPECT_TRUE(false);
  };

  // Shouldn't error on this.
  eval.apply({PartitionOp::AssignFresh(Element(0)),
              PartitionOp::Transfer(Element(0), transferSingletons[0]),
              PartitionOp::UndoTransfer(Element(0), instSingletons[0]),
              PartitionOp::Require(Element(0), instSingletons[0])});
}
