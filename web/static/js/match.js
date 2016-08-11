import socket from "./socket"
import React from "react"
import ReactDOM from "react-dom"
import Table from "./table"

class Match {
  constructor(id, playerId, elementId, socket) {
    this.id = id
    this.playerId = playerId
    this.socket = socket
    this.channel = socket.channel("match:" + this.id, {})
    this.elementId = elementId
  }

  connect() {
    this.table = ReactDOM.render(
      <Table 
        playerId={this.playerId}
        match={this} />,
      document.getElementById(this.elementId)
    )

    this.socket.connect()

    this.channel.join()
      .receive("ok", resp => {
        console.log("Joined successfully", resp)
        this.table.setState({ game: resp })
      })
      .receive("error", resp => { console.log("Unable to join", resp) })

    this.channel.on("game", game => {
      this.table.setState({ game: game })
    })
  }

  startGame() {
    this.channel.push("start_game", {})
  }

  discardAndEndTurn(cardIndex, discardIndex) {
    this.channel.push("discard_and_end_turn", { card_index: cardIndex, discard_index: discardIndex })
  }

  buildFromStock(buildIndex) {
    this.channel.push("build_from_stock", { build_index: buildIndex })
  }

  buildFromHand(cardIndex, buildIndex) {
    this.channel.push("build_from_hand", { card_index: cardIndex, build_index: buildIndex })
  }

  buildFromDiscard(discardIndex, buildIndex) {
    this.channel.push("build_from_discard", { discard_index: discardIndex, build_index: buildIndex })
  }
}

export default Match