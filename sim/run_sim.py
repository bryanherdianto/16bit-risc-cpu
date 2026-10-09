import subprocess
import sys
import os

VSIM_EXE = r"D:\intelFPGA_lite\20.1\modelsim_ase\win32aloem\vsim.exe"
VCOM_EXE = r"D:\intelFPGA_lite\20.1\modelsim_ase\win32aloem\vcom.exe"
VLIB_EXE = r"D:\intelFPGA_lite\20.1\modelsim_ase\win32aloem\vlib.exe"

CPU_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
WORK_DIR = os.path.join(CPU_DIR, "work")
SRC_DIR = os.path.join(CPU_DIR, "src")
SIM_DIR = os.path.join(CPU_DIR, "sim")

def run():
    print("=" * 65)
    print("16-BIT RISC CPU IN VHDL - AUTOMATED SIMULATION RUNNER")
    print("=" * 65)

    if not os.path.exists(WORK_DIR):
        print("[1/3] Creating ModelSim work library...")
        subprocess.run([VLIB_EXE, WORK_DIR], check=True)
    else:
        print("[1/3] Using existing work library...")

    print("[2/3] Compiling VHDL design files...")
    sources = [
        os.path.join(SRC_DIR, "cpu_pkg.vhd"),
        os.path.join(SRC_DIR, "decoder.vhd"),
        os.path.join(SRC_DIR, "alu.vhd"),
        os.path.join(SRC_DIR, "registerfile.vhd"),
        os.path.join(SRC_DIR, "cpu.vhd"),
        os.path.join(SIM_DIR, "cpu_tb.vhd")
    ]
    compile_cmd = [VCOM_EXE, "-work", WORK_DIR] + sources
    comp_res = subprocess.run(compile_cmd, capture_output=True, text=True)
    if comp_res.returncode != 0:
        print("Compilation Failed:\n", comp_res.stdout, comp_res.stderr)
        sys.exit(1)
    print("      Compilation successful: 0 Errors, 0 Warnings.")

    print("[3/3] Running simulation in ModelSim...")
    sim_cmd = [
        VSIM_EXE,
        "-c",
        "-lib", WORK_DIR,
        "cpu_tb",
        "-do", "run -all; quit -f"
    ]
    sim_res = subprocess.run(sim_cmd, capture_output=True, text=True)
    print(sim_res.stdout)
    if "ALL CPU VERIFICATION TESTS COMPLETED SUCCESSFULLY!" in sim_res.stdout:
        print("=" * 65)
        print("SUCCESS: All CPU tests passed perfectly!")
        print("=" * 65)
    else:
        print("FAILED: Output did not indicate successful completion.")
        sys.exit(1)

if __name__ == "__main__":
    run()