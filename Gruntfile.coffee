# Generated on 2014-03-03 using generator-angular 0.7.1
"use strict"

# # Globbing
# for performance reasons we're only matching one level down:
# 'test/spec/{,*/}*.js'
# use this if you want to recursively match all subfolders:
# 'test/spec/**/*.js'
module.exports = (grunt) ->
  
  # Load grunt tasks automatically
  require("load-grunt-tasks") grunt
  
  # Time how long tasks take. Can help when optimizing build times
  require("time-grunt") grunt
  process.env.dirname = __dirname
  # Define the configuration for all the tasks
  grunt.initConfig
    
    # Project settings
    yeoman:
      
      # configurable paths
      app: require("./bower.json").appPath or "app"
      dist: "dist"
      livereload: 35729
      
    # Watches files for changes and runs tasks based on the changed files
    watch:
      options:
        livereload: "<%= yeoman.livereload %>"
      coffee:
        files: ["ngapp/**/*.coffee"]
        tasks: ['newer:coffee']
      jade:
        files: ["ngapp/**/*.jade"]
        tasks: ['newer:jade']
      stylus:
        files: ["ngapp/**/*.styl"]
        tasks: ['newer:stylus','autoprefixer']
      gruntfile:
        files: ["Gruntfile.coffee"]
        tasks: [
          "express:dev:stop"
          "serve"
        ]
        options:
          spawn: false
      bower:
        files: ["bower.json"]
        tasks: ["bowerInstall"]
      express:
        tasks: [
          "express:dev"
        ]
        files: [
          "resources/**/*"
          "server/**/*"
        ]
        options:
          spawn: false
          atBegin: true
    jade: 
      compile: 
        files: [
          expand: true,
          cwd: 'ngapp/',
          src: '**/*.jade',
          ext: ".html",
          dest: 'ngapp_compiled/'          
        ]
    coffee:
      compile:
        files: [
          expand: true,
          cwd: 'ngapp/',
          src: '**/*.coffee',
          ext: ".js",
          dest: 'ngapp_compiled/'          
        ]
    stylus:
      compile:
        files: [
          expand: true,
          cwd: 'ngapp/',
          src: '**/*.styl',
          ext: ".css",
          dest: 'ngapp_compiled/'          
        ] 

    # The actual grunt server settings
    express:
      options:
        port: process.env.PORT or 9000
        opts: ['node_modules/coffee-script/bin/coffee']
      dev:
        options:
          script: "server/server.coffee"

    
    # Empties folders to start fresh
    clean:
      compile:
        files: [
          dot: true
          src: [
            "ngapp_compiled/*"
          ]
        ]

    
    # Add vendor prefixed styles
    autoprefixer:
      options:
        browsers: ["last 1 version"]
      dist:
        files: [
          expand: true
          cwd: "ngapp_compiled/"
          src: "**/*.css"
          dest: "ngapp_compiled/"
        ]

    # Automatically inject Bower components into the app
    bowerInstall:
      target:
        src: ["ngapp/index.jade"]

    
    # Renames files for browser caching purposes
    rev:
      dist:
        files:
          src: [
            "<%= yeoman.dist %>/scripts/{,*/}*.js"
            "<%= yeoman.dist %>/styles/{,*/}*.css"
            "<%= yeoman.dist %>/images/{,*/}*.{png,jpg,jpeg,gif,webp,svg}"
            "<%= yeoman.dist %>/styles/fonts/*"
          ]

    
    # Reads HTML for usemin blocks to enable smart builds that automatically
    # concat, minify and revision files. Creates configurations in memory so
    # additional tasks can operate on them
    useminPrepare:
      html: "<%= yeoman.app %>/index.html"
      options:
        dest: "<%= yeoman.dist %>"

    
    # Performs rewrites based on rev and the useminPrepare configuration
    usemin:
      html: ["<%= yeoman.dist %>/{,*/}*.html"]
      css: ["<%= yeoman.dist %>/styles/{,*/}*.css"]
      options:
        assetsDirs: ["<%= yeoman.dist %>"]

    
    # The following *-min tasks produce minified files in the dist folder
    imagemin:
      dist:
        files: [
          expand: true
          cwd: "<%= yeoman.app %>/images"
          src: "{,*/}*.{png,jpg,jpeg,gif}"
          dest: "<%= yeoman.dist %>/images"
        ]

    svgmin:
      dist:
        files: [
          expand: true
          cwd: "<%= yeoman.app %>/images"
          src: "{,*/}*.svg"
          dest: "<%= yeoman.dist %>/images"
        ]

    htmlmin:
      dist:
        options:
          collapseWhitespace: true
          collapseBooleanAttributes: true
          removeCommentsFromCDATA: true
          removeOptionalTags: true

        files: [
          expand: true
          cwd: "<%= yeoman.dist %>"
          src: [
            "*.html"
            "views/{,*/}*.html"
          ]
          dest: "<%= yeoman.dist %>"
        ]

    
    # Allow the use of non-minsafe AngularJS files. Automatically makes it
    # minsafe compatible so Uglify does not destroy the ng references
    # ngmin: {
    #   controllers: {
    #     src: ['test/src/controllers/one.js'],
    #     dest: 'test/generated/controllers/one.js'
    #   },
    #   directives: {
    #     expand: true,
    #     cwd: 'test/src',
    #     src: ['directives/**/*.js'],
    #     dest: 'test/generated'
    #   }
    # },
        
    # Run some tasks in parallel to speed up the build process
    concurrent:
      compile:
        tasks: ["coffee","jade","stylus"]
    
    # Test settings
    karma:
      unit:
        configFile: "karma.conf.js"
        singleRun: true

  grunt.registerTask "serve", (target) ->
    if target is "dist"
      return grunt.task.run([
        "build"
        "express:dist"
      ])
    grunt.task.run [
      "clean:compile"
      "bowerInstall"
      "concurrent:compile"
      "autoprefixer"
      "watch"
    ]

  grunt.registerTask "test", [
    "concurrent:test"
    "autoprefixer"
    "express:test"
    "karma"
  ]
  grunt.registerTask "build", [
    "clean:dist"
    "bowerInstall"
    "useminPrepare"
    "concurrent:dist"
    "autoprefixer"
    "concat"
    #  'ngmin',
    "copy:dist"
    "cssmin"
    "uglify"
    "rev"
    "usemin"
    "htmlmin"
  ]
  grunt.registerTask "default", [
    "test"
    "build"
  ]