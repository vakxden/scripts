#!/bin/bash

echo "Content-type: text/html"
echo ""
echo '<html>'
echo '<head>'
echo '<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">'
echo '<title>Settings Panel</title>'
echo '<body>'

echo '<h3><b>Settings for jenkins irls-reader-build job:</b></span></h3>'
echo '</div>'
echo '<b><h4>Current settings:</h4></b>'
echo '<div>'
echo '<span>Link to build job: </span>'
echo '<span id="currentBranch" class="text-danger"><b><a href="http://wpp.isd.dp.ua/jenkins/job/irls-reader-build/">irls-reader-build job</a></b></span>'
echo '</div>'



echo "<form method=GET action=\"${SCRIPT}\">"
echo '<tr>'
    echo '<td>'
        echo '<table id="qqq">'
            echo '<tr>'
                echo '<td>'
                    echo '<span>Select branch:</span>'
                echo '</td>'
                echo '<td>'
                    BRANCHES_ARRAY=($(curl http://wpp.isd.dp.ua/irls-reader-artifacts/branches.json | awk -F'"|"' '{print $2}' | grep -v branches))
                    echo '<select>'
                    echo '<option value="" disabled="disabled" selected="selected">Please select a name</option>'
                    for i in ${BRANCHES_ARRAY[@]}
                    do
                        echo '<option name="deploybranch" value="'$i'">'$i'</option>'
                    done
                    echo '</select>'
                    echo '</div>'
                    echo '</form>'
                echo '</td>'
            echo '</tr>'
        echo '</table>'
    echo '</td>'
    echo '<td>'
        echo '<table id="qqq2">'
            echo '<tr>'
                echo '<td>'
                    echo '<span>Select target:</span>'
                echo '</td>'
                echo '<td>'
                    TARGETS_ARRAY=($(curl http://wpp.isd.dp.ua/irls-reader-artifacts/targets.json | awk -F'"|"' '{print $2}' | grep -v targets))
                    for y in ${TARGETS_ARRAY[@]}
                    do
                        echo '<input type="checkbox" class="radio" name="deploytarget" />'$y'</label>'
                    done
                echo '</td>'
            echo '</tr>'
        echo '</table>'
    echo '</td>'
    echo '</td>'
echo '</tr>'
echo '<br><input type="submit" value="Deploy"></form>'
echo '<br>'
 # If no search arguments, exit gracefully now.
  if [ -z "$QUERY_STRING" ]; then
        echo "QUERY_STRING is null!!!"
        exit 0
  else
     # No looping this time, just extract the data you are looking for with sed:
     echo "QUERY_STRING is $QUERY_STRING"
     XX=`echo "$QUERY_STRING" | sed -n 's/^.*deploybranch=\([^&]*\).*$/\1/p' | sed "s/%20/ /g"`
     YY=`echo "$QUERY_STRING" | sed -n 's/^.*deploytarget=\([^&]*\).*$/\1/p' | sed "s/%20/ /g"`
     echo '<br>'
     echo "deploybranch: " $XX
     echo '<br>'
     echo "deploytarget: " $YY
  fi



echo '</body>'
echo '</html>'

exit 0

