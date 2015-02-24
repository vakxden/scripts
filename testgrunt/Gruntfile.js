//run with next command: "time grunt --reponame=test_for_grunt --branchname=develop"

module.exports = function(grunt) {

grunt.initConfig({
    gitclone: {
        clone: {
            options: {
                repository: 'git@wpp.isd.dp.ua:irls/<%= grunt.option("reponame") %>.git',
                branch: '<%= grunt.option("branchname") %>',
                directory: '<%= grunt.option("dirname") %>'
            }
        }
    },
    gitreset: {
        with_hard_option: {
            options: {
                mode: 'hard'
            }
        }
    },
    gitclean: {
        with_fdx_options: {
            options: {
                force: true,
                directories: true,
                nonstandard: true
            }
        }
    },
    gitfetch: {
        with_all_option: {
            options: {
                all: true
            }
        }
    },
    gitcheckout: {
        task: {
            options: {
                branch: 'remotes/origin/<%= grunt.option("branchname") %>'
            }
        }
    },
});


var branchname = grunt.option('branchname');
console.log("received branchname is " + branchname);
var reponame = grunt.option('reponame');
console.log("received reponame is " + reponame);
var dirname = './'+reponame;
console.log("dirname is " + dirname);

grunt.registerTask('gitTask', 'Git', function(dirname) {
    console.log("function dirname is " + dirname);
    var fs=require('fs');
    var exists = fs.existsSync(dirname);
    grunt.loadNpmTasks('grunt-git');
    if(exists){
        console.log('yes');
        process.chdir(dirname);
        grunt.task.run('gitreset', 'gitclean', 'gitfetch','gitcheckout');
    }else{
        console.log("no");
        grunt.task.run('gitclone');
    }
});

grunt.registerTask('default', ['gitTask:' + dirname]);

};
