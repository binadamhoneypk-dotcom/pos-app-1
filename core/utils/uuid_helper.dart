import 'package:uuid/uuid.dart';

final _uuid = Uuid();

/// Generates a new v4 UUID for any new local row (user, business, item,
/// sale, ledger entry...). Always generate the uuid on the CLIENT, never
/// let the server assign it — that's what makes offline creation safe.
String newUuid() => _uuid.v4();

int nowMillis() => DateTime.now().millisecondsSinceEpoch;
