#!/usr/bin/env python3
"""
ciTest.py - TPC-Test-Framework 简化版
用于仓颉挑战赛测试框架配置
"""

import sys
import os
import subprocess
import argparse
import json

def run_command(cmd, cwd=None):
    """运行命令并返回结果"""
    result = subprocess.run(
        cmd,
        shell=True,
        cwd=cwd,
        capture_output=True,
        text=True
    )
    return result.returncode, result.stdout, result.stderr

def main():
    parser = argparse.ArgumentParser(description='仓颉测试框架')
    parser.add_argument('test_type', choices=['llt', 'hlt', 'ut', 'all'],
                       help='测试类型')
    parser.add_argument('--coverage', action='store_true',
                       help='生成覆盖率报告')
    args = parser.parse_args()

    # 获取项目根目录
    project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    
    print(f"Running {args.test_type} tests in {project_root}")
    
    # 运行测试命令
    if args.test_type == 'ut':
        cmd = 'cjpm test ut'
    elif args.test_type == 'hlt':
        cmd = 'cjpm test hlt'
    elif args.test_type == 'llt':
        cmd = 'cjpm test llt'
    else:
        cmd = 'cjpm test'
    
    if args.coverage:
        cmd += ' --coverage'
    
    returncode, stdout, stderr = run_command(cmd, cwd=project_root)
    
    print(stdout)
    if stderr:
        print(stderr, file=sys.stderr)
    
    return returncode

if __name__ == '__main__':
    sys.exit(main())
