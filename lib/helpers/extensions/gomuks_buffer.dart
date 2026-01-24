import "dart:convert";
import "dart:ffi";
import "dart:typed_data";

import "package:ffi/ffi.dart";
import "package:nexus/src/third_party/gomuks.g.dart";

extension GomuksBufferToJson on GomuksBorrowedBuffer {
  Uint8List toBytes() {
    if (base == nullptr || length <= 0) return Uint8List(0);
    return base.asTypedList(length);
  }

  Map<String, dynamic> toJson() {
    final bytes = toBytes();
    if (bytes.isEmpty) return {};
    return jsonDecode(utf8.decode(bytes));
  }
}

extension JsonToGomuksBuffer on Map<String, dynamic> {
  // GomuksBorrowedBuffer toGomuksBuffer() {
  //   final jsonString = json.encode(this);
  //   final bytes = utf8.encode(jsonString);

  //   final dataPtr = calloc<Uint8>(bytes.length);
  //   dataPtr.asTypedList(bytes.length).setAll(0, bytes);

  //   final bufPtr = calloc<GomuksBuffer>();
  //   bufPtr.ref.base = dataPtr;
  //   bufPtr.ref.length = bytes.length;

  //   final bufByValue = bufPtr.ref;

  //   calloc.free(bufPtr);

  //   return bufByValue;
  // }
}
