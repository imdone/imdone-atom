module.exports=
  enabled: true
  name: 'github'
  config:
    rules:
      updateDiscussion: [
        onLineChange: false
        withTag: ""
      ]
      labelBot: [
        withContext: ""
      ]
      createIssue: [
        stripTODOText: true
        withTag: "story"
      ,
        stripTODOText: true
        withTag: "enhancement"
      ,
        stripTODOText: true
        withTag: "feature"
      ,
        stripTODOText: true
        withTag: "chore"
      ]
      closeIssues: [
        withTag: ""
        listName: "DONE"
      ]
