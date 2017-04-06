module.exports = [
    enabled: false
    name: 'github'
    msg:
      info: "Default github connector created"
      detail: "Your default github connector has been created, but it's not enabled.  Go configure it and put your TODO's to work!"
    config:
      rules:
        updateDiscussion: [
          onLineChange: false
          withTag: ""
        ]
        labelBot: [
          withContext: ""
        ]
        waffleIoMappingBot: [
          imdoneListName: "DOING"
          waffleListNameLabel: "in progress"
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
  ,
    enabled: false,
    name: "webhooks"
    msg:
      info: "Default webhook created"
      detail: "Your default webhook has been created, but it's not active.  Go configure it and put your TODO's to work!"
    config:
      rules:
        webhooks: [
          payloadURL: ""
          contentType: ""
          active: false
          secret: ""
          strictSSL: true
        ]
]
