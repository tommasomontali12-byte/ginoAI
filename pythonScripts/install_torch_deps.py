import subprocess
import sys

def run_pip_realtime(args):
    try:
        process = subprocess.Popen(
            args,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1,
            universal_newlines=True
        )
        for line in process.stdout:
            print(line, end='', flush=True)
        process.wait()
        if process.returncode != 0:
            print(f"\n❌ Installation failed.", file=sys.stderr)
            sys.exit(1)
    except FileNotFoundError:
        print("❌ Python/pip not found.", file=sys.stderr)
        sys.exit(1)

def confirm_download():
    print("⚠️  WARNING: This will download ~2.4 GB of data (PyTorch + AI models).")
    print("   - On a 50 Mbps connection: ~6–10 minutes")
    print("   - On mobile/data: could cost money or hit limits")
    print()
    while True:
        response = input("Continue? (y/n): ").strip().lower()
        if response in ("y", "yes"):
            return True
        elif response in ("n", "no"):
            print("Installation cancelled by user.")
            sys.exit(0)
        else:
            print("Please type 'y' or 'n'.")

if __name__ == "__main__":
    print("We are just installing some things to make Image creation possible.")
    print("=" * 70)

    confirm_download()

    python = sys.executable

    cmd1 = [
        python, "-m", "pip", "install",
        "torch", "torchvision", "torchaudio",
        "--index-url", "https://download.pytorch.org/whl/cu121"
    ]
    cmd2 = [
        python, "-m", "pip", "install",
        "diffusers", "transformers", "accelerate", "pillow"
    ]

    print("\n🚀 Starting installation...\n")

    run_pip_realtime(cmd1)
    print("\n✅ PyTorch installed!\n")

    run_pip_realtime(cmd2)
    print("\n✅ All dependencies ready!\n")

    print("🎉 Image generation is now possible!")
    print("\n💡 Tip: Future runs won't need to re-download this.")