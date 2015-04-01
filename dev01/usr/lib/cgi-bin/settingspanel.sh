#!/bin/bash

###
### Variables
###

BRANCHES_ARRAY=($(curl http://wpp.isd.dp.ua/irls-reader-artifacts/branches.json | awk -F'"|"' '{print $2}' | grep -v branches))
TARGETS_ARRAY=($(curl http://wpp.isd.dp.ua/irls-reader-artifacts/targets.json | awk -F'"|"' '{print $2}' | grep -v targets))
CURRENT_TARGETS_ARRAY=($(curl http://wpp.isd.dp.ua/irls-reader-artifacts/irls-reader-build.json | grep currentTargetsConverter | awk -F'"|"' '{print $4}'))
PROCESSOR_BRANCHNAMES_ARRAY=($(curl -s http://wpp.isd.dp.ua/irls-reader-artifacts/lib-processor-status.json | grep "branchName" | awk -F '"|"' '{print $4}'))
SOURCES_BRANCHNAMES_ARRAY=($(curl -s http://wpp.isd.dp.ua/irls-reader-artifacts/lib-sources-status.json | grep "branchName" | awk -F '"|"' '{print $4}'))

###
### Functions
###

# (internal) routine to store POST data
function cgi_get_POST_vars()
{
    # check content type
    # FIXME: not sure if we could handle uploads with this..
    [ "${CONTENT_TYPE}" != "application/x-www-form-urlencoded" ] && \
        echo "Warning: you should probably use MIME type "\
             "application/x-www-form-urlencoded!" 1>&2
    # save POST variables (only first time this is called)
    [ -z "$QUERY_STRING_POST" \
      -a "$REQUEST_METHOD" = "POST" -a ! -z "$CONTENT_LENGTH" ] && \
        read -n $CONTENT_LENGTH QUERY_STRING_POST
    return
}

# (internal) routine to decode urlencoded strings
function cgi_decodevar()
{
    [ $# -ne 1 ] && return
    local v t h
    # replace all + with whitespace and append %%
    t="${1//+/ }%%"
    while [ ${#t} -gt 0 -a "${t}" != "%" ]; do
        v="${v}${t%%\%*}" # digest up to the first %
        t="${t#*%}"       # remove digested part
        # decode if there is anything to decode and if not at end of string
        if [ ${#t} -gt 0 -a "${t}" != "%" ]; then
            h=${t:0:2} # save first two chars
            t="${t:2}" # remove these
            v="${v}"`echo -e \\\\x${h}` # convert hex to special char
        fi
    done
    # return decoded string
    echo "${v}"
    return
}

# routine to get variables from http requests
# usage: cgi_getvars method varname1 [.. varnameN]
# method is either GET or POST or BOTH
# the magic varible name ALL gets everything
function cgi_getvars()
{
    [ $# -lt 2 ] && return
    local q p k v s
    # get query
    case $1 in
        GET)
            [ ! -z "${QUERY_STRING}" ] && q="${QUERY_STRING}&"
            ;;
        POST)
            cgi_get_POST_vars
            [ ! -z "${QUERY_STRING_POST}" ] && q="${QUERY_STRING_POST}&"
            ;;
        BOTH)
            [ ! -z "${QUERY_STRING}" ] && q="${QUERY_STRING}&"
            cgi_get_POST_vars
            [ ! -z "${QUERY_STRING_POST}" ] && q="${q}${QUERY_STRING_POST}&"
            ;;
    esac
    shift
    s=" $* "
    # parse the query data
    while [ ! -z "$q" ]; do
        p="${q%%&*}"  # get first part of query string
        k="${p%%=*}"  # get the key (variable name) from it
        v="${p#*=}"   # get the value from it
        q="${q#$p&*}" # strip first part from query string
        # decode and evaluate var if requested
        [ "$1" = "ALL" -o "${s/ $k /}" != "$s" ] && \
            eval "$k=\"`cgi_decodevar \"$v\"`\""
    done
    return
}

echo "Content-type: text/html"
echo ""
echo '<html>'
echo '<head>'
echo '<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">'
echo '<title>Settings Panel</title>'
echo '<body>'

echo '<h3><b>Settings for jenkins irls-reader-build job:</b></span></h3>'
echo '<span>Link to build job: </span>'
echo '<span id="DeployJob" class="text-danger"><b><a href="http://wpp.isd.dp.ua/jenkins/job/irls-reader-build/">irls-reader-build job</a></b></span>'
echo '<br>'
echo '<br>'
# form of Deploy
echo '<form action="'${SCRIPT}'" method=POST>'
echo '<span>Select branch:</span>'
echo '<select name="deploybranch">'
echo '<option value="" disabled="disabled" selected="selected">Please select a branch name</option>'
for i in ${BRANCHES_ARRAY[@]}
do
        echo '<option value="'$i'">'$i'</option>'
done
echo '</select>'
echo '<br>'
echo '<span>Select target:</span>'
for y in ${TARGETS_ARRAY[@]}
do
        echo '<input type="checkbox" name="deploytarget" value="'$y'"/>'$y'</label>'
done
echo '<br><input type="submit" value="Deploy"></form>'

echo '<hr align="left" width="400" size="3" color="#0000dd" />'
# register all GET and POST variables
cgi_getvars BOTH ALL
# Processing of parameters, run of "irls-reader-build" job
if [ ! -z "$QUERY_STRING_POST" ]; then
        DEPLOY_BRANCH=$(echo $QUERY_STRING_POST | sed -n 's#^.*deploybranch=\([^&]*\).*$#\1#p' | sed 's#%20# #g' | sed 's#%2F#/#g')
        declare -a DEPLOY_TARGET
        DEPLOY_TARGET=($(echo $QUERY_STRING_POST |  grep -oE "(^|[?&])deploytarget=[0-9a-z_-]++" |  cut -f 2 -d "="))
        if [ ! -z $DEPLOY_BRANCH ] && [ ! -z $DEPLOY_TARGET ]; then
                curl http://wpp.isd.dp.ua/jenkins/job/irls-reader-build/buildWithParameters?token=Sheedah8\&TARGET=$(echo ${DEPLOY_TARGET[@]} | sed 's@ @%20@g')\&BRANCHNAME=$DEPLOY_BRANCH\&STARTED_BY=Settings%20Panel
                echo '<p>'
                echo 'Processing of deploy parameters:'
                echo '<br>'
                echo '"irls-reader-build" job running with next parameters: BRANCHNAME is <b>'$DEPLOY_BRANCH'</b> and TARGET is <b>'$(echo ${DEPLOY_TARGET[@]})'</b>'
                echo '<hr align="left" width="400" size="3" color="#0000dd" />'
                echo '</p>'
                echo '<script>window.setTimeout(function(){document.location.href = document.location.href;}, 3000);</script>'
        fi
fi
# form of Convert
echo '<h3><b>Settings for jenkins lib-convert:</b></span></h3>'
echo '<span>Link to build job: </span>'
echo '<span id="ConvertJob" class="text-danger"><b><a href="http://wpp.isd.dp.ua/jenkins/job/lib-build/">lib-build job</a></b></span>'
echo '<br>'
echo 'Default target is <b>test-target</b>'
echo '<br>'
echo '<br>'
echo '<form action="'${SCRIPT}'" method=POST>'
echo '<span>Select <b>lib-processor</b> branch:</span>'
echo '<select name="processor_branchname">'
#echo '<option value="" disabled="disabled" selected="selected">Please select a branch name</option>'
echo '<option value="" disabled="disabled" selected="selected">develop</option>'
for j in ${PROCESSOR_BRANCHNAMES_ARRAY[@]}
do
        echo '<option value="'$j'">'$j'</option>'
done
echo '</select>'
echo '<br>'
echo '<span>Select <b>lib-sources</b> branch:</span>'
echo '<select name="sources_branchname">'
#echo '<option value="" disabled="disabled" selected="selected">Please select a branch name</option>'
echo '<option value="" disabled="disabled" selected="selected">master</option>'
for k in ${SOURCES_BRANCHNAMES_ARRAY[@]}
do
        echo '<option value="'$k'">'$k'</option>'
done
echo '</select>'
echo '<br>'
echo '<span>Select target (one only):</span>'
for z in ${TARGETS_ARRAY[@]}
do
        echo '<input type="radio" name="converttarget" value="'$z'" checked="test-target"/>'$z'</label>'
done
echo '<br><input type="submit" value="Convert"></form>'
echo '<hr align="left" width="400" size="3" color="#0000dd" />'
# register all GET and POST variables
cgi_getvars BOTH ALL
# Processing of parameters, run of "irls-rrm-processor-convert" job
if [ ! -z "$QUERY_STRING_POST" ]; then
        TARGET=$(echo $QUERY_STRING_POST |  grep -oE "(^|[?&])converttarget=[0-9a-z_-]++" |  cut -f 2 -d "=")
        PROCESSOR_BRANCHNAME=($(echo $QUERY_STRING_POST |  grep -oE "(^|[?&])processor_branchname=[0-9a-z_-]++" |  cut -f 2 -d "="))
        SOURCES_BRANCHNAME=($(echo $QUERY_STRING_POST |  grep -oE "(^|[?&])sources_branchname=[0-9a-z_-]++" |  cut -f 2 -d "="))
        STARTED_BY="Settings Panel"
        if [ ! -z $TARGET ]; then
                curl -d SOURCES_BRANCHNAME="$SOURCES_BRANCHNAME" \
                -d PROCESSOR_BRANCHNAME="$PROCESSOR_BRANCHNAME" \
                -d TARGET="$TARGET" \
                -d STARTED_BY="$STARTED_BY" \
                http://wpp.isd.dp.ua/jenkins/job/lib-build/buildWithParameters\?token=Sheedah8
                echo '<p>'
                echo 'Processing of convert parameters:'
                echo '<br>'
                echo '"lib-convert" job will running with next parameters: target is <b>'$TARGET'</b>,<br>processor branchname is <b>'$PROCESSOR_BRANCHNAME'</b>,<br> sources branchname is <b>'$SOURCES_BRANCHNAME'</b>'
                echo '<hr align="left" width="400" size="3" color="#0000dd" />'
                echo '</p>'
                echo '<script>window.setTimeout(function(){document.location.href = document.location.href;}, 3000);</script>'
        fi
fi

echo '</body>'
echo '</html>'

exit 0
