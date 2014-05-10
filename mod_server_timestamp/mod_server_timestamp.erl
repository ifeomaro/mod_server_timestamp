%%% Modified from mod_stanza_ack (https://github.com/Mingism/ejabberd-stanza-ack)

-module(mod_server_timestamp).
-author("Ifeoma Okereke").

-behaviour(gen_mod).

-include("ejabberd.hrl").
-include("jlib.hrl").

-type host()	:: string().
-type name()	:: string().
-type value()	:: string().
-type opts()	:: [{name(), value()}, ...].

-define(NS_RECEIPTS, <<"urn:xmpp:receipts">>).

-export([start/2, stop/1]).
-export([on_user_send_packet/3, send_ack_response/3, on_filter_packet/1, replace_tag_attrs/3]).

-spec start(host(), opts()) -> ok.
start(Host, Opts) ->
    ?INFO_MSG("Starting mod_server_timestamp ...", []),
    mod_disco:register_feature(Host, ?NS_RECEIPTS),
    ejabberd_hooks:add(filter_packet, global, ?MODULE, on_filter_packet, 0),
    ejabberd_hooks:add(user_send_packet, Host, ?MODULE, on_user_send_packet, 0),
    ok.

-spec stop(host()) -> ok.
stop(Host) ->
    ?INFO_MSG("Stopping mod_server_timestamp ...", []),
    ejabberd_hooks:delete(filter_packet, global, ?MODULE, on_filter_packet, 0),
    ejabberd_hooks:delete(user_send_packet, Host, ?MODULE, on_user_send_packet, 0),
    ok.

on_filter_packet({From, To, Packet}) ->
     Body = xml:get_path_s(Packet, [{elem, "body"}, cdata]),
     Delay = xml:get_path_s(Packet, [{elem, "delay"}, cdata]),
     Output = 
      case xml:get_tag_attr_s("type", Packet) of
	 "chat" ->
	    if (Body /= "") and (Delay == "") ->
		Timestamp = list_to_binary(integer_to_list(date_util:datetime_to_epoch(calendar:universal_time()))),
		NewPacket = replace_tag_attrs("serverTimestamp", Timestamp, Packet),
		?INFO_MSG("Added server timestamp", []),
		{From, To, NewPacket};
	    true ->
		{From, To, Packet}
	    end;
         _ ->
	    {From, To, Packet}
      end,
    Output.

replace_tag_attrs(Attr, Value, {xmlelement, Name, Attrs, Els}) ->
    Attrs1 = lists:keydelete(Attr, 1, Attrs),
    Attrs2 = [{Attr, Value} | Attrs1],
    {xmlelement, Name, Attrs2, Els}.

on_user_send_packet(From, To, Packet) ->
    RegisterFromJid = To,
    Body = xml:get_path_s(Packet, [{elem, "body"}, cdata]),
    Composing = xml:get_path_s(Packet, [{elem, "composing"}, cdata]),
    case xml:get_tag_attr_s("type", Packet) of
        %%Case: Return ack that the chat message has been received by the server
		%% only if the message has a body and is not "composing"
        "chat" ->
	   if (Body /= "") and (Composing == "") ->
	      ?INFO_MSG("Sending ack packet from ~p to ~p", [To#jid.luser, From#jid.luser]),
	      RegisterToJid = From, 
              send_ack_response(Packet, RegisterFromJid, RegisterToJid);
	   true ->
	      ok
	   end;
        _ ->
        ok
    end,
    ok.

send_ack_response(Pkt, RegisterFromJid, RegisterToJid) ->
  %% create a UTC (or GMT) timestamp and append to the receipt
    Timestamp = list_to_binary(integer_to_list(date_util:datetime_to_epoch(calendar:universal_time()))),
    ReceiptId = xml:get_tag_attr_s("id", Pkt),
    XmlBody = {xmlelement, "message", [{"from", RegisterFromJid}, {"to", RegisterToJid}],
                [{xmlelement, "received", [{"xmlns", ?NS_RECEIPTS}, {"id", ReceiptId}, {"serverTimestamp", Timestamp}],
                  []}]},
    ejabberd_router:route(RegisterFromJid, RegisterToJid, XmlBody),
    ?INFO_MSG("Ack packet sent", []).
