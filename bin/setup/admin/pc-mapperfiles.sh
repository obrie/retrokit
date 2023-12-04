#!/bin/bash

system='pc'
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../system-common.sh"

setup_module_id='admin/pc-mapperfiles'
setup_module_desc='Generates game-specific mapperfiles (local development purposes only)'

# Mappings from dosbox-staging config name to exodos name
declare -A dobox_to_exodos_name
dobox_to_exodos_name=(
  [abreed]='alienbre'
  [abreedta]="alienbrt"
  [actuas]="actuasoc"
  [aitd2]="adark2"
  [aitd3]="adark394"
  [aitd]="adark1"
  [aitdjack]="adark2"
  [aladdin]="disneysa"
  [alienc]="aliencar"
  [alienr]="alienriv"
  [alientri]="alientri"
  [alphasto]="alphstor"
  [alqadim]="alqadim"
  [amok]="amok"
  [another]="outofthi"
  [batmanac]="batmancc"
  [batmanf]="batmnfor"
  [bigredr]="bigredra"
  [blam]="blam!mac"
  [blood]="blood"
  [bluesb]="blubro"
  [bluesbja]="blubroja"
  [bstone2]="blakesta"
  [bstone]="blakestp"
  [bthorne]="blacktho"
  [cadillac]="cadillac"
  [cataco3d]="cataco3d"
  [catapoc]="terrorof"
  [chxquest]="chexq"
  [cite]="cite"
  [ckeen1]="ckeen1"
  [clifd]="clifdang"
  [coolspot]="coolspot"
  [covertac]="covertac"
  [crusnreg]="crusregr"
  [crusnrem]="crusremo"
  [cyberm]="cybmari"
  [d]="d"
  [dderby2]="dederby2"
  [dderby]="dederby"
  [ddragon2]="ddragon2"
  [ddragon3]="ddragon3"
  [ddragon]="ddragon"
  [descent2]="descent2"
  [descent]="descent"
  [disc]="disc"
  [dnukem2]="duken2"
  [dnukem]="duken11"
  [doom2]="doom2d"
  [doom]="doom"
  [drally]="deathral"
  [dstrike]="dragonst"
  [duke3d]="duke3d"
  [ecstatic2]="ecstati2"
  [ecstatic]="ecstatic"
  [eradicat]="eradicat"
  [ewj2]="ewj2"
  [ewj]="ewj"
  [exhumed]="powslav"
  [extremea]="extremea"
  [fadetb]="fadetobl"
  [fatalr]="whiplash"
  [fb]="firebrig"
  [fifa96]="fifa96"
  [fifa97]="fifasocc"
  [fifa]="fifainte"
  [firestrm]="firestrm"
  [funtrack]="ignition"
  [fxfightr]="fxfighte"
  [gb2]="ghostbu2"
  [gods]="gods"
  [goldnaxe]="goldenax"
  [gta]="gta"
  [gtalond]=""
  [heretic]="heretic"
  [hexen]="hexenbey"
  [hioctane]="hioct"
  [horde]="thehorde"
  [hulkpant]="theincre"
  [humans]="humans"
  [jazz]="jazzjack"
  [jbazooka]="johnnyba"
  [jdredd]="judgedre"
  [jimpower]="jimpower"
  [joemac]="joemacca"
  [jstrike]="junglest"
  [jungbook]="jbook88"
  [jurassic]="jurassic"
  [krusty]="krustysf"
  [lba2]="twinsen"
  [lba]="lba"
  [lionking]="thelionk"
  [lollypop]="lollypop"
  [lostv2]="norsebyn"
  [lostv]="thelostv"
  [magicp]="magicpoc"
  [mars3d]="mars3d"
  [mdk]="mdk"
  [megarac2]="megarac2"
  [megarace]="megarace"
  [menace]="menace"
  [microcsm]="micrcos"
  [mk1]="mk"
  [mk2]="mk2"
  [mk3]="mk3"
  [mktril]="mktril"
  [mm2]="mm2"
  [mm]="mm1"
  [moktar]="lagafles"
  [moon]="kmoon"
  [nba97]="nbalive9"
  [nbajamte]="nbajamto"
  [nfsse]="tnfsse"
  [nhl97]="nhl97"
  [novas]="novastor"
  [oddworld]="oddworld"
  [omf2097]="onemustf"
  [panzakb]="panzakic"
  [petesamp]="petesamp"
  [pitfghtr]="pitfigh"
  [pop2]="ppersia2"
  [pop]="ppersia"
  [prayfd]="prayford"
  [preh2]="prehist2"
  [preh]="prehisto"
  [primrage]="primalra"
  [pushover]="pushover"
  [quake]="quake"
  [raiden]="raiden"
  [rallyc]="rallycha"
  [raptor]="raptorca"
  [rayman]="rayman"
  [redneck2]="redramra"
  [redneck]="redram"
  [reloaded]="reloade"
  [rg97]="rolandg"
  [rise2]="resurrec"
  [rise]="riseotr"
  [rott]="rottdw"
  [scorchdp]="scoplan"
  [screamr2]="screamr2"
  [screamr]="screamer"
  [sf2]="sf2"
  [shadoww]="shadowwa"
  [shells]=shellsho""
  [simparc]="simparc"
  [simpbvs]="simpbvs"
  [skynet]="skynet"
  [spacer]="spacerac"
  [spearod]="sod3d"
  [speedbl2]="speedbl2"
  [spidey]="amzsman"
  [srally]="scrmral"
  [ssf2t]="ssf2t"
  [stargunr]="stargunn"
  [streetr]="streetra"
  [strife]="strife"
  [superc]="superc"
  [swdf]="swdforc"
  [swiv3d]="swiv3d"
  [tbraider]="tombraig"
  [term2]="terminat"
  [termfs]="termfs"
  [timec]="timecomm"
  [timegate]="timegate"
  [timewar]="timewarr"
  [tmnt]="tmnt"
  [tmntarc]="tmnt2"
  [tmntman]="tmntmm"
  [trackatk]="trackatt"
  [turric2]="turrican"
  [tvcd]="termvel"
  [tyrian]="tyrian"
  [wacky]="wackywhe"
  [warriors]="savagewa"
  [wcrew]="wreckinc"
  [whaven2]="witchav2"
  [whaven]="witchave"
  [wilds]="wildstre"
  [wipeout]="wipeout"
  [wolf3d]="wolf3d"
  [wrallyf]="worldral"
  [wwfarc]="wwfarc"
  [wwfiyh]="wwfinyou"
  [xenon2]="xenon2me"
  [xmcota]="xmenchi"
)

depends() {
  # Download configurations
  mkdir -p "$tmp_dir/pc"
  git clone --depth 1 https://github.com/dosbox-staging/dosbox-staging.git "$tmp_dir/pc/dosbox-staging" || true
  pushd "$tmp_dir/pc/dosbox-staging" && git pull && popd
}

build() {
  local default_joystick_binds_file=$(mktemp -p "$tmp_ephemeral_dir")
  local default_binds_file=$(mktemp -p "$tmp_ephemeral_dir")

  # Determine default joystick configurations
  __sort_joystick_binds "$system_config_dir/mapperfiles/dosbox.map" > "$default_joystick_binds_file"
  sed 's/ *"stick[^"]\+ *"//g' "$default_joystick_binds_file" > "$default_binds_file"

  # Map exodos name to romkit name
  declare -A exodos_to_romkit_name
  while IFS=$'\t' read romkit_name exodos_name; do
    exodos_name=${exodos_name,,}
    exodos_to_romkit_name[$exodos_name]=$romkit_name
  done < <(PROFILES=filter-reset bin/romkit.sh list pc | jq -r '[.name, (.xref .path | split("/") | .[-1])] | @tsv')

  # Remove existing mapperfiles so we start from scratch (in case some were deleted from the source)
  # find "$system_config_dir/mapperfiles" -name '*.map' -not -name 'dosbox*.map' -exec rm -f '{}' +

  while IFS=$'\t' read game_mapperfile; do
    # Find the corresponding file to write to
    local dosbox_name=$(basename "$game_mapperfile" .map)
    local exodos_name=${dobox_to_exodos_name[$dosbox_name]}
    if [ -z "$exodos_name" ]; then
      echo "[$dosbox_name] missing"
      continue
    fi
    local romkit_name=${exodos_to_romkit_name[$exodos_name]}

    echo "[$romkit_name] Building mapperfile"
    local staging_mapperfile=$(mktemp -p "$tmp_ephemeral_dir")
    local target_mapperfile="$system_config_dir/mapperfiles/$romkit_name.map"

    # Add game binds
    __sort_joystick_binds "$game_mapperfile" > "$staging_mapperfile"

    # Remove xbox "button 8" because it doesn't have a default mapping in RetroPie
    sed -i 's/ *"stick_0 button 8"//g' "$staging_mapperfile"
    sed -i '/^key[^"]\+"key[^"]\+" *$/d' "$staging_mapperfile"

    # Add default binds (keys only) in case we need to revert what was set globally
    cat "$default_binds_file" >> "$staging_mapperfile"

    # Write the binds that aren't in common with the defaults
    comm -13 <(cat "$default_joystick_binds_file") <(awk -F' ' '! seen[$1]++' "$staging_mapperfile" | sort) > "$target_mapperfile"

    # Ensure the maperfile is set to look in the correct place
    crudini --set "$system_config_dir/conf/$romkit_name.conf" sdl mapperfile "mapperfiles/$romkit_name.map"
  done < <(ls "$tmp_dir/pc/dosbox-staging/contrib/resources/mapperfiles/xbox/"*.map)
}

__sort_joystick_binds() {
  local source_file=$1

  while read line; do
    local event=$(echo "$line" | cut -d' ' -f 1)
    local sorted_binds=$(echo "$line" | grep -oE '"[^"]+"' | sort | tr '\n' ' ' | awk '{$1=$1};1')

    echo "$event $sorted_binds"
  done < <(grep -E '^key_.*stick_0' "$source_file" | sort)
}

setup "${@}"
