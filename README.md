# DGX Spark Scientific Bench Artifact

This repository is a binary-only artifact package for the DGX Spark shared-memory Rodinia Bench. 

## Contents

- `run_all.sh`: runs the packaged CUDA benchmarks and writes `all_output.txt` and `summary.csv`
- `cuda/`: benchmark binaries and benchmark-local assets
- `data/`: Rodinia input files required by `run_all.sh`

## Workloads Evaluated

- `srad_v1`: baseline, unified
- `nn`: baseline, unified
- `hotspot`: baseline, unified
- `heartwall`: baseline, unified

## Platform assumptions

- Linux on `aarch64`
- NVIDIA DGX Spark environment

## Usage

Run from the repository root:

```bash
chmod +x run_all.sh
./run_all.sh
```

Outputs:

- `all_output.txt`: combined stdout/stderr log from all runs
- `summary.csv`: parsed timing and memory summary lines

## Data provenance

The packaged benchmark inputs under `data/` were extracted from the Rodinia 3.1 dataset archive and reduced to only the files referenced by `run_all.sh`.
