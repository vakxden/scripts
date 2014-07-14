###
### This job sets default values facets for further deployment
###
ARTIFACTS_DIR=/home/jenkins/irls-reader-artifacts
deploymentPackageId=($(echo $ID))
for i in "${deploymentPackageId[@]}"
do
	BRANCHNAME=$(grep "reader.*:" $ARTIFACTS_DIR/$i/meta.json -A3 | grep "branchName" | awk -F "\"" '{print $4}')
	rm -f $WORKSPACE/myenv
	echo "BRANCHNAME=$BRANCHNAME" >> $WORKSPACE/myenv
done
if [ -z $BRANCHNAME ]; then
printf "[ERROR_BRANCH] unable to determine the branch name \n"
exit 1
fi
