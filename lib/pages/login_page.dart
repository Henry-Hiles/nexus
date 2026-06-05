import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/controllers/client_controller.dart";
import "package:nexus/widgets/appbar.dart";
import "package:nexus/helpers/required_validator_helper.dart";

class LoginPage extends HookConsumerWidget {
  final Uri homeserver;
  const LoginPage({super.key, required this.homeserver});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(ClientController.provider.notifier);

    final isLoading = useState(false);
    final username = useTextEditingController();
    final password = useTextEditingController();

    final inputError = useState<String?>(null);
    final formKey = useRef(GlobalKey<FormState>());

    Future<void> tryLogin() async {
      isLoading.value = true;

      try {
        if (formKey.value.currentState?.validate() != true) return;

        final error = await client.login(
          .new(
            username: username.text,
            password: password.text,
            homeserverUrl: homeserver.origin,
          ),
        );

        if (error != null) {
          inputError.value = error;
          isLoading.value = false;
        } else {
          if (context.mounted) Navigator.of(context).pop();
        }
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      appBar: Appbar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: Navigator.of(context).pop,
        ),
      ),
      body: AlertDialog(
        title: Text("Login to ${homeserver.host}"),
        content: Form(
          key: formKey.value,
          child: Column(
            mainAxisSize: .min,
            crossAxisAlignment: .start,
            children: [
              TextFormField(
                autofocus: true,
                textInputAction: .next,
                autovalidateMode: .onUserInteraction,
                validator: requiredValidator,
                decoration: .new(label: Text("Username")),
                controller: username,
              ),
              SizedBox(height: 12),
              TextFormField(
                textInputAction: .done,
                decoration: .new(
                  label: Text("Password"),
                  errorText: inputError.value,
                  errorMaxLines: 5,
                ),
                autovalidateMode: .onUserInteraction,
                validator: requiredValidator,
                controller: password,
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: isLoading.value ? null : tryLogin,
            child: Text("Sign In"),
          ),
        ],
      ),
    );
  }
}
