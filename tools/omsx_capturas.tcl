# Capturas del cartucho corriendo de verdad, para MIRARLO.
#
# Las imagenes de la web NO salen de aqui: esas las dibuja tools/graficos.py
# desde los bytes de la ROM. Esto es para ver el juego y no escribir de oidas.
#
# Trampas ya pagadas en esta serie, y por que el guion es asi:
#   - lanzado con -script el emulador arranca con el renderer en
#     `uninitialized`, y `screenshot` devuelve un PNG en negro con rc=0. Hay
#     que encenderlo a mano con `set renderer SDLGL-PP`.
#   - con `set throttle off` la maquina corre a toda pastilla y el renderer se
#     salta los cuadros: la captura hay que pedirla con el acelerador PUESTO y
#     con `after realtime`, que es reloj de pared.
#
# El cartucho se pone en la linea de ordenes con -cart, que es lo que hace el
# resto de la serie; aqui solo se dispara y se fotografia.
#
#   CPK_OUT=<dir> [CPK_TECLAS="2 1;6 FOTO"] [CPK_FIN=20] openmsx #       -machine Philips_VG_8020 -cart cabbagepatch.rom -script este.tcl
set OUT $::env(CPK_OUT)
file mkdir $OUT
set LOG [open "$OUT/capturas.log" w]
proc say {m} { global LOG; puts $LOG "t=[format %8.2f [machine_info time]]  $m"; flush $LOG }

catch {set renderer SDLGL-PP}
set throttle on
say "en marcha"

set ::n 0
proc foto {} {
    global OUT
    incr ::n
    set f [format "%s/tiro_%02d.png" $OUT $::n]
    catch {screenshot -raw -doublesize $f} e
    say "foto $f rc=$e  PC=[format 0x%04X [reg PC]]  estado=[debug read memory 0xE000]"
}

# La fila 8 del teclado del MSX: la barra y los cuatro cursores. `type` no
# vale para el disparo -escribiria la palabra-, asi que se toca la matriz.
set ::BARRA 0x01
set ::IZQ   0x10
set ::ARR   0x20
set ::ABA   0x40
set ::DER   0x80
proc pulsa {mascara} {
    say [format "pulsa %02X" $mascara]
    keymatrixdown 8 $mascara
    after realtime 0.4 [list keymatrixup 8 $mascara]
}

if {[info exists ::env(CPK_TECLAS)]} {
    foreach par [split $::env(CPK_TECLAS) ";"] {
        lassign $par t k
        switch -- $k {
            FOTO    { after realtime $t foto }
            BARRA   { after realtime $t {pulsa $::BARRA} }
            ARRIBA  { after realtime $t {pulsa $::ARR} }
            ABAJO   { after realtime $t {pulsa $::ABA} }
            IZQ     { after realtime $t {pulsa $::IZQ} }
            DER     { after realtime $t {pulsa $::DER} }
            default { after realtime $t [list apply {{k} { say "tecla '$k'"; type $k }} $k] }
        }
    }
}
# Y, para las pantallas a las que un tecleo a ciegas no llega, se puede
# empujar el estado a mano: CPK_POKE="30 0xE001 4" escribe ese byte a los 30
# segundos. Es lo mismo que hace el juego al pasar de paso, solo que sin
# esperar a que el jugador acierte con la tecla.
if {[info exists ::env(CPK_POKE)]} {
    foreach orden [split $::env(CPK_POKE) ";"] {
        lassign $orden t dir val
        after realtime $t [list apply {{d v} {
            debug write memory $d $v
            say [format "poke %s = %s" $d $v]
        }} $dir $val]
    }
}

set FIN [expr {[info exists ::env(CPK_FIN)] ? $::env(CPK_FIN) : 20}]
after realtime $FIN { say "FIN"; exit 0 }
