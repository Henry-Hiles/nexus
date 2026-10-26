import "dart:convert";
import "dart:ffi";
import "dart:typed_data";

import "package:ffi/ffi.dart";
import "package:nexus/src/third_party/gomuks.g.dart";

extension GomuksOwnedBufferToX on GomuksOwnedBuffer {
  Uint8List toBytesAndFree() {
    try {
      if (base == nullptr || length <= 0) return .new(0);
      return .fromList(base.asTypedList(length));
    } finally {
      GomuksFreeBuffer(this);
    }
  }

  dynamic toJsonAndFree() {
    final bytes = toBytesAndFree();
    return bytes.isEmpty ? null : jsonDecode(utf8.decode(bytes));
  }
}

extension JsonToGomuksBuffer on Map<String, dynamic> {
  GomuksOwnedBuffer toGomuksOwnedBuffer() {
    final bytes = utf8.encode(json.encode(this));
    final buffer = GomuksAllocBuffer(bytes.length);
    buffer.base.asTypedList(bytes.length).setAll(0, bytes);
    return buffer;
  }

  Pointer<GomuksBorrowedBuffer> toGomuksBufferPtr() {
    final bytes = utf8.encode(json.encode(this));

    final dataPtr = calloc<Uint8>(bytes.length);
    dataPtr.asTypedList(bytes.length).setAll(0, bytes);

    return calloc<GomuksBorrowedBuffer>()
      ..ref.base = dataPtr
      ..ref.length = bytes.length;
  }
}
