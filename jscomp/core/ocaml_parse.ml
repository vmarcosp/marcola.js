(* Copyright (C) 2015-2016 Bloomberg Finance L.P.
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * In addition to the permissions granted to you by the LGPL, you may combine
 * or link a "work that uses the Library" with a publicly distributed version
 * of this file to produce a combined library or application, then distribute
 * that combined work under the terms of your choosing, with no requirement
 * to comply with the obligations normally placed on you by section 4 of the
 * LGPL version 3 (or the corresponding section of a later version of the LGPL
 * should you choose to use a later version).
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA. *)

let print_if ppf flag printer arg =
  if !flag then Format.fprintf ppf "%a@." printer arg;
  arg

let parse_interface ppf sourcefile = 
  Ppx_entry.rewrite_signature (Pparse.parse_interface ~tool_name:Js_config.tool_name ppf sourcefile)


let lazy_parse_interface ppf sourcefile =
  lazy (parse_interface ppf sourcefile)

let parse_implementation ppf sourcefile = 
  Ppx_entry.rewrite_implementation
    (
      Pparse.parse_implementation ~tool_name:Js_config.tool_name ppf sourcefile
#if undefined BS_RELEASE_BUILD then       
      |> print_if ppf Clflags.dump_parsetree Printast.implementation
      |> print_if ppf Clflags.dump_source Pprintast.structure

#end
      )

let parse_implementation_from_string  str = 
  let lb = Lexing.from_string str in
  Location.init lb "//toplevel//";
  Ppx_entry.rewrite_implementation (Parse.implementation lb)


let lazy_parse_implementation ppf sourcefile =
  lazy (parse_implementation ppf sourcefile)

type valid_input = 
  | Implementation 
  | Interface
  | Mlast    
  | Mliast 
  | Mlmap
  | Cmi

(** This is per-file based, 
    when [ocamlc] [-c -o another_dir/xx.cmi] 
    it will return (another_dir/xx)
*)    

let check_suffix  name  = 
  let ext = Ext_filename.get_extension_maybe name in 
  let input = 
    if ext = Literals.suffix_ml ||  ext = Literals.suffix_re then 
      Implementation
    else if ext = !Config.interface_suffix || ext = Literals.suffix_rei then 
      Interface  
    else if ext =  ".mlast" then 
      Mlast 
    else if ext = ".mliast" then 
      Mliast
    else if ext =  ".mlmap"  then 
      Mlmap 
    else if ext =  ".cmi" then 
      Cmi
    else 
      raise(Arg.Bad("don't know what to do with " ^ name)) in 
  input, Compenv.output_prefix name
