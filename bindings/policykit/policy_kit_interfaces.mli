(* File auto-generated by obus_gen_interface.best, DO NOT EDIT. *)
open OBus_member
module Org_freedesktop_PolicyKit_AuthenticationAgent : sig
  val m_ObtainAuthorization : (string * int32 * int32, bool) Method.t
  val make :
    ?notify_mode : 'a OBus_object.notify_mode ->
    m_ObtainAuthorization : (bool OBus_context.t -> 'a -> string * int32 * int32 -> bool Lwt.t) ->
    unit -> 'a OBus_object.interface
end
