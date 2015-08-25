# imdone-atom
A task-board for TODOs, FIXMEs, HACKs, etc in your code.

iMDone gives you an interface similar to Trello for your TODO comments.  Most tools give you a list of TODO comments with no regard to order.  iMDone lets you sort them in the order you want and keeps them in sync with your project files.

iMDone works best with todo.txt and markdown syntax.  See the [syntax guide at imdone-core](https://github.com/imdone/imdone-core#task-formats)

![Create filter and move](https://cloud.githubusercontent.com/assets/233505/9454838/d3784fb2-4a8a-11e5-8503-73bf7a2028f1.gif)

Ignoring files
----
1. Configuration setting  
You can ignore files with the "Exclude Vcs Ignored Paths" setting

2. .imdoneignore  
[Glob](https://www.npmjs.com/package/glob) patterns in `.imdoneignore` will be matched against files and directories.  For example, if your project is in `/home/jesse/projects/imdone-atom` and your `.imdoneignore` looks like this, then all files and folders in `/home/jesse/projects/imdone-atom/lib` will be ignored.
```
lib
```
3. .imdone/config.json  
iMDone will also ignore files and folders that match a regex in the `.imdone/config.json`, `exclude` array.  The array is seeded with some common excludes on first run.

**IMPORTANT:** If your project is large (#files > 1000) consider adding an .imdoneignore file.

Linking to External Resources with Metadata
----
Using [todo.txt metadata](https://github.com/imdone/imdone-core#metadata) in your tasks and a few modifications to `.imdone/config.json`, you can link to external resources like github issues and profiles.  Look at [imdone/imdone-core#metadata](https://github.com/imdone/imdone-core#metadata) for more info.

Check out [this example](https://github.com/imdone/imdone-atom/blob/master/.imdone/config.json#L48).

Roadmap
----
- [ ] #BACKLOG:20 Add configuration editor view for .imdone/config.json +Roadmap
  - Use copy/modified version of [settings-view/settings-panel.coffee at master · atom/settings-view](https://github.com/atom/settings-view/blob/master/lib/settings-panel.coffee)
- [ ] #DOING:0 Integrate with github issues +Roadmap
  - If git-iss exists in meta config then add button for create when no issue is present.
  - Maybe another package???

Documentation
----
- [ ] #BACKLOG:40 Add rename list gif +help
- [ ] #BACKLOG:30 Add new list gif +help
- [ ] #BACKLOG:10 Add hide/show list gif +help
- [ ] #BACKLOG:50 Add move list gif +help

Completed
----
- [x] #DONE:20 Consider respecting "Exclude VCS ignored paths" or .imdoneignore git-iss:6 +enhancement
- [x] #DONE:40 Add list rename +Roadmap
- [x] #DONE:100 Add help for configuration
- [x] #DONE:110 Add help for task syntax
- [x] #DONE:130 Add help for todo.txt syntax
