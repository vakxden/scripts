var target_name = 'ffa';
var product_build_id = 'e99a6a9_ffa';
var build_number = 5478;
var build_url = 'http://wpp.isd.dp.ua/jenkins/job/irls-reader-build-replica/68/';
var commit_date = "2015-03-12 10:17:53 +0200";
var rrm_processor_commitID = "8fff0140ad5a49cf5519d5d0ea0aa0109212b36b";
var rrm_processor_commitMessage = "BLABLABLA";
var rrm_processor_branch = "develop";
var rrm_processor_commitAuthor = "Tro Lolo";
var rrm_processor_commitDate = "2015-03-12 13:56:02 +0200";
var rrm_processor_email = "trololo@isd.dp.ua";
var rrm_processor_commitURL = "http://wpp.isd.dp.ua/gitlab/irls/lib-processor/commit/8fff0140ad5a49cf5519d5d0ea0aa0109212b36b";
var rrm_ocean_commitID = "08bbd134795697a486f9ea407407d99ba0cd6eb3";
var rrm_ocean_commitMessage = "OLOLOLOLO";
var rrm_ocean_branch = "master";
var rrm_ocean_commitAuthor = "Lolo Tro";
var rrm_ocean_commitDate = "2015-02-20 13:48:16 +0200";
var rrm_ocean_email = "ololo@isd.dp.ua";
var rrm_ocean_commitURL = "http://wpp.isd.dp.ua/gitlab/irls/lib-processor/commit/8fff0140ad5a49cf5519d5d0ea0aa0109212b36b";
var rrm_reader_commitID = "f0a1a82f65f64afad6fe60b80706e14cd5748c89";
var rrm_reader_commitMessage = "Merge branch 'develop' of wpp.isd.dp.ua:irls/product into develop";
var rrm_reader_branch = "develop";
var rrm_reader_commitAuthor = "Gena Sherstyuk";
var rrm_reader_commitDate = "2015-03-19 11:39:29 +0200";
var rrm_reader_email = "gshe@isd.dp.ua";
var rrm_reader_commitURL = "http://wpp.isd.dp.ua/gitlab/product/commit/f0a1a82f65f64afad6fe60b80706e14cd5748c89";
var jsonBody = {
	buildID: product_build_id,
	buildNumber: build_number,
	targetName: target_name,
	buildURL: build_url,
	commitDate: commit_date,
	"rrm-processor": {
		commitID: rrm_processor_commitID,
		commitMessage: rrm_processor_commitMessage,
		branchName: rrm_processor_branch,
                commitAuthor: rrm_processor_commitAuthor,
                commitDate: rrm_processor_commitDate,
                email: rrm_processor_email,
                commitURL: rrm_processor_commitURL
	},
        "rrm-ocean" : {
                commitID: rrm_ocean_commitID,
                commitMessage: rrm_ocean_commitMessage,
                branchName: rrm_ocean_branch,
                commitAuthor: rrm_ocean_commitAuthor,
                commitDate: rrm_ocean_commitDate,
                email: rrm_ocean_email,
                commitURL: rrm_ocean_commitURL
        },
        "reader" : {
                commitID: rrm_reader_commitID,
                commitMessage: rrm_reader_commitMessage,
                branchName: rrm_reader_branch,
                commitAuthor: rrm_reader_commitAuthor,
                commitDate: rrm_reader_commitDate,
                email: rrm_reader_email,
                commitURL: rrm_reader_commitURL
        }
};
content_meta = JSON.stringify(jsonBody, null, '\t');
console.log(content_meta);
fs = require('fs');
fs.writeFile('meta.json', content_meta, function (err) {
  if (err) return console.log(err);
});
