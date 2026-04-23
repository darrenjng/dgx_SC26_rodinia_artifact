#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_FILE="${ROOT_DIR}/all_output.txt"
CSV_FILE="${ROOT_DIR}/summary.csv"

cd "${ROOT_DIR}"

> "${OUTPUT_FILE}"
printf "app,version,total_time,compute_time,host_peak_rss,gpu_mem_used,gpu_mem_free,gpu_mem_total\n" > "${CSV_FILE}"

log() {
    echo "$*" | tee -a "${OUTPUT_FILE}"
}

append_csv_from_log() {
    local app="$1"
    local version="$2"
    local tag="$3"
    local logfile="$4"
    local line

    line="$(grep -E "^ *\\[${tag}\\].*" "${logfile}" | tail -1 || true)"
    if [[ -z "${line}" ]]; then
        log "Warning: no summary line found for ${app} ${version}"
        return 0
    fi

    local total_time compute_time host_peak_rss gpu_mem_used gpu_mem_free gpu_mem_total
    total_time="$(echo "${line}" | sed -n 's/.*total_time \([0-9.]*\) sec.*/\1/p')"
    compute_time="$(echo "${line}" | sed -n 's/.*compute_time \([0-9.]*\) sec.*/\1/p')"
    host_peak_rss="$(echo "${line}" | sed -n 's/.*host_peak_rss \([0-9]*\) KB.*/\1/p')"
    gpu_mem_used="$(echo "${line}" | sed -n 's/.*gpu_mem_used \([0-9]*\).*/\1/p')"
    gpu_mem_free="$(echo "${line}" | sed -n 's/.*gpu_mem_free \([0-9]*\).*/\1/p')"
    gpu_mem_total="$(echo "${line}" | sed -n 's/.*gpu_mem_total \([0-9]*\).*/\1/p')"

    printf "%s,%s,%s,%s,%s,%s,%s,%s\n" \
        "${app}" "${version}" "${total_time}" "${compute_time}" "${host_peak_rss}" \
        "${gpu_mem_used}" "${gpu_mem_free}" "${gpu_mem_total}" >> "${CSV_FILE}"
}

run_case() {
    local app="$1"
    local version="$2"
    local rel_dir="$3"
    local binary="$4"
    local tag="$5"
    shift 5

    local workdir="${ROOT_DIR}/${rel_dir}"
    local exe="${workdir}/${binary}"
    local logfile
    logfile="$(mktemp)"

    if [[ ! -x "${exe}" ]]; then
        log "Skipping ${app} ${version}: missing binary ${rel_dir}/${binary}"
        rm -f "${logfile}"
        return 0
    fi

    log "Running ${app} ${version}..."
    if (
        cd "${workdir}"
        "${exe}" "$@"
    ) 2>&1 | tee -a "${OUTPUT_FILE}" | tee "${logfile}" >/dev/null; then
        append_csv_from_log "${app}" "${version}" "${tag}" "${logfile}"
    else
        log "Run failed for ${app} ${version}"
    fi

    rm -f "${logfile}"
}

run_case "srad_v1" "baseline" "cuda/srad/srad_v1" "srad" "srad_v1" 10 0.5 2048 2048
run_case "srad_v1" "unified" "cuda/srad/srad_v1" "srad_unified" "srad_v1_unified" 10 0.5 2048 2048

run_case "nn" "baseline" "cuda/nn" "nn" "nn" filelist_4 30.0 90.0 10 -q
run_case "nn" "unified" "cuda/nn" "nn_unified" "nn_unified" filelist_4 30.0 90.0 10 -q

run_case "hotspot" "baseline" "cuda/hotspot" "hotspot" "hotspot" 512 512 1000 ../../data/hotspot/temp_512 ../../data/hotspot/power_512 output_baseline.dat
run_case "hotspot" "unified" "cuda/hotspot" "hotspot_unified" "hotspot_unified" 512 512 1000 ../../data/hotspot/temp_512 ../../data/hotspot/power_512 output_unified.dat

run_case "heartwall" "baseline" "cuda/heartwall" "heartwall" "heartwall" ../../data/heartwall/test.avi 20
run_case "heartwall" "unified" "cuda/heartwall" "heartwall_unified" "heartwall_unified" ../../data/heartwall/test.avi 20

log "All runs completed. Outputs in ${OUTPUT_FILE}, summaries in ${CSV_FILE}."
