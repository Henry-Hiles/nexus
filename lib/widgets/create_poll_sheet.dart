import "package:collection/collection.dart";
import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/models/content/poll_start.dart";
import "package:nexus/widgets/sheet_layout.dart";

class const CreatePollSheet({
  required final void Function(PollStart poll) onCreate,
  super.key,
}) extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final questionController = useTextEditingController();
    final question = useValueListenable(questionController).text.trim();

    // Keyed by ID, so fields keep their text when one above is removed
    final nextId = useRef(2);
    final answers = useState<IMap<int, String>>(.new({0: "", 1: ""}));
    final filledAnswers = answers.value.entries
        .map(
          (answer) =>
              PollAnswer(id: "${answer.key}", text: answer.value.trim()),
        )
        .where((answer) => answer.text.isNotEmpty)
        .toIList();

    final allowMultiple = useState(false);

    final canCreate = question.isNotEmpty && filledAnswers.length >= 2;

    void submit() => onCreate(
      .new(
        question: question,
        answers: filledAnswers,
        maxSelections: allowMultiple.value ? filledAnswers.length : 1,
      ),
    );

    return SheetLayout(
      title: const Text("Create a Poll"),
      actions: [
        TextButton(
          onPressed: Navigator.of(context).pop,
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: canCreate ? submit : null,
          child: const Text("Create"),
        ),
      ],
      children: [
        TextField(
          controller: questionController,
          autofocus: true,
          textCapitalization: .sentences,
          decoration: const .new(labelText: "Question"),
        ),
        AnimatedSize(
          duration: Durations.medium2,
          curve: Curves.easeInOut,
          alignment: .topCenter,
          child: Column(
            spacing: 12,
            children: answers.value.entries
                .mapIndexed(
                  (index, answer) => TextFormField(
                    key: ValueKey(answer.key),
                    initialValue: answer.value,
                    textCapitalization: .sentences,
                    onChanged: (text) =>
                        answers.value = answers.value.add(answer.key, text),
                    decoration: .new(
                      labelText: "Answer ${index + 1}",
                      suffixIcon: answers.value.length > 2
                          ? IconButton(
                              tooltip: "Remove answer",
                              icon: const Icon(Icons.close),
                              onPressed: () => answers.value = answers.value
                                  .remove(answer.key),
                            )
                          : null,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        Align(
          alignment: .centerLeft,
          child: TextButton.icon(
            onPressed: answers.value.length < PollStart.maxAnswers
                ? () => answers.value = answers.value.add(nextId.value++, "")
                : null,
            icon: const Icon(Icons.add),
            label: const Text("Add Answer"),
          ),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.checklist),
          title: const Text("Allow multiple answers"),
          subtitle: const Text("Voters can choose more than one"),
          value: allowMultiple.value,
          onChanged: (value) => allowMultiple.value = value,
        ),
      ],
    );
  }
}
