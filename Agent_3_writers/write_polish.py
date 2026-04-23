import sys
import re

def polish_cii(filepath):
    """
    Polishing logic specifically to match the format of BM_CII.CII exactly.
    For this assignment, we mostly just enforce CRLF.
    """
    with open(filepath, 'rb') as f:
        content = f.read()

    # Ensure CRLF line endings
    content = content.replace(b'\r\n', b'\n').replace(b'\n', b'\r\n')

    # Optionally ensure file ends with CRLF
    if not content.endswith(b'\r\n'):
        content += b'\r\n'

    with open(filepath, 'wb') as f:
        f.write(content)

if __name__ == '__main__':
    polish_cii(sys.argv[1])
