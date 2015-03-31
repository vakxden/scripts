// example
// grunt --git_commit=$SOURCES_HASHCOMMIT --commit_message="$COMMIT_MESSAGE" --branchname="$SOURCES_BRANCHNAME" --commit_author="$COMMIT_AUTHOR" --commit_date="$COMMIT_DATE" --email="$EMAIL" --commit_url="$COMMIT_URL" --meta_json_file=$SOURCES_META --current_code_path=$CURRENT_CODE_PATH

/*global module: false*/
module.exports = function(grunt)
{
        'use strict';
        var sources = ['src/*.js','src/DictionaryFiles/*.js', 'test/*.js'],
        pkg = grunt.file.readJSON('package.json');

        grunt.initConfig({
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

        grunt.registerTask('default', ['create_meta', 'rsync_to_current_code_dir:'+current_code_dir,'current_code_dir_clean:'+current_code_path]);
};
