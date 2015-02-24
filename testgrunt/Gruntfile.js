// this running with next command: " grunt --reponame=test_for_grunt gitTask:./test_for_grunt"

module.exports = function(grunt) {

grunt.initConfig({
    gitclone: {
        clone: {
            options: {
                repository: 'git@wpp.isd.dp.ua:irls/<%= grunt.option("reponame") %>',
                branch: 'develop',
                directory: '<%= grunt.option("directory") %>'
            }
        }
    },
    gitcheckout: {
        task: {
            options: {
                branch: 'develop',
                cwd: '<%= grunt.option("directory") %>'
            }
        }
    },
});


grunt.registerTask('gitTask', 'Git', function(directory) {
    var fs=require('fs');
    var exists = fs.existsSync(directory);
    console.log(directory);
    grunt.option('directory', directory);
    var reponame = grunt.option('reponame');
    console.log(reponame);
    grunt.loadNpmTasks('grunt-git');
    if(exists){
        console.log('yes');
        grunt.task.run('gitcheckout');
    }else{
        console.log("no");
        grunt.task.run('gitclone', 'gitcheckout');
    }
});

//var directory = './build_re';
grunt.registerTask('default', ['gitTask']);

};

