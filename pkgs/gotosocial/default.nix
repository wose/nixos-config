{ buildGoModule, fetchFromGitHub, lib, pkgs }:

buildGoModule rec {
  pname = "gotosocial";
  version = "0.2.1";

  src = fetchFromGitHub {
    owner = "superseriousbusiness";
    repo = "gotosocial";
    rev = "v${version}";
    sha256 = "ldU2wzahCjy2rThcBIuzHCSWtUK1jxDEB+QKBv8Aqrw=";
  };

  vendorSha256 = null;

  doCheck = false;

  tags = [ "netgo" "osusergo" "static_build" ];
  ldflags = ["-s" "-w" "-extldflags '-static'" "-X 'main.Version=${version}'" ];

  meta = with lib; {
    description = "Golang fediverse server";
    homepage = "https://docs.gotosocial.org";
    license = licenses.agpl3Only;
    maintainer = with maintainers; [ wose ];
    platforms = platforms.linux;
  };
}
