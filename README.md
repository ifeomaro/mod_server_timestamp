#mod_server_timestamp

mod_server_timestamp was used with the [CarrierPigeon iOS project] (https://github.com/mychrisdangelo/CarrierPigeon) to implement the "message delivered" functionality by adding a timestamp to messages sent by users.

mod_server_timestamp source code:

- `src/mod_server_timestamp.erl` - Erlang source code for the server timestamp module.
- `src/date_util.erl` - [Date util functions] (https://gist.github.com/zaphar/104903).

## Setting up

- Install [erlang] (https://github.com/erlang/otp)
- Install ejabberd
  - git clone https://github.com/processone/ejabberd.git
  - git checkout -b 2.0.x origin/2.0.x
  - export EJABBERD_PATH=$HOME/ejabberd/src
- Run `make` from `src/`.

### Sample Message Stanza
- `<message type="chat" from=“Alice” to="Bob" id=“ae134" serverTimestamp="1399779348">`
- `<body>Hi</body><active xmlns=“http://jabber.org/protocol/chatstates”>`
- `</active></message>`
