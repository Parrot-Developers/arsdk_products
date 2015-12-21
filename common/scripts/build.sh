#!/bin/bash

set -e

# Get full path to this script
if [ -L ${BASH_SOURCE} ]; then
	SCRIPT_PATH=$(cd $(dirname $(readlink ${BASH_SOURCE})) && pwd)
else
	SCRIPT_PATH=$(cd $(dirname ${BASH_SOURCE}) && pwd)
fi
TOP_DIR=$(cd ${SCRIPT_PATH}/../../.. && pwd)

PRODUCT=
VARIANT=

################################################################################
# Print usage and exits with given exit code.
# $1 : exit code.
################################################################################
function usage()
{
	echo "Usage:"
	echo "  $(basename $0) -h"
	echo "  $(basename $0) -l"
	echo "  $(basename $0) -p [<product>-<variant>] [<args>...]"
	exit $1
}

################################################################################
# Get list of available products (excluding 'common').
################################################################################
function _get_products()
{
	local products_dir=${TOP_DIR}/products
	local products=$(cd ${products_dir} && ls -d */ | tr -d "/" | sed "s/common//g")
	echo ${products}
}

################################################################################
# Get list of available variants of a products (excluding 'common').
# $1 : product name.
################################################################################
function _get_variants()
{
	local variants_dir=${TOP_DIR}/products/$1
	local variants=$(cd ${variants_dir} && ls -d */ | tr -d "/" | sed "s/common//g")
	echo ${variants}
}

################################################################################
# Slpit <product>-<variant> in variables PRODUCT and VARIANT
# $1 <product>-<variant>
################################################################################
function _set_combo()
{
	local combo=$1
	PRODUCT=
	VARIANT=

	if [ "${combo}" = "forall" -o "${combo}" = "forall-forall" ]; then
		PRODUCT="forall"
		VARIANT="forall"
		return
	fi

	for product in $(_get_products); do
		for variant in $(_get_variants ${product}) forall; do
			if [ "${combo}" = "${product}-${variant}" ]; then
				PRODUCT=${product}
				VARIANT=${variant}
				return
			fi
		done
	done

	echo >&2 "Unknown product specification: ${combo}"
	exit 1
}

################################################################################
# Restart the build script with given product/variant
# $1 : product name.
# $2 : variant name.
################################################################################
function _restart()
{
	local product=$1; shift
	local variant=$1; shift
	echo >&2 "> ${BASH_SOURCE} -p ${product}-${variant} "$@""
	PRODUCT=${product} VARIANT=${variant} ${BASH_SOURCE} -p ${product}-${variant} "$@"
}

################################################################################
################################################################################
function _launch_alchemake()
{
	# Setup alchemy
	export ALCHEMY_WORKSPACE_DIR=${TOP_DIR}
	export ALCHEMY_HOME=${ALCHEMY_WORKSPACE_DIR}/build/alchemy
	export ALCHEMY_USE_COLORS=1
	ALCHEMAKE=${ALCHEMY_HOME}/scripts/alchemake

	export ALCHEMY_TARGET_PRODUCT=${PRODUCT}
	export ALCHEMY_TARGET_PRODUCT_VARIANT=${VARIANT}
	export ALCHEMY_TARGET_CONFIG_DIR=${TOP_DIR}/products/${PRODUCT}/${VARIANT}/config
	export ALCHEMY_TARGET_OUT=${TOP_DIR}/out/${PRODUCT}-${VARIANT}

	export ALCHEMY_TARGET_SCAN_PRUNE_DIRS=${ALCHEMY_WORKSPACE_DIR}
	export ALCHEMY_TARGET_SCAN_ADD_DIRS=${ALCHEMY_WORKSPACE_DIR}/packages

	# Go!
	echo >&2 "> ${ALCHEMAKE} "$@""
	${ALCHEMAKE} "$@"
}

################################################################################
################################################################################
function _build_android_jni()
{
    echo >&2 "> ndk-build"
    DIRS=$(find ${TOP_DIR}/packages/Samples/ -name 'Android.mk' -print0 | xargs -0 -n1 dirname)
    for DIR in ${DIRS}
    do
        cd ${DIR}
        ${ANDROID_NDK_PATH}/ndk-build
    done
    cd ${TOP_DIR}
}

################################################################################
################################################################################
function _build_android_samples()
{
    echo >&2 "> gradle"
    DIRS=$(find ${TOP_DIR}/packages/Samples -name 'gradlew' -print0 | xargs -0 -n1 dirname)
    for DIR in ${DIRS}
    do
        cd ${DIR}
        ./gradlew assembleDebug
    done
    cd ${TOP_DIR}
}

################################################################################
################################################################################
function _build_ios_samples()
{
    echo >&2 "> xcodebuild"
    DIRS=$(find ${TOP_DIR}/packages/Samples -name '*.xcodeproj' -print0 | xargs -0 -n1 dirname)
    for DIR in ${DIRS}
    do
        cd ${DIR}
        xcodebuild -arch x86_64  -sdk iphonesimulator9.0
    done
    cd ${TOP_DIR}
}

################################################################################
################################################################################

# Parse command line arguments
opt_list_products=0
opt_product_variant=
opt_task=
while getopts "hlp:t:" opt; do
	case ${opt} in
		l) opt_list_products=1;;
		h) usage 0;;
		p) opt_product_variant=${OPTARG};;
		t) opt_task=${OPTARG};;
	esac
done
shift $((OPTIND - 1))

if [ -z "${opt_product_variant}" ]; then
	echo >&2 "Missing -p option"
	exit 1
fi
_set_combo ${opt_product_variant}

if [ "${PRODUCT}" = "forall" ]; then
	for product in $(_get_products); do
		_restart ${product} "forall" "$@"
	done
elif [ "${VARIANT}" = "forall" ]; then
	for variant in $(_get_variants ${PRODUCT}); do
		_restart ${PRODUCT} ${variant} "$@"
	done

	if [ "${PRODUCT}" = "Android" ]; then
		if [ "${opt_task}" = "build-jni" ]; then
			_build_android_jni
		elif [ "${opt_task}" = "build-samples" ]; then
			_build_android_jni
			_build_android_samples
		fi
	fi
else
	_launch_alchemake "$@"

	if [ "${PRODUCT}" = "iOS" ]; then
		if [ "${VARIANT}" = "iphonesimulator" ]; then
			if [ "${opt_task}" = "build-samples" ]; then
				_build_ios_samples
			fi
		fi
	fi
fi


