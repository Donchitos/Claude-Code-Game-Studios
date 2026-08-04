"""
Check PixelLab account balance.

Usage:
    python pixellab_balance.py
"""
import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pixellab_client import get_balance

result = get_balance()
print(result)
