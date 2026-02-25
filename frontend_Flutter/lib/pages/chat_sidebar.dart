import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../providers/theme_provider.dart';
import '../theme/theme_colors.dart';

class ConversationSidebar extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onClose;
  final String? selectedConversationId;
  final Function(String) onConversationSelected;
  final VoidCallback onNewConversation;
  final bool isLoading;
  final String? loadingConversationId;

  const ConversationSidebar({
    super.key,
    required this.isOpen,
    required this.onClose,
    this.selectedConversationId,
    required this.onConversationSelected,
    required this.onNewConversation,
    this.isLoading = false,
    this.loadingConversationId,
  });

  @override
  State<ConversationSidebar> createState() => _ConversationSidebarState();
}

class _ConversationSidebarState extends State<ConversationSidebar> {
  List<ConversationSummary> _conversations = [];
  bool _loading = false;
  String? _lastConversationId;
  final Map<String, String> _formattedTimeCache = {};

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  @override
  void didUpdateWidget(covariant ConversationSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!mounted) return;
    if (widget.selectedConversationId != oldWidget.selectedConversationId) {
      if (widget.selectedConversationId != null &&
          widget.selectedConversationId != _lastConversationId) {
        _lastConversationId = widget.selectedConversationId;
        _loadConversations();
      }
    }
  }

  Future<void> _loadConversations() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final conversations = await ApiService.getConversations();
      if (!mounted) return;
      _formattedTimeCache.clear();
      for (final conv in conversations) {
        _formattedTimeCache[conv.conversationId] = _formatTime(conv.updatedAt);
      }
      setState(() {
        _conversations = conversations;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _deleteConversation(String conversationId) async {
    if (!mounted) return;
    final colors = context.read<ThemeProvider>().colors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('删除对话'),
            content: const Text('确定要删除这个对话吗？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: colors.error),
                child: const Text('删除'),
              ),
            ],
          ),
    );
    if (!mounted) return;
    if (confirmed == true) {
      await ApiService.deleteConversation(conversationId: conversationId);
      if (!mounted) return;
      _loadConversations();
    }
  }

  Future<void> _renameConversation(ConversationSummary conversation) async {
    if (!mounted) return;
    final controller = TextEditingController(text: conversation.title ?? '新对话');
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('重命名对话'),
            content: TextField(controller: controller, autofocus: true),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('确定'),
              ),
            ],
          ),
    );
    if (!mounted) return;
    if (confirmed == true && controller.text.isNotEmpty) {
      await ApiService.renameConversation(
        conversationId: conversation.conversationId,
        title: controller.text,
      );
      if (!mounted) return;
      _loadConversations();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;
    return Container(
      color: colors.surface,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(colors),
            Expanded(child: _buildConversationList(colors)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '对话历史',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 20, color: colors.textSecondary),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: widget.onClose,
          ),
        ],
      ),
    );
  }

  Widget _buildConversationList(ThemeColors colors) {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: colors.primary));
    }
    if (_conversations.isEmpty) {
      return Center(
        child: Text('暂无对话', style: TextStyle(color: colors.textSecondary)),
      );
    }
    return ListView.builder(
      itemCount: _conversations.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildNewItem(colors);
        }
        final conversation = _conversations[index - 1];
        return _buildConversationItem(conversation, colors);
      },
    );
  }

  Widget _buildNewItem(ThemeColors colors) {
    final isCreatingNew = widget.isLoading &&
        (widget.loadingConversationId == null ||
            widget.loadingConversationId!.isEmpty);
    return ListTile(
      leading: isCreatingNew
          ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.primary,
              ),
            )
          : Icon(Icons.add, color: colors.primary),
      title: Text(
        isCreatingNew ? '创建中...' : '新建对话',
        style: TextStyle(color: colors.primary),
      ),
      onTap: isCreatingNew ? null : widget.onNewConversation,
    );
  }

  Widget _buildConversationItem(
    ConversationSummary conversation,
    ThemeColors colors,
  ) {
    final isSelected =
        conversation.conversationId == widget.selectedConversationId;
    final isThisLoading = widget.isLoading &&
        widget.loadingConversationId == conversation.conversationId;
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? colors.primary.withValues(alpha: 0.15) : null,
        border: Border(
          left: BorderSide(
            color: isSelected ? colors.primary : Colors.transparent,
            width: 4,
          ),
        ),
      ),
      child: ListTile(
        title: Row(
          children: [
            Expanded(
              child: Text(
                conversation.title ?? '新对话',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected ? colors.primary : colors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isThisLoading) ...[
              const SizedBox(width: 8),
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.primary,
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          _formattedTimeCache[conversation.conversationId] ?? '',
          style: TextStyle(fontSize: 12, color: colors.textSecondary),
        ),
        onTap: () => widget.onConversationSelected(conversation.conversationId),
        trailing: isThisLoading
            ? null
            : SizedBox(
              width: 40,
              child: PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                onSelected: (value) {
                  if (value == 'rename') {
                    _renameConversation(conversation);
                  }
                  if (value == 'delete') {
                    _deleteConversation(conversation.conversationId);
                  }
                },
                itemBuilder:
                    (context) => [
                      const PopupMenuItem(value: 'rename', child: Text('重命名')),
                      const PopupMenuItem(value: 'delete', child: Text('删除')),
                    ],
              ),
            ),
      ),
    );
  }

  String _formatTime(String timeStr) {
    try {
      final dt = DateTime.parse(timeStr);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inDays == 0) return '今天';
      if (diff.inDays == 1) return '昨天';
      if (diff.inDays < 7) return '${diff.inDays}天前';
      return '${dt.month}月${dt.day}日';
    } catch (e) {
      return '';
    }
  }
}
