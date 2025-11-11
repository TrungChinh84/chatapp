import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// ===========================
/// MAIN CHAT SCREEN WIDGET
/// ===========================
class RealtimeDemo extends StatefulWidget {
  const RealtimeDemo({super.key});

  @override
  State<RealtimeDemo> createState() => _RealtimeDemoState();
}

class _RealtimeDemoState extends State<RealtimeDemo> {
  /// ===========================
  /// 1. DATABASE REFERENCE
  /// ===========================
  late final DatabaseReference db;

  /// Controller cho TextField nhập tin nhắn
  final TextEditingController c = TextEditingController();

  /// ===========================
  /// 2. INIT STATE
  /// - Khởi tạo database
  /// - Bật offline sync cho mobile
  /// ===========================
  @override
  void initState() {
    super.initState();

    // Khởi tạo reference tới node "messages"
    db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: DefaultFirebaseOptions.currentPlatform.databaseURL,
    ).ref("messages");

    // Bật offline persistence cho mobile
    if (!kIsWeb) FirebaseDatabase.instance.setPersistenceEnabled(true);

    // Luôn đồng bộ dữ liệu "messages" với local cache
    db.keepSynced(true);
  }

  /// ===========================
  /// 3. CRUD OPERATIONS
  /// ===========================

  // ---------------------------
  // 3.1 CREATE: Thêm tin nhắn
  // ---------------------------
  void addMsg(String text) {
    final uid = FirebaseAuth.instance.currentUser!.uid; // UID user hiện tại
    db.push().set({
      "text": text,
      "time": ServerValue.timestamp,
      "uid": uid, // dùng để check quyền sửa/xóa
    });
    c.clear(); // xóa textfield sau khi gửi
  }

  // ---------------------------
  // 3.2 UPDATE: Cập nhật tin nhắn
  // Chỉ owner mới được sửa
  // ---------------------------
  void updateMsg(String key, String newText) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final snap = await db.child(key).get();
    if (snap.exists) {
      final data = Map<String, dynamic>.from(snap.value as Map);
      if (data['uid'] == uid) {
        db.child(key).update({"text": newText});
      }
    }
  }

  // ---------------------------
  // 3.3 DELETE: Xóa tin nhắn
  // Chỉ owner mới được xóa
  // ---------------------------
  void delMsg(String key) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final snap = await db.child(key).get();
    if (snap.exists) {
      final data = Map<String, dynamic>.from(snap.value as Map);
      if (data['uid'] == uid) {
        db.child(key).remove();
      }
    }
  }

  /// ===========================
  /// 4. BUILD UI
  /// ===========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Realtime Chat")),

      /// ===========================
      /// BODY: Column gồm:
      /// 1. ListView hiển thị tin nhắn
      /// 2. Row nhập tin nhắn
      /// ===========================
      body: Column(
        children: [
          /// ---------------------------
          /// 4.1 STREAMBUILDER HIỂN THỊ TIN NHẮN
          /// ---------------------------
          Expanded(
            child: StreamBuilder(
              stream: db.orderByChild("time").onValue,
              builder: (context, snap) {
                if (!snap.hasData || snap.data!.snapshot.value == null) {
                  return const Center(child: Text("Chưa có dữ liệu"));
                }

                // Chuyển dữ liệu Firebase Map sang Map<String, dynamic>
                final data = Map<String, dynamic>.from(
                  snap.data!.snapshot.value as Map,
                );

                // Chuyển Map thành list để sort theo thời gian giảm dần
                final items = data.entries.toList()
                  ..sort(
                    (a, b) =>
                        (b.value["time"] ?? 0).compareTo(a.value["time"] ?? 0),
                  );

                // Build ListView hiển thị từng tin nhắn
                return ListView(
                  children: items.map((e) {
                    final key = e.key!;
                    final text = e.value["text"] ?? "";
                    final ownerUid = e.value["uid"];
                    final currentUid = FirebaseAuth.instance.currentUser!.uid;

                    // Nếu user hiện tại là owner thì show nút edit/delete
                    return ListTile(
                      title: Text(text),
                      trailing: ownerUid == currentUid
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () =>
                                      updateMsg(key, "$text (updated)"),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => delMsg(key),
                                ),
                              ],
                            )
                          : null,
                    );
                  }).toList(),
                );
              },
            ),
          ),

          /// ---------------------------
          /// 4.2 ROW NHẬP TIN NHẮN
          /// ---------------------------
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: c,
                  decoration: const InputDecoration(
                    labelText: "Nhập tin nhắn...",
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () {
                  final text = c.text.trim();
                  if (text.isNotEmpty) addMsg(text);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
