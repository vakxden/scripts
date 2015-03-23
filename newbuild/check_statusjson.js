
console.log("this script received argument #1 (reponame) - " + process.argv[2]);
console.log("this script received argument #2 (branch) - " + process.argv[3]);
console.log("this script received argument #3 (git commit hash) - " + process.argv[4]);

var jsonBody = {
	"libprocessor" : [
		{"branchName":"master",
		"commitID":"e4c4bcec74b5dd90aaeb34d8d7b6ddb84784d53e"
		},
		{"branchName":"develop",
		"commitID":"3102ecd92cd5579dbef6704d68e477dcffe6eff6"
		},
		{"branchName":"feature/conversion_result_caching",
		"commitID":"b34e62abe823426397890b12441b6c11d20d5c8d"
		}
	],
	"libsources" : [
		{"branchName":"master",
		"commitID":"c04a22a91161f6514faa5eb2681de7d90c167009"
		}
	]
};

fs = require('fs');
var jsonFileName = "status.json";
var exists = fs.existsSync(jsonFileName);
if(exists){
	console.log("file " + jsonFileName + " exists");
	var obj = JSON.parse(fs.readFileSync(jsonFileName, 'utf8'));
	reponame = process.argv[2];
	console.log("reponame is " + reponame);
	console.log(obj[reponame]);
	for (var i = 0, total = obj[reponame].length; i < total; i++) {
		console.log(obj[reponame][i].branchName);
		console.log(obj[reponame][i].commitID);
	};
}
else{
	content_status = JSON.stringify(jsonBody, null, '\t');
	fs.writeFile(jsonFileName, content_status, function (err) {
		if (err) return console.log(err);
	});
}
