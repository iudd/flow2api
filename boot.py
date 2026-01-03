import os
import sys
import time
import subprocess
import threading
import shutil
from pathlib import Path

def run_command(command, shell=False):
    """Run a command and print output"""
    try:
        subprocess.run(command, shell=shell, check=True)
    except subprocess.CalledProcessError as e:
        print(f"Command failed: {e}")
    except Exception as e:
        print(f"Error running command: {e}")

def configure_rclone():
    """Configure rclone from environment variable"""
    rclone_conf = os.environ.get("RCLON_CONF")
    if not rclone_conf:
        print("No RCLON_CONF environment variable found. Skipping rclone setup.")
        return False

    print("Configuring rclone...")
    config_dir = Path.home() / ".config" / "rclone"
    config_dir.mkdir(parents=True, exist_ok=True)
    config_file = config_dir / "rclone.conf"

    # Parse config to avoid cleartext password if possible, or just write it
    # For simplicity and robustness, we'll write the temp file and let rclone config create handle it if we can parse it,
    # otherwise just write the raw content.
    
    try:
        # Simple parsing
        lines = rclone_conf.strip().split('\n')
        conf_data = {}
        for line in lines:
            if '=' in line:
                key, value = line.split('=', 1)
                conf_data[key.strip()] = value.strip()
        
        if 'pass' in conf_data:
            # Re-create config to obscure password
            print("Obscuring password and creating config...")
            cmd = [
                "rclone", "config", "create", "infini_dav",
                conf_data.get("type", "webdav"),
                "url", conf_data.get("url", ""),
                "vendor", conf_data.get("vendor", "other"),
                "user", conf_data.get("user", ""),
                "pass", conf_data.get("pass", ""),
                "--non-interactive"
            ]
            run_command(cmd)
        else:
            # Write directly if parsing fails or no password
            print("Writing config directly...")
            config_file.write_text(rclone_conf)
            
        return True
    except Exception as e:
        print(f"Error configuring rclone: {e}")
        return False

def restore_data():
    """Restore data from WebDAV"""
    print("Restoring data from remote...")
    # --ignore-existing to avoid overwriting newer local files if any (though on boot local is usually empty)
    run_command(["rclone", "copy", "infini_dav:flow2api_data", "/app/data", "--ignore-existing"])

def background_sync():
    """Sync data to remote every 15 minutes"""
    print("Starting background sync thread...")
    while True:
        time.sleep(900)  # 15 minutes
        print("Syncing data to remote...")
        run_command(["rclone", "sync", "/app/data", "infini_dav:flow2api_data"])

def main():
    # 1. Setup Rclone
    if configure_rclone():
        # 2. Restore Data
        restore_data()
        
        # 3. Start Sync Thread
        sync_thread = threading.Thread(target=background_sync, daemon=True)
        sync_thread.start()

    # 4. Start Main Application
    print("Starting main application...")
    # We run main.py in the same process or subprocess. 
    # Using subprocess allows us to catch its exit code if needed, 
    # but replacing the process is better for signal handling.
    
    # Option A: Import and run (runs in same process)
    # import main
    # main.main() 
    
    # Option B: Subprocess (cleaner separation)
    sys.stdout.flush()
    os.execl(sys.executable, sys.executable, "main.py")

if __name__ == "__main__":
    main()
