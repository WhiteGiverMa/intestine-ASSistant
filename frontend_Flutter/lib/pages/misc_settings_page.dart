import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/api_service.dart';

class MiscSettingsPage extends StatefulWidget {
  const MiscSettingsPage({super.key});

  @override
  State<MiscSettingsPage> createState() => _MiscSettingsPageState();
}

class _MiscSettingsPageState extends State<MiscSettingsPage> {
  int _maxYear = 2112;
  final _maxYearController = TextEditingController();
  String? _message;
  bool _isLoading = false;

  final Map<String, bool> _clearSelections = {
    'api_config': false,
    'settings_data': false,
    'bowel_records': false,
  };

  final Map<String, bool> _exportSelections = {
    'api_config': false,
    'settings_data': false,
    'bowel_records': false,
  };

  final Map<String, String> _dataTypeLabels = {
    'api_config': 'API配置',
    'settings_data': '设置数据',
    'bowel_records': '排便记录',
  };

  final Map<String, String> _dataTypeDescriptions = {
    'api_config': 'AI API密钥、URL、模型配置',
    'settings_data': '开发者模式、最大年份等设置',
    'bowel_records': '所有排便记录数据',
  };

  @override
  void initState() {
    super.initState();
    _loadMaxYear();
  }

  @override
  void dispose() {
    _maxYearController.dispose();
    super.dispose();
  }

  Future<void> _loadMaxYear() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _maxYear = prefs.getInt('max_year') ?? 2112;
      _maxYearController.text = _maxYear.toString();
    });
  }

  Future<void> _saveMaxYear() async {
    final newMaxYear = int.tryParse(_maxYearController.text) ?? 2112;
    final clampedYear = newMaxYear.clamp(2013, 9999);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('max_year', clampedYear);
    setState(() {
      _maxYear = clampedYear;
      _maxYearController.text = clampedYear.toString();
      _message = '最大年份已设置为 $clampedYear';
    });
  }

  Future<void> _clearSelectedData() async {
    final selectedTypes = _clearSelections.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    if (selectedTypes.isEmpty) {
      setState(() => _message = '请至少选择一项数据类型');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清除'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('确定要清除以下数据吗？此操作不可撤销。'),
            const SizedBox(height: 12),
            ...selectedTypes.map((type) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.check, size: 16, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(_dataTypeLabels[type]!),
                ],
              ),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('确认清除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();

      for (final type in selectedTypes) {
        switch (type) {
          case 'api_config':
            await ApiService.updateUserSettings(
              aiApiKey: '',
              aiApiUrl: '',
              aiModel: '',
            );
            break;
          case 'settings_data':
            await prefs.remove('max_year');
            await ApiService.updateUserSettings(devMode: false);
            _maxYearController.text = '2112';
            break;
          case 'bowel_records':
            final records = await ApiService.getRecords(limit: 1000);
            for (final record in records) {
              await ApiService.deleteRecord(record.recordId);
            }
            break;
        }
      }

      setState(() {
        _clearSelections.updateAll((key, value) => false);
        _message = '已清除选中的数据';
      });
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      if (errorMsg.contains('认证') || errorMsg.contains('token')) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');
        await prefs.remove('user');
        setState(() => _message = '登录已过期，请重新登录');
      } else {
        setState(() => _message = '清除失败: $errorMsg');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _exportSelectedData() async {
    final selectedTypes = _exportSelections.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    if (selectedTypes.isEmpty) {
      setState(() => _message = '请至少选择一项数据类型');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final exportData = <String, dynamic>{
        'export_time': DateTime.now().toIso8601String(),
        'app_version': '1.0.0',
      };

      final prefs = await SharedPreferences.getInstance();

      for (final type in selectedTypes) {
        switch (type) {
          case 'api_config':
            final settings = await ApiService.getUserSettings();
            exportData['api_config'] = {
              'ai_api_key': settings['ai_api_key'] ?? '',
              'ai_api_url': settings['ai_api_url'] ?? '',
              'ai_model': settings['ai_model'] ?? '',
            };
            break;
          case 'settings_data':
            exportData['settings_data'] = {
              'max_year': prefs.getInt('max_year') ?? 2112,
              'dev_mode': prefs.getBool('dev_mode') ?? false,
            };
            break;
          case 'bowel_records':
            final records = await ApiService.getRecords(limit: 1000);
            exportData['bowel_records'] = records
                .map((r) => {
                      'record_id': r.recordId,
                      'record_date': r.recordDate,
                      'record_time': r.recordTime,
                      'duration_minutes': r.durationMinutes,
                      'stool_type': r.stoolType,
                      'color': r.color,
                      'smell_level': r.smellLevel,
                      'feeling': r.feeling,
                      'symptoms': r.symptoms,
                      'notes': r.notes,
                      'is_no_bowel': r.isNoBowel,
                      'created_at': r.createdAt,
                    })
                .toList();
            break;
        }
      }

      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
      final fileName = 'intestine_assistant_export_$timestamp.json';
      final jsonContent = const JsonEncoder.withIndent('  ').convert(exportData);

      if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
        final outputPath = await FilePicker.platform.saveFile(
          dialogTitle: '导出数据',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['json'],
        );

        if (outputPath == null) {
          setState(() => _isLoading = false);
          return;
        }

        final file = File(outputPath);
        await file.writeAsString(jsonContent);

        setState(() {
          _exportSelections.updateAll((key, value) => false);
          _message = '数据已导出至: $outputPath';
        });
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/$fileName';
        final file = File(filePath);
        await file.writeAsString(jsonContent);

        await Share.shareXFiles(
          [XFile(filePath)],
          subject: '肠道助手数据导出',
          text: '已导出您的用户数据',
        );

        setState(() {
          _exportSelections.updateAll((key, value) => false);
          _message = '数据已导出并分享';
        });
      }
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      if (errorMsg.contains('认证') || errorMsg.contains('token')) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');
        await prefs.remove('user');
        setState(() => _message = '登录已过期，请重新登录');
      } else {
        setState(() => _message = '导出失败: $errorMsg');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE8F5E9), Color(0xFFB2DFDB)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildMaxYearCard(),
                      const SizedBox(height: 16),
                      _buildClearDataCard(),
                      const SizedBox(height: 16),
                      _buildExportDataCard(),
                      if (_message != null) ...[
                        const SizedBox(height: 16),
                        _buildMessage(),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Text(
              '←',
              style: TextStyle(fontSize: 20, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            '杂项',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaxYearCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text('📅', style: TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '系统记录最大年份',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '设置日期选择器的最大年份限制',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 20),
          Text(
            '设置日期选择器的最大年份限制（默认：2112）',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _maxYearController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: '最大年份',
                    hintText: '2112',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _saveMaxYear,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '保存',
                  style: TextStyle(fontSize: 14, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '最小年份固定为 2012',
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildClearDataCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text('🗑️', style: TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '清除用户数据',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '选择要清除的数据类型',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          ..._dataTypeLabels.entries.map((entry) => _buildClearCheckbox(
                entry.key,
                entry.value,
                _dataTypeDescriptions[entry.key]!,
              )),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _clearSelectedData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isLoading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  else
                    const Text('🗑️', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(
                    _isLoading ? '处理中...' : '清除选中数据',
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClearCheckbox(String key, String label, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Checkbox(
            value: _clearSelections[key],
            onChanged: (value) {
              setState(() {
                _clearSelections[key] = value ?? false;
              });
            },
            activeColor: Colors.red,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportDataCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text('📤', style: TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '导出用户数据',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '选择要导出的数据类型',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          ..._dataTypeLabels.entries.map((entry) => _buildExportCheckbox(
                entry.key,
                entry.value,
                _dataTypeDescriptions[entry.key]!,
              )),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _exportSelectedData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isLoading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  else
                    const Text('📤', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(
                    _isLoading ? '处理中...' : '导出选中数据',
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportCheckbox(String key, String label, String description) {
    final isApiConfig = key == 'api_config';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: _exportSelections[key],
                onChanged: (value) {
                  setState(() {
                    _exportSelections[key] = value ?? false;
                  });
                },
                activeColor: const Color(0xFF2E7D32),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isApiConfig)
            Padding(
              padding: const EdgeInsets.only(left: 40, top: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, size: 14, color: Colors.orange[700]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '导出的文件将包含API密钥，请注意保管，避免泄露',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.orange[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessage() {
    final isSuccess = _message!.contains('成功') ||
        _message!.contains('已设置') ||
        _message!.contains('已清除') ||
        _message!.contains('已导出');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSuccess ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle : Icons.error,
            color: isSuccess ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _message!,
              style: TextStyle(
                fontSize: 12,
                color: isSuccess ? Colors.green : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
