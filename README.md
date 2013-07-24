=======
lsc-web
=======

This is a brief proposal for the source directory structure for web components in LALSuite. It relies on [Grunt](http://gruntjs.com/) and [RequireJS](http://requirejs.org/) for managing the build process. Code may be written in either JavaScript or [CoffeeScript](http://coffeescript.org).

Installation
------------
Grunt and CoffeeScript both rely on [node.js](http://nodejs.org/) to provide a server-side JavaScript implementation. This allows for scripting the build process in JavaScript itself. Installation of node.js is relatively simple and is outlined at [http://nodejs.org/](http://nodejs.org/). node.js *only* needs to be installed on your local development machine (i.e. not on the grid). The node.js package manager ([npm](https://npmjs.org/)) is automatically included.

To install **Grunt**

1. Run `npm install -g grunt-cli`, which will install the Grunt command-line tools globally. If node.js has been installed in a non-standard directory, make sure that you find the Grunt `bin` directory and add it to `$PATH`.

To install **CoffeeScript**

1. Run `npm install -g coffee-script`

To install **lsc-web**

1. Clone into the GitHub repo.
2. Run `npm install` inside of `lsc-web/`

Example Build Process
---------------------
To do a full build, just run `grunt` or `grunt --debug` inside of `lsc-web/`.
To rebuild one packaged JavaScript module, run `grunt jsModule:MODULE_NAME`. In this demo repo, try `grunt jsModule:triggers`.

Directory Structure
-------------------

* `deploy/` contains the deployable web application that can be pointed to by the server. It has `js/`, `css/`, and `html/` subfolders.
* `build/` is used internally by the build process to create packaged files.
* `lib/{js,css,html}/` contains external JS/CSS/HTML library files that are automatically copied to `deploy/{js,css,html}/`.
* `src/{js,css,html}/` contains LSC web source files, split up by content type. CoffeeScript files can be freely intermingled with native JavaScript files inside of `src/js/`.

JavaScript Modules and Dependency Analysis
------------------------------------------
In order to support modular JS development, we use [RequireJS](http://requirejs.org/). RequireJS also allows us to produce one, minified `.js` file containing many separate modules. At the start of *every* JavaScript file, there should be the following
```JavaScript
define(['IMPORT1', 'PACKAGE1/IMPORT2'], function(import1, import2) {
```
Likewise, every CoffeeScript file should begin with
```CoffeeScript
define ['IMPORT1', 'PACKAGE1/IMPORT2'], (import1, import2) ->
```
The first argument to `define` is an array of import paths, the second is a function that is passed arguments corresponding to the imported modules. This function should return an object of exports that are made available to other modules importing the current one. For example, in JavaScript to export a `sayHello` function,
```JavaScript
define(['jquery'], function($) {
  return {
    sayHello: function(name) {
      if (name == null) {
        name = "World";
      }
      $('body').append("<p>Hello, " + name + "!</p>");
    }
  };
});
```
Or, equivalently in CoffeeScript
```CoffeeScript
define ['jquery'], ($) ->
  sayHello: (name="World") -> $('body').append "<p>Hello, #{name}!</p>"
```
Note that the CoffeeScript example takes advantage of several pieces of syntactic sugar (default parameters, function call parentheses can be omitted, string interpolation using `#{}`, functions automatically return the value of the last expression, and simplified object notation). Seriously, check out [CoffeeScript](http://coffeescript.org)!

### External Libraries
RequireJS can easily load external libraries specified by either a CDN link or including a `.js` file inside of `lib/js/`. Some common libraries are already included:

* [`"jquery"`](http://jquery.com/) via https://ajax.googleapis.com/ajax/libs/jquery/2.0.3/jquery.min
* [`"jquery-ui"`](http://jqueryui.com/) via https://ajax.googleapis.com/ajax/libs/jqueryui/1.10.3/jquery-ui.min
* [`"datatables"`](https://datatables.net/) via https://ajax.aspnetcdn.com/ajax/jquery.dataTables/1.9.4/jquery.dataTables.min
* [`"d3"`](http://d3js.org/) via `lib/js/d3.v3.min.js`

Sometimes, these modules will not play nicely with RequireJS and need to be shimm'd inside of `src/js/requireConfig.coffee`.

### Main Files
Typically, we want to specify a main JS entry point for a web page. This is accomplished by creating a `PACKAGE/main.{js,coffee}` file and creating a RequireJS task inside of `Gruntfile.coffee`. For example, say we create `src/js/triggers/main.coffee` with the following content
```CoffeeScript
define ['triggers/plot', 'jquery'], (plot, $) ->
  console.log "Loaded"
  $ -> plot.makePlot()
```
We then need to add the line
```CoffeeScript
  triggers: makeRequireJSTask "triggers/main"
```
to the `requirejs` task in `Gruntfile.coffee` (located in `grunt.initConfig: ... requirejs: ...`). This ensures that if we run either `grunt requirejs:triggers` or `grunt jsModule:triggers`, we will produce a single `deploy/js/triggers/main.js` file that contains *all* dependencies. If `grunt` is run without the `--debug` flag, this file will also be minified. (The difference between the two grunt commands being `grunt requirejs:triggers` only does dependency analysis/minification, while `grunt jsModule:triggers` will compile CoffeeScript, process JavaScript and call `grunt requirejs:triggers`).

### Including Modules in an HTML File
Including a JS module inside of an HTML file is a two-step process. First we need to tell RequireJS where our modules are stored
```HTML
<script type="text/javascript"> var require = { baseUrl: "../js" }; </script>
```
Hence, if the HTML file is inside of `deploy/html/`, it will load JS modules from `deploy/js`. (This may need to change depending on how your server is using the HTML files). Then, we include RequireJS and tell it what our entry point is
```HTML
<script type="text/javascript" src="../js/lib/require.js" data-main="triggers/main"></script>
```

Building
--------
The build process is managed by `grunt` which uses the tasks defined inside of `Gruntfile.coffee`. There is quite a bit of room for customization and feature-inclusion, like jshint, cssmin, htmlmin, etc. To run a task, call `grunt TASK` or `grunt TASK:SUBTASK`. Calling `grunt TASK` will call each `SUBTASK` defined in `TASK`. Some basic tasks already included

* `grunt coffee` will compile all CoffeeScript files inside of `src/js/` to `build/js/`

* `grunt watch:coffee` will watch `.coffee` files in `src/js/` and automatically call `grunt coffee` on modification

* `grunt copy` will copy JS, CSS, HTML, and other extraneous files from `src/` and `lib/` into appropriate locations inside of `build/` and `deploy/`. Files that need further processing (i.e. JS) will be put in `build/` while the rest go straight to `deploy/`.
* `grunt copy:{js,jsLib,css,cssLib,html,htmlLib}` will only copy the specified subset of files.

* `grunt clean` will empty the `build/` and `deploy/` directories.

* `grunt requirejs` will do RequireJS dependency analysis, create packaged JS modules, and minify (but only if `--debug` is not specified).
* `grunt requirejs:MODULE` will do `grunt requirejs` on a single module. Make sure that you have included the appropriate `MODULE: makeRequireJSTask "PACKAGE/main"` line inside of `Gruntfile.coffee`.

* `grunt jsModule:MODULE` will run `grunt coffee`, `grunt copy:js`, and `grunt requirejs:MODULE`.

* `grunt full` or just `grunt` will run all of the above.
