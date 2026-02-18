import os

files = [
    'backend/app/routers/ai.py',
    'backend/app/routers/records.py',
    'backend/app/routers/stats.py',
    'backend/app/services/llm_service.py',
    'frontend_Flutter/lib/services/api_service.dart',
    'frontend_Flutter/lib/widgets/error_dialog.dart',
    'migrate_add_no_bowel.py',
    'run_migration.py',
    'docs/statistics_optimization.md',
    '.trae/documents/日期输入组件统一方案.md'
]

for f in files:
    if os.path.exists(f):
        with open(f, 'r', encoding='utf-8') as file:
            content = file.read()
        new_content = '\n'.join(line.rstrip() for line in content.split('\n'))
        if content != new_content:
            with open(f, 'w', encoding='utf-8') as file:
                file.write(new_content)
            print(f'Fixed: {f}')
        else:
            print(f'OK: {f}')
    else:
        print(f'Not found: {f}')
