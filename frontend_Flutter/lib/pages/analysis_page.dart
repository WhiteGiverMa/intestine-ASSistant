import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/deepseek_service.dart';
import '../services/local_db_service.dart';
import '../models/models.dart';
import '../widgets/error_dialog.dart';
import '../widgets/compact_tab_switcher.dart';
import '../widgets/analysis_result.dart';
import '../widgets/app_header.dart';
import '../providers/theme_provider.dart';
import '../theme/theme_colors.dart';
import '../theme/theme_decorations.dart';
import '../utils/animations.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/expanded_text_editor_dialog.dart';
import 'chat_sidebar.dart';
import 'chat_message_widgets.dart';
import 'chat_settings.dart';

class AnalysisPage extends StatefulWidget {
  final void Function(NavTab tab)? onNavigate;

  const AnalysisPage({super.key, this.onNavigate});

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

class _AnalysisPageState extends State<AnalysisPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  int _currentTab = 0;

  AiStatus? _aiStatus;
  List<ChatMessage> _messages = [];
  String? _conversationId;
  bool _chatLoading = false;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _currentRequestId = '';

  String _analysisType = 'weekly';
  bool _analysisLoading = false;
  AnalysisResult? _result;
  String? _error;
  AppError? _statusError;

  String? _recordsStartDate;
  String? _recordsEndDate;
  String? _actualRecordsStartDate;
  bool _showRecordsAdjustedHint = false;
  bool _showRequestDetails = false;
  bool _showRequestDetailsButton = false;

  bool _sidebarOpen = false;
  ThinkingIntensity _thinkingIntensity = ThinkingIntensity.none;
  String? _systemPrompt;
  bool _streamingEnabled = false;

  final Map<String, _BackgroundChatState> _backgroundChats = {};
  final Map<String, List<ChatMessage>> _conversationCache = {};

  DateTime? _lastStatusCheck;

  @override
  void initState() {
    super.initState();
    _initPage();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 当页面依赖变化时（包括页面切换回来），刷新AI状态
    _checkAiStatusIfNeeded();
  }

  void _checkAiStatusIfNeeded() {
    // 限制检查频率，最少间隔1秒
    final now = DateTime.now();
    if (_lastStatusCheck == null ||
        now.difference(_lastStatusCheck!).inSeconds >= 1) {
      _lastStatusCheck = now;
      _checkAiStatus();
    }
  }

  Future<void> _initPage() async {
    _loadChatSettings();
    _loadShowRequestDetails();
    _checkAiStatus();
  }

  Future<void> _loadShowRequestDetails() async {
    final savedValue = await LocalDbService.getSetting('show_request_details');
    if (!mounted) return;
    setState(() {
      _showRequestDetails = savedValue == 'true';
    });
  }

  Future<void> _loadChatSettings() async {
    final savedPrompt = await DeepSeekService.getSystemPrompt();
    final streamingEnabled = await LocalDbService.getSetting(
      'streaming_enabled',
    );
    final intensityStr = await LocalDbService.getSetting('thinking_intensity');
    final thinkingEnabled = await LocalDbService.getSetting('thinking_enabled');

    ThinkingIntensity intensity;
    if (intensityStr != null) {
      intensity = ThinkingIntensity.fromApiValue(intensityStr);
    } else if (thinkingEnabled == 'true') {
      intensity = ThinkingIntensity.medium;
    } else {
      intensity = ThinkingIntensity.none;
    }

    if (!mounted) return;
    setState(() {
      _thinkingIntensity = intensity;
      _systemPrompt = savedPrompt;
      _streamingEnabled = streamingEnabled == 'true';
    });
  }

  Future<void> _checkAiStatus() async {
    try {
      final status = await ApiService.checkAiStatus();
      if (!mounted) return;
      setState(() {
        _aiStatus = status;
        _statusError = null;
      });
    } catch (e) {
      final appError = ErrorHandler.handleError(e);
      if (!mounted) return;
      setState(() {
        _statusError = appError;
        _aiStatus = AiStatus(
          hasApiKey: false,
          hasApiUrl: false,
          hasModel: false,
          isConfigured: false,
        );
      });
      // 显示错误弹窗，让用户可以看到详细错误信息并复制
      if (mounted) {
        ErrorDialog.showFromAppError(
          context,
          error: appError,
          onRetry: () {
            setState(() => _statusError = null);
            _checkAiStatus();
          },
        );
      }
    }
  }

  Future<void> _loadChatHistory() async {
    try {
      final session = await ApiService.getChatHistory(
        conversationId: _conversationId,
      );
      if (!mounted) return;
      setState(() {
        _messages = List<ChatMessage>.from(session.messages);
        if (_conversationId == null && session.conversationId.isNotEmpty) {
          _conversationId = session.conversationId;
        }
        if (_conversationId != null) {
          _conversationCache[_conversationId!] = List<ChatMessage>.from(
            _messages,
          );
        }
      });
      _scrollToBottom();
    } catch (e) {
      final appError = ErrorHandler.handleError(e, context: '加载对话历史失败');
      if (mounted) {
        ErrorDialog.showFromAppError(context, error: appError);
      }
    }
  }

  Future<void> _loadConversation(String conversationId) async {
    _currentRequestId = DateTime.now().millisecondsSinceEpoch.toString();

    final hasBackgroundChat =
        _backgroundChats.containsKey(conversationId) &&
        !_backgroundChats[conversationId]!.isComplete;

    final hasCache = _conversationCache.containsKey(conversationId);

    setState(() {
      _conversationId = conversationId;
      _messages =
          hasCache ? List.from(_conversationCache[conversationId]!) : [];
      _chatLoading = !hasCache && hasBackgroundChat;
      _showRequestDetailsButton = false;
    });

    if (hasCache) {
      _scrollToBottom();
      _loadChatHistorySilent(conversationId);
    } else {
      await _loadChatHistory();
    }

    if (hasBackgroundChat) {
      _syncBackgroundChatState(conversationId);
    }
  }

  Future<void> _loadChatHistorySilent(String conversationId) async {
    try {
      final session = await ApiService.getChatHistory(
        conversationId: conversationId,
      );
      if (!mounted) return;
      final newMessages = List<ChatMessage>.from(session.messages);
      final cachedMessages = _conversationCache[conversationId];
      final hasChanged =
          cachedMessages == null ||
          newMessages.length != cachedMessages.length ||
          _messagesChanged(newMessages, cachedMessages);

      if (hasChanged && _conversationId == conversationId) {
        setState(() {
          _messages = newMessages;
          _conversationCache[conversationId] = List<ChatMessage>.from(
            newMessages,
          );
        });
        _scrollToBottom();
      } else if (hasChanged) {
        _conversationCache[conversationId] = List<ChatMessage>.from(
          newMessages,
        );
      }
    } catch (e) {
      // ignore
    }
  }

  bool _messagesChanged(List<ChatMessage> a, List<ChatMessage> b) {
    if (a.length != b.length) return true;
    for (var i = 0; i < a.length; i++) {
      if (a[i].messageId != b[i].messageId || a[i].content != b[i].content) {
        return true;
      }
    }
    return false;
  }

  void _syncBackgroundChatState(String conversationId) {
    final bgState = _backgroundChats[conversationId];
    if (bgState == null) return;

    setState(() {
      final tempIndex = _messages.indexWhere(
        (m) => m.messageId.startsWith('temp-assistant-'),
      );
      if (tempIndex != -1) {
        _messages[tempIndex] = ChatMessage(
          messageId: bgState.messageId ?? _messages[tempIndex].messageId,
          conversationId: conversationId,
          role: 'assistant',
          content: bgState.content,
          createdAt: _messages[tempIndex].createdAt,
          thinkingContent: bgState.thinkingContent,
        );
      } else if (bgState.content.isNotEmpty) {
        _messages.add(
          ChatMessage(
            messageId:
                bgState.messageId ?? 'temp-assistant-${bgState.requestId}',
            conversationId: conversationId,
            role: 'assistant',
            content: bgState.content,
            createdAt: DateTime.now().toIso8601String(),
            thinkingContent: bgState.thinkingContent,
          ),
        );
      }
      _chatLoading = !bgState.isComplete;
      if (bgState.isComplete) {
        _showRequestDetailsButton = _showRequestDetails;
        _backgroundChats.remove(conversationId);
      }
    });
    _scrollToBottom();
  }

  void _newConversation() {
    _currentRequestId = DateTime.now().millisecondsSinceEpoch.toString();
    setState(() {
      _conversationId = null;
      _messages = [];
      _sidebarOpen = false;
      _showRequestDetailsButton = false;
      _chatLoading = false;
    });
    ApiService.clearLastChatRequestDetails();
  }

  void _cancelCurrentRequest() {
    ApiService.cancelCurrentRequest();
    _currentRequestId = DateTime.now().millisecondsSinceEpoch.toString();

    if (_conversationId != null &&
        _backgroundChats.containsKey(_conversationId)) {
      final bgState = _backgroundChats[_conversationId]!;
      if (bgState.content.isNotEmpty) {
        LocalDbService.saveMessage(
          conversationId: _conversationId!,
          role: 'assistant',
          content: bgState.content,
          thinkingContent: bgState.thinkingContent,
        );
      }
      _backgroundChats.remove(_conversationId);
    }

    setState(() {
      _chatLoading = false;
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _messageController.clear();

    final requestId = DateTime.now().millisecondsSinceEpoch.toString();
    _currentRequestId = requestId;
    final isNewConversation = _conversationId == null;

    final hasRecords = _recordsStartDate != null && _recordsEndDate != null;
    List<BowelRecord>? attachedRecords;
    String? recordsDateRange;

    if (hasRecords) {
      try {
        attachedRecords = await LocalDbService.getRecords(
          startDate: _recordsStartDate,
          endDate: _recordsEndDate,
        );
        if (attachedRecords.isNotEmpty) {
          recordsDateRange = '$_recordsStartDate 至 $_recordsEndDate';
        }
      } catch (e) {
        // ignore
      }
    }

    final tempUserMessage = ChatMessage(
      messageId: 'temp-$requestId',
      conversationId: _conversationId ?? '',
      role: 'user',
      content: message,
      createdAt: DateTime.now().toIso8601String(),
      attachedRecords: attachedRecords,
      recordsDateRange: recordsDateRange,
    );

    setState(() {
      _messages.add(tempUserMessage);
      _chatLoading = true;
      _showRequestDetailsButton = false;
    });
    _scrollToBottom();

    if (_streamingEnabled) {
      await _sendMessageStream(
        message,
        tempUserMessage,
        requestId,
        isNewConversation,
        attachedRecords,
        recordsDateRange,
      );
    } else {
      await _sendMessageNormal(
        message,
        tempUserMessage,
        requestId,
        isNewConversation,
        attachedRecords,
        recordsDateRange,
      );
    }
  }

  String _generateTitleFromMessage(String message) {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return '新对话';
    if (trimmed.length <= 10) return trimmed;
    return '${trimmed.substring(0, 10)}...';
  }

  Future<void> _autoRenameConversation(
    String conversationId,
    String message,
  ) async {
    final title = _generateTitleFromMessage(message);
    try {
      await ApiService.renameConversation(
        conversationId: conversationId,
        title: title,
      );
    } catch (e) {
      // ignore
    }
  }

  Future<void> _sendMessageNormal(
    String message,
    ChatMessage tempUserMessage,
    String requestId,
    bool isNewConversation,
    List<BowelRecord>? attachedRecords,
    String? recordsDateRange,
  ) async {
    final tempAssistantMessageId = 'temp-assistant-$requestId';
    final tempAssistantMessage = ChatMessage(
      messageId: tempAssistantMessageId,
      conversationId: _conversationId ?? '',
      role: 'assistant',
      content: '',
      createdAt: DateTime.now().toIso8601String(),
    );

    setState(() {
      _messages.add(tempAssistantMessage);
    });
    _scrollToBottom();

    try {
      final result = await ApiService.sendMessage(
        message: message,
        conversationId: _conversationId,
        recordsStartDate: _recordsStartDate,
        recordsEndDate: _recordsEndDate,
        thinkingIntensity:
            _thinkingIntensity.shouldSendToApi
                ? _thinkingIntensity.toApiValue()
                : null,
        systemPrompt: _systemPrompt,
        attachedRecords: attachedRecords,
        recordsDateRange: recordsDateRange,
      );

      if (_currentRequestId != requestId) {
        return;
      }

      if (!mounted) return;
      final response = result.message;
      final actualStartDate = result.actualStartDate;

      final wasAdjusted =
          actualStartDate != null &&
          _recordsStartDate != null &&
          actualStartDate != _recordsStartDate;

      final newConversationId = response.conversationId;
      setState(() {
        _messages.removeWhere((m) => m.messageId == tempUserMessage.messageId);
        _messages.removeWhere((m) => m.messageId == tempAssistantMessageId);

        _conversationId ??= newConversationId;

        final userMessage = ChatMessage(
          messageId: 'user-$requestId',
          conversationId: newConversationId,
          role: 'user',
          content: message,
          createdAt: response.createdAt,
          attachedRecords: attachedRecords,
          recordsDateRange: recordsDateRange,
        );
        _messages.add(userMessage);

        _messages.add(response);
        _chatLoading = false;
        _actualRecordsStartDate = actualStartDate;
        _showRecordsAdjustedHint = wasAdjusted;
        _showRequestDetailsButton = _showRequestDetails;
        if (_conversationId != null) {
          _conversationCache[_conversationId!] = List<ChatMessage>.from(
            _messages,
          );
        }
      });
      _scrollToBottom();

      if (isNewConversation && newConversationId.isNotEmpty) {
        _autoRenameConversation(newConversationId, message);
      }
    } catch (e) {
      if (_currentRequestId != requestId) {
        return;
      }
      if (!mounted) return;
      final appError = ErrorHandler.handleError(e);
      setState(() {
        _messages.removeWhere((m) => m.messageId == tempUserMessage.messageId);
        _messages.removeWhere((m) => m.messageId == tempAssistantMessageId);
        _chatLoading = false;
      });
      ErrorDialog.showFromAppError(
        context,
        error: appError,
        onRetry: () => _sendMessage(),
      );
    }
  }

  Future<void> _sendMessageStream(
    String message,
    ChatMessage tempUserMessage,
    String requestId,
    bool isNewConversation,
    List<BowelRecord>? attachedRecords,
    String? recordsDateRange,
  ) async {
    String? finalMessageId;
    String? streamConversationId;
    final tempAssistantMessageId = 'temp-assistant-$requestId';
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
        messageId: 'user-$requestId',
        conversationId: _conversationId ?? '',
        role: 'user',
        content: message,
        createdAt: DateTime.now().toIso8601String(),
        attachedRecords: attachedRecords,
        recordsDateRange: recordsDateRange,
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
        thinkingIntensity:
            _thinkingIntensity.shouldSendToApi
                ? _thinkingIntensity.toApiValue()
                : null,
        systemPrompt: _systemPrompt,
        attachedRecords: attachedRecords,
        recordsDateRange: recordsDateRange,
      )) {
        if (chunk.conversationId != null && streamConversationId == null) {
          final convId = chunk.conversationId!;
          streamConversationId = convId;

          _backgroundChats[convId] = _BackgroundChatState(
            conversationId: convId,
            requestId: requestId,
          );

          if (isNewConversation) {
            _autoRenameConversation(convId, message);
          }

          if (_currentRequestId == requestId && mounted) {
            setState(() {
              _conversationId = streamConversationId;
              final userMsgIndex = _messages.indexWhere(
                (m) => m.role == 'user' && m.conversationId.isEmpty,
              );
              if (userMsgIndex != -1) {
                final oldMsg = _messages[userMsgIndex];
                _messages[userMsgIndex] = ChatMessage(
                  messageId: oldMsg.messageId,
                  conversationId: streamConversationId!,
                  role: 'user',
                  content: oldMsg.content,
                  createdAt: oldMsg.createdAt,
                  attachedRecords: oldMsg.attachedRecords,
                  recordsDateRange: oldMsg.recordsDateRange,
                );
              }
            });
          }
        }

        if (chunk.actualStartDate != null && _actualRecordsStartDate == null) {
          if (_currentRequestId == requestId && mounted) {
            final wasAdjusted =
                _recordsStartDate != null &&
                chunk.actualStartDate != _recordsStartDate;
            setState(() {
              _actualRecordsStartDate = chunk.actualStartDate;
              _showRecordsAdjustedHint = wasAdjusted;
            });
          }
        }

        if (chunk.content != null || chunk.reasoningContent != null) {
          final bgState =
              streamConversationId != null
                  ? _backgroundChats[streamConversationId]
                  : null;

          if (bgState != null) {
            bgState.content += chunk.content ?? '';
            if (chunk.reasoningContent != null) {
              bgState.thinkingContent =
                  (bgState.thinkingContent ?? '') + chunk.reasoningContent!;
            }
          }

          if (_currentRequestId == requestId && mounted) {
            setState(() {
              final index = _messages.indexWhere(
                (m) => m.messageId == tempAssistantMessageId,
              );
              if (index != -1) {
                final currentMessage = _messages[index];
                _messages[index] = ChatMessage(
                  messageId: chunk.messageId ?? tempAssistantMessageId,
                  conversationId:
                      streamConversationId ??
                      _conversationId ??
                      currentMessage.conversationId,
                  role: 'assistant',
                  content: currentMessage.content + (chunk.content ?? ''),
                  createdAt: currentMessage.createdAt,
                  thinkingContent:
                      chunk.reasoningContent != null
                          ? (currentMessage.thinkingContent ?? '') +
                              chunk.reasoningContent!
                          : currentMessage.thinkingContent,
                );
              }
            });
            _scrollToBottom();
          }
        }

        if (chunk.done && chunk.messageId != null) {
          finalMessageId = chunk.messageId;
          if (streamConversationId != null &&
              _backgroundChats.containsKey(streamConversationId)) {
            _backgroundChats[streamConversationId]!.messageId = finalMessageId;
            _backgroundChats[streamConversationId]!.isComplete = true;
          }
        }
      }

      if (_currentRequestId == requestId && mounted) {
        setState(() {
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
          _showRequestDetailsButton = _showRequestDetails;
          if (_conversationId != null) {
            _conversationCache[_conversationId!] = List<ChatMessage>.from(
              _messages,
            );
          }
        });
      }

      if (streamConversationId != null &&
          _backgroundChats.containsKey(streamConversationId)) {
        _backgroundChats.remove(streamConversationId);
      }
    } catch (e) {
      final appError = ErrorHandler.handleError(e);

      if (streamConversationId != null &&
          _backgroundChats.containsKey(streamConversationId)) {
        _backgroundChats[streamConversationId]!.error = e.toString();
        _backgroundChats[streamConversationId]!.isComplete = true;
      }

      if (_currentRequestId == requestId && mounted) {
        setState(() {
          _messages.removeWhere((m) => m.messageId == tempAssistantMessageId);
          _messages.removeWhere((m) => m.messageId.startsWith('temp-records-'));
          _messages.removeWhere((m) => m.messageId.startsWith('records-'));
          _chatLoading = false;
        });
        ErrorDialog.showFromAppError(
          context,
          error: appError,
          onRetry: () => _sendMessage(),
        );
      }
    }
  }

  Future<void> _analyze() async {
    setState(() {
      _analysisLoading = true;
      _error = null;
    });

    try {
      final result = await LocalDbService.analyzeLocally(
        analysisType: _analysisType,
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _analysisLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _analysisLoading = false;
      });
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

  Future<void> _selectRecordsDateRange() async {
    final now = DateTime.now();
    final firstDate = now.subtract(const Duration(days: 365));
    final lastDate = now;

    final startDate = await showDatePicker(
      context: context,
      initialDate:
          _recordsStartDate != null
              ? DateTime.parse(_recordsStartDate!)
              : now.subtract(const Duration(days: 7)),
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: '选择开始日期',
    );

    if (startDate == null || !mounted) return;

    final endDate = await showDatePicker(
      context: context,
      initialDate:
          _recordsEndDate != null ? DateTime.parse(_recordsEndDate!) : now,
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
      _actualRecordsStartDate = null;
      _showRecordsAdjustedHint = false;
    });
  }

  bool _isMobile() {
    return MediaQuery.of(context).size.width < 600;
  }

  void _toggleSidebar() {
    setState(() {
      _sidebarOpen = !_sidebarOpen;
    });
  }

  void _openSettings() {
    showChatSettings(
      context,
      onThinkingChanged: (intensity) {
        setState(() {
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

  Future<void> _toggleStreaming() async {
    final newValue = !_streamingEnabled;
    await LocalDbService.setSetting('streaming_enabled', newValue.toString());
    setState(() {
      _streamingEnabled = newValue;
    });
  }

  void _cycleThinkingIntensity() {
    const values = ThinkingIntensity.values;
    final currentIndex = values.indexOf(_thinkingIntensity);
    final nextIndex = (currentIndex + 1) % values.length;
    _saveThinkingIntensity(values[nextIndex]);
  }

  Future<void> _saveThinkingIntensity(ThinkingIntensity value) async {
    await LocalDbService.setSetting('thinking_intensity', value.toApiValue());
    setState(() {
      _thinkingIntensity = value;
    });
  }

  String _getThinkingLabel() {
    switch (_thinkingIntensity) {
      case ThinkingIntensity.none:
        return '默认';
      case ThinkingIntensity.low:
        return '低';
      case ThinkingIntensity.medium:
        return '中';
      case ThinkingIntensity.high:
        return '高';
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final themeProvider = context.watch<ThemeProvider>();
    final colors = themeProvider.colors;

    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
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
                              color: colors.headerText,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CompactTabBar(
                              currentIndex: _currentTab,
                              onTabChanged:
                                  (index) =>
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
                          ),
                        ],
                      ),
                      trailing:
                          _aiStatus?.isConfigured == true
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
    final topPadding = MediaQuery.of(context).padding.top;
    const sidebarTop = 0.0;
    final buttonTop = topPadding + 56;

    return Stack(
      children: [
        if (isMobile && _sidebarOpen)
          GestureDetector(
            onTap: _toggleSidebar,
            child: AnimatedContainer(
              duration: AppAnimations.durationNormal,
              curve: AppAnimations.curveEnter,
              color: Colors.black.withValues(alpha: _sidebarOpen ? 0.5 : 0),
            ),
          ),
        AnimatedPositioned(
          duration: AppAnimations.durationSlow,
          curve: AppAnimations.curveEnter,
          left: _sidebarOpen ? 0 : -sidebarWidth,
          top: sidebarTop,
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
            isLoading: _chatLoading,
            loadingConversationId: _conversationId,
          ),
        ),
        AnimatedPositioned(
          duration: AppAnimations.durationNormal,
          curve: AppAnimations.curveEnter,
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
    return RefreshIndicator(
      onRefresh: _checkAiStatus,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Center(
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
                const SizedBox(height: 8),
                Text(
                  '下拉可刷新状态',
                  style: TextStyle(color: colors.textHint, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    widget.onNavigate?.call(NavTab.settings);
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
        ),
      ),
    );
  }

  Widget _buildMessageList(ThemeColors colors) {
    if (_messages.isEmpty) {
      return RefreshIndicator(
        onRefresh: _checkAiStatus,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 100),
                const Text('💬', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 16),
                Text(
                  '开始与 AI 对话',
                  style: TextStyle(color: colors.textSecondary, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  '询问关于肠胃健康的问题',
                  style: TextStyle(color: colors.textHint, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Text(
                  '下拉可刷新状态',
                  style: TextStyle(color: colors.textHint, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _checkAiStatus,
            child: ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return MessageBubble(message: message);
              },
            ),
          ),
        ),
        if (_showRequestDetailsButton && !_chatLoading)
          _buildRequestDetailsButton(colors),
      ],
    );
  }

  Widget _buildRequestDetailsButton(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: _showRequestDetailsDialog,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: colors.surfaceVariant,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.divider),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 16, color: colors.textSecondary),
              const SizedBox(width: 6),
              Text(
                '查看请求详情',
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRequestDetailsDialog() {
    final colors = context.read<ThemeProvider>().colors;
    final details = ApiService.getLastChatRequestDetails();

    if (details == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('没有可用的请求详情'),
          backgroundColor: colors.warning,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.info_outline, color: colors.primary),
                const SizedBox(width: 8),
                const Text('AI对话请求详情'),
              ],
            ),
            content: SingleChildScrollView(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDetailRow('时间', details.timestamp.toIso8601String()),
                    _buildDetailRow(
                      '耗时',
                      '${details.duration?.inMilliseconds ?? 'N/A'} ms',
                    ),
                    _buildDetailRow('URL', details.url),
                    _buildDetailRow(
                      '状态码',
                      details.statusCode?.toString() ?? 'N/A',
                    ),
                    if (details.errorMessage != null)
                      _buildDetailRow(
                        '错误',
                        details.errorMessage!,
                        isError: true,
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  '关闭',
                  style: TextStyle(color: colors.textSecondary),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(text: details.toFormattedString()),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('请求详情已复制到剪贴板'),
                      backgroundColor: colors.success,
                    ),
                  );
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('复制完整详情'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.textOnPrimary,
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isError = false}) {
    final colors = context.read<ThemeProvider>().colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: colors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(
                color: isError ? colors.error : colors.textPrimary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
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
          if (_showRecordsAdjustedHint && _actualRecordsStartDate != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '记录已自动调整：实际发送 $_actualRecordsStartDate 至 $_recordsEndDate',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap:
                        () => setState(() => _showRecordsAdjustedHint = false),
                    child: Icon(
                      Icons.close,
                      size: 14,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              GestureDetector(
                onTap:
                    hasRecords
                        ? _clearRecordsDateRange
                        : _selectRecordsDateRange,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color:
                        hasRecords
                            ? colors.primaryLight.withValues(alpha: 0.5)
                            : colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                    border:
                        hasRecords ? Border.all(color: colors.primary) : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.attach_file,
                        size: 16,
                        color:
                            hasRecords ? colors.primary : colors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '发送记录',
                        style: TextStyle(
                          color:
                              hasRecords
                                  ? colors.primary
                                  : colors.textSecondary,
                          fontSize: 12,
                          fontWeight:
                              hasRecords ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _cycleThinkingIntensity,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color:
                        _thinkingIntensity != ThinkingIntensity.none
                            ? Colors.orange.shade100
                            : colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                    border:
                        _thinkingIntensity != ThinkingIntensity.none
                            ? Border.all(color: Colors.orange.shade400)
                            : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.psychology,
                        size: 16,
                        color:
                            _thinkingIntensity != ThinkingIntensity.none
                                ? Colors.orange.shade800
                                : colors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getThinkingLabel(),
                        style: TextStyle(
                          color:
                              _thinkingIntensity != ThinkingIntensity.none
                                  ? Colors.orange.shade800
                                  : colors.textSecondary,
                          fontSize: 12,
                          fontWeight:
                              _thinkingIntensity != ThinkingIntensity.none
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
                    color:
                        _streamingEnabled
                            ? colors.primaryLight.withValues(alpha: 0.5)
                            : colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                    border:
                        _streamingEnabled
                            ? Border.all(color: colors.primary)
                            : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.stream,
                        size: 16,
                        color:
                            _streamingEnabled
                                ? colors.primary
                                : colors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '流式输出',
                        style: TextStyle(
                          color:
                              _streamingEnabled
                                  ? colors.primary
                                  : colors.textSecondary,
                          fontSize: 12,
                          fontWeight:
                              _streamingEnabled
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
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 120),
                      child: SingleChildScrollView(
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
                            contentPadding: const EdgeInsets.only(
                              left: 16,
                              right: 40,
                              top: 12,
                              bottom: 12,
                            ),
                          ),
                          maxLines: null,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ),
                    if (_messageController.text.length > 100)
                      Positioned(
                        right: 4,
                        top: 4,
                        child: IconButton(
                          icon: Icon(
                            Icons.open_in_full,
                            size: 18,
                            color: colors.textSecondary,
                          ),
                          tooltip: '展开编辑',
                          onPressed: () async {
                            final result = await ExpandedTextEditorDialog.show(
                              context,
                              title: '编辑消息',
                              hintText: '输入消息...',
                              initialText: _messageController.text,
                              showClearButton: true,
                            );
                            if (result != null) {
                              _messageController.text = result;
                            }
                          },
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _chatLoading ? _cancelCurrentRequest : _sendMessage,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _chatLoading ? colors.error : colors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _chatLoading ? Icons.stop : Icons.send,
                    color: colors.textOnPrimary,
                    size: 20,
                  ),
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
          AnimatedEntrance(child: _buildAnalysisOptions(colors)),
          const SizedBox(height: 16),
          if (_analysisLoading)
            Center(child: CircularProgressIndicator(color: colors.primary))
          else if (_error != null)
            AnimatedEntrance(
              delay: const Duration(
                milliseconds: AppAnimations.staggerIntervalMs,
              ),
              child: AnalysisErrorCard(error: _error!, colors: colors),
            )
          else if (_result != null)
            AnalysisResultView(result: _result!, colors: colors)
          else
            AnimatedEntrance(
              delay: const Duration(
                milliseconds: AppAnimations.staggerIntervalMs,
              ),
              child: AnalysisPlaceholder(colors: colors),
            ),
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
                      color:
                          _analysisType == 'weekly'
                              ? colors.primary
                              : colors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '周分析',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color:
                            _analysisType == 'weekly'
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
                      color:
                          _analysisType == 'monthly'
                              ? colors.primary
                              : colors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '月分析',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color:
                            _analysisType == 'monthly'
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
                _analysisLoading ? '分析中...' : '📊 开始本地分析',
                style: TextStyle(fontSize: 16, color: colors.textOnPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundChatState {
  final String conversationId;
  final String requestId;
  String content = '';
  String? thinkingContent;
  bool isComplete = false;
  String? messageId;
  String? error;

  _BackgroundChatState({required this.conversationId, required this.requestId});
}
