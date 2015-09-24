imdone-atom
====

[![apm](https://img.shields.io/apm/dm/imdone-atom.svg)](https://atom.io/packages/imdone-atom)
[![apm](https://img.shields.io/apm/v/imdone-atom.svg)]()

A task-board for TODOs, FIXMEs, HACKs, etc in your code.

![Create filter and move](https://cloud.githubusercontent.com/assets/233505/9454838/d3784fb2-4a8a-11e5-8503-73bf7a2028f1.gif)


iMDone gives you an interface similar to Trello for TODO comments in your code.  Most tools give you a list of TODO comments with no regard to order.  iMDone lets you sort them in the order you want and keeps them in sync with your project files.

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
- [ ] #DOING:10 Integrate with github issues +Roadmap
  - If gh-issue exists in meta config then add button for create when no issue is present.
  - Maybe another package for searching issues???
  - [New Services API](http://blog.atom.io/2015/03/25/new-services-API.html)
- [ ] #DOING:0 Re-apply filter when board is refreshed


Documentation
----
- [ ] #BACKLOG:50 Add rename list gif +help
- [ ] #BACKLOG:40 Add new list gif +help
- [ ] #BACKLOG:20 Add hide/show list gif +help
- [ ] #BACKLOG:60 Add move list gif +help

Completed
----
- [x] #DONE:30 Consider respecting "Exclude VCS ignored paths" or .imdoneignore issue:6 +enhancement
- [x] #DONE:40 Add list rename +Roadmap
- [x] #DONE:100 Add help for configuration
- [x] #DONE:110 Add help for task syntax
- [x] #DONE:130 Add help for todo.txt syntax
