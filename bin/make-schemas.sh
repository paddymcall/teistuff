#!/usr/bin/env bash

set -e

BINDIR=$(dirname ${0})
CURRDIR=`pwd`
TEISTUFF=$(realpath "${BINDIR}/../")
TEI_STYLESHEETS=${TEISTUFF}/Stylesheets
TEI_P5=${TEISTUFF}/TEI/P5
TEI_P5_SUBSET="${TEI_P5}/p5subset.xml"
SCHEMADIR="./schemas/"

CALLEDFORDIR=NO
TMPDIR=""
CONTAINERDIR=NO
IGNOREGIT=NO

if [ -z ${JAVA_HOME} ] && [ ! -z ${GUIX_ENVIRONMENT} ]; then
    echo "Setting JAVA_HOME to ${GUIX_ENVIRONMENT}"
    JAVA_HOME=${GUIX_ENVIRONMENT}
    export JAVA_HOME
fi

show_help () {
    echo "Usage: make-schemas.sh [options] TEI-XML-file"
    echo "Options:"
    echo "-h|--help: show this help"
    echo "-i|--ignore-git-status: ignore current git status (might overwrite things that haven't been saved!) "
    echo "--schema-dir=DIR: Where to put generated schemas"
    echo ""
    echo "This command creates an RNC schema for a specified TEI XML file."
    echo "An odd will be generated and saved in ./schemas/, unless it's already there."
    echo "From that ODD, an RNC file will be created in the same location."
    echo "Your config is this:"
    echo "TEISTUFF=${TEISTUFF}"
    echo "TEI_STYLESHEETS=${TEI_STYLESHEETS}"
    echo "TEI_P5=${TEI_P5}"
    echo "TEI_P5_SUBSET=${TEI_P5_SUBSET}"
}



for i in "$@"
do
case $i in
    -h|--help)
        show_help
        exit 0
        shift
        ;;
    -i|--ignore-git-status)
        IGNOREGIT=YES
        shift
        ;;
    --schema-dir=*)
        SCHEMADIR=$(echo $1 | sed 's/.*=//')
        shift
        ;;
    *)
        break
        # unknown option
    ;;
esac
done

FILE="$1"

# Use Bash Parameter expansion
# (https://stackoverflow.com/questions/3963716/how-to-manually-expand-a-special-variable-ex-tilde-in-bash/27485157#27485157)
SCHEMADIR=$(realpath "${SCHEMADIR/#\~/$HOME}")

echo "Expecting schemas in ${SCHEMADIR}"

if [ ! -d "${SCHEMADIR}" ]; then
    echo "Creating ${SCHEMADIR}"
    mkdir "${SCHEMADIR}"
fi

if output=$(git status --porcelain) && [ -z "$output" ]; then
    echo "Repo clean, will proceed"
elif [ ${IGNOREGIT} == "YES" ]; then
    echo "Your git repo is not clean, but I'll continue anyway"
else
    echo "Please clean up your repo (git commit -a) before running this script"
    exit 1
fi

if [ -z ${FILE} ]; then
    echo "You have to tell me which file or directory to work on"
    exit 1
elif [ -d ${FILE} ]; then
    echo "Working on directory: ${FILE}"
    CALLEDFORDIR=YES
elif [ ! -f ${FILE} ]; then
    echo "Can't read file: ${FILE}, treating as dummy file."
else
    echo "Working on ${FILE}"
fi

if [ ${CALLEDFORDIR} == "NO" ]; then
    TARGETODD="${SCHEMADIR}/$(basename ${FILE} xml)odd"
    TARGETSCHEMA="${SCHEMADIR}/$(basename ${FILE} xml)rng"
else
    TARGETODD="${SCHEMADIR}/schema.odd"
    TARGETSCHEMA="${SCHEMADIR}/schema.rng"
fi

TARGETSCHEMARNC="$(dirname ${TARGETSCHEMA})"/"$(basename -s rng ${TARGETSCHEMA})""rnc"

echo "Going for ${TARGETODD} and then ${TARGETSCHEMA}"

if [ ${CALLEDFORDIR} == "NO" ] && [ ! -f "${TARGETODD}" ]; then
    TMPDIR=`mktemp -d`
    cp ${FILE} ${TMPDIR}
    echo "Copied ${FILE} to ${TMPDIR} so the ODD stuff will work."
    FILE=${TMPDIR}/`basename ${FILE}`    
    CONTAINERDIR=${TMPDIR}
else
    CONTAINERDIR=$(dirname ${FILE})
fi

echo "Targeting ${FILE} in <${CONTAINERDIR}>"

# This script will only have a chance of working if we have a “built”
# TEI P5 distro.  To get that, do:


if [ ! -f "${TEI_P5_SUBSET}"  ]; then
    echo "You have to provide ${TEI_P5_SUBSET}"
    echo "Probably this will work:"
    echo "mkdir ${TEI_P5} cd ${TEI_P5} && make clean && XSL=$TEI_STYLESHEETS make -e p5.xml"
    echo "Shall I run that?"
    select yn in "Yes" "No"; do
        case $yn in
            Yes ) mkdir -p "${TEI_P5}" && \
			cd "${TEI_P5}" && \
			make clean && \
			XSL="${TEI_STYLESHEETS}" make -e p5.xml && \
			cd -; break;;
            No ) exit 1;;
        esac
    done

    # cd $TEI_P5 && \
    #     XSL=$TEI_STYLESHEETS make -e clean && \
    #     XSL=$TEI_STYLESHEETS make -e
else
    echo "Using ${TEI_P5_SUBSET}"
fi

# do we have an odd?
if [ ! -f "${TARGETODD}" ] ; then
    echo "${TARGETODD} not found, creating with oddbyexample"
    java -jar ${TEI_STYLESHEETS}/lib/saxon10he.jar \
	 -xsl:${TEI_STYLESHEETS}/tools/oddbyexample.xsl \
	 -it:main \
	 -xi:on \
	 corpus="${CONTAINERDIR}" \
	 enumerateRend=true \
	 defaultSource=$(realpath -e "${TEI_P5_SUBSET}") > "${TARGETODD}"
	 # verbose=true
else
    echo "Using existing ${TARGETODD}"
fi

# and the rnc?

echo "Producing RNG" && \
    "${TEI_STYLESHEETS}"/bin/oddtorng \
         --localsource=$(realpath -e "${TEI_P5_SUBSET}") \
         --odd \
         "${TARGETODD}" \
         "${TARGETSCHEMA}"

echo "Producing RNC (from rng)" && \
    java -jar  "${TEI_P5}/Utilities/lib/trang.jar" "${TARGETSCHEMA}" "${TARGETSCHEMARNC}"

# do an evaluation
if [ -f ${FILE} ] ; then
    echo "Evaluating ${FILE} against ${TARGETSCHEMARNC} (silence=ok)" && \
	java -jar  "${TEI_P5}/Utilities/lib/jing.jar" -c "${TARGETSCHEMARNC}" "${FILE}" ||\
	    echo "${FILE} is invalid according to ${TARGETSCHEMARNC}!"
else
    echo "Not validating for dummy file"
fi

rm -rf "${TMPDIR}"


