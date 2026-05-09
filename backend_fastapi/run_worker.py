import subprocess
import sys
import os

def run_worker():
    """
    Start the Celery worker for the Smart Campus Assistant.
    Equivalent to: celery -A app.celery_app worker --loglevel=info -P solo
    (Using -P solo for Windows compatibility)
    """
    print("🚀 Starting Smart Campus Celery Worker...")
    
    # Ensure the current directory is in the python path
    os.environ["PYTHONPATH"] = os.getcwd()
    
    cmd = [
        "celery",
        "-A", "app.celery_app",
        "worker",
        "--loglevel=info",
        "-P", "solo"
    ]
    
    try:
        subprocess.run(cmd, check=True)
    except KeyboardInterrupt:
        print("\n🛑 Worker stopped.")
    except Exception as e:
        print(f"❌ Error starting worker: {e}")

if __name__ == "__main__":
    run_worker()
