{ ... }:

let
  username = "";
  import_programs = [
  ];
in
{
  imports = [
    (import ../_core { username = username; import_programs = import_programs; })
  ];
}
