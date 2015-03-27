//run with next command: "time grunt --reponame=build_re --branchname=develop"

module.exports = function(grunt) {

grunt.initConfig({
    gitclone: {
        clone: {
            options: {
                repository: 'git@wpp.isd.dp.ua:irls/<%= grunt.option("reponame") %>.git',
                branch: '<%= grunt.option("branchname") %>',
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
    rsync: {
        options: {
            args: ["--verbose"],
            exclude: [".git*", "node_modules", "Gruntfile.js", "package.json"],
            recursive: true
        },
        irls-autotests: {
            options: {
                src: '<%= grunt.option("dirname") %>/',
                dest: '~/git/<%= grunt.option("reponame") %>/',
                host: 'jenkins@irls-autotests.design.isd.dp.ua',
                delete: true
            }
        },
        users-mac-mini: {
            options: {
                src: '<%= grunt.option("dirname") %>/',
                dest: '~/git/<%= grunt.option("reponame") %>/',
                host: 'jenkins@users-mac-mini.design.isd.dp.ua',
                delete: true
            }
        },
        yuriys-mac-mini: {
            options: {
                src: '<%= grunt.option("dirname") %>/',
                dest: '~/git/<%= grunt.option("reponame") %>/',
                host: 'jenkins@yuriys-mac-mini.isd.dp.ua',
                delete: true
            }
        },
        dev02: {
            options: {
                src: '<%= grunt.option("dirname") %>/',
                dest: '~/git/<%= grunt.option("reponame") %>/',
                host: 'jenkins@dev02.design.isd.dp.ua',
                delete: true
            }
        }
    }
});


var branchname = grunt.option('branchname');
var reponame = grunt.option('reponame');
var dirname = __dirname+'/'+reponame;

grunt.registerTask('gitTask', 'Git', function(dirname) {
    var fs=require('fs');
    var exists = fs.existsSync(dirname);
    grunt.loadNpmTasks('grunt-git');
    grunt.loadNpmTasks('grunt-rsync');
    grunt.option ('dirname', dirname);
    if(exists){
        process.chdir(dirname);
        grunt.task.run('gitreset', 'gitclean', 'gitfetch', 'gitcheckout', 'rsync');
    }else{
        grunt.task.run('gitclone', 'rsync');
    }
});

grunt.registerTask('default', ['gitTask:' + dirname]);

};
