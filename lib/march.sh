#!/usr/bin/env bash

declare -A KERNEL_BY_MARCH=(
	["native"]="amd"
	["skylake"]="intel"
	["haswell"]="intel"
	["ivybridge"]="intel"
	["sandybridge"]="intel"
	["nehalem"]="intel"
	["westmere"]="intel"
	["core2"]="intel"
	["pentium-m"]="intel"
	["nocona"]="intel"
	["prescott"]="intel"
	["znver1"]="amd"
	["znver2"]="amd"
	["znver3"]="amd"
	["bdver4"]="amd"
	["bdver3"]="amd"
	["btver2"]="amd"
	["bdver2"]="amd"
	["bdver1"]="amd"
	["btver1"]="amd"
	["amdfam10"]="amd"
	["opteron-sse3"]="amd"
	["geode"]="amd"
	["opteron"]="amd"
	["power8"]="amd"
)

function get_kernel_by_march() {
	TARGET_KERNEL=${KERNEL_BY_MARCH[$1]}
}