#!/usr/bin/env python3
"""
数据库设置脚本
帮助用户配置和初始化数据库
"""

import os
import sys
import getpass
from pathlib import Path

# 添加当前目录到 Python 路径
current_dir = Path(__file__).parent
sys.path.append(str(current_dir))

def setup_database():
    """设置数据库配置"""
    print("=== iSeeFit 数据库设置 ===")
    print()
    
    # 获取数据库配置
    print("请输入 MySQL 数据库配置信息：")
    db_host = input("数据库主机 (默认: localhost): ").strip() or "localhost"
    db_port = input("数据库端口 (默认: 3306): ").strip() or "3306"
    db_user = input("数据库用户名 (默认: root): ").strip() or "root"
    db_password = getpass.getpass("数据库密码: ")
    db_name = input("数据库名称 (默认: iseefit): ").strip() or "iseefit"
    
    # 设置环境变量
    os.environ["DB_HOST"] = db_host
    os.environ["DB_PORT"] = db_port
    os.environ["DB_USER"] = db_user
    os.environ["DB_PASSWORD"] = db_password
    os.environ["DB_NAME"] = db_name
    
    print()
    print("配置信息：")
    print(f"  主机: {db_host}")
    print(f"  端口: {db_port}")
    print(f"  用户: {db_user}")
    print(f"  密码: {'*' * len(db_password)}")
    print(f"  数据库: {db_name}")
    print()
    
    # 确认配置
    confirm = input("确认使用以上配置？(y/N): ").strip().lower()
    if confirm != 'y':
        print("设置已取消")
        return False
    
    # 创建 .env 文件
    env_content = f"""# 数据库配置
DB_HOST={db_host}
DB_PORT={db_port}
DB_USER={db_user}
DB_PASSWORD={db_password}
DB_NAME={db_name}

# JWT 配置
SECRET_KEY=your-secret-key-here-change-in-production
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# 文件上传配置
UPLOAD_DIR=uploads
MAX_FILE_SIZE=10485760  # 10MB

# 日志配置
LOG_LEVEL=INFO

# 推荐系统配置
RECOMMENDATION_UPDATE_INTERVAL=24  # 小时
"""
    
    env_file = current_dir / ".env"
    with open(env_file, "w", encoding="utf-8") as f:
        f.write(env_content)
    
    print(f"配置已保存到 {env_file}")
    print()
    
    # 测试数据库连接
    print("测试数据库连接...")
    try:
        from init_db import init_database
        init_database()
        print("✅ 数据库连接成功！")
        print("✅ 数据库表创建成功！")
        print("✅ 示例数据创建成功！")
        return True
    except Exception as e:
        print(f"❌ 数据库连接失败: {e}")
        print()
        print("请检查：")
        print("1. MySQL 服务是否正在运行")
        print("2. 数据库用户名和密码是否正确")
        print("3. 是否有权限创建数据库")
        return False

def main():
    """主函数"""
    try:
        success = setup_database()
        if success:
            print()
            print("🎉 数据库设置完成！")
            print()
            print("现在你可以启动 API 服务器：")
            print("  python start_server.py")
            print()
            print("或者使用 uvicorn：")
            print("  uvicorn main:app --host 0.0.0.0 --port 8000 --reload")
            print()
            print("API 文档地址：")
            print("  http://localhost:8000/docs")
        else:
            print()
            print("❌ 数据库设置失败，请检查配置后重试")
            sys.exit(1)
    except KeyboardInterrupt:
        print("\n设置已取消")
        sys.exit(0)
    except Exception as e:
        print(f"设置过程中出现错误: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
