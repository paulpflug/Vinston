# Generated on 2014-03-03 using generator-angular 0.7.1
"use strict"
path = require "path"
util = require "util"
# # Globbing
# for performance reasons we're only matching one level down:
# 'test/spec/{,*/}*.js'
# use this if you want to recursively match all subfolders:
# 'test/spec/**/*.js'
module.exports = (grunt) ->
  
  # Load grunt tasks automatically
  require("load-grunt-tasks") grunt
  grunt.registerMultiTask "injectJson", "Inject json in js file" , () ->
    this.files.forEach (file) ->
      json = file.src[0].replace(/.js/i,".json").replace(/_compiled/i,"")
      if grunt.file.exists(json)
        console.log "found "+json
        data = grunt.file.readJSON json
        content = grunt.file.read file.src[0]
        returnType = if /\r\n/.test(content) then '\r\n' else '\n';
        formatedData = ["  // content from "+json+returnType]
        for k,v of data
          formatedData.push "  var "+k+" = "+util.inspect(v,{depth:null}).replace(/: /g,":")+";"+returnType
        formatedData.push "  // end of content from "+json+returnType
        formatedData = formatedData.join("")
        content = content.replace(/\(function\(\) {/i,"(function() {"+returnType+formatedData)
        grunt.file.write file.src[0], content

  # Time how long tasks take. Can help when optimizing build times
  require("time-grunt") grunt
  process.env.dirname = __dirname
  # Define the configuration for all the tasks
  grunt.initConfig
    
    # Project settings
    yeoman:
      
      # configurable paths
      app: require("./bower.json").appPath or "ngapp"
      dist: "dist"
      livereload: 35729
    
    env: 
      dev:
        NODE_ENV: "development"
        DEBUG: "socket.io:* node server/server.coffee"

    # Watches files for changes and runs tasks based on the changed files
    watch:
      options:
        livereload: "<%= yeoman.livereload %>"
      coffee:
        files: ["ngapp/**/*.coffee"]
        tasks: ['newer:coffee',"injectJson"]
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
      options:
        basedir: "<%= yeoman.app %>"
        data: (dest,src) ->
          json = src[0].replace(/.jade/i,".json")
          if grunt.file.exists(json)
            console.log "found "+json
            return grunt.file.readJSON(json) 
          else
            return false
      compile: 
        files: [
          expand: true,
          cwd: 'ngapp/',
          src: ['**/*.jade',"!components/mixins/*.jade"],
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
    injectJson:
      compile:
        files: [
          expand: true,
          cwd: 'ngapp_compiled/',
          src: ['**/*.js'],
          dest: 'ngapp_compiled/'          
        ]
    # The actual grunt server settings
    express:
      options:
        port: process.env.PORT or 9000
        opts: ['node_modules/coffee-script/bin/coffee']
      dev:
        options:
          debug: true
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
      html: ["ngapp_compiled/index.html"]

    
    # Performs rewrites based on rev and the useminPrepare configuration
    usemin:
      html: ["ngapp_compiled/**/*.html"]
      css: ["ngapp_compiled/**/*.css"]

    
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
          cwd: "ngapp_compiled/"
          src: ["**/*.html"]
          dest: "ngapp_compiled/"
        ]

    ngmin: 
      all: 
        expand: true
        cwd: "ngapp_compiled/"
        src: "**/*.js"
        dest: "ngapp_compiled/"

        
    # Run some tasks in parallel to speed up the build process
    concurrent:
      compile:
        tasks: ["coffee","jade","stylus"]
      rework:
        tasks:["autoprefixer","injectJson"]

    
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
      "env:dev"
      "clean:compile"
      "bowerInstall"
      "concurrent"
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