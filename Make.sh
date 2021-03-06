#!/bin/sh

# ---
# Non-Haskell RGL build script for Unix-based machines
# ---

# Modules to compile for each language
# langs="Afr Amh Ara Eus Bul Cat Chi Dan Dut Eng Est Fin Fre Grc Gre Heb Hin Ger Ice Ina Ita Jpn Lat Lav Mlt Mon Nep Nor Nno Pes Pol Por Pnb Ron Rus Snd Spa Swe Tha Tur Urd"
modules_langs="All Symbol Compatibility"
modules_api="Try Symbolic"

# Defaults (may be overridden by options)
gf="gf"
dest=""
verbose="false"

# Check command line options
for arg in "$@"; do
  case $arg in
    --gf=*)
      gf="${arg#*=}"; shift ;;
    --dest=*)
      dest="${arg#*=}"; shift ;;
    --verbose|-v)
      verbose="true"; shift ;;
    *) echo "Unknown option: ${arg}" ; exit 1 ;;
  esac
done

# Try to determine install location
if [ -z "$dest" ]; then
  dest="$GF_LIB_PATH"
fi
if [ -z "$dest" ] && [ -f "../gf-core/DATA_DIR" ]; then
  dest=$(cat ../gf-core/DATA_DIR)
  if [ -n "$dest" ]; then dest="${dest}/lib"; fi
fi
if [ -z "$dest" ]; then
  echo "Unable to determine where to install the RGL. Please do one of the following:"
  echo " - Pass the --dest=... flag to this script"
  echo " - Set the GF_LIB_PATH environment variable"
  echo " - Compile & install GF from the gf-core repository (must be in same directory as gf-rgl)"
  exit 1
fi

# A few more definitions before we get started
src="src"
dist="dist"
gfc="${gf} --batch --gf-lib-path=${src} --quiet"

# Redirect stderr if not verbose
if [ $verbose = false ]; then
  exec 2> /dev/null
fi

# Make directories if not present
mkdir -p "${dist}/prelude"
mkdir -p "${dist}/present"
mkdir -p "${dist}/alltenses"

# Build: prelude
echo "Building [prelude]"
${gfc} --gfo-dir="${dist}"/prelude "${src}"/prelude/*.gf

# Gather all language modules for building
for mod in $modules_langs; do
  for file in "${src}"/*/"${mod}"???.gf; do
    modules="${modules} ${file}"
  done
done
for mod in $modules_api; do
  for file in "${src}"/api/"${mod}"???.gf; do
    modules="${modules} ${file}"
  done
done

# Build: present
echo "Building [present]"
for module in $modules; do
  ${gfc} --no-pmcfg --gfo-dir="${dist}"/present --preproc=mkPresent "${module}"
done

# Build: alltenses
echo "Building [alltenses]"
for module in $modules; do
  ${gfc} --no-pmcfg --gfo-dir="${dist}"/alltenses "${module}"
done

# Copy
echo "Copying to ${dest}"
cp -R "${dist}"/* "${dest}"
