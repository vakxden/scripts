module.exports = function(grunt) {

    grunt.initConfig({
        http: {
            get_targets_file: {
                options: {
                    url: 'http://wpp.isd.dp.ua/irls-reader-artifacts/targets.json',
                },
            dest: 'targets.json'
            }
        }
    });

    grunt.loadNpmTasks('grunt-http');

    grunt.registerTask('read_targets_file', 'read targets from targets.json', function() {
        var targetslistJSON = grunt.file.readJSON('targets.json');
        for (var i = 0, total = targetslistJSON.targets.length; i < total; i++) {
            var target = targetslistJSON.targets[i];
            if (target.branch) {
                console.log('target is ' + target.target_name +' branch is ' + target.branch);
            }
        }
    });

    grunt.registerTask('default', [ 'http', 'read_targets_file']);

};
