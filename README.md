// A &#35;HACK:4 ble task-board in your code.
----
### You live in the code, your tasks should too!

![Create filter and move](https://cloud.githubusercontent.com/assets/233505/9454838/d3784fb2-4a8a-11e5-8503-73bf7a2028f1.gif)

[![apm](https://img.shields.io/apm/dm/imdone-atom.svg)](https://atom.io/packages/imdone-atom)
[![apm](https://img.shields.io/apm/v/imdone-atom.svg)]()


Developers are creative people and the text editor is their canvas.  For decades they've used TODO style code comments to track issues that almost never end up in issue tracking software.  iMDone is a plugin for your favorite text editor that turns code comments into trackable issues.  It collects all TODO style comments in your project and organizes them in a drag and drop task-board that integrates with any web based issue tracking system.

iMDone works best with todo.txt and markdown syntax.  See the [syntax guide at imdone-core](https://github.com/imdone/imdone-core#task-formats) for details.

Install
----
```
$ apm install imdone-atom
```
or open Atom and go to Preferences > Install and search for `imdone-atom`

Ignoring files
----
- Configuration setting  
You can ignore files with the "Exclude Vcs Ignored Paths" setting

- .imdoneignore  
[Glob](https://www.npmjs.com/package/glob) patterns in `.imdoneignore` will be matched against files and directories.  For example, if your project is in `/home/jesse/projects/imdone-atom` and your `.imdoneignore` looks like this, then all files and folders in `/home/jesse/projects/imdone-atom/lib` will be ignored.
```
lib
```
- .imdone/config.json  
iMDone will also ignore files and folders that match a regex in the `.imdone/config.json`, `exclude` array.  The array is seeded with some common excludes on first run.

**IMPORTANT:** If your project is large (#files > 1000) consider adding an .imdoneignore file.

How To Link Code And Github Issues
----
Using [todo.txt metadata](https://github.com/imdone/imdone-core#metadata) in your tasks and a minor change to `.imdone/config.json`, you can link to external resources like github issues and profiles.  

- Add a `meta` attribute to `.imdone/config.json`  
```javascript
"meta": {
  "issue": {
    "urlTemplate": "https://github.com/imdone/imdone-core/issues/%s",
    "titleTemplate": "github issue #%s"
  }
}
```

- Use `issue:[gh issue id]` as metadata in your tasks.  
<pre>
// &#35;BACKLOG:0 issue:27 Export TODOs
</pre>

- Your issue is linked to the comment!  
![gh-issue-imdone](https://cloud.githubusercontent.com/assets/233505/9595122/72542350-502a-11e5-87b3-a4eb49428b7c.png)

Look at [imdone/imdone-core#metadata](https://github.com/imdone/imdone-core#metadata) for more info.

Roadmap
----
- [ ] #BACKLOG:30 Add configuration editor view for .imdone/config.json +Roadmap
  - Use copy/modified version of [settings-view/settings-panel.coffee at master · atom/settings-view](https://github.com/atom/settings-view/blob/master/lib/settings-panel.coffee)
- [ ] #DONE:10 Provide service for plugins

Documentation
----
- [ ] #BACKLOG:40 Add rename list gif +help
- [ ] #BACKLOG:10 Add new list gif +help
- [ ] #BACKLOG:20 Add hide/show list gif +help
- [ ] #BACKLOG:50 Add move list gif +help

Completed
----
- [x] #DONE:40 Re-apply filter when board is refreshed
- [x] #DONE:20 Consider respecting "Exclude VCS ignored paths" or .imdoneignore issue:6 issue:4 +enhancement
- [x] #DONE:60 Add list rename +Roadmap
- [x] #DONE:130 Add help for configuration
- [x] #DONE:140 Add help for task syntax
- [x] #DONE:160 Add help for todo.txt syntax
