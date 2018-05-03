(function(module) {
    'use strict';

    var _ = module._,
        App = module.App,
        fetch = module.fetch,

        shaders = [
            'main.vert',
            'main.frag'
        ],
        snippets = [
            // 'random',
            // 'noise',
            // 'matrix-transform',
            // 'wrap',
            'constants',
            'functions',
            'trigonometry',
            'distance',
            'ray'
        ];

    Promise.all(_.map(shaders.concat(snippets), function(shader) {
            return fetch('./shaders/'+shader+'.glsl');
        }))
        .then(function(responses) {
                function extract(shader) {
                    var shaderDeps = [];

                    shader.replace(/\@requires\s*([^\s\*\@\,]*)/gi,
                        function(all, require) {
                            if(!_.contains(shaderDeps, require)) {
                                shaderDeps.push(require);
                            }
                        });

                    return shaderDeps;
                }

                function insert(sorted, shaderKey, shaderDeps) {
                    // Check if any of the shader deps are already
                    // included; if they are, we want to insert the
                    // shader before that point.
                    // If that point is before another shader/partial
                    // that depends on this shader, then we have a
                    // circular dependency (this could be even more
                    // complex).
                    var i = ((sorted.length > 0)?
                                // _.findIndex(sorted,
                                _.findLastIndex(sorted,
                                    function(require) {
                                        return _.contains(shaderDeps, require);
                                    })
                            :   0);

                    return i;
                }

                // Resolve all the dependencies in the shaders, starting at the
                // `main` shaders, and sorting any `@require`d files to be
                // prepended to the files that depend on them.
                var mains = _.zipObject(shaders, responses.slice(0, 2)),
                    deps = _.zipObject(snippets, responses.slice(2)),
                    lib = _.extend({}, mains, deps);

                return _.map(mains, function(main, m) {
                        var included = [m];

                        for(var r = 0; r < included.length; ++r) {
                            var key = included[r],
                                shaderDeps = extract(lib[key]),
                                i = insert(included, key, shaderDeps);

                            // Move the shader before any of its existing deps.
                            if(i >= 0 && i < r) {
                                included.splice(i, 0, included.splice(r, 1)[0]);
                            }

                            // Don't duplicate any existing deps.
                            _.pull.apply(_, [shaderDeps].concat(included));

                            included.push.apply(included, shaderDeps);
                        }

                        return _.at(lib, included.reverse())
                                .join('\n\n\n\n//========================\n\n');
                    });
            },
            function(rejection) {
                alert('Couldn\'t load the shaders, because... '+rejection);
            })
        .then(function(shader) {
            module.app = new App(document.getElementById('viewport'), {
                        vertex: shader[0],
                        fragment: shader[1]
                    });
        });
})(module);
