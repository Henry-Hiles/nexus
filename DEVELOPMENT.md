# Development Documentation

## Build instructions

CBuild instructions can be found in [README.md](./README.md#build-it-yourself).

## Updating Gomuks

You can run the following command to update the Gomuks submodule:

```sh
git submodule update --remote
```

## Code Style

### Controllers and Helpers ([Riverpod](https://pub.dev/packages/riverpod))

Controllers live in `lib/controllers/` and provide a source that exposes data and logic via Riverpod providers, allowing other parts of the code to watch state changes with ref.watch (`ref.watch(MyController.provider)`), access the current value with ref.read (`ref.read(MyController.provider)`), and run helper methods on those classes using the notifier:

```dart
ref.watch(MyController.provider.notifier).helperMethod()
```

We use an object oriented style for controllers, where `provider` is a static member on the controller class. E.g.

```dart
class MyController extends AsyncNotifier<DataThisControllerExposes> {
  final SomeInputType input;
  MyController(this.input);

  @override
  Future<DataThisControllerExposes> build() async {
    return input.foo;
  }

  static final provider =
	AsyncNotifierProvider.family<MyController, DataThisControllerExposes, SomeInputType>(
	  AuthorController.new,
	);
}
```

Providers which are not controllers, e.g. they expose no data, only methods, should instead live in `lib/helpers/`. For an example, see `lib/helpers/launch_helper.dart`. Other, non-provider helpers, like extensions or helper methods can also go in `lib/helpers/`.

### Don't use StatefulWidgets ([Flutter Hooks](https://pub.dev/packages/flutter_hooks))

This project uses Flutter Hooks to help with boilerplate that StatefulWidgets create. Instead of using a StatefulWidget, we just use hooks like `useState` or `useEffect` in the build method of a `HookWidget`, which is a drop in replacement for `StatelessWidget`. If you need both a `WidgetRef` to watch providers, and access to hooks, use `HookConsumerWidget`.

### Models ([Freezed](https://pub.dev/packages/freezed))

We use Freezed for our models to avoid boilerplate and enforce an immutable style of state and data modeling throughout the code. See their documentation for more info, or see our existing models in `lib/models/`.

### Immutable Data Collections ([Fast Immutable Collections](https://pub.dev/packages/fast_immutable_collections))

When possible, use immutable collections instead of the mutable equivalent. For example, use `IMap` over `Map`, `IList` over `List`, `ISet` over `Set`. This matches the immutable style of Riverpod and Freezed.

### Don't create globals

When possible, we prefer not to create global variables or methods. You can usually replace a global variable with a Riverpod controller, and a global method with an extension method.

## Code of Conduct

All contributions must follow the [Federated Nexus Code of Conduct](https://federated.nexus/code/).
