from passlib.context import CryptContext

pwd = CryptContext(schemes=['bcrypt'], deprecated='auto')
print('Testing hash')
try:
    hash_val = pwd.hash('test123')
    print('Hash:', hash_val)
    print('Verify:', pwd.verify('test123', hash_val))
except Exception as e:
    print('Error:', e)
    import traceback
    traceback.print_exc()