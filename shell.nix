let
  nixpkgs = builtins.fetchTarball {
    url    = "https://github.com/NixOS/nixpkgs/archive/fb8d36459a4310d51471461123aa7798c15b7dde.tar.gz";
    sha256 = "136bb6s5fzyppm8ir4r8j23pcg2prr4jvnnd793h3dns9d5bl8mh";
  };

  pkgs = import nixpkgs { config = {}; };
in
  pkgs.mkShell {
    buildInputs = with pkgs; [
      git
      gnumake
      docker
      docker-compose
      elixir_1_15
      postgresql
      inotify-tools
    ];
  }
