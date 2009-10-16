(*
 * pong.ml
 * -------
 * Copyright : (c) 2008, Jeremie Dimino <jeremie@dimino.org>
 * Licence   : BSD3
 *
 * This file is a part of obus, an ocaml implementation of D-Bus.
 *)

(* Very simple service with one object have a ping method *)

open Lwt
open Lwt_io
open OBus_type.Perv

module M = OBus_object.Make(struct
                              type obj = OBus_object.t
                              let get x = x
                            end)

include M.MakeInterface(struct let name = "org.plop.foo" end)

let ping obj msg =
  lwt () = printlf "received: %s" msg in
  return msg

OL_method Ping : string -> string

let _ = Lwt_main.run begin
  lwt bus = Lazy.force OBus_bus.session in

  (* Request a name *)
  lwt _ = OBus_bus.request_name bus "org.plop" in

  (* Create the object *)
  let obj = OBus_object.make ["plip"] in

  (* Export the object on the connection *)
  M.export bus obj;

  (* Wait forever *)
  fst (wait ())
end