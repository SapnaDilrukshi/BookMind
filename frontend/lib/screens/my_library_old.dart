import 'dart:math' as math;
import 'package:bookmind/screens/favorites_screen.dart';
import 'package:bookmind/screens/reviews_screen.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/user_session.dart';
import '../config/color.dart';

class MyLibraryPage extends StatefulWidget {
  const MyLibraryPage({super.key});

  @override
  State<MyLibraryPage> createState() => _MyLibraryPageState();
}

class _MyLibraryPageState extends State<MyLibraryPage>
    with TickerProviderStateMixin {
  bool _loading = true;

  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _insightsMe;
  List<String> _favorites = [];
  List<dynamic> _notes = [];
  String _noteSearch = "";
  List<dynamic> _libraryAll = [];
  String _librarySearch = "";
  String _activeTab = "reading";

  bool _editingProfile = false;
  late TextEditingController _usernameCtrl;
  late TextEditingController _bioCtrl;
  late TextEditingController _visionCtrl;
  late TextEditingController _missionCtrl;

  List<String> _interestsDraft = [];
  List<String> _emotionsDraft = [];
  List<String> _goalsDraft = [];

  late AnimationController _chartAnimCtrl;
  late Animation<double> _chartAnim;

  final List<String> _interestOptions = const [
    "technology", "fantasy", "romance", "mystery", "thriller",
    "finance", "children", "psychology", "parenting", "history",
    "science", "self-help",
  ];
  final List<String> _emotionOptions = const [
    "happy", "sad", "inspired", "scary", "romantic",
    "dark", "adventurous", "mysterious", "neutral",
  ];

  @override
  void initState() {
    super.initState();
    _usernameCtrl = TextEditingController();
    _bioCtrl = TextEditingController();
    _visionCtrl = TextEditingController();
    _missionCtrl = TextEditingController();
    _chartAnimCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));
    _chartAnim =
        CurvedAnimation(parent: _chartAnimCtrl, curve: Curves.easeOutCubic);
    _loadAll();
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _bioCtrl.dispose();
    _visionCtrl.dispose();
    _missionCtrl.dispose();
    _chartAnimCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final profile = await ApiService.getMyProfile();
      final insights = await ApiService.getInsightsMe();
      final favs = await ApiService.fetchFavorites();
      final notes = await ApiService.fetchNotes(limit: 50);
      final library = await ApiService.fetchLibrary(limit: 500);
      _profile = profile;
      _insightsMe = insights;
      _favorites = favs;
      _notes = notes;
      _libraryAll = library;
      _usernameCtrl.text = (profile["username"] ?? "").toString();
      _bioCtrl.text = (profile["bio"] ?? "").toString();
      _visionCtrl.text = (profile["vision"] ?? "").toString();
      _missionCtrl.text = (profile["mission"] ?? "").toString();
      _interestsDraft = List<String>.from(profile["interests"] ?? []);
      _emotionsDraft = List<String>.from(profile["preferred_emotions"] ?? []);
      _goalsDraft = List<String>.from(profile["goals"] ?? []);
    } catch (e) {
      _toast("Load failed: $e");
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        _chartAnimCtrl.forward(from: 0);
      }
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: AppColors.primaryDark,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  String _initials(String name) {
    final s = name.trim();
    if (s.isEmpty) return "?";
    final parts = s.split(RegExp(r"\s+")).where((x) => x.isNotEmpty).toList();
    if (parts.isEmpty) return "?";
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  int _safeInt(dynamic v) {
    try {
      if (v is int) return v;
      return int.parse(v.toString());
    } catch (_) {
      return 0;
    }
  }

  // ─── Profile ──────────────────────────────────────────────────────────────

  Future<void> _saveProfile() async {
    try {
      final payload = <String, dynamic>{
        "username": _usernameCtrl.text.trim(),
        "bio": _bioCtrl.text.trim(),
        "vision": _visionCtrl.text.trim(),
        "mission": _missionCtrl.text.trim(),
        "goals": _goalsDraft,
        "interests": _interestsDraft,
        "preferred_emotions": _emotionsDraft,
      };
      final updated = await ApiService.updateMyProfile(payload);
      final email = (_profile?["email"] ?? "").toString();
      await UserSession.saveUser(
        userId: (_profile?["id"] ?? "").toString(),
        email: email,
        username: updated["username"] ?? _usernameCtrl.text.trim(),
        interests: List<String>.from(updated["interests"] ?? _interestsDraft),
        emotions: List<String>.from(
            updated["preferred_emotions"] ?? _emotionsDraft),
        isFirstLogin: false,
      );
      _profile = {...?_profile, ...updated};
      setState(() => _editingProfile = false);
      _toast("Profile saved ✅");
    } catch (e) {
      _toast("Save failed: $e");
    }
  }

  void _resetProfileEdits() {
    final p = _profile ?? {};
    _usernameCtrl.text = (p["username"] ?? "").toString();
    _bioCtrl.text = (p["bio"] ?? "").toString();
    _visionCtrl.text = (p["vision"] ?? "").toString();
    _missionCtrl.text = (p["mission"] ?? "").toString();
    _interestsDraft = List<String>.from(p["interests"] ?? []);
    _emotionsDraft = List<String>.from(p["preferred_emotions"] ?? []);
    _goalsDraft = List<String>.from(p["goals"] ?? []);
    setState(() {});
    _toast("Reset done");
  }

  // ─── Note Dialog ──────────────────────────────────────────────────────────

  Future<void> _showAddNoteDialog() async {
    final titleCtrl = TextEditingController();
    final textCtrl = TextEditingController();
    String mood = "neutral";
    bool pinned = false;

    await showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => StatefulBuilder(builder: (ctx, setLocal) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 44, vertical: 44),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppColors.largeShadow,
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.edit_note,
                        color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 10),
                  const Text("Add Diary Note",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6)),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 15),
                    ),
                  ),
                ]),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _textField(titleCtrl, "Title (optional)"),
                        const SizedBox(height: 10),
                        _textField(textCtrl, "Write your thoughts…",
                            maxLines: 4),
                        const SizedBox(height: 12),
                        const Text("Mood",
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: AppColors.darkText)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _emotionOptions.map((e) {
                            final active = mood == e;
                            return GestureDetector(
                              onTap: () => setLocal(() => mood = e),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 130),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 9, vertical: 4),
                                decoration: BoxDecoration(
                                  color: active
                                      ? AppColors.primary
                                      : AppColors.backgroundAlt,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                      color: active
                                          ? AppColors.primary
                                          : AppColors.border),
                                ),
                                child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(_moodEmoji(e),
                                          style:
                                              const TextStyle(fontSize: 11)),
                                      const SizedBox(width: 3),
                                      Text(e,
                                          style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: active
                                                  ? Colors.white
                                                  : AppColors.mediumText)),
                                    ]),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                              color: AppColors.backgroundAlt,
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(color: AppColors.border)),
                          child: Row(children: [
                            Icon(Icons.push_pin_rounded,
                                size: 13,
                                color: pinned
                                    ? AppColors.accent
                                    : AppColors.mediumText),
                            const SizedBox(width: 6),
                            const Expanded(
                                child: Text("Pin this note",
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                        color: AppColors.darkText))),
                            Switch(
                                value: pinned,
                                onChanged: (v) =>
                                    setLocal(() => pinned = v),
                                activeColor: AppColors.accent,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap),
                          ]),
                        ),
                      ]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.mediumText,
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9)),
                          padding:
                              const EdgeInsets.symmetric(vertical: 11)),
                      child: const Text("Cancel",
                          style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final text = textCtrl.text.trim();
                        if (text.isEmpty) {
                          _toast("Text is required");
                          return;
                        }
                        try {
                          final created =
                              await ApiService.createNote({
                            "title": titleCtrl.text.trim(),
                            "text": text,
                            "mood": mood,
                            "tags": [],
                            "pinned": pinned,
                          });
                          setState(
                              () => _notes = [created, ..._notes]);
                          if (mounted) Navigator.pop(ctx);
                          _toast("Note added ✅");
                        } catch (e) {
                          _toast("Create failed: $e");
                        }
                      },
                      icon: const Icon(Icons.save_rounded, size: 15),
                      label: const Text("Save Note",
                          style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9)),
                          padding:
                              const EdgeInsets.symmetric(vertical: 11)),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
        );
      }),
    );
    titleCtrl.dispose();
    textCtrl.dispose();
  }

  Future<void> _deleteNote(String noteId) async {
    try {
      await ApiService.deleteNote(noteId);
      setState(() => _notes
          .removeWhere((n) => (n["id"] ?? "").toString() == noteId));
      _toast("Deleted");
    } catch (e) {
      _toast("Delete failed: $e");
    }
  }

  List<dynamic> get _notesFiltered {
    final q = _noteSearch.trim().toLowerCase();
    if (q.isEmpty) return _notes;
    return _notes.where((n) {
      final title = (n["title"] ?? "").toString().toLowerCase();
      final text = (n["text"] ?? "").toString().toLowerCase();
      final mood = (n["mood"] ?? "").toString().toLowerCase();
      return title.contains(q) || text.contains(q) || mood.contains(q);
    }).toList();
  }

  // ─── Library Dialog ───────────────────────────────────────────────────────

  List<dynamic> get _libraryByTab {
    var items = _libraryAll
        .where((it) => (it["status"] ?? "").toString() == _activeTab)
        .toList();
    final q = _librarySearch.trim().toLowerCase();
    if (q.isNotEmpty) {
      items = items.where((it) {
        final t = (it["book_title"] ?? "").toString().toLowerCase();
        final a = (it["author"] ?? "").toString().toLowerCase();
        return t.contains(q) || a.contains(q);
      }).toList();
    }
    return items;
  }

  Future<void> _showAddLibraryDialog() async {
    final titleCtrl = TextEditingController();
    final authorCtrl = TextEditingController();
    int progress = 0;
    String status = _activeTab;

    await showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => StatefulBuilder(builder: (ctx, setLocal) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 44, vertical: 44),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppColors.largeShadow,
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                decoration: BoxDecoration(
                  gradient: AppColors.warmGradient,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.library_add,
                        color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 10),
                  const Text("Add Book",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6)),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 15),
                    ),
                  ),
                ]),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _textField(titleCtrl, "Book title *"),
                        const SizedBox(height: 10),
                        _textField(authorCtrl, "Author (optional)"),
                        const SizedBox(height: 12),
                        const Text("Status",
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: AppColors.darkText)),
                        const SizedBox(height: 8),
                        Row(children: [
                          _statusChip("to_read", "📋 To Read", status,
                              (v) => setLocal(() => status = v)),
                          const SizedBox(width: 6),
                          _statusChip("reading", "📖 Reading", status,
                              (v) => setLocal(() => status = v)),
                        ]),
                        const SizedBox(height: 6),
                        Row(children: [
                          _statusChip("finished", "✅ Finished", status,
                              (v) => setLocal(() => status = v)),
                          const SizedBox(width: 6),
                          _statusChip("later", "🕐 Later", status,
                              (v) => setLocal(() => status = v)),
                        ]),
                        if (status == "reading") ...[
                          const SizedBox(height: 12),
                          Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Progress",
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                        color: AppColors.darkText)),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                      color: AppColors.accent
                                          .withOpacity(0.15),
                                      borderRadius:
                                          BorderRadius.circular(6)),
                                  child: Text("$progress%",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.accent,
                                          fontSize: 12)),
                                ),
                              ]),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress / 100,
                              minHeight: 7,
                              backgroundColor:
                                  AppColors.accent.withOpacity(0.12),
                              valueColor: const AlwaysStoppedAnimation(
                                  AppColors.accent),
                            ),
                          ),
                          SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: Colors.transparent,
                              inactiveTrackColor: Colors.transparent,
                              thumbColor: AppColors.primary,
                              overlayColor:
                                  AppColors.accent.withOpacity(0.12),
                              thumbShape:
                                  const RoundSliderThumbShape(
                                      enabledThumbRadius: 8),
                              trackHeight: 0,
                            ),
                            child: Slider(
                                value: progress.toDouble(),
                                min: 0,
                                max: 100,
                                divisions: 100,
                                onChanged: (v) =>
                                    setLocal(() => progress = v.round())),
                          ),
                        ],
                      ]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.mediumText,
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9)),
                          padding:
                              const EdgeInsets.symmetric(vertical: 11)),
                      child: const Text("Cancel",
                          style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final title = titleCtrl.text.trim();
                        if (title.isEmpty) {
                          _toast("Book title is required");
                          return;
                        }
                        try {
                          final saved =
                              await ApiService.addToLibrary({
                            "book_title": title,
                            "author": authorCtrl.text.trim(),
                            "status": status,
                            "progress":
                                status == "reading" ? progress : 0,
                          });
                          setState(() {
                            _libraryAll.removeWhere((x) {
                              final sameId =
                                  (x["id"] ?? "").toString() ==
                                      (saved["id"] ?? "").toString();
                              final sameTitle =
                                  (x["book_title"] ?? "")
                                          .toString()
                                          .toLowerCase() ==
                                      (saved["book_title"] ?? "")
                                          .toString()
                                          .toLowerCase();
                              return sameId || sameTitle;
                            });
                            _libraryAll = [saved, ..._libraryAll];
                            _activeTab = status;
                          });
                          if (mounted) Navigator.pop(ctx);
                          _toast("Book added ✅");
                        } catch (e) {
                          _toast("Save failed: $e");
                        }
                      },
                      icon: const Icon(Icons.add_rounded, size: 15),
                      label: const Text("Add Book",
                          style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9)),
                          padding:
                              const EdgeInsets.symmetric(vertical: 11)),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
        );
      }),
    );
    titleCtrl.dispose();
    authorCtrl.dispose();
  }

  Widget _statusChip(String value, String label, String current,
      ValueChanged<String> onTap) {
    final active = current == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.backgroundAlt,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: active ? AppColors.primary : AppColors.border),
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color:
                        active ? Colors.white : AppColors.mediumText)),
          ),
        ),
      ),
    );
  }

  Future<void> _updateLibraryProgress(String itemId, int progress) async {
    try {
      final updated = await ApiService.updateLibraryItem(
          itemId, {"progress": progress});
      setState(() {
        final idx = _libraryAll
            .indexWhere((x) => (x["id"] ?? "").toString() == itemId);
        if (idx >= 0) _libraryAll[idx] = updated;
      });
    } catch (e) {
      _toast("Update failed: $e");
    }
  }

  Future<void> _updateLibraryStatus(String itemId, String status) async {
    try {
      final updated = await ApiService.updateLibraryItem(
          itemId, {"status": status});
      setState(() {
        final idx = _libraryAll
            .indexWhere((x) => (x["id"] ?? "").toString() == itemId);
        if (idx >= 0) _libraryAll[idx] = updated;
      });
      _toast("Moved ✅");
    } catch (e) {
      _toast("Move failed: $e");
    }
  }

  Future<void> _deleteLibraryItem(String itemId) async {
    try {
      await ApiService.deleteLibraryItem(itemId);
      setState(() => _libraryAll
          .removeWhere((x) => (x["id"] ?? "").toString() == itemId));
      _toast("Deleted");
    } catch (e) {
      _toast("Delete failed: $e");
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: _buildFABs(),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppColors.accent, strokeWidth: 2.5))
          : SafeArea(
              child: RefreshIndicator(
                onRefresh: _loadAll,
                color: AppColors.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding:
                      const EdgeInsets.fromLTRB(14, 12, 14, 120),
                  child: Column(children: [
                    _buildHeroCard(),
                    const SizedBox(height: 14),
                    _buildAboutMeCard(),
                    const SizedBox(height: 14),
                    _buildDiaryCard(),
                    const SizedBox(height: 14),
                    _buildVisionMissionCard(),
                    const SizedBox(height: 14),
                    _buildReadingTrackerCard(),
                  ]),
                ),
              ),
            ),
    );
  }

  // ─── FABs ─────────────────────────────────────────────────────────────────

  Widget _buildFABs() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FloatingActionButton.extended(
          heroTag: "fabNote",
          onPressed: _showAddNoteDialog,
          backgroundColor: AppColors.secondary,
          foregroundColor: Colors.white,
          elevation: 3,
          icon: const Icon(Icons.edit_note, size: 20),
          label: const Text("Note",
              style: TextStyle(fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 10),
        FloatingActionButton.extended(
          heroTag: "fabLibrary",
          onPressed: _showAddLibraryDialog,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 3,
          icon: const Icon(Icons.library_add, size: 20),
          label: const Text("Book",
              style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  // ─── Hero Card — clean, no gradient overload ──────────────────────────────

  Widget _buildHeroCard() {
    final username =
        (_profile?["username"] ?? "User").toString();
    final email = (_profile?["email"] ?? "").toString();

    final toRead = _libraryAll
        .where((x) => (x["status"] ?? "") == "to_read")
        .length;
    final reading = _libraryAll
        .where((x) => (x["status"] ?? "") == "reading")
        .length;
    final finished = _libraryAll
        .where((x) => (x["status"] ?? "") == "finished")
        .length;
    final later = _libraryAll
        .where((x) => (x["status"] ?? "") == "later")
        .length;
    final total = toRead + reading + finished + later;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border, width: 1.2),
        boxShadow: AppColors.mediumShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top bar: title + refresh ─────────────────────────
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(22)),
              border: Border(
                  bottom:
                      BorderSide(color: AppColors.border, width: 1)),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.auto_stories,
                    color: AppColors.primary, size: 16),
              ),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text("My Library",
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryDark,
                        letterSpacing: 0.1)),
                Text("Track your reading journey",
                    style: TextStyle(
                        color: AppColors.mediumText,
                        fontSize: 11)),
              ]),
              const Spacer(),
              GestureDetector(
                onTap: _loadAll,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.border, width: 1)),
                  child: const Icon(Icons.refresh_rounded,
                      color: AppColors.primary, size: 16),
                ),
              ),
            ]),
          ),

          // ── Profile + donut ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Avatar + name/email ──────────────────────
                Expanded(
                  flex: 5,
                  child: Row(
                    children: [
                      // Avatar circle
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppColors.primary.withOpacity(0.3),
                              width: 2),
                        ),
                        child: Center(
                          child: Text(
                            _initials(username),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              username,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.darkTextAlt,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.mediumText,
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Total books badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: AppColors.border, width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.menu_book_rounded,
                                      size: 12, color: AppColors.primary),
                                  const SizedBox(width: 5),
                                  Text(
                                    "$total books total",
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // ── Donut + legend ───────────────────────────
                Expanded(
                  flex: 4,
                  child: Column(
                    children: [
                      SizedBox(
                        width: 90,
                        height: 90,
                        child: AnimatedBuilder(
                          animation: _chartAnim,
                          builder: (_, __) => CustomPaint(
                            painter: _DonutChartPainter(
                              sections: total == 0
                                  ? [
                                      _DonutSection(1,
                                          AppColors.borderLight)
                                    ]
                                  : [
                                      _DonutSection(reading.toDouble(),
                                          AppColors.accent),
                                      _DonutSection(finished.toDouble(),
                                          const Color(0xFF4ADE80)),
                                      _DonutSection(toRead.toDouble(),
                                          const Color(0xFF60A5FA)),
                                      _DonutSection(later.toDouble(),
                                          AppColors.hintText),
                                    ],
                              progress: _chartAnim.value,
                              centerLabel: total.toString(),
                              centerSub: "books",
                              labelColor: AppColors.darkTextAlt,
                              subColor: AppColors.mediumText,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _donutLegend(
                          "Reading", reading, AppColors.accent),
                      const SizedBox(height: 3),
                      _donutLegend("Finished", finished,
                          const Color(0xFF4ADE80)),
                      const SizedBox(height: 3),
                      _donutLegend(
                          "To Read", toRead, const Color(0xFF60A5FA)),
                      const SizedBox(height: 3),
                      _donutLegend(
                          "Later", later, AppColors.hintText),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _donutLegend(String label, int count, Color color) {
    return Row(children: [
      Container(
          width: 7,
          height: 7,
          decoration:
              BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 5),
      Expanded(
          child: Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: AppColors.mediumText,
                  fontWeight: FontWeight.w500))),
      Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(4)),
        child: Text(count.toString(),
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: color)),
      ),
    ]);
  }

  // ─── About Me ─────────────────────────────────────────────────────────────

  Widget _buildAboutMeCard() {
    final email = (_profile?["email"] ?? "").toString();
    return _sectionCard(
      icon: Icons.person_outline_rounded,
      title: "About Me",
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        if (!_editingProfile)
          _actionBtn("Edit", Icons.edit_outlined,
              () => setState(() => _editingProfile = true)),
        if (_editingProfile) ...[
          _actionBtn("Save", Icons.check_rounded, _saveProfile,
              filled: true),
          const SizedBox(width: 6),
          _actionBtn("Reset", Icons.refresh_rounded, _resetProfileEdits),
        ],
      ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _editingProfile
            ? _textField(_usernameCtrl, "Name")
            : _infoRow("Name",
                (_profile?["username"] ?? "").toString()),
        const SizedBox(height: 10),
        _infoRow("Email", email, muted: true),
        const SizedBox(height: 14),
        _sectionLabel("Interests"),
        const SizedBox(height: 8),
        _multiSelectChips(
            options: _interestOptions,
            selected: _interestsDraft,
            enabled: _editingProfile,
            onToggle: (v) => setState(() {
                  if (_interestsDraft.contains(v))
                    _interestsDraft.remove(v);
                  else
                    _interestsDraft.add(v);
                })),
        const SizedBox(height: 14),
        _sectionLabel("Preferred emotions"),
        const SizedBox(height: 8),
        _multiSelectChips(
            options: _emotionOptions,
            selected: _emotionsDraft,
            enabled: _editingProfile,
            onToggle: (v) => setState(() {
                  if (_emotionsDraft.contains(v))
                    _emotionsDraft.remove(v);
                  else
                    _emotionsDraft.add(v);
                })),
        const SizedBox(height: 14),
        _editingProfile
            ? _textField(_bioCtrl, "Bio (1–2 lines)", maxLines: 2)
            : _infoRow(
                "Bio",
                (_profile?["bio"] ?? "").toString().isEmpty
                    ? "—"
                    : (_profile?["bio"] ?? "").toString()),
      ]),
    );
  }

  // ─── Diary ────────────────────────────────────────────────────────────────

  Widget _buildDiaryCard() {
    return _sectionCard(
      icon: Icons.edit_note_rounded,
      title: "My Diary",
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(
          width: 150,
          height: 34,
          child: TextField(
            onChanged: (v) => setState(() => _noteSearch = v),
            style: const TextStyle(
                fontSize: 12, color: AppColors.darkText),
            decoration: InputDecoration(
              hintText: "Search…",
              hintStyle: const TextStyle(
                  fontSize: 11, color: AppColors.hintText),
              prefixIcon: const Icon(Icons.search,
                  size: 15, color: AppColors.mediumText),
              filled: true,
              fillColor: AppColors.backgroundAlt,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                      color: AppColors.primary, width: 1.5)),
            ),
          ),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: _showAddNoteDialog,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8)),
            child:
                const Icon(Icons.add, size: 18, color: Colors.white),
          ),
        ),
      ]),
      child: Column(children: [
        if (_notesFiltered.isEmpty)
          _emptyState(
              title: "No notes yet",
              subtitle: "Tap + to start your reading diary.",
              icon: Icons.note_add_outlined,
              actionText: "Add Note",
              onAction: _showAddNoteDialog)
        else
          Column(
            children: _notesFiltered.take(3).map((n) {
              final id = (n["id"] ?? "").toString();
              final title =
                  (n["title"] ?? "").toString().trim();
              final text = (n["text"] ?? "").toString().trim();
              final mood = (n["mood"] ?? "").toString();
              final pinned = (n["pinned"] ?? false) == true;
              final createdAt =
                  (n["created_at"] ?? "").toString();
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _noteTile(
                  title:
                      title.isEmpty ? "Untitled" : title,
                  subtitle: text,
                  mood: mood,
                  date: createdAt.isEmpty
                      ? ""
                      : createdAt.split("T").first,
                  pinned: pinned,
                  onDelete: () => _confirmDelete(
                      title: "Delete note?",
                      onYes: () => _deleteNote(id)),
                ),
              );
            }).toList(),
          ),
      ]),
    );
  }

  // ─── Vision & Mission ─────────────────────────────────────────────────────

  Widget _buildVisionMissionCard() {
    return _sectionCard(
      icon: Icons.flag_outlined,
      title: "Vision & Mission",
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _editingProfile
            ? _textField(_visionCtrl, "Vision", maxLines: 2)
            : _vmRow(Icons.visibility_outlined, "Vision",
                (_profile?["vision"] ?? "").toString()),
        const SizedBox(height: 10),
        _editingProfile
            ? _textField(_missionCtrl, "Mission", maxLines: 2)
            : _vmRow(Icons.rocket_launch_outlined, "Mission",
                (_profile?["mission"] ?? "").toString()),
        const SizedBox(height: 14),
        _sectionLabel("Goals"),
        const SizedBox(height: 8),
        if (_editingProfile) ...[
          ..._goalsDraft.asMap().entries.map((entry) {
            final i = entry.key;
            final ctrl =
                TextEditingController(text: entry.value);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Expanded(child: _textField(ctrl, "Goal ${i + 1}")),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: BorderRadius.circular(8)),
                  child: IconButton(
                      onPressed: () => setState(
                          () => _goalsDraft.removeAt(i)),
                      icon: const Icon(Icons.close,
                          size: 16, color: AppColors.error)),
                ),
              ]),
            );
          }),
          TextButton.icon(
            onPressed: () =>
                setState(() => _goalsDraft.add("")),
            icon: const Icon(Icons.add,
                color: AppColors.primary, size: 16),
            label: const Text("Add goal",
                style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12)),
          ),
        ] else ...[
          if ((_profile?["goals"] as List?)?.isEmpty ?? true)
            const Text("—",
                style: TextStyle(color: AppColors.mediumText))
          else
            Column(
              children:
                  List<String>.from(_profile?["goals"] ?? [])
                      .where((x) => x.trim().isNotEmpty)
                      .map((g) => Padding(
                            padding:
                                const EdgeInsets.only(bottom: 7),
                            child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Container(
                                      margin: const EdgeInsets.only(
                                          top: 5, right: 8),
                                      width: 5,
                                      height: 5,
                                      decoration: const BoxDecoration(
                                          color: AppColors.accent,
                                          shape: BoxShape.circle)),
                                  Expanded(
                                      child: Text(g,
                                          style: const TextStyle(
                                              color:
                                                  AppColors.darkText,
                                              fontSize: 13))),
                                ]),
                          ))
                      .toList(),
            ),
        ],
      ]),
    );
  }

  Widget _vmRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: AppColors.backgroundAlt,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderLight)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(7)),
          child: Icon(icon, size: 14, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mediumText)),
            const SizedBox(height: 3),
            Text(value.isEmpty ? "—" : value,
                style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.darkText,
                    height: 1.4)),
          ]),
        ),
      ]),
    );
  }

  // ─── Reading Tracker ──────────────────────────────────────────────────────

  Widget _buildReadingTrackerCard() {
    return _sectionCard(
      icon: Icons.menu_book_rounded,
      title: "Reading Tracker",
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(
          width: 150,
          height: 34,
          child: TextField(
            onChanged: (v) =>
                setState(() => _librarySearch = v),
            style: const TextStyle(
                fontSize: 12, color: AppColors.darkText),
            decoration: InputDecoration(
              hintText: "Search…",
              hintStyle: const TextStyle(
                  fontSize: 11, color: AppColors.hintText),
              prefixIcon: const Icon(Icons.search,
                  size: 15, color: AppColors.mediumText),
              filled: true,
              fillColor: AppColors.backgroundAlt,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                      color: AppColors.primary, width: 1.5)),
            ),
          ),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: _showAddLibraryDialog,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8)),
            child:
                const Icon(Icons.add, size: 18, color: Colors.white),
          ),
        ),
      ]),
      child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildTabBar(),
        const SizedBox(height: 12),
        if (_activeTab == "reading" &&
            _libraryByTab.isNotEmpty) ...[
          _buildProgressSummaryBar(),
          const SizedBox(height: 4),
        ],
        if (_libraryByTab.isEmpty)
          _emptyState(
              title: "No books here yet",
              subtitle: "Tap + to add your first book.",
              icon: Icons.library_add_outlined,
              actionText: "Add Book",
              onAction: _showAddLibraryDialog)
        else
          Column(
            children: _libraryByTab.take(8).map((it) {
              final id = (it["id"] ?? "").toString();
              final title =
                  (it["book_title"] ?? "").toString();
              final author = (it["author"] ?? "").toString();
              final status = (it["status"] ?? "").toString();
              final progress = _safeInt(it["progress"]);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _libraryTile(
                  id: id,
                  title: title,
                  author: author.isEmpty ? "—" : author,
                  status: status,
                  progress: progress,
                  onProgressChanged: status == "reading"
                      ? (v) => _updateLibraryProgress(id, v)
                      : null,
                  onMove: (s) => _updateLibraryStatus(id, s),
                  onDelete: () => _confirmDelete(
                      title: "Remove this book?",
                      onYes: () => _deleteLibraryItem(id)),
                  onQuickNote: _showAddNoteDialog,
                ),
              );
            }).toList(),
          ),
      ]),
    );
  }

  Widget _buildProgressSummaryBar() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: _libraryByTab.take(6).map((book) {
          final title = (book["book_title"] ?? "").toString();
          final progress = _safeInt(book["progress"]);
          final color = _bookCoverColor(title);
          return Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Row(children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.7)]),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                    child: Text(_bookInitials(title),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 10))),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkText)),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: progress / 100,
                          minHeight: 5,
                          backgroundColor:
                              color.withOpacity(0.12),
                          valueColor:
                              AlwaysStoppedAnimation(color),
                        ),
                      ),
                    ]),
              ),
              const SizedBox(width: 8),
              Text("$progress%",
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: color)),
            ]),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabBar() {
    Widget tab(String key, String label, String emoji) {
      final active = _activeTab == key;
      final count = _libraryAll
          .where((x) => (x["status"] ?? "") == key)
          .length;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _activeTab = key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 7),
            decoration: BoxDecoration(
              gradient:
                  active ? AppColors.accentGradient : null,
              color: active ? null : AppColors.backgroundAlt,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                  color: active
                      ? AppColors.primary
                      : AppColors.border),
              boxShadow:
                  active ? AppColors.smallShadow : null,
            ),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji,
                      style: const TextStyle(fontSize: 13)),
                  const SizedBox(height: 1),
                  Text(label,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 9,
                          color: active
                              ? Colors.white
                              : AppColors.mediumText)),
                  Text(count.toString(),
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: active
                              ? Colors.white
                              : AppColors.darkText)),
                ]),
          ),
        ),
      );
    }

    return Row(children: [
      tab("to_read", "To Read", "📋"),
      const SizedBox(width: 5),
      tab("reading", "Reading", "📖"),
      const SizedBox(width: 5),
      tab("finished", "Done", "✅"),
      const SizedBox(width: 5),
      tab("later", "Later", "🕐"),
    ]);
  }

  // ─── Library Tile ─────────────────────────────────────────────────────────

  Widget _libraryTile({
    required String id,
    required String title,
    required String author,
    required String status,
    required int progress,
    required VoidCallback onDelete,
    required VoidCallback onQuickNote,
    required ValueChanged<String> onMove,
    ValueChanged<int>? onProgressChanged,
  }) {
    String statusLabel(String s) {
      switch (s) {
        case "to_read":
          return "To Read";
        case "reading":
          return "Reading";
        case "finished":
          return "Finished";
        case "later":
          return "Later";
        default:
          return s;
      }
    }

    Color statusColor(String s) {
      switch (s) {
        case "reading":
          return AppColors.accent;
        case "finished":
          return AppColors.success;
        case "to_read":
          return AppColors.primary;
        case "later":
          return AppColors.mediumText;
        default:
          return AppColors.mediumText;
      }
    }

    final coverColor = _bookCoverColor(title);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWarm,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.smallShadow,
      ),
      padding: const EdgeInsets.all(11),
      child:
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 42,
          height: 58,
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [coverColor, coverColor.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(7),
            boxShadow: [
              BoxShadow(
                  color: coverColor.withOpacity(0.35),
                  blurRadius: 5,
                  offset: const Offset(2, 3))
            ],
          ),
          child: Stack(children: [
            Positioned(
                left: 6,
                top: 0,
                bottom: 0,
                child: Container(
                    width: 1.5,
                    color: Colors.white.withOpacity(0.25))),
            Center(
                child: Text(_bookInitials(title),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12))),
          ]),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                      child: Text(title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkText,
                              fontSize: 13))),
                  const SizedBox(width: 6),
                  _statusBadge(
                      statusLabel(status), statusColor(status)),
                ]),
                if (author != "—") ...[
                  const SizedBox(height: 2),
                  Text(author,
                      style: const TextStyle(
                          color: AppColors.mediumText,
                          fontSize: 11)),
                ],
                if (status == "reading") ...[
                  const SizedBox(height: 7),
                  Row(children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: progress / 100,
                          minHeight: 6,
                          backgroundColor:
                              coverColor.withOpacity(0.12),
                          valueColor:
                              AlwaysStoppedAnimation(coverColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text("$progress%",
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: coverColor)),
                  ]),
                  SizedBox(
                    height: 24,
                    child: SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: Colors.transparent,
                        inactiveTrackColor: Colors.transparent,
                        thumbColor: coverColor,
                        overlayColor:
                            coverColor.withOpacity(0.12),
                        thumbShape:
                            const RoundSliderThumbShape(
                                enabledThumbRadius: 6),
                        trackHeight: 0,
                      ),
                      child: Slider(
                        value: progress.toDouble(),
                        min: 0,
                        max: 100,
                        divisions: 100,
                        onChanged: onProgressChanged == null
                            ? null
                            : (v) =>
                                onProgressChanged(v.round()),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 5),
                Row(children: [
                  GestureDetector(
                    onTap: onQuickNote,
                    child: const Row(children: [
                      Icon(Icons.edit_note_rounded,
                          size: 13, color: AppColors.primary),
                      SizedBox(width: 3),
                      Text("Note",
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary)),
                    ]),
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    onSelected: onMove,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11)),
                    color: AppColors.surface,
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                          value: "to_read",
                          child: Text("📋 To Read")),
                      PopupMenuItem(
                          value: "reading",
                          child: Text("📖 Reading")),
                      PopupMenuItem(
                          value: "finished",
                          child: Text("✅ Finished")),
                      PopupMenuItem(
                          value: "later",
                          child: Text("🕐 Later")),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                          color: AppColors.backgroundAlt,
                          borderRadius:
                              BorderRadius.circular(6),
                          border: Border.all(
                              color: AppColors.border)),
                      child: const Icon(Icons.more_horiz,
                          size: 15,
                          color: AppColors.mediumText),
                    ),
                  ),
                  const SizedBox(width: 5),
                  GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                          color: AppColors.errorLight,
                          borderRadius:
                              BorderRadius.circular(6)),
                      child: const Icon(Icons.delete_outline,
                          size: 13, color: AppColors.error),
                    ),
                  ),
                ]),
              ]),
        ),
      ]),
    );
  }

  // ─── Shared helpers ───────────────────────────────────────────────────────

  Color _bookCoverColor(String title) {
    const colors = [
      AppColors.primary,
      Color(0xFFE74C6E),
      AppColors.accent,
      Color(0xFF9B59B6),
      Color(0xFFFF8C42),
      AppColors.secondary,
      Color(0xFF2980B9),
      Color(0xFFF39C12),
      AppColors.primaryDark,
      Color(0xFF6C5CE7),
    ];
    final hash = title.codeUnits.fold(0, (a, b) => a + b);
    return colors[hash % colors.length];
  }

  String _bookInitials(String title) {
    final words = title.trim().split(RegExp(r"\s+"));
    if (words.isEmpty) return "?";
    if (words.length == 1)
      return words[0]
          .substring(0, math.min(2, words[0].length))
          .toUpperCase();
    return (words[0][0] + words[1][0]).toUpperCase();
  }

  Widget _sectionCard(
      {required IconData icon,
      required String title,
      Widget? trailing,
      required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.mediumShadow,
      ),
      padding: const EdgeInsets.all(15),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8)),
              child:
                  Icon(icon, size: 16, color: AppColors.primary)),
          const SizedBox(width: 9),
          Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.darkText,
                      letterSpacing: 0.1))),
          if (trailing != null) trailing,
        ]),
        const Divider(color: AppColors.borderLight, height: 20),
        child,
      ]),
    );
  }

  Widget _sectionLabel(String label) => Text(label,
      style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12,
          color: AppColors.darkText,
          letterSpacing: 0.1));

  Widget _actionBtn(String label, IconData icon, VoidCallback onTap,
      {bool filled = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: filled ? AppColors.primary : AppColors.primaryLight,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
              color: filled ? AppColors.primary : AppColors.border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon,
              size: 12,
              color: filled ? Colors.white : AppColors.primary),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: filled ? Colors.white : AppColors.primary)),
        ]),
      ),
    );
  }

  Widget _infoRow(String label, String value,
      {bool muted = false}) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
          width: 60,
          child: Text(label,
              style: TextStyle(
                  color: muted
                      ? AppColors.lightText
                      : AppColors.mediumText,
                  fontWeight: FontWeight.w600,
                  fontSize: 12))),
      const SizedBox(width: 8),
      Expanded(
          child: Text(value,
              style: TextStyle(
                  color: muted
                      ? AppColors.mediumText
                      : AppColors.darkText,
                  fontSize: 13))),
    ]);
  }

  Widget _textField(TextEditingController c, String label,
      {int maxLines = 1}) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      style:
          const TextStyle(color: AppColors.darkText, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
            color: AppColors.mediumText, fontSize: 12),
        filled: true,
        fillColor: AppColors.surfaceWarm,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide:
                const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide:
                const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(
                color: AppColors.primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 10),
      ),
    );
  }

  Widget _multiSelectChips({
    required List<String> options,
    required List<String> selected,
    required bool enabled,
    required ValueChanged<String> onToggle,
  }) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: options.map((o) {
        final active = selected.contains(o);
        return GestureDetector(
          onTap: enabled ? () => onToggle(o) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 130),
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: active
                  ? AppColors.primary
                  : AppColors.backgroundAlt,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                  color: active
                      ? AppColors.primary
                      : AppColors.border),
            ),
            child: Text(o,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: active
                        ? Colors.white
                        : AppColors.mediumText)),
          ),
        );
      }).toList(),
    );
  }

  Widget _noteTile({
    required String title,
    required String subtitle,
    required String mood,
    required String date,
    required bool pinned,
    required VoidCallback onDelete,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWarm,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.smallShadow,
      ),
      padding: const EdgeInsets.all(11),
      child:
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 33,
          height: 33,
          decoration: BoxDecoration(
              color: pinned
                  ? AppColors.accentLight
                  : AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8)),
          child: Center(
              child: Text(_moodEmoji(mood),
                  style: const TextStyle(fontSize: 15))),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                      child: Text(title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkText,
                              fontSize: 12))),
                  if (pinned)
                    const Icon(Icons.push_pin_rounded,
                        size: 11, color: AppColors.accent),
                ]),
                const SizedBox(height: 3),
                Text(subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.mediumText,
                        fontSize: 11)),
                const SizedBox(height: 5),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(4)),
                    child: Text(mood.isEmpty ? "—" : mood,
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary)),
                  ),
                  const SizedBox(width: 5),
                  Text(date,
                      style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.lightText)),
                ]),
              ]),
        ),
        GestureDetector(
          onTap: onDelete,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(6)),
            child: const Icon(Icons.delete_outline,
                size: 13, color: AppColors.error),
          ),
        ),
      ]),
    );
  }

  Widget _statusBadge(String label, Color color) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withOpacity(0.12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: color)),
    );
  }

  Widget _emptyState({
    required String title,
    required String subtitle,
    required IconData icon,
    required String actionText,
    required VoidCallback onAction,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: AppColors.border),
          color: AppColors.backgroundAlt),
      child: Row(children: [
        Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, size: 19, color: AppColors.primary)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkText,
                        fontSize: 12)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        color: AppColors.mediumText,
                        fontSize: 11)),
              ]),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: onAction,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(
                horizontal: 11, vertical: 8),
            textStyle: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700),
          ),
          child: Text(actionText),
        ),
      ]),
    );
  }

  Future<void> _confirmDelete(
      {required String title,
      required Future<void> Function() onYes}) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(
            horizontal: 60, vertical: 220),
        child: Container(
          decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppColors.largeShadow),
          padding: const EdgeInsets.all(18),
          child:
              Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.warning_amber_rounded,
                  color: AppColors.error, size: 22),
            ),
            const SizedBox(height: 10),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkText,
                    fontSize: 14)),
            const SizedBox(height: 5),
            const Text("This cannot be undone.",
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.mediumText, fontSize: 11)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.mediumText,
                      side: const BorderSide(
                          color: AppColors.border),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(8))),
                  child: const Text("Cancel",
                      style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(8))),
                  child: const Text("Delete",
                      style: TextStyle(fontSize: 12)),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
    if (ok == true) await onYes();
  }

  String _moodEmoji(String mood) {
    switch (mood.toLowerCase()) {
      case "happy":
        return "😊";
      case "sad":
        return "😢";
      case "inspired":
        return "✨";
      case "scary":
        return "😱";
      case "romantic":
        return "💕";
      case "dark":
        return "🌑";
      case "adventurous":
        return "⚡";
      case "mysterious":
        return "🔮";
      case "neutral":
        return "😐";
      default:
        return "📝";
    }
  }
}

// ─── Donut Chart Painter ──────────────────────────────────────────────────────

class _DonutSection {
  final double value;
  final Color color;
  const _DonutSection(this.value, this.color);
}

class _DonutChartPainter extends CustomPainter {
  final List<_DonutSection> sections;
  final double progress;
  final String centerLabel;
  final String centerSub;
  final Color labelColor;
  final Color subColor;

  const _DonutChartPainter({
    required this.sections,
    required this.progress,
    required this.centerLabel,
    required this.centerSub,
    this.labelColor = AppColors.darkTextAlt,
    this.subColor = AppColors.mediumText,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 5;
    const stroke = 11.0;
    const gap = 0.05;
    final total = sections.fold(0.0, (s, e) => s + e.value);

    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = AppColors.borderLight
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke);

    if (total == 0) return;

    double start = -math.pi / 2;
    for (final s in sections) {
      final sweep =
          (s.value / total) * 2 * math.pi * progress - gap;
      if (sweep <= 0) {
        start += (s.value / total) * 2 * math.pi * progress;
        continue;
      }
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        false,
        Paint()
          ..color = s.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round,
      );
      start += sweep + gap;
    }

    _drawText(canvas, center, centerLabel,
        TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: labelColor),
        offsetY: -6);
    _drawText(canvas, center, centerSub,
        TextStyle(fontSize: 9, color: subColor),
        offsetY: 12);
  }

  void _drawText(Canvas canvas, Offset center, String text,
      TextStyle style,
      {double offsetY = 0}) {
    final tp = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr)
      ..layout();
    tp.paint(canvas,
        center + Offset(-tp.width / 2, -tp.height / 2 + offsetY));
  }

  @override
  bool shouldRepaint(_DonutChartPainter old) =>
      old.progress != progress;
}