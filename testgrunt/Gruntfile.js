
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

grunt.registerTask('gitTask', 'Git', function() {   
    var fs=require('fs');
    var exists = fs.existsSync('./build_re');
        grunt.loadNpmTasks('grunt-git');
        if(exists){
            console.log('yes');
            grunt.task.run('gitcheckout');
        }else{
            console.log("no");
            grunt.task.run('gitclone', 'gitcheckout');
        }
});

grunt.registerTask('default', ['gitTask']);

};
