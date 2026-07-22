import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:image_picker/image_picker.dart";

class ImagePickerController extends Notifier<ImagePicker> {
  @override
  ImagePicker build() => .new();

  static final provider = NotifierProvider<ImagePickerController, ImagePicker>(
    ImagePickerController.new,
  );
}
