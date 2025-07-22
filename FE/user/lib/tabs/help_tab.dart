import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user/services/bot_ai_services.dart';

/* ===== MODELS ===== */
enum Role { user, bot }

class ChatMsg {
  final Role role;
  String text;
  ChatMsg(this.role, this.text);
}

class GeminiSession {
  final String id;
  final String title;
  GeminiSession({required this.id, required this.title});
}

/* ===== MAIN WIDGET ===== */
class HelpTab extends StatefulWidget {
  const HelpTab({Key? key}) : super(key: key);
  @override
  State<HelpTab> createState() => _HelpTabState();
}

class _HelpTabState extends State<HelpTab> {
  final _promptCtr = TextEditingController();
  final _scrollCtr = ScrollController();

  List<GeminiSession> _sessions = [];
  String? _currentSessionId;
  List<ChatMsg> _messages = [];
  bool _loading = false;
  bool _loadingSessions = true;
  bool _loggedIn = false;

  Timer? _typingTimer;

  // BƯỚC 1: TẠO GETTER ĐỂ KIỂM TRA TRẠNG THÁI TYPING
  bool get _isBotTyping => _typingTimer?.isActive ?? false;

  @override
  void initState() {
    super.initState();
    _initLoginState();
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _promptCtr.dispose();
    _scrollCtr.dispose();
    super.dispose();
  }

  /* ---------- LOGIN CHECK ---------- */
  Future<void> _initLoginState() async {
    // ... (logic không đổi)
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _loggedIn = prefs.containsKey('user_id');
      if (_loggedIn) {
        _fetchSessions();
      } else {
        _loadingSessions = false;
      }
    });
  }

  /* ---------- SESSION LOGIC ---------- */
  Future<void> _fetchSessions() async {
    // ... (logic không đổi)
    setState(() => _loadingSessions = true);
    try {
      final res = await BotAiServices.getAllSessions();
      final list = (res.data['data'] as List).cast<Map>();
      if (!mounted) return;
      setState(() {
        _sessions = list
            .map((e) => GeminiSession(
          id: e['sessionId'].toString(),
          title: (e['title'] ?? 'Untitled').toString(),
        ))
            .toList();
      });
    } catch (e) {
      print("Lỗi khi fetch sessions: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể tải các cuộc trò chuyện.')));
      }
    } finally {
      if (mounted) setState(() => _loadingSessions = false);
    }
  }

  Future<void> _createSession() async {
    // ... (logic không đổi)
    if (Scaffold.of(context).isDrawerOpen) Navigator.pop(context);
    final title = await _showCreateSessionDialog();
    if (title == null || title.isEmpty) return;
    setState(() => _loading = true);
    try {
      final res = await BotAiServices.createSession(title: title);
      final data = res.data['data'] ?? res.data;
      final sid = data['sessionId'] ?? data;
      final newSession = GeminiSession(id: sid.toString(), title: title);
      if (!mounted) return;
      setState(() {
        _sessions.insert(0, newSession);
        _currentSessionId = newSession.id;
        _messages.clear();
      });
    } catch (e) {
      print("Lỗi khi tạo session: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tạo cuộc trò chuyện mới thất bại.')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteSession(String sessionId) async {
    // ... (logic không đổi)
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xoá cuộc trò chuyện?'),
        content: const Text('Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Huỷ')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xoá', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true) return;
    await BotAiServices.deleteSession(sessionId: sessionId);
    if (!mounted) return;
    setState(() {
      _sessions.removeWhere((s) => s.id == sessionId);
      if (_currentSessionId == sessionId) {
        _currentSessionId = null;
        _messages.clear();
      }
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Đã xoá cuộc trò chuyện')));
  }

  Future<void> _loadSession(String sessionId) async {
    // ... (logic không đổi)
    Navigator.pop(context);
    setState(() {
      _loading = true;
      _currentSessionId = sessionId;
      _messages.clear();
    });
    try {
      final res = await BotAiServices.getSessionById(sessionId: sessionId);
      final sess = res.data['data'] as Map;
      final list = (sess['messages'] as List).cast<Map>();
      if (!mounted) return;
      setState(() {
        _messages = list
            .map((e) => ChatMsg(
          e['sender'].toString().toLowerCase() == 'user'
              ? Role.user
              : Role.bot,
          e['text'].toString(),
        ))
            .toList();
      });
      _scrollBottom();
    } catch (e) {
      print("Lỗi khi tải session: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Không thể tải nội dung cuộc trò chuyện.')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /* ---------- CHAT LOGIC ---------- */
  Future<void> _send() async {
    // THÊM ĐIỀU KIỆN NGĂN GỬI KHI BOT ĐANG TYPING
    final prompt = _promptCtr.text.trim();
    if (prompt.isEmpty || _currentSessionId == null || _loading || _isBotTyping)
      return;

    _typingTimer?.cancel();

    setState(() {
      _promptCtr.clear();
      _messages.add(ChatMsg(Role.user, prompt));
      _loading = true;
    });
    _scrollBottom();

    try {
      final res = await BotAiServices.askGemini(
          prompt: prompt, sessionId: _currentSessionId!);
      final fullReply = _pickReply(res.data);

      if (!mounted) return;

      setState(() {
        _loading = false;
        _messages.add(ChatMsg(Role.bot, ''));
      });
      _scrollBottom();

      final words = fullReply.split(RegExp(r'(?<=\s)'));
      int wordIndex = 0;
      const typingSpeed = Duration(milliseconds: 100);

      _typingTimer = Timer.periodic(typingSpeed, (timer) {
        if (wordIndex < words.length) {
          if (!mounted) {
            timer.cancel();
            return;
          }
          setState(() {
            _messages.last.text += words[wordIndex];
          });
          if (wordIndex % 5 == 0 || wordIndex == words.length - 1) {
            _scrollBottom();
          }
          wordIndex++;
        } else {
          // BƯỚC 3: CẬP NHẬT UI KHI TYPING XONG
          timer.cancel();
          setState(() {}); // Gọi setState để rebuild lại nút bấm
          _scrollBottom();
        }
      });
    } catch (e) {
      print("Lỗi khi gửi tin nhắn: $e");
      if (mounted) {
        setState(() {
          _loading = false;
          _messages.add(
              ChatMsg(Role.bot, "Xin lỗi, đã có lỗi xảy ra. Vui lòng thử lại."));
        });
      }
    }
  }

  String _pickReply(dynamic data) {
    // ... (logic không đổi)
    if (data is Map) {
      if (data['botReply'] != null) return data['botReply'].toString();
      if (data['data'] != null) return _pickReply(data['data']);
    }
    return data.toString();
  }

  void _scrollBottom() {
    // ... (logic không đổi)
    Timer(const Duration(milliseconds: 100), () {
      if (_scrollCtr.hasClients) {
        _scrollCtr.animateTo(
          _scrollCtr.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _getCurrentSessionTitle() {
    // ... (logic không đổi)
    if (_currentSessionId == null) return 'Măm Bot';
    return _sessions
        .firstWhere((s) => s.id == _currentSessionId,
        orElse: () => GeminiSession(id: '', title: 'Măm Bot'))
        .title;
  }

  /* ---------- UI BUILDERS ---------- */
  @override
  Widget build(BuildContext context) {
    // ... (UI không đổi)
    if (!_loggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Gemini Chat')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Bạn cần đăng nhập để sử dụng tính năng này.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            tooltip: 'Mở menu',
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(_getCurrentSessionTitle()),
        centerTitle: true,
      ),
      drawer: _buildDrawer(),
      body: _currentSessionId == null ? _buildEmptyState() : _buildChatView(),
    );
  }

  Widget _buildDrawer() {
    // ... (UI không đổi)
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: OutlinedButton.icon(
                onPressed: _createSession,
                icon: const Icon(Icons.add),
                label: const Text('Cuộc trò chuyện mới'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const Divider(),
            if (_loadingSessions)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _sessions.length,
                  itemBuilder: (_, i) {
                    final s = _sessions[i];
                    return ListTile(
                      title: Text(s.title, overflow: TextOverflow.ellipsis),
                      selected: s.id == _currentSessionId,
                      selectedTileColor: Colors.blueAccent.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      onTap: () => _loadSession(s.id),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.redAccent),
                        onPressed: () => _deleteSession(s.id),
                      ),
                    );
                  },
                ),
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Tải lại danh sách'),
              onTap: _fetchSessions,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    // ... (UI không đổi)
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline,
                size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Bắt đầu cuộc trò chuyện',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Chọn một cuộc trò chuyện hoặc tạo mới từ menu bên trái.',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatView() {
    // ... (UI không đổi)
    return Column(
      children: [
        Expanded(child: _chatList()),
        _chatInput(),
      ],
    );
  }

  Widget _chatList() {
    // ... (UI không đổi)
    return ListView.builder(
      controller: _scrollCtr,
      padding: const EdgeInsets.all(12),
      itemCount: _messages.length + (_loading ? 1 : 0),
      itemBuilder: (_, i) {
        if (_loading && i == _messages.length) {
          return const Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        final m = _messages[i];
        final isUser = m.role == Role.user;
        final align = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
        final color = isUser ? Colors.blueAccent : Colors.grey.shade200;
        final textColor = isUser ? Colors.white : Colors.black87;
        Widget messageContent;
        if (isUser) {
          messageContent =
              Text(m.text, style: TextStyle(color: textColor, fontSize: 16));
        } else {
          // Thêm một ký tự không thể bị break (zero-width space) để MarkdownBody không bị lỗi khi data rỗng
          final displayText = m.text.isEmpty ? '\u200B' : m.text;
          messageContent = MarkdownBody(
            data: displayText,
            selectable: true,
            styleSheet:
            MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
              p: TextStyle(color: textColor, fontSize: 16),
              strong: TextStyle(fontWeight: FontWeight.bold, color: textColor),
              listBullet: TextStyle(color: textColor, fontSize: 16),
            ),
          );
        }
        return Column(
          crossAxisAlignment: align,
          children: [
            Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75),
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
                  bottomRight: isUser ? Radius.zero : const Radius.circular(16),
                ),
              ),
              child: messageContent,
            ),
          ],
        );
      },
    );
  }

  // =================================================================
  // ===== BƯỚC 2: CẬP NHẬT WIDGET _chatInput() =====
  // =================================================================
  Widget _chatInput() {
    // Điều kiện để vô hiệu hóa input và nút gửi
    final bool isDisabled = _loading || _isBotTyping;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _promptCtr,
                enabled: !isDisabled, // Vô hiệu hóa textfield
                decoration: InputDecoration(
                  hintText: _isBotTyping ? 'Bot đang trả lời...' : 'Nhập tin nhắn...',
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: Colors.grey.shade300)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(color: Colors.blueAccent)),
                ),
                onSubmitted: isDisabled ? null : (_) => _send(), // Vô hiệu hóa gửi bằng Enter
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              icon: const Icon(Icons.send),
              onPressed: isDisabled ? null : _send, // Vô hiệu hóa nút gửi
              style: IconButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _showCreateSessionDialog() async {
    // ... (UI không đổi)
    final c = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bắt đầu cuộc trò chuyện mới'),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Tiêu đề',
            hintText: '...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Huỷ'),
          ),
          ElevatedButton(
            onPressed: () {
              if (c.text.trim().isNotEmpty) {
                Navigator.pop(context, c.text.trim());
              }
            },
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
  }
}