###
### Variables
###

COJ="/var/lib/jenkins/jobs/irls-reader-build/config.xml" # Path to the configuration file of jenkins job
JSON_FILE="/home/jenkins/irls-reader-artifacts/irls-reader-build.json"
LIST_OF_ALL_TARGETS=("autotest" "chapters" "farsiref_ffa" "ffa" "ffa-master" "irls-audio" "irls-audiobywords" "irls-epubtest" "irls-ocean" "mediaoverlay_ffa" "nbproject" "ocean" "ocean-master" "test-target")


#generating of json-file
if grep "currentTargetsConverter" $JSON_FILE; then
        CGC=$(grep "currentTargetsConverter" $JSON_FILE) ### preserve "currentTargetsConverter"
        echo "CGC=$CGC"
fi
LAST_BRANCH_READER=$(grep lastReaderBranchCommit $JSON_FILE | awk -F'["|"]' '{print $4}')
sudo chown jenkins:git $JSON_FILE
sudo chmod 664 $JSON_FILE
cat /dev/null > $JSON_FILE
VJF_CURRENT_BRANCH=$(grep -n -A1 "<hudson.plugins.git.BranchSpec>" $COJ | grep name | awk -F"[<>]" '{print $3}') #variable for json-file
VJF_CURRENT_TARGET_ALL=$(grep -A5 -n 'if.*BRANCHNAME.*develop' $COJ | grep -A2 else | grep -v "#TARGET" | grep "TARGET=" | awk -F"[()]" '{print $2}')
VJF_CURRENT_TARGET_DEVELOP=$(grep -A2 -n 'if.*BRANCHNAME.*develop' $COJ | grep -v "#TARGET" | grep "TARGET=" | awk -F"[()]" '{print $2}')
echo -e "{" >> $JSON_FILE
if [ "$VJF_CURRENT_BRANCH" == "**" ]; then
        echo -e "\t\"currentBranch\":  \"all\"," >> $JSON_FILE
else
        echo -e "\t\"currentBranch\":  \""$VJF_CURRENT_BRANCH"\"," >> $JSON_FILE
fi
echo -e "\t\"currentTargetsNotDevelop\": \""$VJF_CURRENT_TARGET_ALL"\"," >> $JSON_FILE
echo -e "\t\"listOfAllTargets\": \""${LIST_OF_ALL_TARGETS[@]}"\"," >> $JSON_FILE
echo -e "\t\"lastReaderBranchCommit\": \""$LAST_BRANCH_READER"\"," >> $JSON_FILE
echo -e "$CGC" >> $JSON_FILE
echo -e "\t\"currentTargetsDevelop\": \""$VJF_CURRENT_TARGET_DEVELOP"\"" >> $JSON_FILE
echo -e "}" >> $JSON_FILE
