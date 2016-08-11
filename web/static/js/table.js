import React from "react"
import ReactDOM from "react-dom"

class Card extends React.Component {
  constructor(props) {
    super(props)

    this.state = {
      selected: false
    }

    this.clicked = this.clicked.bind(this)
  }

  clicked(e) {
    e.preventDefault()
    if (this.props.onClick) {
      this.props.onClick(this.state.selected)
    }
  }

  cardClass() {
    return this.props.selected ? "card selected" : "card"
  }

  render() {
    if (this.props.value == 0) {
      var text = "S!"
    } else {
      var text = this.props.value;
    }
    return <div className={this.cardClass()} onClick={this.clicked}>
      {text}
    </div>
  }
}

class BuildPile extends React.Component {
  render() {
    if (this.props.cards.length == 0) {
      var pileValue = ""
    } else {
      var pileValue = this.props.cards.length
    }

    return <div className="card" onClick={this.props.onClick}>
      { pileValue }
    </div>
  }
}

class DiscardPile extends React.Component {
  render() {
    let reversed = this.props.cards.slice().reverse()

    if (this.props.cards.length == 0) {
      let className = this.props.selected ? "card selected" : "card"
      return <div className={className} onClick={this.props.onClick} />
    } else {
      let className = this.props.selected ? "stacked-pile selected" : "stacked-pile"
      return <div className={className} onClick={this.props.onClick}>
        { reversed.map((card, i) => {
          return <div className="stacked-card" key={i}>{card || "S!"}</div>
        }) }
      </div>
    }
  }
}

class Seat extends React.Component {
  constructor(props) {
    super(props)

    this.state = {
      selectedHandIndex: null,
      selectedStock: false,
      selectedDiscardIndex: null
    }

    this.handClicked = this.handClicked.bind(this)
    this.stockClicked = this.stockClicked.bind(this)
  }

  handClicked(index) {
    if (!this.props.me || !this.props.active) {
      return;
    }

    if (this.state.selectedHandIndex == index) {
      this.setState({ selectedHandIndex: null })
    } else {
      this.setState({ selectedHandIndex: index, selectedDiscardIndex: null, selectedStock: false });
    }
  }

  stockClicked() {
    if (!this.props.me || !this.props.active) {
      return;
    }

    if (this.state.selectedStock) {
      this.setState({ selectedStock: false })
    } else {
      this.setState({ selectedHandIndex: null, selectedDiscardIndex: null, selectedStock: true });
    }
  }

  discardClicked(index) {
    if (this.state.selectedHandIndex == null) {
      if (this.state.selectedDiscardIndex == index) {
        this.setState({ selectedDiscardIndex: null })
      } else {
        this.setState({ selectedDiscardIndex: index, selectedStock: false, selectedHandIndex: null })
      }
    } else {
      this.props.match.discardAndEndTurn(this.state.selectedHandIndex, index)
      this.deselectAll()
    }
  }

  deselectAll() {
    this.setState({ selectedHandIndex: null, selectedStock: false, selectedDiscardIndex: null })
  }

  render() {
    return <div>
      <div className="row">
        <div className="col-md-12">
          <h3>
            Player {this.props.index + 1} 
            {this.props.me ? " (me)" : ""}
            {this.props.active ? " <–" : ""}</h3>
        </div>
        <div className="col-md-2">
          <h4>Stock ({this.props.seat.stock.length})</h4>
          <Card 
            value={this.props.seat.stock[0]} 
            selected={this.state.selectedStock}
            onClick={this.stockClicked}/>
          <div className="clearFix" />
        </div>
        <div className="col-md-5">
          <h4>Hand ({this.props.seat.hand.length})</h4>
          { this.props.me ? this.props.seat.hand.map((card, i) => {
            return <Card 
              key={i} 
              value={card} 
              selected={i == this.state.selectedHandIndex}
              onClick={this.handClicked.bind(this, i)} />
          }) : null}
        </div>
        <div className="col-md-5">
          <h4>Discards</h4>
          <DiscardPile cards={this.props.seat.discards[0]} onClick={this.discardClicked.bind(this, 0)} selected={this.state.selectedDiscardIndex == 0}/>
          <DiscardPile cards={this.props.seat.discards[1]} onClick={this.discardClicked.bind(this, 1)} selected={this.state.selectedDiscardIndex == 1}/>
          <DiscardPile cards={this.props.seat.discards[2]} onClick={this.discardClicked.bind(this, 2)} selected={this.state.selectedDiscardIndex == 2}/>
          <DiscardPile cards={this.props.seat.discards[3]} onClick={this.discardClicked.bind(this, 3)} selected={this.state.selectedDiscardIndex == 3}/>
        </div>
      </div>
    </div>
  }
}

class Table extends React.Component {
  constructor(props) {
    super(props)

    this.buildClicked = this.buildClicked.bind(this)
  }

  buildClicked(index) {
    let seat = this.refs.active_seat

    if (seat.state.selectedStock) {
      match.buildFromStock(index)
      seat.deselectAll()
    } else if (seat.state.selectedHandIndex != null) {
      match.buildFromHand(seat.state.selectedHandIndex, index)
      seat.deselectAll()
    } else if (seat.state.selectedDiscardIndex != null) {
      match.buildFromDiscard(seat.state.selectedDiscardIndex, index)
      seat.deselectAll()
    }
  }

  render() {
    if (this.state == null || this.state.game == null) {
      return <div>Initializing...</div>
    }

    if (!this.state.game.started) {
      if (this.state.game.seats.length < 2) {
        return <div>Waiting for other players...</div>
      } else {
        return <div>
          <button className="btn btn-primary" onClick={() => this.props.match.startGame()}>
            Start the game with {this.state.game.seats.length} players!
          </button>
        </div>
      }
    }

    if (this.state.game.winner != null) {
      var winner = <div className="winner">
        Player {this.state.game.winner + 1} wins!
      </div>
    } else {
      var winner = null
    }

    return <div>
      { winner }
      <div>
        Deck: { this.state.game.deck.length },
        Trash: { this.state.game.trash.length }
      </div>
      <div className="row">
        <div className="col-md-6">
          <h3>Builds</h3>
          <BuildPile cards={this.state.game.builds[0]} onClick={this.buildClicked.bind(this, 0)} />
          <BuildPile cards={this.state.game.builds[1]} onClick={this.buildClicked.bind(this, 1)} />
          <BuildPile cards={this.state.game.builds[2]} onClick={this.buildClicked.bind(this, 2)} />
          <BuildPile cards={this.state.game.builds[3]} onClick={this.buildClicked.bind(this, 3)} />
        </div>
      </div>

      { this.state.game.seats.map((seat, i) => 
        <Seat index={i} 
          seat={seat} 
          key={seat.player} 
          active={i == this.state.game.current} 
          me={seat.player == this.props.playerId}
          ref={i == this.state.game.current ? "active_seat" : null}
          match={this.props.match} />
      )}
    </div>
  }
}

export default Table