// RUN: %target-swift-frontend  -disable-availability-checking %s -emit-sil -o /dev/null -verify
// RUN: %target-swift-frontend  -disable-availability-checking %s -emit-sil -o /dev/null -verify -strict-concurrency=targeted
// RUN: %target-swift-frontend  -disable-availability-checking %s -emit-sil -o /dev/null -verify -verify-additional-prefix complete-tns- -strict-concurrency=complete
// RUN: %target-swift-frontend  -disable-availability-checking %s -emit-sil -o /dev/null -verify -verify-additional-prefix complete-tns- -strict-concurrency=complete -enable-experimental-feature RegionBasedIsolation

// REQUIRES: concurrency
// REQUIRES: asserts

@globalActor
actor SomeGlobalActor {
  static let shared = SomeGlobalActor()
}

@MainActor(unsafe) func globalMain() { } // expected-note {{calls to global function 'globalMain()' from outside of its actor context are implicitly asynchronous}}

@SomeGlobalActor(unsafe) func globalSome() { } // expected-note 2{{calls to global function 'globalSome()' from outside of its actor context are implicitly asynchronous}}
// expected-complete-tns-note @-1 {{calls to global function 'globalSome()' from outside of its actor context are implicitly asynchronous}}

// ----------------------------------------------------------------------
// Witnessing and unsafe global actor
// ----------------------------------------------------------------------
protocol P1 {
  @MainActor(unsafe) func onMainActor() // expected-note{{mark the protocol requirement 'onMainActor()' 'async' to allow actor-isolated conformances}}
  // expected-complete-tns-note @-1 {{mark the protocol requirement 'onMainActor()' 'async' to allow actor-isolated conformances}}
}

struct S1_P1: P1 {
  func onMainActor() { }
}

struct S2_P1: P1 {
  @MainActor func onMainActor() { }
}

struct S3_P1: P1 {
  nonisolated func onMainActor() { }
}

struct S4_P1_quietly: P1 {
  @SomeGlobalActor func onMainActor() { }
  // expected-complete-tns-warning @-1 {{global actor 'SomeGlobalActor'-isolated instance method 'onMainActor()' cannot be used to satisfy main actor-isolated protocol requirement}}
}

@SomeGlobalActor
struct S4_P1: P1 {
  @SomeGlobalActor func onMainActor() { } // expected-warning{{global actor 'SomeGlobalActor'-isolated instance method 'onMainActor()' cannot be used to satisfy main actor-isolated protocol requirement}}
}


@MainActor(unsafe)
protocol P2 {
  func f() // expected-note{{calls to instance method 'f()' from outside of its actor context are implicitly asynchronous}}
  // expected-complete-tns-note @-1 {{calls to instance method 'f()' from outside of its actor context are implicitly asynchronous}}
  nonisolated func g()
}

struct S5_P2: P2 {
  func f() { } // expected-note{{calls to instance method 'f()' from outside of its actor context are implicitly asynchronous}}
  // expected-complete-tns-note @-1 {{calls to instance method 'f()' from outside of its actor context are implicitly asynchronous}}
  func g() { }
}

nonisolated func testP2(x: S5_P2, p2: P2) {
  p2.f() // expected-error{{call to main actor-isolated instance method 'f()' in a synchronous nonisolated context}}
  p2.g() // OKAY
  x.f() // expected-error{{call to main actor-isolated instance method 'f()' in a synchronous nonisolated context}}
  x.g() // OKAY
}

func testP2_noconcurrency(x: S5_P2, p2: P2) {
  // expected-complete-tns-note @-1 2{{add '@MainActor' to make global function 'testP2_noconcurrency(x:p2:)' part of global actor 'MainActor'}}
  p2.f() // okay without complete. with targeted/minimal not concurrency-related code.
  // expected-complete-tns-error @-1 {{call to main actor-isolated instance method 'f()' in a synchronous nonisolated context}}
  p2.g() // okay
  x.f() // okay without complete. with targeted/minimal not concurrency-related code
  // expected-complete-tns-error @-1 {{call to main actor-isolated instance method 'f()' in a synchronous nonisolated context}}
  x.g() // OKAY
}

// ----------------------------------------------------------------------
// Overriding and unsafe global actor
// ----------------------------------------------------------------------
class C1 {
  @MainActor(unsafe) func method() { } // expected-note{{overridden declaration is here}}
}

class C2: C1 {
  override func method() { // expected-note 2{{overridden declaration is here}}
    globalSome() // okay when not in complete
    // expected-complete-tns-error @-1 {{call to global actor 'SomeGlobalActor'-isolated global function 'globalSome()' in a synchronous main actor-isolated context}}
  }
}

class C3: C1 {
  nonisolated override func method() {
    globalSome() // expected-error{{call to global actor 'SomeGlobalActor'-isolated global function 'globalSome()' in a synchronous nonisolated context}}
  }
}

class C4: C1 {
  @MainActor override func method() {
    globalSome() // expected-error{{call to global actor 'SomeGlobalActor'-isolated global function 'globalSome()' in a synchronous main actor-isolated context}}
  }
}

class C5: C1 {
  @SomeGlobalActor override func method() { // expected-error{{global actor 'SomeGlobalActor'-isolated instance method 'method()' has different actor isolation from main actor-isolated overridden declaration}}
  }
}

class C6: C2 {
  // We didn't infer any actor isolation for C2.method().
  @SomeGlobalActor override func method() { // expected-error{{global actor 'SomeGlobalActor'-isolated instance method 'method()' has different actor isolation from main actor-isolated overridden declaration}}
  }
}

class C7: C2 {
  @SomeGlobalActor(unsafe) override func method() { // expected-error{{global actor 'SomeGlobalActor'-isolated instance method 'method()' has different actor isolation from main actor-isolated overridden declaration}}
    globalMain() // expected-error{{call to main actor-isolated global function 'globalMain()' in a synchronous global actor 'SomeGlobalActor'-isolated context}}
    globalSome() // okay
  }
}

@MainActor(unsafe) // expected-note {{'GloballyIsolatedProto' is isolated to global actor 'MainActor' here}}
protocol GloballyIsolatedProto {
}

// rdar://75849035 - trying to conform an actor to a global-actor isolated protocol should result in an error
func test_conforming_actor_to_global_actor_protocol() {
  actor MyValue : GloballyIsolatedProto {}
  // expected-error@-1 {{actor 'MyValue' cannot conform to global actor isolated protocol 'GloballyIsolatedProto'}}
}
