#!/bin/bash

set -eo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
PLATFORM=$(python -c 'import platform; print(platform.system())')

echo "Installing pip-pre dependencies on ${PLATFORM}"
STD_ARGS="--progress-bar off --upgrade --pre"
QT_BINDING="PyQt6"

# Dependencies of scientific-python-nightly-wheels are installed here so that
# we can use strict --index-url (instead of --extra-index-url) below
echo "PyQt6 and scientific-python-nightly-wheels dependencies"
python -m pip install $STD_ARGS pip setuptools packaging \
	threadpoolctl cycler fonttools kiwisolver pyparsing pillow python-dateutil \
	patsy pytz tzdata nibabel tqdm trx-python joblib numexpr "$QT_BINDING"
echo "NumPy/SciPy/pandas etc."
python -m pip uninstall -yq numpy
# No pyarrow yet https://github.com/apache/arrow/issues/40216
# No h5py (and thus dipy) yet until they improve/refactor thier wheel building infrastructure for Windows
OTHERS=""
if [[ "${PLATFORM}" == "Linux" ]]; then
	OTHERS="h5py dipy"
fi
python -m pip install $STD_ARGS --only-binary ":all:" --default-timeout=60 \
	--index-url "https://pypi.anaconda.org/scientific-python-nightly-wheels/simple" \
	"numpy>=2.1.0.dev0" "scikit-learn>=1.6.dev0" "scipy>=1.15.0.dev0" \
	"statsmodels>=0.15.0.dev0" "pandas>=3.0.0.dev0" "matplotlib>=3.10.0.dev0" \
	$OTHERS

# No Numba because it forces an old NumPy version

if [[ "${PLATFORM}" == "Linux" ]]; then
	echo "pymatreader"
	pip install https://gitlab.com/obob/pymatreader/-/archive/master/pymatreader-master.zip
fi

echo "OpenMEEG"
python -m pip install $STD_ARGS --only-binary ":all:" --extra-index-url "https://test.pypi.org/simple" "openmeeg>=2.6.0.dev4"

echo "nilearn"
# TODO: Revert once settled:
# https://github.com/scikit-learn/scikit-learn/pull/30268#issuecomment-2479701651
python -m pip install $STD_ARGS "git+https://github.com/larsoner/nilearn@sklearn"

echo "VTK"
# No pre until PyVista fixes a bug
if [[ "${PLATFORM}" == "Windows" ]]; then
	python -m pip install $STD_ARGS "vtk<9.4"  # 9.4 requires GLSL 1.5 and Azure win only has 1.3
else
	python -m pip install $STD_ARGS --only-binary ":all:" --extra-index-url "https://wheels.vtk.org" vtk
fi
python -c "import vtk"

echo "PyVista"
python -m pip install $STD_ARGS "git+https://github.com/pyvista/pyvista"

echo "picard"
python -m pip install $STD_ARGS git+https://github.com/pierreablin/picard

echo "pyvistaqt"
pip install $STD_ARGS git+https://github.com/pyvista/pyvistaqt

echo "imageio-ffmpeg, xlrd, mffpy"
pip install $STD_ARGS imageio-ffmpeg xlrd mffpy traitlets pybv eeglabio

echo "mne-qt-browser"
pip install $STD_ARGS git+https://github.com/mne-tools/mne-qt-browser

echo "mne-bids"
pip install $STD_ARGS git+https://github.com/mne-tools/mne-bids

echo "nibabel"
pip install $STD_ARGS git+https://github.com/nipy/nibabel

echo "joblib"
pip install $STD_ARGS git+https://github.com/joblib/joblib

echo "edfio"
# Disable protection for Azure, see
# https://github.com/mne-tools/mne-python/pull/12609#issuecomment-2115639369
GIT_CLONE_PROTECTION_ACTIVE=false pip install $STD_ARGS git+https://github.com/the-siesta-group/edfio

if [[ "${PLATFORM}" == "Linux" ]]; then
	echo "h5io"
	pip install $STD_ARGS git+https://github.com/h5io/h5io

	echo "pysnirf2"
	pip install $STD_ARGS git+https://github.com/BUNPC/pysnirf2
fi

# Make sure we're on a NumPy 2.0 variant
echo "Checking NumPy version"
python -c "import numpy as np; assert np.__version__[0] == '2', np.__version__"

# And that Qt works
echo "Checking Qt"
${SCRIPT_DIR}/check_qt_import.sh "$QT_BINDING"
