define ["react", "jquery"], (React, jQuery)->

  class EditView extends React.Component

    CodingArea    = require("editor/views/coding_area")
    EditorActions = require("editor/views/editor_actions")
    CodingActions = require("editor/views/coding_actions")
    StatusArea    = require("editor/views/status_area")
    SourceInfo    = require("editor/views/source_info")

    constructor: (props)->
      @state =
        source: props.source
        saving: false
        running: false
        inserting: false
        errorOnSaving: false
        errorOnRunning: false
        errorOnInserting: false
        markers: []
      @source = props.source
      @models = [
        @source
      ]

    componentDidMount: ->
      @initModalInstallRepoEvents()
      @source.on "add:text change:text remove:text", =>
        @setState source: @source
        @forceUpdate(null)
      @source.on "add:newRanges change:newRanges remove:newRanges", =>
        console.log "source change new ranges"
        @setState markers: @source.get("newRanges")

    initModalInstallRepoEvents: ->
      jQuery(document).on "click", "#modal-install-repo button.install", ->
        repoName = jQuery("#modal-install-repo input.repo-name").val()
        ajaxOpts =
          url: "#{SSNIP_URL}/actions/install"
          type: "post"
          dataType: "json"
          data:
            repos: [repoName]
        jQuery.ajax ajaxOpts
          .then ->
            jQuery("#modal-install-repo").modal "hide"
          .then null, (e)->

    componentWillUnmount: ->
      @models.forEach (model)=>
        model.off null, null, @

    showMessage = (text)->
      EditorApp.vent.trigger "message", {
        type: "System"
        text: text
      }

    showErrorMessage = (text)->
      EditorApp.vent.trigger "message", {
        type: "Error"
        text: text
      }

    showStatusMessage = (text)->
      EditorApp.vent.trigger "message", {
        type: "Output"
        text: text
      }

    showRawMessage = (text)->
      EditorApp.vent.trigger "message:raw", {
        text: text
      }

    save: =>
      showMessage "Saving Data..."
      @setState
        saving: true
      @source.save()
        .then =>
          showMessage "Saved"
          @setState
            saving: false
          EditorApp.vent.trigger "editor:show", @source
        .then null, (err)=>
          showErrorMessage err
          throw err

    run: =>
      status = new EditorApp.Editor.Status
        source_id: @source.id
      @setState
        running: true
      showMessage "Sending Source... (and Waiting Result...)"
      status.save()
        .then =>
          showMessage "Sent"
          @setState
            running: false
          term = []
          term.push "$ #{status.get "lang_version"}"
          term.push status.get("output")
          showRawMessage term.join("\n")

    insert: =>
      showMessage "Inserting Snippet..."
      @source.insertSnippet()
        .then ->
          showMessage "Done"
        .then null, (err)->
          showErrorMessage err
          throw err

    install: ->
      jQuery("#modal-install-repo").modal()

    help: ->
      jQuery("#modal-help").modal()

    onChangeSource: (event)=>
      @source.set "text", event.target.value

    onChangeLanguage: (event)=>
      @source.set "language", event.target.value

    render: ->
      <div className="row">
        <div className="editor-area">
          <CodingActions
            saving={this.state.saving}
            running={this.state.running}
            inserting={this.state.inserting}
            errorOnSaving={this.state.errorOnSaving}
            errorOnRunning={this.state.errorOnRunning}
            errorOnInserting={this.state.errorOnInserting}
            onClickSave={this.save}
            onClickRun={this.run}
            onClickInsert={this.insert}
            onClickInstall={this.install}
            onClickHelp={this.help} />
          <SourceInfo source={this.state.source}
            onChangeLanguage={this.onChangeLanguage} />
          <CodingArea source={this.state.source}
            markers={this.state.markers}
            onChange={this.onChangeSource} />
          <StatusArea />
        </div>
      </div>

