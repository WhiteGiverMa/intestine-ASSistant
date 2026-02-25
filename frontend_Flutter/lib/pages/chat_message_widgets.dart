import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:highlight/highlight.dart' show highlight;
import 'package:highlight/languages/all.dart' show allLanguages;
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/theme_provider.dart';
import '../theme/theme_colors.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;
    switch (message.role) {
      case 'user':
        return _UserMessageBubble(message: message, colors: colors);
      case 'assistant':
        return _buildAssistantBubble(colors);
      case 'system':
        return _buildSystemBubble(colors);
      default:
        return _buildAssistantBubble(colors);
    }
  }

  Widget _buildAssistantBubble(ThemeColors colors) {
    final isLoading = message.content.isEmpty &&
        (message.thinkingContent == null ||
            message.thinkingContent!.isEmpty);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, right: 60),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colors.shadow,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.thinkingContent != null &&
                message.thinkingContent!.isNotEmpty)
              ThinkingBlock(content: message.thinkingContent!, colors: colors),
            if (isLoading)
              _buildLoadingIndicator(colors)
            else
              _buildMarkdownContent(message.content, colors),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator(ThemeColors colors) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: colors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Thinking...',
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 14,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  MarkdownStyleSheet _getAssistantMarkdownStyle(ThemeColors colors) {
    return MarkdownStyleSheet(
      p: TextStyle(fontSize: 14, height: 1.6, color: colors.textPrimary),
      h1: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: colors.textPrimary,
      ),
      h2: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: colors.textPrimary,
      ),
      h3: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: colors.textPrimary,
      ),
      h4: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: colors.textPrimary,
      ),
      h5: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: colors.textPrimary,
      ),
      h6: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: colors.textPrimary,
      ),
      code: TextStyle(
        backgroundColor: colors.surfaceVariant,
        fontFamily: 'monospace',
        fontSize: 13,
      ),
      codeblockDecoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
      ),
      codeblockPadding: EdgeInsets.zero,
      blockquote: TextStyle(
        color: colors.textSecondary,
        fontStyle: FontStyle.italic,
      ),
      blockquoteDecoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(4),
      ),
      blockquotePadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      listBullet: TextStyle(fontSize: 14, color: colors.textPrimary),
      tableHead: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
        color: colors.textPrimary,
      ),
      tableBody: TextStyle(fontSize: 14, color: colors.textPrimary),
      tableBorder: TableBorder.all(color: colors.divider),
      tableCellsPadding: const EdgeInsets.all(8),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.divider)),
      ),
    );
  }

  Widget _buildMarkdownContent(String content, ThemeColors colors) {
    return MarkdownBody(
      data: content,
      selectable: true,
      styleSheet: _getAssistantMarkdownStyle(colors),
      builders: {'pre': CodeBlockBuilder()},
      extensionSet: md.ExtensionSet.gitHubWeb,
      onTapLink: (text, href, title) {
        if (href != null) {
          Clipboard.setData(ClipboardData(text: href));
        }
      },
    );
  }

  Widget _buildSystemBubble(ThemeColors colors) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: colors.info.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.info.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline, size: 16, color: colors.info),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message.content,
                style: TextStyle(color: colors.info, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserMessageBubble extends StatefulWidget {
  final ChatMessage message;
  final ThemeColors colors;

  const _UserMessageBubble({required this.message, required this.colors});

  @override
  State<_UserMessageBubble> createState() => _UserMessageBubbleState();
}

class _UserMessageBubbleState extends State<_UserMessageBubble> {
  bool _recordsExpanded = false;

  static final _bowelRecordsRegex = RegExp(
    r'<bowel_records(?:\s+date_range="([^"]*)")?\s*>([\s\S]*?)</bowel_records>',
  );

  ({String text, List<BowelRecord>? records, String? dateRange}) _parseMessageContent() {
    if (widget.message.attachedRecords != null && widget.message.attachedRecords!.isNotEmpty) {
      return (
        text: widget.message.content,
        records: widget.message.attachedRecords,
        dateRange: widget.message.recordsDateRange,
      );
    }

    final match = _bowelRecordsRegex.firstMatch(widget.message.content);
    if (match == null) {
      return (text: widget.message.content, records: null, dateRange: null);
    }

    final dateRange = match.group(1);
    final jsonContent = match.group(2)?.trim();
    final text = widget.message.content.replaceFirst(match.group(0)!, '').trim();

    if (jsonContent == null || jsonContent.isEmpty) {
      return (text: text, records: null, dateRange: dateRange);
    }

    try {
      final List<dynamic> decoded = jsonDecode(jsonContent);
      final records = decoded.map((json) => BowelRecord.fromJson(json)).toList();
      return (text: text, records: records, dateRange: dateRange);
    } catch (e) {
      return (text: text, records: null, dateRange: dateRange);
    }
  }

  @override
  Widget build(BuildContext context) {
    final parsed = _parseMessageContent();
    final hasRecords = parsed.records != null && parsed.records!.isNotEmpty;

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, left: 60),
        decoration: BoxDecoration(
          color: widget.colors.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (parsed.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: MarkdownBody(
                  data: parsed.text,
                  styleSheet: _getUserMarkdownStyle(widget.colors),
                  selectable: true,
                  onTapLink: (text, href, title) {},
                ),
              ),
            if (hasRecords) _buildRecordsBlock(parsed.records!, parsed.dateRange),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordsBlock(List<BowelRecord> records, String? dateRange) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: widget.colors.textOnPrimary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => setState(() => _recordsExpanded = !_recordsExpanded),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.attach_file,
                    size: 14,
                    color: widget.colors.textOnPrimary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '排便记录 (${records.length}条)',
                    style: TextStyle(
                      color: widget.colors.textOnPrimary,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                  if (dateRange != null && dateRange.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Text(
                      dateRange,
                      style: TextStyle(
                        color: widget.colors.textOnPrimary.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                  const SizedBox(width: 4),
                  Icon(
                    _recordsExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: widget.colors.textOnPrimary,
                  ),
                ],
              ),
            ),
          ),
          if (_recordsExpanded)
            Container(
              constraints: const BoxConstraints(maxHeight: 150),
              margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: records.map((r) => _buildRecordItem(r)).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecordItem(BowelRecord record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: widget.colors.textOnPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today, size: 10, color: widget.colors.textOnPrimary.withValues(alpha: 0.8)),
              const SizedBox(width: 4),
              Text(
                record.recordDate,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: widget.colors.textOnPrimary,
                ),
              ),
              if (record.recordTime != null) ...[
                const SizedBox(width: 6),
                Icon(Icons.access_time, size: 10, color: widget.colors.textOnPrimary.withValues(alpha: 0.8)),
                const SizedBox(width: 2),
                Text(
                  record.recordTime!,
                  style: TextStyle(fontSize: 11, color: widget.colors.textOnPrimary.withValues(alpha: 0.8)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Wrap(
            spacing: 8,
            runSpacing: 2,
            children: [
              if (record.stoolType != null)
                _buildBadge('类型${record.stoolType}'),
              if (record.durationMinutes != null)
                _buildBadge('${record.durationMinutes}分钟'),
              if (record.feeling != null)
                _buildBadge(record.feeling!),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: widget.colors.textOnPrimary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, color: widget.colors.textOnPrimary),
      ),
    );
  }

  MarkdownStyleSheet _getUserMarkdownStyle(ThemeColors colors) {
    return MarkdownStyleSheet(
      p: TextStyle(color: colors.textOnPrimary, fontSize: 14),
      code: TextStyle(
        color: colors.textOnPrimary,
        backgroundColor: colors.textOnPrimary.withValues(alpha: 0.2),
        fontFamily: 'monospace',
        fontSize: 13,
      ),
      codeblockDecoration: BoxDecoration(
        color: colors.textOnPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      codeblockPadding: const EdgeInsets.all(12),
    );
  }
}

class CodeBlockBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    var language = '';
    if (element.attributes['class'] != null) {
      final className = element.attributes['class']!;
      if (className.startsWith('language-')) {
        language = className.substring(9);
      }
    }

    String code = '';
    if (element.children != null && element.children!.isNotEmpty) {
      final codeElement = element.children!.first;
      if (codeElement is md.Text) {
        code = codeElement.text;
      } else if (codeElement is md.Element && codeElement.children != null) {
        for (final child in codeElement.children!) {
          if (child is md.Text) {
            code += child.text;
          }
        }
      }
    }

    return CodeBlockWidget(code: code, language: language);
  }
}

class CodeBlockWidget extends StatefulWidget {
  final String code;
  final String language;

  const CodeBlockWidget({
    super.key,
    required this.code,
    required this.language,
  });

  @override
  State<CodeBlockWidget> createState() => _CodeBlockWidgetState();
}

class _CodeBlockWidgetState extends State<CodeBlockWidget> {
  bool _copied = false;
  List<InlineSpan>? _cachedSpans;

  List<InlineSpan> get _spans {
    if (_cachedSpans != null) return _cachedSpans!;
    _cachedSpans = _buildSpans();
    return _cachedSpans!;
  }

  List<InlineSpan> _buildSpans() {
    final language = widget.language.isNotEmpty ? widget.language : 'plaintext';
    final mode = allLanguages[language];

    if (mode != null) {
      try {
        final result = highlight.parse(widget.code, language: language);
        return _nodesToSpans(result.nodes!);
      } catch (e) {
        return [TextSpan(text: widget.code, style: const TextStyle(color: Colors.white))];
      }
    }
    return [TextSpan(text: widget.code, style: const TextStyle(color: Colors.white))];
  }

  @override
  void didUpdateWidget(CodeBlockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.code != widget.code || oldWidget.language != widget.language) {
      _cachedSpans = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: const BoxDecoration(
              color: Color(0xFF2D2D2D),
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                Text(
                  widget.language.isNotEmpty ? widget.language : 'code',
                  style: const TextStyle(
                    color: Color(0xFF808080),
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _copyCode,
                  child: Row(
                    children: [
                      Icon(
                        _copied ? Icons.check : Icons.copy,
                        size: 16,
                        color:
                            _copied ? colors.success : const Color(0xFF808080),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _copied ? '已复制' : '复制',
                        style: TextStyle(
                          color:
                              _copied
                                  ? colors.success
                                  : const Color(0xFF808080),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: SelectableText.rich(
              TextSpan(
                children: _spans,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: widget.code));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _copied = false);
      }
    });
  }

  List<InlineSpan> _nodesToSpans(List<dynamic> nodes) {
    final spans = <InlineSpan>[];
    for (final node in nodes) {
      spans.addAll(_nodeToSpans(node));
    }
    return spans;
  }

  List<InlineSpan> _nodeToSpans(dynamic node) {
    final spans = <InlineSpan>[];

    if (node is String) {
      spans.add(
        TextSpan(text: node, style: const TextStyle(color: Colors.white)),
      );
    } else if (node.className != null && node.className!.isNotEmpty) {
      final color = _getColorForClass(node.className!);
      if (node.children != null) {
        for (final child in node.children!) {
          if (child is String) {
            spans.add(TextSpan(text: child, style: TextStyle(color: color)));
          } else {
            spans.addAll(_nodeToSpans(child));
          }
        }
      } else if (node.value != null) {
        spans.add(
          TextSpan(text: node.value.toString(), style: TextStyle(color: color)),
        );
      }
    } else if (node.children != null) {
      for (final child in node.children!) {
        spans.addAll(_nodeToSpans(child));
      }
    } else if (node.value != null) {
      spans.add(
        TextSpan(
          text: node.value.toString(),
          style: const TextStyle(color: Colors.white),
        ),
      );
    }

    return spans;
  }

  Color _getColorForClass(String className) {
    switch (className) {
      case 'keyword':
      case 'built_in':
        return const Color(0xFFC678DD);
      case 'string':
        return const Color(0xFF98C379);
      case 'number':
        return const Color(0xFFD19A66);
      case 'comment':
        return const Color(0xFF5C6370);
      case 'function':
        return const Color(0xFF61AFEF);
      case 'class':
      case 'title':
        return const Color(0xFFE5C07B);
      case 'variable':
      case 'params':
        return const Color(0xFFE06C75);
      case 'literal':
      case 'constant':
        return const Color(0xFF56B6C2);
      case 'meta':
        return const Color(0xFF61AFEF);
      case 'attribute':
        return const Color(0xFFD19A66);
      case 'symbol':
        return const Color(0xFF98C379);
      case 'regexp':
        return const Color(0xFF98C379);
      case 'tag':
        return const Color(0xFFE06C75);
      case 'name':
        return const Color(0xFFE06C75);
      case 'attr':
        return const Color(0xFFD19A66);
      case 'property':
        return const Color(0xFF61AFEF);
      case 'type':
        return const Color(0xFFE5C07B);
      case 'punctuation':
        return const Color(0xFFABB2BF);
      case 'operator':
        return const Color(0xFF56B6C2);
      default:
        return const Color(0xFFABB2BF);
    }
  }
}

class ThinkingBlock extends StatefulWidget {
  final String content;
  final ThemeColors colors;

  const ThinkingBlock({super.key, required this.content, required this.colors});

  @override
  State<ThinkingBlock> createState() => _ThinkingBlockState();
}

class _ThinkingBlockState extends State<ThinkingBlock> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: widget.colors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: widget.colors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.psychology, size: 16, color: widget.colors.warning),
                  const SizedBox(width: 8),
                  Text(
                    '深度思考',
                    style: TextStyle(
                      color: widget.colors.warning,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: widget.colors.warning,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Container(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: MarkdownBody(
                data: widget.content,
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(fontSize: 13, color: widget.colors.warning),
                  code: TextStyle(
                    backgroundColor: widget.colors.warning.withValues(alpha: 0.1),
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
