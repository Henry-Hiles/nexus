import "dart:convert";
import "dart:ffi";
import "dart:typed_data";
import "package:ffi/ffi.dart";
import "package:nexus/src/third_party/gomuks.g.dart";

extension GomuksOwnedBufferToJson on GomuksOwnedBuffer {
  Uint8List toBytes() {
    try {
      if (base == nullptr || length <= 0) return Uint8List(0);
      return Uint8List.fromList(base.asTypedList(length));
    } finally {
      calloc.free(base);
    }
  }

  Map<String, dynamic> toJson() {
    final bytes = toBytes();
    if (bytes.isEmpty) return {};
    final json = jsonDecode(utf8.decode(bytes));

    if (json is Map<String, dynamic>?) return json ?? {};
    throw json;
  }
}

extension JsonToGomuksBuffer on Map<String, dynamic> {
  Pointer<GomuksBorrowedBuffer> toGomuksBufferPtr() {
    final jsonString = json.encode(this);
    final bytes = utf8.encode(jsonString);

    final dataPtr = calloc<Uint8>(bytes.length);
    dataPtr.asTypedList(bytes.length).setAll(0, bytes);

    final ptr = calloc<GomuksBorrowedBuffer>();

    ptr.ref
      ..base = dataPtr
      ..length = bytes.length;

    return ptr;
  }
}
