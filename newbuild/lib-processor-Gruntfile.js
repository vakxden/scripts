//example
//  grunt --git_commit=213df8390d77d4ef8fe8071a8bebe784057859e4 --commit_message="Feature #817 Vocabulary assessment drops facet" --branchname=develop --commit_author="Gennadiy Sherstyuk" --commit_date="2015-03-24 09:42:01 +0200" --email="gshe@isd.dp.ua" --commit_url="http://wpp.isd.dp.ua/gitlab/irls/lib-processor/commit/213df8390d77d4ef8fe8071a8bebe784057859e4" --meta_json_file="lib-processor-meta.json" --current_code_dir=/home/jenkins/irls-lib-processor-deploy/213df8390d77d4ef8fe8071a8bebe784057859e4 --current_code_path=/home/jenkins/irls-lib-processor-deploy

/*global module: false*/
module.exports = function(grunt)
{
        'use strict';
        var sources = ['src/*.js','src/DictionaryFiles/*.js', 'test/*.js'],
        pkg = grunt.file.readJSON('package.json');

        grunt.initConfig({
                jshint: {
                        options: {
                                jshintrc: 'ci.jshintrc'
                                },
                        all: sources
                },
                jscs: {
                        all: sources,
                        options: {
                                config: ".jscs.json"
                        }
                },
                rsync: {
                        options: {
                                args: ["--verbose"],
                                exclude: [".git*", "node_modules"],
                                recursive: true
                        },
                        irls_lib_processor_deploy: {
                                options: {
                                        src: './',
                                        dest: '<%= grunt.option("current_code_dir") %>/',
                                        delete: false
                                }
                        }
                }
        });

        grunt.loadNpmTasks('grunt-contrib-jshint');
        grunt.loadNpmTasks('grunt-jscs-checker');
        grunt.loadNpmTasks("grunt-rsync");

        var current_code_path = grunt.option ('current_code_path');
        var git_commit = grunt.option ('git_commit');
        var commit_message = grunt.option ('commit_message');
        var branchname = grunt.option ('branchname');
        var commit_author = grunt.option ('commit_author');
        var commit_date = grunt.option ('commit_date');
        var email = grunt.option ('email');
        var commit_url = grunt.option ('commit_url');
        var meta_json_file = grunt.option ('meta_json_file');
        var current_code_dir = current_code_path+'/'+git_commit;

        grunt.registerTask('rsync_to_current_code_dir', 'sync current snapshot (commit) to current code directory', function(current_code_dir) {
                var fs=require('fs');
                var exists = fs.existsSync(current_code_dir);
                console.log("current code directory is " + current_code_dir);
                grunt.option ('current_code_dir', current_code_dir);
                if(exists){
                        grunt.task.run('rsync:irls_lib_processor_deploy');
                }else{
                        fs.mkdirSync(current_code_dir)
                        grunt.task.run('rsync:irls_lib_processor_deploy');
                }
        });
        grunt.registerTask('current_code_dir_clean', 'clean of old directories', function(current_code_path) {
                var fs=require('fs');
                var path = require("path");
                var rmdir = function(dir) {
                        var list = fs.readdirSync(dir);
                        for(var i = 0; i < list.length; i++) {
                                var filename = path.join(dir, list[i]);
                                var stat = fs.statSync(filename);
                                if(filename == "." || filename == "..") {
                                } else if(stat.isDirectory()) {
                                        rmdir(filename);
                                } else {
                                        fs.unlinkSync(filename);
                                }
                        }
                fs.rmdirSync(dir);
                };
                grunt.option ('current_code_path', current_code_path);
                if(current_code_path){
                        process.chdir(current_code_path);
                }
                var dirContents = fs.readdirSync('.');
                var dirs = [];
                var i;
                if(dirContents){
                        for(i=0; i<dirContents.length; i++){
                                var stats = fs.statSync(dirContents[i]);
                                if(stats.isDirectory()){
                                        dirs.push(stats.mtime.getTime()+'/'+dirContents[i]);
                                }
                        }
                        dirs.sort();
                        for(i=0; i<5; i++){
                                dirs.pop();
                        }
                        for(i=0; i<dirs.length; i++){
                                rmdir(dirs[i].replace(/^\d+\//,''));
                        }
                };
        });

        grunt.registerTask('create_meta', 'Creates meta json file', function() {
                var jsonBody = {
                        "Processor": {
                                commitID: git_commit,
                                commitMessage: commit_message,
                                branchName: branchname,
                                commitAuthor: commit_author,
                                commitDate: commit_date,
                                email: email,
                                commitURL: commit_url
                        }
                };
                var content_meta = JSON.stringify(jsonBody, null, '\t');
                var fs = require('fs');
                fs.writeFileSync(meta_json_file, content_meta);
        });

        grunt.registerTask('verify', ['jshint', 'jscs']);
        grunt.registerTask('default', ['verify', 'create_meta', 'rsync_to_current_code_dir:'+current_code_dir,'current_code_dir_clean:'+current_code_path]);
};
