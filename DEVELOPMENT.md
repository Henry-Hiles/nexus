# Development Documentation

## Build instructions

Build instructions can be found in [README.md](./README.md#build-it-yourself).

## Updating Gomuks

You can run the following command to update the Gomuks submodule:

```sh
git submodule update --remote
```

## Code Style

See [Effective Dart: Style](https://dart.dev/effective-dart/style) for general rules. There are some extra rules detailed below:

### Controllers and Helpers ([Riverpod](https://pub.dev/packages/riverpod))

Controllers live in `lib/controllers/` and provide a source that exposes data and logic via Riverpod providers, allowing other parts of the code to watch state changes with ref.watch (`ref.watch(MyController.provider)`), access the current value with ref.read (`ref.read(MyController.provider)`), and run helper methods on those classes using the notifier:

```dart
ref.read(MyController.provider.notifier).helperMethod()
```

We use an object oriented style for controllers, where `provider` is a static member on the controller class. E.g.

```dart
class MyController(final SomeInputType input)
    extends AsyncNotifier<DataThisControllerExposes> {
  @override
  Future<DataThisControllerExposes> build() async {
    return input.foo;
  }

  static final provider =
      AsyncNotifierProvider.family<MyController, DataThisControllerExposes, SomeInputType>(
        MyController.new,
      );
}
```

#### `watch` vs `read`

Only use `ref.watch` in a `build` method, where you want to rebuild when the value changes. Everywhere else, like callbacks, `useEffect`, and methods on a controller, use `ref.read`.

Use `.select` to narrow down what you depend on, e.g. `ref.watch(RoomsController.provider.select((rooms) => rooms[roomId]))`.

Providers which are not controllers, e.g. they expose no data, only methods, should instead live in `lib/helpers/`. For an example, see `lib/helpers/launch_helper.dart`. Other, non-provider helpers, like extensions or helper methods can also go in `lib/helpers/`.

### Don't use StatefulWidgets ([Flutter Hooks](https://pub.dev/packages/flutter_hooks))

This project uses Flutter Hooks to help with boilerplate that StatefulWidgets create. Instead of using a StatefulWidget, we just use hooks like `useState` or `useEffect` in the build method of a `HookWidget`, which is a drop in replacement for `StatelessWidget`. If you need both a `WidgetRef` to watch providers, and access to hooks, use `HookConsumerWidget`.

### Models ([Freezed](https://pub.dev/packages/freezed))

We use Freezed for our models to avoid boilerplate and enforce an immutable style of state and data modeling throughout the code. See their documentation for more info, or see our existing models in `lib/models/`.

### Immutable Data Collections ([Fast Immutable Collections](https://pub.dev/packages/fast_immutable_collections))

When possible, use immutable collections instead of the mutable equivalent. For example, use `IMap` over `Map`, `IList` over `List`, `ISet` over `Set`. This matches the immutable style of Riverpod and Freezed.

### Don't create globals

When possible, we prefer not to create global variables or methods. You can usually replace a global variable with a Riverpod controller, and a global method with an extension method.

I'm also not a big fan of private methods or variables, but this is contextual.

### Modern Dart syntax

We try to use newer Dart language features where they make code shorter:

- Primary constructors for classes, including widgets, e.g. `class const MemberList(final String roomId, {super.key}) extends HookConsumerWidget`.
- Dot shorthands wherever the type can be inferred, e.g. `.new(...)`, `padding: .all(8)`, `relationType == .reply`.
- Patterns and switch expressions over null checks and casts, e.g. `if (event.content case MessageContent(:final body?))` rather than checking `is` then using `!`.

### Prefer `map` over inline `for` loops

When building a list (or set, or map) from another collection, use `.map`, `.expand` and friends rather than a `for` inside the collection literal:

```dart
// Prefer
children: rooms.map((room) => RoomTile(room)).toList(),

// Over
children: [for (final room in rooms) RoomTile(room)],
```

Regular `for` statements are fine for logic that doesn't just build a collection.

### Async values and errors

When rendering an `AsyncValue`, use the `betterWhen` extension, which shows our standard loading and error widgets, or a switch expression if you need more control (e.g. `AsyncData(:final value) || AsyncLoading(:final value?)` to keep showing old data while reloading).

For futures started from the UI that nothing awaits, like button presses, add `.onError(showError)` so failures are shown to the user instead of being lost.

## LLM/AI Assisted Contributions

LLM generated code is NOT allowed. All contributions should be written by humans. Using LLMs for interacting with others, e.g. for Comments, PRs, etc, is also not allowed.

## Code of Conduct

All contributions must follow the [Federated Nexus Code of Conduct](https://federated.nexus/code/).
