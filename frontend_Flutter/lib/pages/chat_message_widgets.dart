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
    switch (message.role) {
      case 'user':
        return _buildUserBubble(context);
      case 'assistant':
        return _buildAssistantBubble(context);
      case 'system':
        return _buildSystemBubble(context);
      default:
        return _buildAssistantBubble(context);
    }
  }

  Widget _buildUserBubble(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, left: 60),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: MarkdownBody(
          data: message.content,
          styleSheet: MarkdownStyleSheet(
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
          ),
          selectable: true,
          onTapLink: (text, href, title) {},
        ),
      ),
    );
  }

  Widget _buildAssistantBubble(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;
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
              ThinkingBlock(content: message.thinkingContent!),
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

  Widget _buildMarkdownContent(String content, ThemeColors colors) {
    return MarkdownBody(
      data: content,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
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
      ),
      builders: {'pre': CodeBlockBuilder()},
      extensionSet: md.ExtensionSet.gitHubWeb,
      onTapLink: (text, href, title) {
        if (href != null) {
          Clipboard.setData(ClipboardData(text: href));
        }
      },
    );
  }

  Widget _buildSystemBubble(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;
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
            child: _buildHighlightedCode(),
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

  Widget _buildHighlightedCode() {
    final language = widget.language.isNotEmpty ? widget.language : 'plaintext';
    final mode = allLanguages[language];

    if (mode != null) {
      try {
        final result = highlight.parse(widget.code, language: language);
        return _buildCodeNodes(result.nodes!);
      } catch (e) {
        return _buildPlainCode();
      }
    }
    return _buildPlainCode();
  }

  Widget _buildPlainCode() {
    return SelectableText(
      widget.code,
      style: const TextStyle(
        fontFamily: 'monospace',
        fontSize: 13,
        color: Colors.white,
      ),
    );
  }

  Widget _buildCodeNodes(List<dynamic> nodes) {
    final spans = <InlineSpan>[];
    for (final node in nodes) {
      spans.addAll(_nodeToSpans(node));
    }
    return SelectableText.rich(
      TextSpan(
        children: spans,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
      ),
    );
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

  const ThinkingBlock({super.key, required this.content});

  @override
  State<ThinkingBlock> createState() => _ThinkingBlockState();
}

class _ThinkingBlockState extends State<ThinkingBlock> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.warning.withValues(alpha: 0.3)),
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
                  Icon(Icons.psychology, size: 16, color: colors.warning),
                  const SizedBox(width: 8),
                  Text(
                    '深度思考',
                    style: TextStyle(
                      color: colors.warning,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: colors.warning,
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
                  p: TextStyle(fontSize: 13, color: colors.warning),
                  code: TextStyle(
                    backgroundColor: colors.warning.withValues(alpha: 0.1),
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
