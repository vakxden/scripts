###
### This job sets default values facets for further deployment
###
ARTIFACTS_DIR=/home/jenkins/irls-reader-artifacts
ARTIFACTS_DIR_STAGE=/home/jenkins/irls-reader-artifacts-stage
if [ -z $TARGET ]; then TARGET=$(echo "$ID" | sed -r 's/^.{8}//g');fi
deploymentPackageId=($(echo $ID))

for i in "${deploymentPackageId[@]}"
do
	if [ "$ENVIRONMENT" == "current" ] || [ "$ENVIRONMENT" == "stage" ]; then
        	BRANCHNAME=$(grep "Product.*:" $ARTIFACTS_DIR/$i/meta.json -A3 | grep "branchName" | awk -F "\"" '{print $4}')
	elif [ "$ENVIRONMENT" == "public" ]; then
        	BRANCHNAME=$(grep "Product.*:" $ARTIFACTS_DIR_STAGE/$i/meta.json -A3 | grep "branchName" | awk -F "\"" '{print $4}')
	fi
        rm -f $WORKSPACE/myenv
        echo "BRANCHNAME=$BRANCHNAME" >> $WORKSPACE/myenv
done
if [ -z $BRANCHNAME ]; then
        printf "[ERROR_BRANCH] unable to determine the branch name \n"
        exit 1
fi
echo TARGET=$TARGET
echo "TARGET=$TARGET" >> $WORKSPACE/myenv
