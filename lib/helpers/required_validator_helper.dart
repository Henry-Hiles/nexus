String? requiredValidator(String? value) =>
    value == null || value.isEmpty ? "This field is required" : null;
