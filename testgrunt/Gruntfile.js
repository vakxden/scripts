
module.exports = function(grunt) {

grunt.initConfig({
    gitclone: {
        clone: {
            options: {
                repository: 'git@wpp.isd.dp.ua:irls/build_re.git',
                branch: 'develop',
                directory: 'build_re'
            }
        }
    },
    gitcheckout: {
        task: {
            options: {
                branch: 'remotes/origin/develop',
                create: true,
		cwd: "./build_re"
            }
        }
    },
});


var fs=require('fs');
fs.exists('./build_re',function(exists){
    if(exists){
        console.log('yes');
	// Default task(s).
	grunt.loadNpmTasks('grunt-git');
	grunt.registerTask('default', ['gitcheckout']);
    }else{
        console.log("no");
	// Default task(s).
	grunt.loadNpmTasks('grunt-git');
	grunt.registerTask('default', ['gitclone', 'gitcheckout']);
    }
});

};
