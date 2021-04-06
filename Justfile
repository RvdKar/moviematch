## MovieMatch project scripts

version := `cat VERSION`
build_dir := justfile_directory() + "/build"
ui_dir := justfile_directory() + "/web/app"
ui_build_dir := ui_dir + "/build"
deno_options := "-A --unstable --import-map=./configs/import_map.json"
deno_compile_options := "--allow-read --allow-write --allow-env --allow-net --unstable"
deno_fmt_ignore := build_dir + "," + ui_dir + "/node_modules" + "," + ui_build_dir

default:
  @just --list

start: install
  #!/bin/bash
  just start-server &
  DENO_PID="$!"
  just start-ui &
  NPM_PID="$!"

  function cleanup() {
    kill $DENO_PID $NPM_PID
    echo "Exited!"
  }

  trap cleanup EXIT
  while true; do sleep 60; done

start-server:
  denon -c configs/denon.config.json run {{ deno_options }} ./cmd/moviematch/main.ts

start-ui:
  rm -rf {{ui_build_dir}}
  cd {{ui_dir}} && npx snowpack dev

build-ui: install-node-modules
  cd {{ui_dir}} && VERSION={{version}} npx snowpack build

build-bundle: clean build-ui
  mkdir -p {{build_dir}}
  deno run {{ deno_options }} ./cmd/moviematch/pkger.ts {{ui_build_dir}}/dist/main.* {{ui_build_dir}}/icons {{ui_build_dir}}/manifest.webmanifest web/template/index.html configs/localization VERSION > {{build_dir}}/pkg.ts
  sed 's/pkger.ts/pkger_release.ts/' < configs/import_map.json > {{build_dir}}/import_map.json
  deno bundle --lock deps.lock --unstable --import-map=build/import_map.json ./cmd/moviematch/main.ts > {{build_dir}}/moviematch.js

build-binary-all: (build-binary "x86_64-unknown-linux-gnu") (build-binary "aarch64-unknown-linux-gnu") (build-binary "x86_64-pc-windows-msvc") (build-binary "x86_64-apple-darwin") (build-binary "aarch64-apple-darwin")
  rm {{build_dir}}/{pkg.ts,import_map.json}

build-binary target: build-bundle
  #!/bin/bash
  mkdir -p {{build_dir}}/{{target}}
  if [[ "{{target}}" != "aarch64-unknown-linux-gnu" ]]; then
    deno compile {{deno_compile_options}} --lite --target {{target}} --output {{build_dir}}/{{target}}/moviematch {{build_dir}}/moviematch.js
  else
    docker run --rm -it --platform linux/arm64 -v {{build_dir}}:{{build_dir}} lukechannings/deno compile {{deno_compile_options}} --output {{build_dir}}/{{target}}/moviematch {{build_dir}}/moviematch.js
  fi
  cd {{build_dir}}/{{target}} && zip -r -j "../{{target}}.zip" ./*

test:
  # https://github.com/denoland/deno/issues/9284
  deno test {{ deno_options }} internal

test-e2e target: install-deno-dependencies
  #!/bin/bash
  export PORT=8765
  ./build/{{target}}/moviematch &
  MM_PID="$!"
  deno test {{ deno_options }} e2e-tests
  kill MM_PID

lint:
  deno fmt --check --ignore={{deno_fmt_ignore}}
  deno lint --unstable --ignore={{build_dir}},{{ui_dir}}

install: install-node-modules install-deno-dependencies

install-node-modules:
  cd {{ui_dir}} && npm install

install-deno-dependencies:
  deno install -qAf --unstable https://deno.land/x/denon/denon.ts
  deno run -A --unstable https://raw.githubusercontent.com/lucacasonato/deno-puppeteer/main/install.ts

clean: clean-ui clean-server

clean-ui:
  rm -rf {{ui_build_dir}} {{ui_dir}}/node_modules

clean-server:
  rm -rf {{build_dir}}

format:
  deno fmt --ignore={{deno_fmt_ignore}}

update-lockfile:
  deno cache --lock deps.lock --lock-write --unstable --import-map=./configs/import_map.json ./cmd/moviematch/main.ts

install-githooks:
  #!/bin/bash
  echo -e "#!/bin/bash\njust lint" > .git/hooks/pre-commit
  chmod +x .git/hooks/pre-commit
  echo -e "#!/bin/bash\njust lint test" > .git/hooks/pre-push
  chmod +x .git/hooks/pre-push