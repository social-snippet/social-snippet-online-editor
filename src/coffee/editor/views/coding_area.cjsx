define ["react"], (React)->

  class CodingArea extends React.Component

    constructor: (props)->
      @state =
        source: props.source

    render: ->
      <textarea className="coding-area" value={this.props.source.getText()} onChange={this.props.onChange} />

