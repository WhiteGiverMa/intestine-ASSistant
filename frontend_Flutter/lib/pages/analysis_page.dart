import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../widgets/error_dialog.dart';
import '../widgets/compact_tab_switcher.dart';
import '../widgets/analysis_result.dart';
import '../widgets/app_header.dart';
import '../providers/theme_provider.dart';
import '../theme/theme_colors.dart';
import '../theme/theme_decorations.dart';
import 'settings_page.dart';
import 'login_page.dart';
import 'chat_sidebar.dart';
import 'chat_message_widgets.dart';
import 'chat_settings.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class AnalysisPageContent extends StatelessWidget {
  const AnalysisPageContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const AnalysisPage();
  }
}

class _AnalysisPageState extends State<AnalysisPage> {
  int _currentTab = 0;

  AiStatus? _aiStatus;
  List<ChatMessage> _messages = [];
  String? _conversationId;
  bool _chatLoading = false;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _analysisType = 'weekly';
  bool _analysisLoading = false;
  AnalysisResult? _result;
  String? _error;
  AppError? _statusError;

  String? _recordsStartDate;
  String? _recordsEndDate;

  bool _sidebarOpen = false;
  bool _thinkingEnabled = false;
  ThinkingIntensity _thinkingIntensity = ThinkingIntensity.medium;
  String? _systemPrompt;
  bool _streamingEnabled = false;

  @override
  void initState() {
    super.initState();
    _initPage();
  }

  Future<void> _initPage() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    _loadChatSettings();
    if (token != null) {
      _checkAiStatus();
    } else {
      setState(() {
        _aiStatus = AiStatus(
          hasApiKey: false,
          hasApiUrl: false,
          hasModel: false,
          isConfigured: false,
        );
      });
    }
  }

  Future<void> _loadChatSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _thinkingEnabled = prefs.getBool('thinking_enabled') ?? false;
      final intensityStr = prefs.getString('thinking_intensity') ?? 'medium';
      _thinkingIntensity = ThinkingIntensity.fromApiValue(intensityStr);
      _systemPrompt = prefs.getString('system_prompt');
      _streamingEnabled = prefs.getBool('streaming_enabled') ?? false;
    });
  }

  Future<void> _checkAiStatus() async {
    try {
      final status = await ApiService.checkAiStatus();
      setState(() {
        _aiStatus = status;
        _statusError = null;
      });
      if (status.isConfigured) {
        _loadChatHistory();
      }
    } catch (e) {
      final appError = ErrorHandler.handleError(e);
      if (appError.type == ErrorType.auth) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');
        await prefs.remove('user');
        setState(() {
          _statusError = appError;
          _aiStatus = AiStatus(
            hasApiKey: false,
            hasApiUrl: false,
            hasModel: false,
            isConfigured: false,
          );
        });
      } else {
        setState(() {
          _statusError = appError;
          _aiStatus = AiStatus(
            hasApiKey: false,
            hasApiUrl: false,
            hasModel: false,
            isConfigured: false,
          );
        });
      }
    }
  }

  Future<void> _loadChatHistory() async {
    try {
      final session = await ApiService.getChatHistory(
        conversationId: _conversationId,
      );
      setState(() {
        _messages = session.messages;
        if (_conversationId == null && session.conversationId.isNotEmpty) {
          _conversationId = session.conversationId;
        }
      });
      _scrollToBottom();
    } catch (e) {
      // ignore
    }
  }

  Future<void> _loadConversation(String conversationId) async {
    setState(() {
      _conversationId = conversationId;
      _messages = [];
    });
    await _loadChatHistory();
  }

  void _newConversation() {
    setState(() {
      _conversationId = null;
      _messages = [];
      _sidebarOpen = false;
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _messageController.clear();

    final tempUserMessage = ChatMessage(
      messageId: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      conversationId: _conversationId ?? '',
      role: 'user',
      content: message,
      createdAt: DateTime.now().toIso8601String(),
    );
    setState(() {
      _messages.add(tempUserMessage);
      _chatLoading = true;
    });
    _scrollToBottom();

    if (_streamingEnabled) {
      await _sendMessageStream(message, tempUserMessage);
    } else {
      await _sendMessageNormal(message, tempUserMessage);
    }
  }

  Future<void> _sendMessageNormal(
    String message,
    ChatMessage tempUserMessage,
  ) async {
    try {
      final response = await ApiService.sendMessage(
        message: message,
        conversationId: _conversationId,
        recordsStartDate: _recordsStartDate,
        recordsEndDate: _recordsEndDate,
        thinkingIntensity: _thinkingEnabled
            ? _thinkingIntensity.toApiValue()
            : null,
        systemPrompt: _systemPrompt,
      );
      setState(() {
        _messages.removeWhere((m) => m.messageId == tempUserMessage.messageId);
        _conversationId ??= response.conversationId;
        final userMessage = ChatMessage(
          messageId: 'user-${DateTime.now().millisecondsSinceEpoch}',
          conversationId: response.conversationId,
          role: 'user',
          content: message,
          createdAt: response.createdAt,
        );
        _messages.add(userMessage);
        _messages.add(response);
        _chatLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      final appError = ErrorHandler.handleError(e);
      setState(() {
        _messages.removeWhere((m) => m.messageId == tempUserMessage.messageId);
        _chatLoading = false;
      });
      if (appError.type == ErrorType.auth) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');
        await prefs.remove('user');
        if (mounted) {
          _showAuthError();
        }
      } else {
        if (mounted) {
          ErrorDialog.showFromAppError(
            context,
            error: appError,
            onRetry: () => _sendMessage(),
          );
        }
      }
    }
  }

  Future<void> _sendMessageStream(
    String message,
    ChatMessage tempUserMessage,
  ) async {
    String? finalConversationId;
    String? finalMessageId;
    final tempAssistantMessageId =
        'temp-assistant-${DateTime.now().millisecondsSinceEpoch}';
    final tempAssistantMessage = ChatMessage(
      messageId: tempAssistantMessageId,
      conversationId: _conversationId ?? '',
      role: 'assistant',
      content: '',
      createdAt: DateTime.now().toIso8601String(),
    );

    setState(() {
      _messages.removeWhere((m) => m.messageId == tempUserMessage.messageId);
      final userMessage = ChatMessage(
        messageId: 'user-${DateTime.now().millisecondsSinceEpoch}',
        conversationId: _conversationId ?? '',
        role: 'user',
        content: message,
        createdAt: DateTime.now().toIso8601String(),
      );
      _messages.add(userMessage);
      _messages.add(tempAssistantMessage);
    });
    _scrollToBottom();

    try {
      await for (final chunk in ApiService.sendMessageStream(
        message: message,
        conversationId: _conversationId,
        recordsStartDate: _recordsStartDate,
        recordsEndDate: _recordsEndDate,
        thinkingIntensity: _thinkingEnabled
            ? _thinkingIntensity.toApiValue()
            : null,
        systemPrompt: _systemPrompt,
      )) {
        finalConversationId ??= chunk.conversationId;

        setState(() {
          final index = _messages.indexWhere(
            (m) => m.messageId == tempAssistantMessageId,
          );
          if (index != -1) {
            final currentMessage = _messages[index];
            _messages[index] = ChatMessage(
              messageId: chunk.messageId ?? tempAssistantMessageId,
              conversationId:
                  chunk.conversationId ?? currentMessage.conversationId,
              role: 'assistant',
              content: currentMessage.content + (chunk.content ?? ''),
              createdAt: currentMessage.createdAt,
              thinkingContent: chunk.reasoningContent != null
                  ? (currentMessage.thinkingContent ?? '') +
                        chunk.reasoningContent!
                  : currentMessage.thinkingContent,
            );
          }
        });
        _scrollToBottom();

        if (chunk.done && chunk.messageId != null) {
          finalMessageId = chunk.messageId;
        }
      }

      setState(() {
        _conversationId ??= finalConversationId;
        final index = _messages.indexWhere(
          (m) => m.messageId == tempAssistantMessageId,
        );
        if (index != -1 && finalMessageId != null) {
          final currentMessage = _messages[index];
          _messages[index] = ChatMessage(
            messageId: finalMessageId,
            conversationId: currentMessage.conversationId,
            role: 'assistant',
            content: currentMessage.content,
            createdAt: currentMessage.createdAt,
            thinkingContent: currentMessage.thinkingContent,
          );
        }
        _chatLoading = false;
      });
    } catch (e) {
      final appError = ErrorHandler.handleError(e);
      setState(() {
        _messages.removeWhere((m) => m.messageId == tempAssistantMessageId);
        _chatLoading = false;
      });
      if (appError.type == ErrorType.auth) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');
        await prefs.remove('user');
        if (mounted) {
          _showAuthError();
        }
      } else {
        if (mounted) {
          ErrorDialog.showFromAppError(
            context,
            error: appError,
            onRetry: () => _sendMessage(),
          );
        }
      }
    }
  }

  Future<void> _analyze() async {
    setState(() {
      _analysisLoading = true;
      _error = null;
    });

    try {
      final result = await ApiService.analyzeData(analysisType: _analysisType);
      setState(() {
        _result = result;
        _analysisLoading = false;
      });
    } catch (e) {
      final appError = ErrorHandler.handleError(e);
      if (appError.type == ErrorType.auth) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');
        await prefs.remove('user');
        setState(() {
          _error = appError.message;
          _analysisLoading = false;
        });
      } else {
        setState(() {
          _error = appError.message;
          _analysisLoading = false;
        });
        if (mounted) {
          ErrorDialog.showFromAppError(
            context,
            error: appError,
            onRetry: () => _analyze(),
          );
        }
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showAuthError() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('登录已过期'),
        content: const Text('请重新登录'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
            child: const Text('去登录'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectRecordsDateRange() async {
    final now = DateTime.now();
    final firstDate = now.subtract(const Duration(days: 365));
    final lastDate = now;

    final startDate = await showDatePicker(
      context: context,
      initialDate: _recordsStartDate != null
          ? DateTime.parse(_recordsStartDate!)
          : now.subtract(const Duration(days: 7)),
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: '选择开始日期',
    );

    if (startDate == null || !mounted) return;

    final endDate = await showDatePicker(
      context: context,
      initialDate: _recordsEndDate != null
          ? DateTime.parse(_recordsEndDate!)
          : now,
      firstDate: startDate,
      lastDate: lastDate,
      helpText: '选择结束日期',
    );

    if (endDate == null || !mounted) return;

    setState(() {
      _recordsStartDate =
          '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
      _recordsEndDate =
          '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';
    });
  }

  void _clearRecordsDateRange() {
    setState(() {
      _recordsStartDate = null;
      _recordsEndDate = null;
    });
  }

  bool _isMobile() {
    return MediaQuery.of(context).size.width < 600;
  }

  bool _isAuthError() {
    return _error != null && (_error!.contains('登录') || _error!.contains('过期'));
  }

  void _toggleSidebar() {
    setState(() {
      _sidebarOpen = !_sidebarOpen;
    });
  }

  void _openSettings() {
    showChatSettings(
      context,
      onThinkingChanged: (enabled, intensity) {
        setState(() {
          _thinkingEnabled = enabled;
          _thinkingIntensity = intensity;
        });
      },
      onStreamingChanged: (enabled) {
        setState(() {
          _streamingEnabled = enabled;
        });
      },
    );
  }

  Future<void> _toggleThinking() async {
    final newValue = !_thinkingEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('thinking_enabled', newValue);
    setState(() {
      _thinkingEnabled = newValue;
    });
  }

  Future<void> _toggleStreaming() async {
    final newValue = !_streamingEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('streaming_enabled', newValue);
    setState(() {
      _streamingEnabled = newValue;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final colors = themeProvider.colors;

    return Scaffold(
      body: Container(
        decoration: ThemeDecorations.backgroundGradient(
          context,
          mode: themeProvider.mode,
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  AppHeader(
                    titleWidget: Row(
                      children: [
                        Text(
                          'AI 健康分析',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        CompactTabBar(
                          currentIndex: _currentTab,
                          onTabChanged: (index) =>
                              setState(() => _currentTab = index),
                          tabs: const [
                            CompactTabItem(
                              label: 'AI 对话',
                              content: SizedBox.shrink(),
                            ),
                            CompactTabItem(
                              label: '本地分析',
                              content: SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: _aiStatus?.isConfigured == true
                        ? GestureDetector(
                            onTap: _openSettings,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: colors.cardBackground,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.settings,
                                color: colors.textSecondary,
                                size: 20,
                              ),
                            ),
                          )
                        : null,
                  ),
                  Expanded(
                    child: CompactTabContent(
                      currentIndex: _currentTab,
                      onTabChanged: (index) =>
                          setState(() => _currentTab = index),
                      tabs: [
                        CompactTabItem(
                          label: 'AI 对话',
                          content: _buildChatLayout(colors),
                        ),
                        CompactTabItem(
                          label: '本地分析',
                          content: _buildLocalAnalysisView(colors),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_currentTab == 0 && _aiStatus?.isConfigured == true)
                _buildAnimatedSidebar(colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatLayout(ThemeColors colors) {
    if (_aiStatus == null) {
      return Center(child: CircularProgressIndicator(color: colors.primary));
    }

    if (_statusError != null) {
      return ErrorWidgetInline(
        error: _statusError!,
        showCopyButton: _statusError!.type != ErrorType.auth,
        onRetry: () {
          setState(() {
            _statusError = null;
          });
          _checkAiStatus();
        },
      );
    }

    if (!_aiStatus!.isConfigured) {
      return _buildNoApiPrompt(colors);
    }

    return _buildMainChatArea(colors);
  }

  Widget _buildAnimatedSidebar(ThemeColors colors) {
    final isMobile = _isMobile();
    final screenWidth = MediaQuery.of(context).size.width;
    final sidebarWidth = isMobile ? screenWidth * 0.8 : 280.0;
    const buttonTop = 72.0;

    return Stack(
      children: [
        if (isMobile && _sidebarOpen)
          GestureDetector(
            onTap: _toggleSidebar,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              color: Colors.black.withValues(alpha: _sidebarOpen ? 0.5 : 0),
            ),
          ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          left: _sidebarOpen ? 0 : -sidebarWidth,
          top: 0,
          bottom: 0,
          width: sidebarWidth,
          child: ConversationSidebar(
            isOpen: _sidebarOpen,
            onClose: _toggleSidebar,
            selectedConversationId: _conversationId,
            onConversationSelected: (id) {
              _loadConversation(id);
              if (isMobile) _toggleSidebar();
            },
            onNewConversation: _newConversation,
          ),
        ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          left: _sidebarOpen ? sidebarWidth + 8 : 12,
          top: buttonTop,
          child: GestureDetector(
            onTap: _toggleSidebar,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.cardBackground,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
              child: Icon(
                _sidebarOpen ? Icons.menu_open : Icons.menu,
                color: colors.textSecondary,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainChatArea(ThemeColors colors) {
    return Column(
      children: [
        Expanded(child: _buildMessageList(colors)),
        _buildInputArea(colors),
      ],
    );
  }

  Widget _buildNoApiPrompt(ThemeColors colors) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: ThemeDecorations.card(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔒', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              '当前未配置 AI API',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '无法进行对话，请前往设置页面配置',
              style: TextStyle(color: colors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                ).then((_) => _checkAiStatus());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('前往设置', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList(ThemeColors colors) {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('💬', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              '开始与 AI 对话',
              style: TextStyle(color: colors.textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              '询问关于肠道健康的问题',
              style: TextStyle(color: colors.textHint, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return MessageBubble(message: message);
      },
    );
  }

  Widget _buildInputArea(ThemeColors colors) {
    final hasRecords = _recordsStartDate != null && _recordsEndDate != null;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 12,
        bottom: bottomPadding + 12,
      ),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasRecords)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colors.primaryLight.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.primaryLight),
              ),
              child: Row(
                children: [
                  Icon(Icons.date_range, size: 14, color: colors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '$_recordsStartDate 至 $_recordsEndDate',
                      style: TextStyle(fontSize: 11, color: colors.primary),
                    ),
                  ),
                  GestureDetector(
                    onTap: _clearRecordsDateRange,
                    child: Icon(Icons.close, size: 14, color: colors.primary),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              GestureDetector(
                onTap: hasRecords
                    ? _clearRecordsDateRange
                    : _selectRecordsDateRange,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: hasRecords
                        ? colors.primaryLight.withValues(alpha: 0.5)
                        : colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                    border: hasRecords
                        ? Border.all(color: colors.primary)
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.attach_file,
                        size: 16,
                        color: hasRecords
                            ? colors.primary
                            : colors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '发送记录',
                        style: TextStyle(
                          color: hasRecords
                              ? colors.primary
                              : colors.textSecondary,
                          fontSize: 12,
                          fontWeight: hasRecords
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _toggleThinking,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _thinkingEnabled
                        ? Colors.orange.shade100
                        : colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                    border: _thinkingEnabled
                        ? Border.all(color: Colors.orange.shade400)
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.psychology,
                        size: 16,
                        color: _thinkingEnabled
                            ? Colors.orange.shade800
                            : colors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '深度思考',
                        style: TextStyle(
                          color: _thinkingEnabled
                              ? Colors.orange.shade800
                              : colors.textSecondary,
                          fontSize: 12,
                          fontWeight: _thinkingEnabled
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _toggleStreaming,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _streamingEnabled
                        ? colors.primaryLight.withValues(alpha: 0.5)
                        : colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                    border: _streamingEnabled
                        ? Border.all(color: colors.primary)
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.stream,
                        size: 16,
                        color: _streamingEnabled
                            ? colors.primary
                            : colors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '流式输出',
                        style: TextStyle(
                          color: _streamingEnabled
                              ? colors.primary
                              : colors.textSecondary,
                          fontSize: 12,
                          fontWeight: _streamingEnabled
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: '输入消息...',
                    hintStyle: TextStyle(color: colors.textHint),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: colors.surfaceVariant,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _chatLoading ? null : _sendMessage,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _chatLoading
                        ? colors.surfaceVariant
                        : colors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: _chatLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.textPrimary,
                          ),
                        )
                      : Icon(Icons.send, color: colors.textOnPrimary, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocalAnalysisView(ThemeColors colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildAnalysisOptions(colors),
          const SizedBox(height: 16),
          if (_analysisLoading)
            Center(child: CircularProgressIndicator(color: colors.primary))
          else if (_error != null)
            AnalysisErrorCard(
              error: _error!,
              colors: colors,
              onLogin: _isAuthError()
                  ? () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    )
                  : null,
            )
          else if (_result != null)
            AnalysisResultView(result: _result!, colors: colors)
          else
            AnalysisPlaceholder(colors: colors),
        ],
      ),
    );
  }

  Widget _buildAnalysisOptions(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: ThemeDecorations.card(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '选择分析周期',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _analysisType = 'weekly'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _analysisType == 'weekly'
                          ? colors.primary
                          : colors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '周分析',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _analysisType == 'weekly'
                            ? Colors.white
                            : colors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _analysisType = 'monthly'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _analysisType == 'monthly'
                          ? colors.primary
                          : colors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '月分析',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _analysisType == 'monthly'
                            ? Colors.white
                            : colors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _analysisLoading ? null : _analyze,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _analysisLoading ? '分析中...' : '🤖 开始 AI 分析',
                style: TextStyle(fontSize: 16, color: colors.textOnPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
