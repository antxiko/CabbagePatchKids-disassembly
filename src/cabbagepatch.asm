; ==========================================================================
; CABBAGE PATCH KIDS - Konami - MSX1 - cartucho RC-716 de 16 KB en la pagina 1
; ==========================================================================
; Generado por tools/mkasm.py a partir del trazado de flujo real.
; Los comentarios provienen de tools/../src/*.notes y estan anclados a
; direccion, de modo que sobreviven a un retrazado.
; ==========================================================================

	org 0x04000


; ----------------------------------------------------------------------
; DATOS cabecera_del_cartucho: La cabecera que lee la BIOS: "AB", INIT=0x404F
;   y a cero STATEMENT, DEVICE y TEXT. La BIOS mapea el cartucho en la pagina
;   1 (0x4000-0x7FFF) y salta a 0x404F al terminar de arrancar
;   0x4000..0x4010  (16 bytes)
DATA_cabecera_del_cartucho:
	defb 041h,042h	; 4000
	defw 0404fh,00000h,00000h,00000h	; 4002  -> INIT 0x0000 0x0000 0x0000
	defb 000h,000h,000h,000h,000h,000h	; 400a

; ======================================================================
; CODIGO 0x4010..0x4124  (276 bytes)
; ======================================================================


VPOKE:		; Escribe A en la VRAM DE
	call PREPARA_ESCRITURA		;4010   ; Manda la direccion y deja el puerto de datos en C'
	exx			;4013
	out (c),a		;4014   ; Y el byte por el registro alternativo, que es donde vive el puerto
	exx			;4016
	ei			;4017
	ret			;4018
VPEEK:		; Lee en A el byte de la VRAM DE
	call PREPARA_LECTURA		;4019
	exx			;401c
	in a,(c)		;401d   ; El otro puerto: el de lectura
	exx			;401f
	ei			;4020
	ret			;4021
HL_MAS_A:		; HL = HL + A, sin signo
	add a,l			;4022
	ld l,a			;4023
	ret nc			;4024
	inc h			;4025
	ret			;4026
DE_MAS_A:		; DE = DE + A, sin signo
	add a,e			;4027
	ld e,a			;4028
	ret nc			;4029
	inc d			;402a
	ret			;402b
L_402C:
	di			;402c
	call 0013eh		;402d   ; BIOS RDVDP - Reads VDP status register
	call EL_REPRODUCTOR		;4030   ; El sonido va antes del candado: suena aunque el paso anterior siga a medias
	ld hl,0e005h		;4033
	bit 0,(hl)		;4036   ; Candado echado: paso anterior sin terminar
	jr nz,L_404C		;4038
	inc (hl)			;403a
	ei			;403b   ; Con el candado echado ya se pueden admitir interrupciones (para el sonido)
	ld a,(0e002h)		;403c
	and 040h		;403f   ; Bit 6: hay partida en marcha
	call nz,LEE_LOS_MANDOS_DEL_JUEGO		;4041
	call PASO_DEL_JUEGO		;4044   ; Un paso del juego segun E000
	di			;4047
	xor a			;4048
	ld (0e005h),a		;4049
L_404C:
	ei			;404c
	reti		;404d

; ----------------------------------------------------------------------
; ######################################################################
; INIT. Pila en 0xE400, RAM 0xE000-0xE3FF a cero, `jp 0x402C` en el
; gancho H.KEYI (0xFD9A), VDP y PSG (44FD), la fuente (4626), y a
; esperar interrupciones para siempre en 0x4080.
; ######################################################################
; ----------------------------------------------------------------------
INIT:		; Arranque desde la cabecera: prepara RAM, gancho, VDP, PSG y fuente
	di			;404f
	im 1		;4050
	ld a,0c3h		;4052
	ld (0fd9ah),a		;4054
	ld hl,L_402C		;4057
	ld (0fd9bh),hl		;405a
	ld sp,0e400h		;405d
	ld hl,0e000h		;4060
	ld de,0e001h		;4063
	ld bc,003ffh		;4066
	ld (hl),000h		;4069
	ldir		;406b
	ld a,001h		;406d   ; Candado echado mientras dura el arranque: la interrupcion no ejecuta pasos
	ld (0e005h),a		;406f
	call ARRANCA_VDP_Y_PSG		;4072
	call CARGA_Y_REPARTE_LA_FUENTE		;4075
	xor a			;4078   ; Se abre el candado: la interrupcion ya corre el estado 0
	ld (0e005h),a		;4079
	call 0013eh		;407c   ; BIOS RDVDP - Reads VDP status register
	ei			;407f
ESPERA_ETERNA:		; Aqui se queda el programa principal; el juego es la interrupcion
	jr ESPERA_ETERNA		;4080

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; EL DESPACHADOR. Se llama con el indice en A y la tabla de palabras
; va PEGADA detras del CALL: el POP HL recoge la direccion de retorno,
; que es la tabla. Cinco: 0x4144 (20 estados), 0x41F8 (6 pasos del menu),
; 0x6016 (17 estados del jugador), 0x785D (4) y 0x7960 (4). Nunca vuelve al CALL.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
DESPACHA:		; Salta al destino A de la tabla de palabras que va detras del CALL
	add a,a			;4082
	pop hl			;4083   ; La direccion de retorno ES la tabla
	call HL_MAS_A		;4084
	ld e,(hl)			;4087
	inc hl			;4088
	ld d,(hl)			;4089
	ex de,hl			;408a
	jp (hl)			;408b
LEE_LOS_MANDOS_DEL_JUEGO:		; El joystick del jugador que toca y, si se juega con teclado, tambien las teclas
	call PUERTO_DEL_JOYSTICK		;408c
	bit 4,(hl)		;408f
	call nz,LEE_EL_TECLADO		;4091
GUARDA_MANDOS:		; Lo de ahora pasa a E009 y lo que habia baja a E008
	ld hl,0e009h		;4094   ; E009 es lo pulsado ahora; E008, lo del fotograma anterior
	ld c,(hl)			;4097   ; Lo que habia en E009 se aparta antes de pisarlo...
	ld (hl),a			;4098
	dec hl			;4099
	ld (hl),c			;409a   ; ...y baja a E008; asi 0x66EE puede ver el flanco del boton en vez de si esta pulsado
	ret			;409b
LEE_EL_TECLADO:		; Monta el mismo mapa de bits con las filas 7 y 8 de la matriz
	ld a,007h		;409c
	call 00141h		;409e   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	cpl			;40a1
	rrca			;40a2
	and 020h		;40a3   ; SELECT (bit 6 de la fila 7) al bit 5: el segundo boton
	ld e,a			;40a5
	ld a,008h		;40a6
	call 00141h		;40a8   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	cpl			;40ab
	rrca			;40ac
	rrca			;40ad
	ld b,a			;40ae
	and 004h		;40af   ; IZQUIERDA al bit 2
	or e			;40b1
	ld c,a			;40b2
	ld a,b			;40b3
	rrca			;40b4
	rrca			;40b5
	ld b,a			;40b6
	and 018h		;40b7   ; DERECHA al bit 3 y ESPACIO al bit 4
	or c			;40b9
	ld c,a			;40ba
	ld a,b			;40bb
	rrca			;40bc
	and 003h		;40bd   ; ARRIBA al bit 0 y ABAJO al bit 1
	or c			;40bf
	ret			;40c0
TRAS_EL_ESTADO_SIN_PARTIDA:		; Lo que corre detras de cada estado cuando no hay partida: una tecla lleva al menu, y en el menu elige
	ld hl,0e040h		;40c1   ; E040 y E041: lo pulsado ahora y en el fotograma anterior
	call LEE_LOS_MANDOS		;40c4
	ret z			;40c7   ; Sin tecla nueva no hay nada que hacer
	ld b,a			;40c8
	ld a,000h		;40c9
	ld (0e004h),a		;40cb   ; Cualquier tecla reinicia la espera del estado
	ld a,005h		;40ce
	ld hl,0e000h		;40d0
	cp (hl)			;40d3   ; Estado 5, el titulo con el menu ya puesto: aqui la tecla elige
	jr nz,L_40EF		;40d4
	ld a,b			;40d6
	cp 010h		;40d7   ; Por debajo de 0x10 no es el disparo: son las flechas, que mueven el cursor
	jr c,MUEVE_EL_CURSOR		;40d9
	ld hl,04124h		;40db
	ld a,(0e042h)		;40de   ; E042, la opcion sobre la que esta el cursor
	call HL_MAS_A		;40e1
	ld a,(hl)			;40e4
	ld (0e002h),a		;40e5   ; La opcion elegida se guarda en E002
	ld hl,00008h		;40e8   ; Una escritura de 16 bits deja E000=8 (el menu) y E001=0 (su primer paso)
	ld (0e000h),hl		;40eb
	ret			;40ee
L_40EF:
	ld (hl),a			;40ef   ; Fuera del estado 5, cualquier tecla salta al 5 y pinta el titulo entero de golpe
	jp MENU_0_PINTA		;40f0
MUEVE_EL_CURSOR:		; Las flechas suben o bajan la opcion (E042), dando la vuelta con el and 3
	push bc			;40f3
	call BORRA_EL_CURSOR_DEL_MENU		;40f4   ; El pitido de la tecla
	pop af			;40f7
	ld hl,0e042h		;40f8
	ld b,(hl)			;40fb
	rra			;40fc   ; Bit 0 (arriba): una opcion menos
	jr nc,L_4100		;40fd
	dec b			;40ff
L_4100:
	rra			;4100   ; Bit 1 (abajo): una mas
	jr nc,L_4104		;4101
	inc b			;4103
L_4104:
	ld a,b			;4104
	and 003h		;4105   ; Cuatro opciones: el cursor da la vuelta solo
	ld (hl),a			;4107
	ret			;4108
LEE_LOS_MANDOS:		; Junta los dos joysticks y el teclado en (HL), baja lo anterior a (HL+1) y devuelve lo que se ACABA de pulsar
	push hl			;4109
	ld e,08fh		;410a   ; Registro 15 del PSG con 0x8F: el joystick 1
	call LEE_EL_JOYSTICK		;410c
	ld d,a			;410f
	ld e,0cfh		;4110   ; Y con 0xCF: el joystick 2
	call LEE_EL_JOYSTICK		;4112
	or d			;4115
	ld d,a			;4116
	call LEE_EL_TECLADO		;4117   ; Y encima, el teclado
	or d			;411a
	pop hl			;411b
	ld c,(hl)			;411c   ; Lo que habia se aparta y baja a (HL+1)
	ld (hl),a			;411d
	inc hl			;411e
	ld (hl),c			;411f
	ld b,a			;4120
	xor c			;4121   ; Lo de ahora sin lo de antes: el flanco, o sea las teclas nuevas
	and b			;4122
	ret			;4123

; ----------------------------------------------------------------------
; DATOS opciones_por_tecla: Cuatro bytes que 0x40DB indexa con (0xE042) y
;   guarda en E002, las opciones de la partida: 0x40, 0x60, 0x50, 0x70
;   0x4124..0x4128  (4 bytes)
DATA_opciones_por_tecla:
	defb 040h,060h,050h,070h	; 4124

; ======================================================================
; CODIGO 0x4128..0x4144  (28 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; UN PASO DEL JUEGO. Cuenta el fotograma, refresca el rotulo 1P/2P
; si toca (472C), mira las teclas 1-4 fuera de la partida, y salta
; al estado E000 por la tabla de 0x4144.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
PASO_DEL_JUEGO:		; Cada fotograma: contador, parpadeo del 1P/2P, teclas 1-4 y el estado de turno
	ld hl,0e003h		;4128   ; E003, el contador de fotogramas: sube uno por interrupcion y de el cuelgan casi todos los ritmos del juego
	inc (hl)			;412b
	ld a,(0e002h)		;412c
	and 040h		;412f   ; Bit 6 de E002: el rotulo 1P/2P solo parpadea con partida en marcha
	ld hl,04735h		;4131
	jr nz,L_4139		;4134
	ld hl,040c1h		;4136
L_4139:
	ld a,(0e000h)		;4139   ; E000, el estado del juego, se guarda en C porque TECLAS_1_A_4 machaca A
	cp 008h		;413c   ; ...y por debajo del 8 tambien; del 8 al 17 son el menu y la partida, donde ya no se puede cambiar de opcion
	jr z,L_4141		;413e
	push hl			;4140
L_4141:
	call DESPACHA		;4141   ; Tabla de 20 estados justo detras

; ----------------------------------------------------------------------
; DATOS tabla_de_estados: Los 20 estados del juego, indice E000. 0 espera; 1-6
;   la secuencia del titulo (KONAMI que sube, VIDEO CARTRIDGE, el logotipo del
;   juego, PLAY SELECT, cortinilla); 7,18,19 la partida de demostracion; 8 el
;   menu; 9 vida nueva; 10 espera; 11 la partida; 12-14 muerte, cambio de
;   jugador y GAME OVER; 15 fase superada; 16,17 cambio de pantalla. Cierra
;   clavada contra su primer destino, 0x416C
;   0x4144..0x416c  (40 bytes)
DATA_tabla_de_estados:
	defw 0416ch	; 4144  -> ESTADO_00_ARRANCA
	defw 0416fh	; 4146  -> ESTADO_01_LOGO
	defw 04183h	; 4148  -> ESTADO_02_SUBE_LOGO
	defw 04196h	; 414a  -> ESTADO_03_ESPERA
	defw 041abh	; 414c  -> L_41AB
	defw 041b3h	; 414e  -> ESTADO_05_MENU_QUIETO
	defw 041bdh	; 4150  -> L_41BD
	defw 041c7h	; 4152  -> ESTADO_07_DEMO
	defw 041f2h	; 4154  -> ESTADO_08_MENU
	defw 042a1h	; 4156  -> ESTADO_09_VIDA_NUEVA
	defw 042d7h	; 4158  -> L_42D7
	defw 04300h	; 415a  -> ESTADO_11_EN_JUEGO
	defw 04320h	; 415c  -> ESTADO_12_MUERTE
	defw 04358h	; 415e  -> L_4358
	defw 04373h	; 4160  -> ESTADO_14_GAME_OVER
	defw 04391h	; 4162  -> L_4391
	defw 043dbh	; 4164  -> ESTADO_16_CAMBIA_PANTALLA
	defw 04418h	; 4166  -> ESTADO_17_PANTALLA_NUEVA
	defw 043dbh	; 4168  -> ESTADO_16_CAMBIA_PANTALLA
	defw 04427h	; 416a  -> L_4427

; ======================================================================
; CODIGO 0x416c..0x41f8  (140 bytes)
; ======================================================================


ESTADO_00_ARRANCA:		; Estado 0: no hace nada; pasa al 1
	jp ESTADO_SIGUIENTE		;416c
ESTADO_01_LOGO:		; Estado 1: si hace falta, la cortinilla (E00B); luego carga el logotipo KONAMI (4B52) y pasa al 2
	ld a,(0e00bh)		;416f   ; E00B lo pone a 1 el fin de la demo (0x41E5): antes del logotipo hay que borrar lo que hubiera
	or a			;4172
	jr z,L_417D		;4173
	call UNA_COLUMNA_DE_CORTINILLA		;4175   ; Una columna por fotograma; este estado se repite hasta que termine
	ret p			;4178   ; CORTINILLA vuelve positiva mientras le queden columnas
	xor a			;4179   ; Borrada del todo: se apaga la peticion y el logotipo se carga en este mismo fotograma
	ld (0e00bh),a		;417a
L_417D:
	call CARGA_LOGO_KONAMI		;417d   ; Descomprime los 26 tiles del KONAMI grande y prepara la subida
	jp ESTADO_SIGUIENTE		;4180
ESTADO_02_SUBE_LOGO:		; Estado 2: cada dos fotogramas sube una fila el KONAMI (4B75); al llegar arriba pinta VIDEO CARTRIDGE y espera 80 fotogramas en el 3
	ld a,(0e003h)		;4183
	rra			;4186   ; Un fotograma si y otro no
	ret nc			;4187
	call SUBE_LOGO_KONAMI		;4188
	ret nz			;418b
	ld hl,04c9ah		;418c   ; "@ VIDEO CARTRIDGE @" en la fila 11
	call PINTA_LISTA		;418f
	xor a			;4192
	jp ESPERA_A_Y_SIGUIENTE		;4193
ESTADO_03_ESPERA:		; Espera los fotogramas de E004, dibuja el titulo y pasa al estado 4
	ld hl,0e004h		;4196
	dec (hl)			;4199
	ret nz			;419a
	call PANTALLA_DEL_TITULO		;419b
	ld de,03880h		;419e   ; Y borra las tres filas de debajo del logotipo
	ld bc,00060h		;41a1
	xor a			;41a4
	call RELLENA_VRAM		;41a5
	jp ESTADO_SIGUIENTE		;41a8
L_41AB:
	call TITULO_COLUMNA		;41ab
	ret c			;41ae
	xor a			;41af   ; E004 = 0: el estado 5 esperara 256 fotogramas
	jp ESPERA_A_Y_SIGUIENTE		;41b0
ESTADO_05_MENU_QUIETO:		; Estado 5: 256 fotogramas con el titulo y el menu; luego cortinilla en el 6
	ld hl,0e004h		;41b3
	dec (hl)			;41b6
	jp nz,PINTA_EL_CURSOR_DEL_MENU		;41b7
	jp L_43D1		;41ba
L_41BD:
	call UNA_COLUMNA_DE_CORTINILLA		;41bd   ; Otra vez una columna por fotograma
	ret p			;41c0
	call PREPARA_DEMO		;41c1   ; Ya borrada: fuente, graficos del juego, partida nueva, marcador y la primera pantalla
	jp ESTADO_SIGUIENTE		;41c4   ; Al estado 7, la partida de demostracion, sin espera ninguna
ESTADO_07_DEMO:		; Estado 7: un fotograma de la partida de demostracion (58B2). Si muere, vuelve al titulo por el 1; si sale de la pantalla, cambia de pantalla por el 18
	call FOTOGRAMA_DE_DEMO		;41c7
	ld hl,0e00ch		;41ca
	xor a			;41cd
	cp (hl)			;41ce   ; E00C: ha muerto
	jr nz,DEMO_TERMINA		;41cf
	inc hl			;41d1
	inc hl			;41d2
	cp (hl)			;41d3   ; E00E: se ha salido de la pantalla
	ret z			;41d4
	ld a,(0e054h)		;41d5
	cp 007h		;41d8
	jp z,DEMO_TERMINA		;41da
	ld a,011h		;41dd   ; Estado 17+1 = 18: cambio de pantalla de la demo
	ld (0e000h),a		;41df
	jp L_43D1		;41e2
DEMO_TERMINA:		; Vuelve al estado 1 pidiendo cortinilla (E00B)
	ld a,001h		;41e5
	ld (0e00bh),a		;41e7
	xor a			;41ea
	ld (hl),a			;41eb
ESTADO_A_MAS_UNO:		; Pone el estado A, E004 = 80 y suma 1 (igual que 0x43CE)
	ld (0e000h),a		;41ec
	jp L_43D1		;41ef
ESTADO_08_MENU:		; Estado 8: el menu, en dos pasos por E001
	ld a,(0e001h)		;41f2
	call DESPACHA		;41f5

; ----------------------------------------------------------------------
; DATOS tabla_del_menu: Los seis pasos del menu: 0x4204, 0x421A, 0x4248,
;   0x4259, 0x425F y 0x426B (PENDIENTE: describir cada paso)
;   0x41f8..0x4204  (12 bytes)
DATA_tabla_del_menu:
	defw 04204h	; 41f8  -> MENU_0_PINTA
	defw 0421ah	; 41fa  -> MENU_1_PARPADEA
	defw 04248h	; 41fc  -> MENU_2_ARRANCA
	defw 04259h	; 41fe  -> L_4259
	defw 0425fh	; 4200  -> L_425F
	defw 0426bh	; 4202  -> MENU_5_NOMBRE

; ======================================================================
; CODIGO 0x4204..0x44a3  (671 bytes)
; ======================================================================


MENU_0_PINTA:		; Paso 0: cortinilla entera de golpe, titulo y menu de una vez, la musica del menu (0x9C) y 80 fotogramas para elegir
	ld a,050h		;4204
	ld (0e004h),a		;4206
MENU_CORTINILLA_BUCLE:		; La cortinilla entera, columna a columna, sin salir
	call BORRA_LA_PANTALLA_DE_JUEGO		;4209   ; La cortinilla completa dentro de este mismo fotograma
	call PANTALLA_DEL_TITULO		;420c
	call TITULO_DE_GOLPE		;420f   ; Titulo, KONAMI 1984 y menu de golpe
	ld bc,05e5fh		;4212
	call PINTA_EL_CURSOR_EN_SU_FILA		;4215
	jr L_4243		;4218
MENU_1_PARPADEA:		; Mientras baja E004, la opcion elegida parpadea; al llegar a cero se pasa al paso siguiente
	ld hl,0e004h		;421a
	dec (hl)			;421d   ; E004 baja un fotograma cada vez
	jr z,L_423B		;421e
	bit 3,(hl)		;4220   ; El bit 3 dice si toca pintar el cursor o borrarlo: parpadea cada ocho
	jp z,L_4883		;4222
	call CASILLA_DE_LA_OPCION		;4225
	inc de			;4228
	inc de			;4229
	ld bc,0001bh		;422a   ; 27 casillas: la linea entera de la opcion
	xor a			;422d
	jp RELLENA_VRAM		;422e
TITULO_DE_GOLPE:		; Saca el logotipo entero sin esperar, columna a columna, y detras el resto de la pantalla
	xor a			;4231
	ld (0e00ah),a		;4232
L_4235:
	call TITULO_COLUMNA		;4235
	jr c,L_4235		;4238
	ret			;423a
L_423B:
	call ALL_STAGE_CLEAR_ESPERA		;423b
L_423E:
	ld a,020h		;423e
	ld (0e004h),a		;4240
L_4243:
	ld hl,0e001h		;4243
	inc (hl)			;4246
	ret			;4247
MENU_2_ARRANCA:		; Cortinilla, sube los sprites de la pantalla y suena la musica
	call CORTINILLA		;4248
	ret p			;424b   ; Una columna por fotograma: hasta que no acabe no sigue
	call CARGA_LOS_SPRITES		;424c
	call PINTA_EL_CURSOR_DEL_NOMBRE		;424f
	ld a,092h		;4252
	call SONIDO		;4254
	jr L_4243		;4257
L_4259:
	call PANTALLA_DE_COLOCAR		;4259
	ret nc			;425c
	jr L_423E		;425d
L_425F:
	call CORTINILLA		;425f
	ret p			;4262
	call PREPARA_EL_MARCADOR		;4263
	call PINTA_LA_PANTALLA_DEL_NOMBRE		;4266
	jr L_4243		;4269
MENU_5_NOMBRE:		; La pantalla del nombre; al terminarla, si juegan dos, le toca al otro, y si no, empieza la partida
	call PANTALLA_DEL_NOMBRE		;426b
	ret nc			;426e   ; Sin acarreo, la pantalla sigue en marcha
	ld a,(0e002h)		;426f
	bit 5,a		;4272   ; Bit 5 de E002: dos jugadores
	jr z,L_4283		;4274
	call ESTADO_13_CAMBIO_TURNO		;4276   ; Cambio de turno: el segundo pone tambien el suyo
	rla			;4279
	jr nc,L_4283		;427a
	ld a,001h		;427c   ; E001 = 1: la pantalla del nombre otra vez, ahora para el otro
	ld (0e001h),a		;427e
	jr L_423E		;4281
L_4283:
	ld a,0a2h		;4283
	call SONIDO		;4285
	xor a			;4288
	ld (0e001h),a		;4289
	call BORRA_LA_PANTALLA_DE_JUEGO		;428c
	ld a,08fh		;428f
	call SONIDO		;4291
	ld bc,0e201h		;4294
	call 00047h		;4297   ; BIOS WRTVDP - Writes data in the VDP-register
	call CARGA_GRAFICOS_JUEGO		;429a
	xor a			;429d
	jp ESPERA_A_Y_SIGUIENTE		;429e   ; 80 fotogramas y al estado 9
ESTADO_09_VIDA_NUEVA:		; Estado 9: tras la cortinilla, una vida menos, fuente y decorado, marcador, PLAYER n si son dos, y BONUS SCORE 2000 o los creditos si viene de superar fase
	call CORTINILLA		;42a1
	ret p			;42a4
	ld hl,0e050h		;42a5
	dec (hl)			;42a8   ; Una vida menos
	call CARGA_LOS_TILES_DE_LA_PANTALLA		;42a9
	call MARCADOR		;42ac
	ld a,(0e001h)		;42af
	or a			;42b2
	ld hl,04c91h		;42b3   ; "PLAYER" y el numero, solo cuando E001 vale 0. OJO: eso NO es "solo con dos jugadores". E001 es el subestado, y quien lo pone a 0x20 con un jugador es SUBESTADO_POR_JUGADORES (0x4469), que solo la llaman el estado 12 (muerte, 0x4353) y el 15 (fase superada, 0x43BE). La primera vez que se entra aqui viene del menu por 0x4288, que deja E001 a 0 sin mirar cuantos juegan: al empezar la partida sale PLAYER 1 aunque se juegue solo
	call z,ROTULO_Y_JUGADOR		;42b6
	ld hl,0e00dh		;42b9
	xor a			;42bc
	cp (hl)			;42bd   ; E00D: se viene de superar una fase
	jr z,L_42D2		;42be
	ld (hl),a			;42c0
	ld a,009h		;42c1
	call SONIDO		;42c3
	ld hl,04cb0h		;42c6   ; "BONUS SCORE 2000" en la fila 12
	call PINTA_LISTA		;42c9
	ld de,02000h		;42cc   ; 2000 puntos
	call SUMA_PUNTOS		;42cf
L_42D2:
	ld a,020h		;42d2
	jp ESPERA_A_Y_SIGUIENTE		;42d4
L_42D7:
	ld a,(0e01dh)		;42d7
	or a			;42da
	ret nz			;42db
ESTADO_10_ESPERA:		; Estado 10: pasada la espera, sonido de salida, borra las filas 9 y 12, arranca la pantalla (5857) y entra en juego
	ld hl,0e004h		;42dc
	dec (hl)			;42df
	ret nz			;42e0
	ld a,08dh		;42e1
	call SONIDO		;42e3
	xor a			;42e6
	ld de,03920h		;42e7   ; Fila 9: PLAYER n
	ld bc,00020h		;42ea
	call RELLENA_VRAM		;42ed
	ld de,03980h		;42f0   ; Fila 12: BONUS SCORE
	ld bc,00020h		;42f3
	xor a			;42f6
	call RELLENA_VRAM		;42f7
	call MONTA_PANTALLA		;42fa
	jp L_43D1		;42fd
ESTADO_11_EN_JUEGO:		; Estado 11: un fotograma de partida (585E) y mira como acabo: muerte (E00C) al 12, fase superada (E00D) al 15, cambio de pantalla (E00E) al 16
	call UN_FOTOGRAMA_DE_PARTIDA		;4300
	ld hl,0e00ch		;4303
	xor a			;4306
	cp (hl)			;4307   ; E00C: ha muerto
	jp nz,L_43D1		;4308
	inc hl			;430b
	cp (hl)			;430c   ; E00D: fase superada
	jr nz,A_FASE_SUPERADA		;430d
	inc hl			;430f
	cp (hl)			;4310   ; E00E: sale de la pantalla
	ret z			;4311
	ld a,00fh		;4312   ; 15+1 = 16: cambio de pantalla
	ld (0e000h),a		;4314
	jp L_43D1		;4317
A_FASE_SUPERADA:		; Al estado 15
	ld a,00fh		;431a
	ld (0e000h),a		;431c
	ret			;431f
ESTADO_12_MUERTE:		; Estado 12: con vidas, sonido de muerte y vida nueva (o turno del otro); sin vidas, GAME OVER y al 14
	xor a			;4320
	ld (0e00ch),a		;4321
	ld a,(0e050h)		;4324
	or a			;4327   ; Quedan vidas
	jr nz,L_4342		;4328
	call CORTINILLA		;432a
	ret p			;432d
	ld a,09bh		;432e
	call SONIDO		;4330
	ld hl,04c84h		;4333   ; "GAME  OVER" en la fila 11 y "PLAYER n" en la 9
	call ROTULO_Y_JUGADOR		;4336
	ld a,00dh		;4339   ; 13+1 = 14: la espera del GAME OVER
	ld (0e000h),a		;433b
	xor a			;433e
	jp ESPERA_A_Y_SIGUIENTE		;433f
L_4342:
	ld a,098h		;4342
	call SONIDO		;4344
	ld a,(0e080h)		;4347   ; Vidas del otro jugador
	or a			;434a
	ld hl,0e001h		;434b
	ld (hl),000h		;434e
	jp nz,ESTADO_SIGUIENTE		;4350
	call SUBESTADO_POR_JUGADORES		;4353
	jr L_435E		;4356
L_4358:
	call ESTADO_13_CAMBIO_TURNO		;4358
	call PUERTO_DEL_JOYSTICK		;435b
L_435E:
	jr A_VIDA_NUEVA		;435e
ESTADO_13_CAMBIO_TURNO:		; Estado 13: intercambia los 32 bytes de los dos jugadores, cambia el bit 7 de E002 y el puerto del joystick, y vida nueva por el 9
	ld hl,0e050h		;4360
	ld de,0e080h		;4363
	ld b,020h		;4366
	call INTERCAMBIA		;4368
	ld hl,0e002h		;436b
	ld a,(hl)			;436e
	xor 080h		;436f   ; Cambia de jugador
	ld (hl),a			;4371
	ret			;4372
ESTADO_14_GAME_OVER:		; Estado 14: 256 fotogramas de GAME OVER; luego el turno del otro (13) o vuelta al titulo con cortinilla (E00B)
	ld hl,0e004h		;4373
	dec (hl)			;4376
	ret nz			;4377
	ld a,(0e080h)		;4378   ; Si el otro jugador tiene vidas, sigue el
	or a			;437b
	ld a,00ch		;437c
	jr nz,CAMBIA_ESTADO_ESPERA		;437e
	ld hl,0e002h		;4380
	res 6,(hl)		;4383   ; Se acabo la partida
	ld a,050h		;4385
	ld (0e004h),a		;4387
	ld (0e00bh),a		;438a
	xor a			;438d
	jp CAMBIA_ESTADO_ESPERA		;438e
L_4391:
	ld a,(0e012h)		;4391   ; E012: canal A ocupado, la musica sigue sonando
	or a			;4394
	ret nz			;4395
	ld a,(0e003h)		;4396
	and 003h		;4399   ; Cada cuatro fotogramas
	ret nz			;439b
	ld a,(0e055h)		;439c
	cp 002h		;439f   ; Tiempo agotado
	jr z,FASE_SIGUIENTE		;43a1
	ld de,00200h		;43a3   ; 200 puntos por cada tramo de tiempo
	call SUMA_PUNTOS_CON_SONIDO		;43a6
	jp TIEMPO_UN_TRAMO_MENOS		;43a9
FASE_SIGUIENTE:		; Una vida mas, fase+1 en BCD, la meta diez SCENE mas alla (E05A), y el tiempo lleno (0x3A) para la fase nueva
	ld hl,0e050h		;43ac
	inc (hl)			;43af
	inc hl			;43b0
	ld a,(hl)			;43b1
	add a,001h		;43b2
	daa			;43b4
	ld (hl),a			;43b5
	ld hl,0e05ah		;43b6
	ld a,(hl)			;43b9
	add a,010h		;43ba
	daa			;43bc
	ld (hl),a			;43bd
	call SUBESTADO_POR_JUGADORES		;43be
	ld a,03ah		;43c1
	ld (0e055h),a		;43c3   ; Tiempo lleno: 0x3A tramos
	ld hl,0383eh		;43c6   ; La barra de tiempo empieza en la fila 1, columna 30
	ld (0e056h),hl		;43c9
A_VIDA_NUEVA:		; Estado 9 con 80 fotogramas de espera
	ld a,008h		;43cc
CAMBIA_ESTADO_ESPERA:		; Pone el estado A, E004 = 80 y suma 1
	ld (0e000h),a		;43ce
L_43D1:
	ld a,020h		;43d1
ESPERA_A_Y_SIGUIENTE:		; E004 = A y estado siguiente
	ld (0e004h),a		;43d3
ESTADO_SIGUIENTE:		; E000 + 1
	ld hl,0e000h		;43d6
	inc (hl)			;43d9
	ret			;43da
ESTADO_16_CAMBIA_PANTALLA:		; Cortinilla, y al acabarla el SCENE sube o baja segun por donde se haya salido
	xor a			;43db
	ld (0e00fh),a		;43dc   ; E00F a cero: el recuadro del SCENE se borra como el resto
	call CORTINILLA		;43df
	ret p			;43e2
	ld hl,0e00eh		;43e3   ; Bit 1 de E00E: salio por la derecha; se cruza con el sentido (bit 0 de E053)
	ld b,(hl)			;43e6
	ld (hl),000h		;43e7
	ld hl,0e053h		;43e9
	ld a,(hl)			;43ec
	bit 1,b		;43ed
	jr z,L_43F2		;43ef
	cpl			;43f1
L_43F2:
	inc hl			;43f2
	rra			;43f3   ; Por la derecha con sentido 0, o por la izquierda con sentido 1: SCENE+1; si no, SCENE-1
	jr c,L_4405		;43f4
	dec (hl)			;43f6   ; Retrocede: al bajar de 1 se queda en 1 y cambia el sentido
	ld a,(hl)			;43f7
	jr z,L_43FD		;43f8
	inc a			;43fa   ; Y al pasarse por arriba, igual
	jr nz,L_4403		;43fb
L_43FD:
	ld a,001h		;43fd
	ld (hl),a			;43ff
	dec hl			;4400
	xor (hl)			;4401
	ld (hl),a			;4402
L_4403:
	jr L_4413		;4403
L_4405:
	inc (hl)			;4405   ; Avanza: si se pasa de 255, a 56
	jr nz,L_440A		;4406
	ld (hl),038h		;4408
L_440A:
	ld a,(0e000h)		;440a
	cp 012h		;440d
	jr nz,L_4413		;440f
	ld (hl),007h		;4411
L_4413:
	call SCENE_A_BCD		;4413   ; SCENE a BCD para el marcador
	jr L_43D1		;4416
ESTADO_17_PANTALLA_NUEVA:		; Estado 17: monta la pantalla nueva (5A64, 5AE3), pinta el SCENE y vuelve al juego (11)
	call BORRA_PANTALLA		;4418   ; Borra el estado EN RAM de la pantalla anterior (E130-E330); el decorado ya lo borro la cortinilla del estado 16
	call CONSTRUYE_PANTALLA		;441b   ; Monta la pantalla nueva entera: sprites, lianas, decorado y obstaculos
	call PINTA_SCENE		;441e   ; El SCENE nuevo en el recuadro de abajo a la derecha
	ld a,00bh		;4421   ; Vuelta al estado 11, el de jugar, sin espera ninguna
	ld (0e000h),a		;4423
	ret			;4426
L_4427:
	call BORRA_PANTALLA		;4427   ; Igual que el estado 17, pero aqui si hay que repintar el marcador...
	call MARCADOR		;442a   ; ...porque en la demo el bit 6 de E002 esta apagado y la cortinilla borra las 24 filas, no solo las 19 de en medio
	call CONSTRUYE_PANTALLA		;442d
	ld a,006h		;4430   ; Estado 6+1 = 7 con 80 fotogramas de espera: sigue la demo
	jp CAMBIA_ESTADO_ESPERA		;4432
ROTULO_Y_JUGADOR:		; Pinta la lista HL y el numero del jugador (1 o 2, bit 7 de E002) en la fila 9, columna 19
	call PINTA_LISTA		;4435
	ld a,(0e002h)		;4438
	rlca			;443b   ; Bit 7 al bit 0: 0 o 1
	and 001h		;443c
	add a,031h		;443e   ; '1' o '2'
	ld de,03933h		;4440
	call VPOKE		;4443
	ret			;4446
SCENE_A_BCD:		; E059 = E054 en BCD (dos cifras: E054 modulo 100)
	ld a,(0e054h)		;4447
	call SCENE_A_BCD_RESTA_100		;444a
	ld (0e059h),a		;444d
	ret			;4450
SCENE_A_BCD_RESTA_100:		; Quita centenas
	ld b,a			;4451
	sub 064h		;4452
	jr nc,SCENE_A_BCD_RESTA_100		;4454
	ld c,000h		;4456
SCENE_A_BCD_DECENAS:		; Cuenta decenas en el nibble alto de C
	ld a,b			;4458   ; Lo que quedo tras quitar las centenas, de diez en diez
	sub 00ah		;4459
	jr c,L_4466		;445b   ; Por debajo de diez, lo que queda son las unidades y ya estan en B
	push af			;445d
	ld a,c			;445e
	add a,010h		;445f   ; Cada resta suma una decena al nibble alto de C
	ld c,a			;4461
	pop af			;4462
	ld b,a			;4463
	jr nz,SCENE_A_BCD_DECENAS		;4464   ; El pop af ha devuelto las banderas del sub: se para justo cuando el resto da cero
L_4466:
	ld a,c			;4466
	or b			;4467
	ret			;4468
SUBESTADO_POR_JUGADORES:		; E001 = 0x20 con un jugador, 0 con dos (con dos se pinta PLAYER n)
	ld hl,0e001h		;4469   ; E001, el subestado, que en la partida solo dice si hay que pintar PLAYER n
	ld a,(0e002h)		;446c   ; Bit 5 de E002: dos jugadores
	xor 020h		;446f   ; Se invierte y se aisla: con dos jugadores queda 0 y con uno 0x20
	and 020h		;4471
	ld (hl),a			;4473   ; Y el estado 9 saca el rotulo PLAYER solo cuando E001 vale 0
	ret			;4474
ALL_STAGE_CLEAR_ESPERA:		; Al estado 10 con E004 = 0
	xor a			;4475
	ld (0e00eh),a		;4476
PARTIDA_NUEVA:		; Borra E043-E142, copia los 11 valores iniciales a E050 y, con dos jugadores, tambien a E080
	ld hl,0e049h		;4479   ; Desde E043, los puntos del 1P; el record (E040-E042) se salva
	ld de,0e04ah		;447c
	ld bc,00100h		;447f   ; 0x100 bytes mas el propio E043: se borra hasta E143
	ld (hl),000h		;4482
	ldir		;4484
	ld hl,044a3h		;4486   ; Los once valores de arranque al jugador que va a jugar
	ld de,0e050h		;4489
	ld bc,00017h		;448c
	ldir		;448f
	ld a,(0e002h)		;4491
	bit 5,a		;4494   ; Bit 5: dos jugadores
	ret z			;4496   ; Con un solo jugador no hay copia que hacer
	ld hl,0e050h		;4497   ; Con dos, los 32 bytes de E050 se clonan en E080: el segundo arranca igual
	ld de,0e080h		;449a
	ld bc,00020h		;449d
	ldir		;44a0
	ret			;44a2

; ----------------------------------------------------------------------
; DATOS valores_iniciales: Los 23 bytes que 0x4486 copia a 0xE050 con un ldir
;   de 0x17 para arrancar al jugador: 3 vidas, fase 1, tiempo 0x3A... y, desde
;   0xE05D, los diez tiles del NOMBRE, que de fabrica son ANNA LEE (el 0x5B se
;   pinta en blanco)
;   0x44a3..0x44ba  (23 bytes)
DATA_valores_iniciales:
	defb 003h,001h,000h,000h,000h,03ah,03eh,038h,008h,000h,010h,000h,010h	; 44a3  .....:>8.....
	defb 05bh,041h,04eh,04eh,041h,05bh,04ch,045h,045h,05bh	; 44b0  [ANNA[LEE[

; ======================================================================
; CODIGO 0x44ba..0x44f1  (55 bytes)
; ======================================================================


ARRANCA_VDP_Y_PSG:		; Registros del VDP, mezclador del PSG (0xB8), puerto del joystick, volumenes a cero y VRAM entera a cero
	call REGISTROS_DEL_VDP		;44ba
	ld a,0b8h		;44bd
	call ESCRIBE_EL_MEZCLADOR		;44bf
	ld a,0a2h		;44c2
	call SONIDO		;44c4
	ld de,00000h		;44c7   ; Los 16 KB de VRAM a cero
	ld bc,04000h		;44ca
	xor a			;44cd
	call RELLENA_VRAM		;44ce
	ret			;44d1
L_44D2:
	ld (0e03fh),a		;44d2
	jr MANDA_REGISTROS_VDP		;44d5
REGISTROS_DEL_VDP:		; Copia los 8 valores de 0x44F1 a E038 y los manda al VDP
	ld hl,044f1h		;44d7
	ld de,0e038h		;44da
	ld bc,00008h		;44dd
	ldir		;44e0
MANDA_REGISTROS_VDP:		; Manda al VDP los 8 registros guardados en E038
	ld hl,0e038h		;44e2
	ld d,008h		;44e5
L_44E7:
	ld b,(hl)			;44e7
	call 00047h		;44e8   ; BIOS WRTVDP - Writes data in the VDP-register
	inc hl			;44eb
	inc c			;44ec
	dec d			;44ed
	jr nz,L_44E7		;44ee
	ret			;44f0

; ----------------------------------------------------------------------
; DATOS registros_del_vdp: Los 8 valores que 0x44D7 copia a 0xE038 y manda al
;   VDP: R0=02 SCREEN 2, R1=E2, R2=0E nombres en 0x3800, R3=FF, R4=03, R5=76,
;   R6=03, R7=E1
;   0x44f1..0x44f9  (8 bytes)
DATA_registros_del_vdp:
	defb 002h	; 44f1
	defb 0e2h	; 44f2
	defb 00eh	; 44f3
	defb 07fh	; 44f4
	defb 007h	; 44f5
	defb 076h	; 44f6
	defb 003h	; 44f7
	defb 0e1h	; 44f8

; ======================================================================
; CODIGO 0x44f9..0x4792  (665 bytes)
; ======================================================================


SUBE_LOS_ATRIBUTOS:		; Los 128 bytes de fichas de sprite de E0B0 a la VRAM 0x3B00
	ld hl,0e0b0h		;44f9
	ld de,03b00h		;44fc
	ld bc,00080h		;44ff
COPIA_A_VRAM:		; BC bytes de HL a la VRAM DE
	di			;4502
	call PREPARA_ESCRITURA		;4503   ; La direccion de destino, por la BIOS
COPIA_A_VRAM_BUCLE:		; El bucle de salida, con la direccion ya puesta
	ld a,(hl)			;4506
	exx			;4507
	out (c),a		;4508   ; El puerto de datos vive en el C alternativo
	exx			;450a
	inc hl			;450b
	dec bc			;450c
	ld a,b			;450d
	or c			;450e
	jr nz,COPIA_A_VRAM_BUCLE		;450f
	ei			;4511   ; El di solo tapaba el poner la direccion; a partir de aqui ya se puede interrumpir
	ret			;4512
BORRA_LA_PANTALLA_DE_JUEGO:		; Aparca 32 sprites y deja la tabla de nombres a cero
	ld hl,0e0b0h		;4513
	ld b,020h		;4516
	call APARCA_SPRITES		;4518   ; Los 32 sprites, fuera de la pantalla
	ld de,07800h		;451b   ; Y las 768 casillas de la tabla de nombres a cero
	ld bc,00300h		;451e
	xor a			;4521
RELLENA_VRAM:		; BC casillas de la VRAM DE con el valor de A
	call PREPARA_ESCRITURA		;4522
L_4525:
	ex af,af'			;4525
RELLENA_VRAM_BUCLE:		; Escribe A en BC casillas seguidas
	ex af,af'			;4526   ; El valor viaja en el A alternativo para no perderlo con los exx
	exx			;4527
	out (c),a		;4528
	exx			;452a
	ex af,af'			;452b
	dec bc			;452c
	ld a,b			;452d
	or c			;452e
	jr nz,RELLENA_VRAM_BUCLE		;452f
	ei			;4531   ; Las interrupciones vuelven al salir; el di solo tapaba el poner la direccion
	ret			;4532
L_4533:
	ld a,(hl)			;4533
	inc hl			;4534
	jr L_4525		;4535
COPIA_VRAM_A_VRAM:		; BC bytes de la VRAM DE a la VRAM HL, byte a byte
	call VPEEK		;4537   ; Un byte de la VRAM DE...
	ex de,hl			;453a
	call VPOKE		;453b   ; ...a la VRAM HL; VPEEK y VPOKE mandan la direccion cada vez
	ex de,hl			;453e
	inc hl			;453f
	inc de			;4540
	dec bc			;4541
	ld a,c			;4542
	or b			;4543
	jr nz,COPIA_VRAM_A_VRAM		;4544
	ret			;4546
TRIPLICA_PATRONES:		; Copia el primer tercio de la tabla de patrones (0x2000) a los otros dos
	ld de,02000h		;4547
	ld hl,02800h		;454a
L_454D:
	ld bc,00800h		;454d
	call COPIA_VRAM_A_VRAM		;4550
	ld bc,00800h		;4553
	jr COPIA_VRAM_A_VRAM		;4556
TRIPLICA_TODO:		; Reparte patrones y colores por los tres tercios de la pantalla
	call TRIPLICA_PATRONES		;4558
TRIPLICA_COLORES:		; Lo mismo con la tabla de colores (0x0000)
	ld de,00000h		;455b
	ld hl,00800h		;455e
	jr L_454D		;4561
UNA_COLUMNA_DE_CORTINILLA:		; Un paso de la cortinilla: baja el contador y borra la columna que toque
	ld hl,0e003h		;4563
	dec (hl)			;4566
	inc hl			;4567
	ld b,018h		;4568
	dec (hl)			;456a   ; Se acabo: negativo
	ret m			;456b
	ld a,(hl)			;456c
	srl a		;456d
	jr c,L_4573		;456f
	xor 01fh		;4571
L_4573:
	ld e,a			;4573
	ld d,038h		;4574
L_4576:
	xor a			;4576
	call VPOKE		;4577
	ld a,020h		;457a
	call DE_MAS_A		;457c
	djnz L_4576		;457f
	ld de,03b00h		;4581   ; 0xD0 en el primer atributo: ningun sprite se pinta
	ld a,0d0h		;4584
	call VPOKE		;4586
	xor a			;4589
	ret			;458a
CORTINILLA:		; Borra la pantalla por columnas desde el centro, una por fotograma, y al final aparca los sprites
	ld hl,0e003h		;458b   ; E003 y E004 bajan a la vez: el fotograma y la columna
	dec (hl)			;458e
	inc hl			;458f
	dec (hl)			;4590
	ret m			;4591   ; Con la columna en negativo se ha acabado
	ld d,038h		;4592
	ld a,(0e000h)		;4594   ; E000: en el menu la cortinilla es de 16 filas y desde otra columna
	cp 008h		;4597   ; En el menu (estado 8) la cortinilla es distinta: 16 filas y desde otra columna
	jr nz,L_45A3		;4599
	inc d			;459b
	ld a,(hl)			;459c
	xor 01fh		;459d   ; El xor 0x1F hace que las columnas salgan del centro hacia fuera
	ld c,010h		;459f
	jr L_45B2		;45a1
L_45A3:
	ld a,(0e058h)		;45a3   ; En juego, por donde entra el jugador decide de que lado se abre
	ld b,05fh		;45a6
	cp 0e8h		;45a8
	jr nz,L_45AE		;45aa
	ld b,040h		;45ac
L_45AE:
	ld a,(hl)			;45ae
	xor b			;45af
	ld c,013h		;45b0   ; Diecinueve filas: la pantalla entera menos el marcador
L_45B2:
	ld e,a			;45b2
	ld b,c			;45b3
	xor a			;45b4
BORRA_UNA_COLUMNA:		; B casillas de la columna, de 32 en 32
	call VPOKE		;45b5
	ld hl,00020h		;45b8   ; Treinta y dos: una fila entera
	add hl,de			;45bb
	ex de,hl			;45bc
	djnz BORRA_UNA_COLUMNA		;45bd
	ld a,(0e000h)		;45bf   ; En el menu la cortinilla no aparca los sprites: los necesita el cursor
	cp 008h		;45c2
	jr nz,L_45CC		;45c4
	ld a,(0e001h)		;45c6
	cp 004h		;45c9
	ret z			;45cb
L_45CC:
	ld b,019h		;45cc
	ld hl,0e0b8h		;45ce
	call APARCA_SPRITES		;45d1
	ld b,001h		;45d4
	ld hl,0e12ch		;45d6
APARCA_SPRITES:		; Pone la Y de B sprites en 0xC3, que en el MSX es fuera de la pantalla
	ld (hl),0c3h		;45d9   ; 0xC3: por debajo del borde de abajo
	ld a,004h		;45db   ; De cuatro en cuatro: solo la Y de cada sprite
	call HL_MAS_A		;45dd
	djnz APARCA_SPRITES		;45e0
	call SUBE_LOS_ATRIBUTOS		;45e2
	xor a			;45e5
	ret			;45e6
PINTA_LISTA:		; Pinta una lista de rotulos: palabra de VRAM y tiles hasta 0xFF; 0xFE cambia de direccion
	ld e,(hl)			;45e7
	inc hl			;45e8
	ld d,(hl)			;45e9
	inc hl			;45ea
PINTA_LISTA_TILES:		; El bucle de tiles con DE ya puesto
	ld a,(hl)			;45eb
	inc hl			;45ec
	ld b,a			;45ed
	inc b			;45ee   ; 0xFF: fin
	ret z			;45ef
	inc b			;45f0   ; 0xFE: sigue otra direccion
	jr z,PINTA_LISTA		;45f1
	call VPOKE		;45f3
	inc de			;45f6
	jr PINTA_LISTA_TILES		;45f7
INTERCAMBIA:		; Cambia B bytes entre (HL) y (DE)
	ld c,(hl)			;45f9   ; Un byte de cada lado por vuelta, con C de apoyo
	ld a,(de)			;45fa
	ld (hl),a			;45fb
	ld a,c			;45fc
	ld (de),a			;45fd
	inc hl			;45fe
	inc de			;45ff
	djnz INTERCAMBIA		;4600
	ret			;4602
PUERTO_DEL_JOYSTICK:		; Registro 15 del PSG: el joystick 1 o el 2 segun el bit 7 de E002
	ld e,08fh		;4603
	ld hl,0e002h		;4605
	bit 7,(hl)		;4608
	jr z,LEE_EL_JOYSTICK		;460a
	set 6,e		;460c
LEE_EL_JOYSTICK:		; Escribe el registro 15, lee el 14 y devuelve las seis teclas en positivo
	ld a,00fh		;460e
	call 00093h		;4610   ; BIOS WRTPSG - Writes data to PSG-register
	ld a,00eh		;4613
	di			;4615
	call 00096h		;4616   ; BIOS RDPSG - Reads value from PSG-register
	ei			;4619
	cpl			;461a
	and 03fh		;461b
	ret			;461d
CARGA_FUENTE:		; Colores blancos (0xF0) y patrones de la fuente (0x4A37, 48 tiles 0x30-0x5F) y los triplica a los tres tercios
	ld a,0f0h		;461e   ; Blanco sobre transparente para los tiles 0x30-0x5F
	ld de,00180h		;4620
	ld bc,00180h		;4623
	call RELLENA_VRAM		;4626
	ld hl,04a37h		;4629   ; La fuente: 48 glifos
	ld de,02180h		;462c
	ld bc,00180h		;462f
	jp COPIA_A_VRAM		;4632
CARGA_Y_REPARTE_LA_FUENTE:		; La fuente, repetida en los tres tercios
	call CARGA_FUENTE		;4635
	ld de,00008h		;4638
	ld a,011h		;463b
L_463D:
	ld b,008h		;463d
CARGA_UN_TILE:		; Ocho bytes seguidos a la VRAM
	call VPOKE		;463f
	inc de			;4642
	djnz CARGA_UN_TILE		;4643
	add a,011h		;4645   ; El codigo del tile sube 0x11 cada vuelta: la fuente se reparte por los tres tercios
	jr nc,L_463D		;4647
	jp TRIPLICA_TODO		;4649
SUMA_PUNTOS_CON_SONIDO:		; Sonido 1 y suma DE puntos
	ld a,001h		;464c
	call SONIDO		;464e
SUMA_PUNTOS:		; Suma DE (BCD) a los puntos del jugador que juega; en la demo no; vida extra y record de paso
	ld a,(0e002h)		;4651
	add a,a			;4654   ; Bit 6 al signo (sin partida no se puntua) y bit 7 al acarreo (que jugador)
	ret p			;4655
	ld hl,0e049h		;4656   ; E043 los puntos del 1P, E046 los del 2P
	jr nc,L_465D		;4659
	ld l,04ch		;465b
L_465D:
	ld a,(hl)			;465d   ; Byte bajo, con daa detras: los puntos estan en BCD
	add a,e			;465e
	daa			;465f
	ld (hl),a			;4660
	ld e,a			;4661
	inc l			;4662   ; inc l y no inc hl: los tres bytes no se salen de la pagina
	ld a,(hl)			;4663
	adc a,d			;4664
	daa			;4665
	ld (hl),a			;4666
	ld d,a			;4667
	jr nc,L_467F		;4668
	inc hl			;466a   ; El tercer byte solo si hubo acarreo
	ld a,(hl)			;466b
	adc a,000h		;466c
	daa			;466e
	ld (hl),a			;466f
	jr nc,VIDA_EXTRA		;4670
	ld bc,09999h		;4672   ; Se pasa de 999999: record a 999999
	ld (0e046h),bc		;4675   ; Dos escrituras de 16 bits solapadas dejan los tres bytes del record a 0x99
	ld (0e047h),bc		;4679
	jr PINTA_RECORD		;467d
L_467F:
	inc hl			;467f
VIDA_EXTRA:		; A los 10000 y luego cada 20000 (E052 guarda las decenas de millar del proximo)
	ld a,(0e052h)		;4680
	cp (hl)			;4683
	push de			;4684
	push hl			;4685
	jr nc,RECORD		;4686
	add a,002h		;4688   ; Proximo umbral: +20000
	daa			;468a
	jr nc,GUARDA_EL_UMBRAL		;468b
	ld a,0ffh		;468d   ; Ya no hay mas vidas extra
GUARDA_EL_UMBRAL:		; El umbral de la vida extra siguiente, una vida mas y su sonido
	ld (0e052h),a		;468f
	ld hl,0e050h		;4692   ; E050 son las vidas
	inc (hl)			;4695
	call PINTA_LAS_VIDAS_QUE_QUEDAN		;4696
	ld a,00bh		;4699   ; El sonido de la vida extra
	call SONIDO		;469b
RECORD:		; Si los puntos superan el record, se copian y se pinta
	pop hl			;469e
	ld a,(0e048h)		;469f   ; E042, el byte alto del record
	ld b,(hl)			;46a2   ; (HL) es el byte alto de los puntos
	sub (hl)			;46a3
	ex de,hl			;46a4
	pop de			;46a5
	jr c,RECORD_NUEVO		;46a6   ; El record se queda corto: hay marca nueva
	jr nz,PINTA_PUNTOS		;46a8   ; Distintos y sin acarreo: el record sigue por delante
	push hl			;46aa
	ld hl,(0e046h)		;46ab
	sbc hl,de		;46ae
	pop hl			;46b0
	jr nc,PINTA_PUNTOS		;46b1
RECORD_NUEVO:		; E040-E042 = los puntos
	ld (0e046h),de		;46b3
	ld a,b			;46b7
	ld (0e048h),a		;46b8
	jr PINTA_RECORD		;46bb
MARCADOR:		; Pinta el marcador entero: rotulos, puntos de los dos, fase, tiempo, SCENE y el KONAMI 1984 de abajo
	ld hl,04bb7h		;46bd   ; "1P", "HI", "STAGE", "TIME" y "SCENE"
	call PINTA_LISTA		;46c0
	ld a,(0e002h)		;46c3
	bit 5,a		;46c6   ; Bit 5: dos jugadores
	jr z,L_46D8		;46c8
	ld hl,04bf3h		;46ca   ; "2P"
	call PINTA_LISTA		;46cd
	ld a,(0e002h)		;46d0
	xor 080h		;46d3   ; Los puntos del otro jugador
	call PINTA_PUNTOS_DE		;46d5
L_46D8:
	call PINTA_LAS_VIDAS		;46d8
	call PINTA_FASE		;46db
	call PINTA_TIEMPO		;46de
	call PINTA_SCENE		;46e1
	ld hl,04bf9h		;46e4   ; KONAMI 1984 en la fila 23, columna 1
	call PINTA_LISTA		;46e7
PINTA_RECORD:		; Seis cifras del record en la fila 0, columna 15
	ld hl,0e048h		;46ea
	ld de,0380fh		;46ed
	call PINTA_3_BYTES_BCD		;46f0
PINTA_PUNTOS:		; Los del jugador que juega
	ld a,(0e002h)		;46f3
PINTA_PUNTOS_DE:		; Los del jugador del bit 7 de A: 1P en la fila 0, columna 5; 2P en la fila 1
	ld de,03805h		;46f6   ; Fila 0, columna 5: los puntos del 1P
	ld hl,0e04bh		;46f9   ; E043-E045; se entra por el byte alto porque PINTA_BCD recorre HL hacia atras
	add a,a			;46fc   ; El bit 7 de A al acarreo: puesto, es el jugador 2
	jr nc,PINTA_3_BYTES_BCD		;46fd
	ld e,025h		;46ff   ; Fila 1, columna 5 (0x3825), y sus puntos en E046-E048
	ld hl,0e04eh		;4701
PINTA_3_BYTES_BCD:		; Seis cifras
	ld b,003h		;4704
	jr PINTA_BCD		;4706
PINTA_SCENE:		; Dos cifras de E059 en la fila 23, columna 28
	ld de,03afch		;4708
	ld hl,0e059h		;470b
	jr PINTA_1_BYTE_BCD		;470e
PINTA_FASE:		; Dos cifras de E051 en la fila 0, columna 28
	ld de,0381ch		;4710
	ld hl,0e051h		;4713
PINTA_1_BYTE_BCD:		; Dos cifras
	ld b,001h		;4716
PINTA_BCD:		; B bytes BCD desde HL hacia abajo, dos cifras por byte, en la VRAM DE
	ld a,(hl)			;4718   ; HL va hacia atras: la cifra menos significativa esta la primera
L_4719:
	push af			;4719
	and 00fh		;471a   ; El nibble bajo es la cifra de la derecha; 0x30 es el tile del cero
	or 030h		;471c
	ld c,a			;471e
	pop af			;471f
	and 0f0h		;4720   ; El alto, la de la izquierda, que se pinta antes
	rra			;4722
	rra			;4723
	rra			;4724
	rra			;4725
	or 030h		;4726
	call VPOKE		;4728
	inc de			;472b
	ld a,c			;472c
	call VPOKE		;472d
	dec hl			;4730
	inc de			;4731   ; DE hacia delante: dos columnas por byte
	djnz PINTA_BCD		;4732
	ret			;4734
TRAS_EL_ESTADO_EN_PARTIDA:		; Lo que corre detras de cada estado con partida en marcha: hace parpadear el rotulo del jugador al que le toca
	ld bc,(0e002h)		;4735   ; C = E002 (las opciones) y B = E003 (el contador de fotogramas)
	ld a,b			;4739
	and 01fh		;473a   ; Solo uno de cada 32 fotogramas
	ret nz			;473c
	ld de,03802h		;473d
	ld hl,04bedh		;4740   ; El rotulo 1P, en la fila 0 columna 2
	bit 7,c		;4743   ; Bit 7 de E002: si juega el segundo, el 2P de la fila 1
	jr z,L_474C		;4745
	ld hl,04bf3h		;4747
	ld e,022h		;474a
L_474C:
	bit 5,b		;474c   ; Bit 5 del contador: 32 fotogramas se ve y 32 no
	jp nz,PINTA_LISTA		;474e
	xor a			;4751
	ld bc,00003h		;4752   ; Y apagado son tres casillas en blanco
	jp RELLENA_VRAM		;4755
PINTA_LAS_VIDAS:		; Copia los doce atributos de los tres sprites de las vidas, los coloca y apaga los que ya no quedan
	ld bc,0000ch		;4758   ; Doce bytes: tres sprites de cuatro
	ld hl,04792h		;475b
	ld de,0e11ch		;475e
	push de			;4761   ; DE se empuja dos veces porque hacen falta las dos: una para el IX y otra para la copia a la VRAM
	push de			;4762
	ldir		;4763
	call COLOCA_LOS_SPRITES_DEL_DECORADO		;4765   ; Los del decorado se colocan por su cuenta
	pop ix		;4768
	ld (ix+003h),c		;476a
	ld (ix+007h),c		;476d
	ld (ix+00bh),00bh		;4770
	pop hl			;4774
	ld de,03b6ch		;4775
	ld bc,00010h		;4778
	call COPIA_A_VRAM		;477b
	ld de,03ac4h		;477e
	call PINTA_EL_NOMBRE_EN		;4781
PINTA_LAS_VIDAS_QUE_QUEDAN:		; El numero de vidas (E050) en la fila 22
	ld de,03adch		;4784
	ld a,(0e050h)		;4787
	call SCENE_A_BCD_RESTA_100		;478a
	ld b,001h		;478d
	jp L_4719		;478f

; ----------------------------------------------------------------------
; DATOS atributos_de_tres_sprites: Los 12 bytes que 0x475B copia a 0xE11C
;   (tres sprites de cuatro bytes: Y, X, patron y color)
;   0x4792..0x479e  (12 bytes)
DATA_atributos_de_tres_sprites:
	defb 0a7h,008h,060h,000h	; 4792
	defb 0a7h,010h,064h,000h	; 4796
	defb 0a7h,00bh,05ch,000h	; 479a

; ======================================================================
; CODIGO 0x479e..0x4894  (246 bytes)
; ======================================================================


ESPEJA_TILES_EN_VRAM:		; Copia C tiles de la VRAM DE a la VRAM HL dandoles la vuelta izquierda-derecha
	call ESPEJA_UN_TILE		;479e   ; Ocho filas por tile
	ld a,020h		;47a1
	call DE_MAS_A		;47a3
	dec c			;47a6
	jr nz,ESPEJA_TILES_EN_VRAM		;47a7
	ret			;47a9
ESPEJA_UN_TILE:		; Los 16 bytes de un tile, con los bits de cada fila al reves
	push de			;47aa
L_47AB:
	ld b,010h		;47ab
ESPEJA_UNA_FILA:		; Las ocho filas de un tile, cada una con sus bits al reves
	ex de,hl			;47ad
	call VPEEK		;47ae   ; Un byte del original...
	ex de,hl			;47b1
	call BITS_AL_REVES		;47b2   ; ...con los bits al reves...
	call VPOKE		;47b5   ; ...y al tile espejado
	inc e			;47b8
	inc hl			;47b9
	djnz ESPEJA_UNA_FILA		;47ba
	ld a,e			;47bc
	sub 020h		;47bd   ; Al acabar el tile, atras 32: la VRAM avanza de ocho en ocho
	ld e,a			;47bf
	bit 4,e		;47c0
	jr z,L_47AB		;47c2
	pop de			;47c4
	ret			;47c5
BITS_AL_REVES:		; Da la vuelta a los ocho bits de A
	push bc			;47c6
	ld c,a			;47c7
	ld b,008h		;47c8
L_47CA:
	rr c		;47ca   ; Sale por un lado y entra por el otro: ocho vueltas
	rla			;47cc
	djnz L_47CA		;47cd
	pop bc			;47cf
	ret			;47d0
PREPARA_ESCRITURA:		; Manda la direccion DE al VDP y deja el puerto de datos en el C alternativo
	ex af,af'			;47d1
	ex de,hl			;47d2
	call 00053h		;47d3   ; BIOS SETWRT - Enables VDP to write | BIOS SETWRT, que es quien sabe la direccion base de la VRAM
	di			;47d6
	ex de,hl			;47d7
	exx			;47d8
	ld a,(00006h)		;47d9   ; 0x0006 tiene el puerto de datos del VDP de esta maquina, no se supone
	ld c,a			;47dc
	exx			;47dd
	ex af,af'			;47de
	ret			;47df
PREPARA_LECTURA:		; Lo mismo para leer: SETRD y el puerto de lectura de 0x0007
	ex de,hl			;47e0
	call 00050h		;47e1   ; BIOS SETRD - Enables VDP to read
	di			;47e4
	ex de,hl			;47e5
	exx			;47e6
	ld a,(00007h)		;47e7
	ld c,a			;47ea
	exx			;47eb
	ret			;47ec
PINTA_EL_CURSOR_DEL_MENU:		; Los dos tiles del cursor a la izquierda de la opcion, o dos blancos
	ld bc,05e5fh		;47ed   ; Los tiles 0x5E y 0x5F, que son el cursor
	bit 3,(hl)		;47f0   ; Un bit del contador: parpadea
	jr nz,PINTA_EL_CURSOR_EN_SU_FILA		;47f2
BORRA_EL_CURSOR_DEL_MENU:		; Los mismos dos sitios, con el tile 0
	ld bc,00000h		;47f4   ; Un bloque de 2 por 2 tiles
PINTA_EL_CURSOR_EN_SU_FILA:		; Los dos tiles del cursor en la casilla de la opcion
	call CASILLA_DE_LA_OPCION		;47f7
PINTA_DOS_TILES:		; B y C, uno al lado del otro, en la VRAM DE
	ld a,b			;47fa
	call VPOKE		;47fb
	ld a,c			;47fe
	inc de			;47ff   ; La casilla de al lado
	call VPOKE		;4800
	ret			;4803
CASILLA_DE_LA_OPCION:		; La VRAM de la fila donde esta el cursor: dos filas por opcion desde la 10
	ld a,(0e042h)		;4804   ; E042 es la opcion, de 0 a 3
	add a,014h		;4807   ; Fila 10 mas dos por opcion, en casillas de 32: sale 0x7Axx, o sea 0x3Axx con el bit de escritura
	rrca			;4809
	rrca			;480a
	ld e,a			;480b
	ld d,07ah		;480c
	ret			;480e

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; LA PANTALLA DEL TITULO. Los tiles 0x40-0x61 del primer tercio se
; redefinen con el logotipo del titulo (RLE de 0x4894, 400 bytes de VRAM) y sus
; colores (RLE de 0x4A2B, 16 bytes que se repiten); la fuente del tercio
; de abajo se pone en cyan (0x70) para el menu.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
PANTALLA_DEL_TITULO:		; Patrones y colores del logotipo del titulo, fuente cyan abajo, y borra VIDEO CARTRIDGE
	ld hl,04894h		;480f   ; RLE con la direccion delante: patrones a 0x2200 (tiles 0x40-0x61)
	call RLE_A_VRAM		;4812
	ld de,04400h		;4815
	ld b,018h		;4818
L_481A:
	push bc			;481a   ; Diecisiete vueltas, una por fila de 16 colores
	push de			;481b
	ld hl,04a2bh		;481c   ; Siempre el mismo bloque RLE: los 34 tiles del logotipo llevan colores identicos de dos en dos
	call RLE_A_VRAM_DE		;481f   ; Descomprime 16 bytes: 0x08 0xE0 son ocho 0xE0, y 0x88 copia e0 e0 30 30 30 20 20 c0 tal cual
	pop hl			;4822
	ld bc,00010h		;4823   ; DE avanza 16 bytes, los colores de dos tiles
	add hl,bc			;4826
	ex de,hl			;4827
	pop bc			;4828
	djnz L_481A		;4829
	ld de,00580h		;482b
	ld bc,00010h		;482e
	ld a,0c0h		;4831
	call RELLENA_VRAM		;4833
	ld a,070h		;4836   ; Cyan sobre transparente para la fuente del tercio de abajo (el menu)
	ld de,01180h		;4838   ; VRAM 0x1180: la tabla de colores empieza en 0x0000, y ahi cae el tile 0x30 del tercio de abajo
	ld bc,00170h		;483b   ; 0x180 bytes son 48 tiles, del 0x30 al 0x5F: las cifras y las letras que usa el menu
	call RELLENA_VRAM		;483e
	ld de,03966h		;4841   ; Borra "@ VIDEO CARTRIDGE @"
	ld bc,00013h		;4844
	xor a			;4847
	call RELLENA_VRAM		;4848
	xor a			;484b
	ld (0e00ah),a		;484c   ; E00A a cero: TITULO_COLUMNA empezara por la columna 0
	ret			;484f
TITULO_COLUMNA:		; Una columna del logotipo por llamada (17 columnas de 2 tiles, filas 5 y 6); luego el KONAMI 1984 hasta 52 llamadas. Acarreo mientras queda
	ld hl,0e00ah		;4850   ; E00A cuenta las llamadas y sube en cada una
	ld a,(hl)			;4853
	inc (hl)			;4854
	cp 018h		;4855
	jr nc,L_4883		;4857
	ld de,03864h		;4859   ; Fila 4, columna 8: la fila 4 se borra y las 5 y 6 llevan los tiles 0x40+2n y 0x41+2n
	ld c,a			;485c
	add a,e			;485d   ; La columna n de la fila 4 es 0x3888 mas n
	ld e,a			;485e
	ld a,c			;485f
	add a,a			;4860   ; Dos tiles por columna: 0x80+2n arriba y 0x81+2n justo debajo
	add a,080h		;4861
	ld c,a			;4863
	ld b,002h		;4864
L_4866:
	ld a,c			;4866
	call VPOKE		;4867   ; Dos tiles en la misma columna, uno debajo del otro, filas 5 y 6
	ld a,020h		;486a   ; Bajar una fila en la tabla de nombres es sumar 32
	call DE_MAS_A		;486c
	inc c			;486f
	djnz L_4866		;4870
	ld a,e			;4872
	sub 0abh		;4873   ; La columna, contra el 0xAB: solo la 7 y la 8 llevan tercera fila
	cp 002h		;4875
	jr nc,L_4880		;4877
	add a,0b0h		;4879   ; Los tiles 0xB0 y 0xB1, que son la cola de la g de Cabbage
L_487B:
	call VPOKE		;487b
	scf			;487e   ; Acarreo: aun quedan columnas por sacar
	ret			;487f
L_4880:
	xor a			;4880   ; En las demas columnas, el tile 0: nada
	jr L_487B		;4881
L_4883:
	push af			;4883
	ld hl,04c08h		;4884
	call PINTA_LISTA		;4887
	ld hl,04c1ah		;488a   ; KONAMI 1984 en la fila 8, columna 11
	call PINTA_LISTA		;488d
	pop af			;4890
	cp 034h		;4891   ; 52 llamadas en total
	ret			;4893

; ----------------------------------------------------------------------
; DATOS rle_4894: flujo RLE (0x4812 lo descomprime en 400 bytes de VRAM)
;   0x4894..0x4a2b  (407 bytes)
DATA_rle_4894:
	defb 000h,064h,0f0h,007h,01fh,03fh,07eh,078h,0f8h,0f0h,0f0h,0f0h,0f0h,0f8h,078h,07eh	; 4894  .d...?~x......x~
	defb 03fh,01fh,007h,0e0h,0f0h,0f0h,010h,000h,003h,003h,000h,000h,003h,007h,007h,017h	; 48a4  ?...............
	defb 0f7h,0f7h,0e3h,000h,000h,000h,000h,000h,0f8h,0fch,03ch,01ch,0fch,0fch,01ch,01ch	; 48b4  ..........<.....
	defb 0fch,0fch,0deh,0e0h,0e0h,0e0h,0e0h,0e0h,0ffh,0ffh,0ffh,0f1h,0e0h,0e0h,0e0h,0f1h	; 48c4  ................
	defb 0ffh,0ffh,0efh,00eh,00eh,00eh,00eh,00eh,00eh,0cfh,0cfh,0efh,0eeh,0eeh,0eeh,0efh	; 48d4  ................
	defb 0cfh,0cfh,00eh,000h,000h,000h,000h,000h,0f0h,0fch,0fch,01eh,00eh,00eh,00eh,01eh	; 48e4  ................
	defb 0fch,0fch,0f0h,000h,000h,000h,000h,000h,07fh,07fh,007h,003h,07fh,0ffh,0e3h,0e3h	; 48f4  ................
	defb 0ffh,0ffh,07bh,0f0h,000h,000h,000h,000h,000h,003h,087h,08fh,08eh,08fh,087h,083h	; 4904  ..{.............
	defb 087h,083h,08fh,0deh,000h,000h,000h,01ch,03ch,0fch,0f0h,078h,039h,079h,0f1h,0e1h	; 4914  ........<..x9y..
	defb 001h,0e0h,0f8h,03ch,000h,000h,000h,000h,000h,03ch,0ffh,0e7h,0c3h,0ffh,0ffh,0c0h	; 4924  ...<.....<......
	defb 0e0h,0ffh,0ffh,03fh,000h,000h,000h,000h,000h,000h,000h,000h,080h,080h,080h,000h	; 4934  ...?............
	defb 080h,080h,080h,000h,03fh,03fh,03fh,03ch,03ch,03ch,03ch,03fh,03fh,03fh,03ch,03ch	; 4944  ....???<<<<???<<
	defb 03ch,03ch,03ch,03ch,0e0h,0f8h,0f8h,07ch,03ch,03ch,07ch,0f8h,0f8h,0e0h,001h,001h	; 4954  <<<<...|<<|.....
	defb 001h,001h,001h,000h,000h,000h,000h,000h,000h,0feh,0ffh,00fh,007h,0ffh,0ffh,0c7h	; 4964  ................
	defb 0c7h,0ffh,0ffh,0f7h,0f0h,000h,000h,00ch,01ch,01ch,01ch,03fh,03fh,01ch,01ch,01ch	; 4974  ...........??...
	defb 01ch,01ch,01fh,00fh,087h,000h,000h,000h,000h,003h,00fh,09fh,09ch,038h,038h,038h	; 4984  .............888
	defb 038h,09ch,09fh,08fh,003h,00eh,00eh,00eh,00eh,0ceh,0eeh,0efh,02fh,00fh,00eh,00eh	; 4994  8.........../...
	defb 00eh,02eh,0eeh,0eeh,0ceh,000h,000h,000h,000h,000h,0f0h,0f8h,0fch,03ch,01ch,01ch	; 49a4  .............<..
	defb 01ch,01ch,01ch,01ch,01ch,001h,001h,001h,001h,001h,001h,001h,001h,001h,001h,001h	; 49b4  ................
	defb 001h,001h,001h,001h,001h,0e1h,0e3h,0e7h,0efh,0ffh,0feh,0fch,0fch,0feh,0ffh,0efh	; 49c4  ................
	defb 0e7h,0e3h,0e1h,0e0h,0e0h,0f0h,0e1h,0c1h,080h,000h,001h,001h,001h,001h,001h,081h	; 49d4  ................
	defb 0c1h,0e1h,0f1h,0f9h,07dh,0c0h,080h,0c0h,0c0h,080h,000h,0c3h,0cfh,0cfh,0deh,0dch	; 49e4  ....}...........
	defb 0dch,0dch,0deh,0cfh,0cfh,0c3h,01ch,01ch,01ch,01ch,01ch,0dch,0fch,0fch,03ch,01ch	; 49f4  ..............<.
	defb 01ch,01ch,03dh,0fdh,0fch,0dch,000h,000h,000h,000h,07ch,0feh,0feh,0e2h,0f8h,07eh	; 4a04  ..=.......|....~
	defb 03fh,007h,087h,0ffh,0feh,07ch,01ch,01ch,01eh,00fh,003h,000h,000h,000h,01ch,01ch	; 4a14  ?....|..........
	defb 03ch,0f8h,0e0h,000h,000h,000h,000h	; 4a24

; ----------------------------------------------------------------------
; DATOS rle_4A2B: flujo RLE (0x481F lo descomprime en 16 bytes de VRAM)
;   0x4a2b..0x4a37  (12 bytes)
DATA_rle_4A2B:
	defb 008h,0e0h,088h,0e0h,0e0h,030h,030h,030h,020h,020h,0c0h,000h	; 4a2b  .....000  ..

; ----------------------------------------------------------------------
; DATOS fuente: Los 48 glifos de ocho bytes que 0x4629 sube a la VRAM 0x2180:
;   el codigo de tile ES el ASCII, asi que van del 0x30 ('0') al 0x5F
;   0x4a37..0x4bb7  (384 bytes)
DATA_fuente:
	defb 000h,01ch,022h,063h,063h,063h,022h,01ch	; 4a37  .."ccc".
	defb 000h,018h,038h,018h,018h,018h,018h,07eh	; 4a3f  ..8....~
	defb 000h,03eh,063h,003h,00eh,03ch,070h,07fh	; 4a47  .>c..<p.
	defb 000h,03eh,063h,003h,00eh,003h,063h,03eh	; 4a4f  .>c...c>
	defb 000h,00eh,01eh,036h,066h,066h,07fh,006h	; 4a57  ...6ff..
	defb 000h,07fh,060h,07eh,063h,003h,063h,03eh	; 4a5f  ..`~c.c>
	defb 000h,03eh,063h,060h,07eh,063h,063h,03eh	; 4a67  .>c`~cc>
	defb 000h,07fh,063h,006h,00ch,018h,018h,018h	; 4a6f  ..c.....
	defb 000h,03eh,063h,063h,03eh,063h,063h,03eh	; 4a77  .>cc>cc>
	defb 000h,03eh,063h,063h,03fh,003h,063h,03eh	; 4a7f  .>cc?.c>
	defb 03ch,042h,099h,0a1h,0a1h,099h,042h,03ch	; 4a87  <B....B<
	defb 000h,010h,038h,07ch,0feh,038h,038h,038h	; 4a8f  ..8|.888
	defb 000h,038h,038h,038h,0feh,07ch,038h,010h	; 4a97  .888.|8.
	defb 000h,010h,018h,0fch,0feh,0fch,018h,010h	; 4a9f  ........
	defb 000h,000h,000h,000h,000h,018h,008h,010h	; 4aa7  ........
	defb 000h,000h,000h,000h,000h,000h,018h,018h	; 4aaf  ........
	defb 000h,000h,000h,000h,07eh,000h,000h,000h	; 4ab7  ....~...
	defb 000h,01ch,036h,063h,063h,07fh,063h,063h	; 4abf  ..6cc.cc
	defb 000h,07eh,063h,063h,07eh,063h,063h,07eh	; 4ac7  .~cc~cc~
	defb 000h,03eh,063h,060h,060h,060h,063h,03eh	; 4acf  .>c```c>
	defb 000h,07ch,066h,063h,063h,063h,066h,07ch	; 4ad7  .|fcccf|
	defb 000h,07fh,060h,060h,07eh,060h,060h,07fh	; 4adf  ..``~``.
	defb 000h,07fh,060h,060h,07eh,060h,060h,060h	; 4ae7  ..``~```
	defb 000h,03eh,063h,060h,067h,063h,063h,03fh	; 4aef  .>c`gcc?
	defb 000h,063h,063h,063h,07fh,063h,063h,063h	; 4af7  .ccc.ccc
	defb 000h,03ch,018h,018h,018h,018h,018h,03ch	; 4aff  .<.....<
	defb 000h,01fh,006h,006h,006h,006h,066h,03ch	; 4b07  ......f<
	defb 000h,063h,066h,06ch,078h,07ch,06eh,067h	; 4b0f  .cflx|ng
	defb 000h,060h,060h,060h,060h,060h,060h,07fh	; 4b17  .``````.
	defb 000h,063h,077h,07fh,07fh,06bh,063h,063h	; 4b1f  .cw..kcc
	defb 000h,063h,073h,07bh,07fh,06fh,067h,063h	; 4b27  .cs{.ogc
	defb 000h,03eh,063h,063h,063h,063h,063h,03eh	; 4b2f  .>ccccc>
	defb 000h,07eh,063h,063h,063h,07eh,060h,060h	; 4b37  .~ccc~``
	defb 000h,03eh,063h,063h,063h,06fh,066h,03dh	; 4b3f  .>cccof=
	defb 000h,07eh,063h,063h,062h,07ch,066h,063h	; 4b47  .~ccb|fc
	defb 000h,03eh,063h,060h,03eh,003h,063h,03eh	; 4b4f  .>c`>.c>
	defb 000h,07eh,018h,018h,018h,018h,018h,018h	; 4b57  .~......
	defb 000h,063h,063h,063h,063h,063h,063h,03eh	; 4b5f  .cccccc>
	defb 000h,063h,063h,063h,063h,036h,01ch,008h	; 4b67  .cccc6..
	defb 000h,063h,063h,06bh,06bh,07fh,077h,022h	; 4b6f  .cckk.w"
	defb 000h,063h,076h,03ch,01ch,01eh,037h,063h	; 4b77  .cv<..7c
	defb 000h,066h,066h,07eh,03ch,018h,018h,018h	; 4b7f  .ff~<...
	defb 000h,07fh,007h,00eh,01ch,038h,070h,07fh	; 4b87  .....8p.
	defb 000h,024h,024h,024h,000h,000h,000h,000h	; 4b8f  .$$$....
	defb 000h,000h,002h,000h,08ah,0aah,0aah,0dah	; 4b97  ........
	defb 000h,000h,008h,048h,0eeh,04ah,04ah,06ah	; 4b9f  ...H.JJj
	defb 000h,00fh,01fh,0ffh,0ffh,0ffh,0ffh,00fh	; 4ba7  ........
	defb 000h,000h,0feh,0e0h,0e0h,0c0h,0c0h,080h	; 4baf  ........

; ----------------------------------------------------------------------
; DATOS lista_del_marcador: Lista de 42 tiles con su VRAM delante, que 0x46C0
;   pinta entera: los rotulos de arriba. Lleva 0xFE por medio para saltar de
;   sitio, y sus seis ultimos bytes (0x4BED) son a la vez la lista suelta del
;   rotulo 1P, que 0x4735 pinta por su cuenta
;   0x4bb7..0x4bf3  (60 bytes)
DATA_lista_del_marcador:
	defb 00ch,038h,048h,049h,040h,0feh,016h,038h,053h,054h,041h,047h,045h,040h,0feh,02ch	; 4bb7  .8HI@..8STAGE@.,
	defb 038h,054h,049h,04dh,045h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 4bc7  8TIME...........
	defb 000h,000h,000h,0feh,0d6h,03ah,052h,045h,053h,054h,000h,040h,0feh,0f6h,03ah,053h	; 4bd7  .....:REST.@..:S
	defb 043h,045h,04eh,045h,040h,0feh,002h,038h,031h,050h,040h,0ffh	; 4be7  CENE@..81P@.

; ----------------------------------------------------------------------
; DATOS lista_2p: La lista del rotulo 2P, en la fila 1 columna 2; la pinta
;   0x46CD al empezar y 0x4735 al hacerlo parpadear
;   0x4bf3..0x4bf9  (6 bytes)
DATA_lista_2p:
	defb 022h,038h,032h,050h,040h,0ffh	; 4bf3

; ----------------------------------------------------------------------
; DATOS lista_4BF9: lista de 12 tiles con su VRAM delante, la pinta 0x46E7
;   0x4bf9..0x4c08  (15 bytes)
DATA_lista_4BF9:
	defb 0e1h,03ah,03ah,04bh,04fh,04eh,041h,04dh,049h,000h,031h,039h,038h,034h,0ffh	; 4bf9  .::KONAMI.1984.

; ----------------------------------------------------------------------
; DATOS lista_4C08: lista de 15 tiles con su VRAM delante, la pinta 0x4887
;   0x4c08..0x4c1a  (18 bytes)
DATA_lista_4C08:
	defb 0e9h,038h,03ah,000h,04fh,041h,041h,03eh,049h,04eh,043h,03fh,000h,031h,039h,038h	; 4c08  .8:.OAA>INC?.198
	defb 033h,0ffh	; 4c18

; ----------------------------------------------------------------------
; DATOS lista_4C1A: lista de 91 tiles con su VRAM delante, la pinta 0x488D
;   0x4c1a..0x4c84  (106 bytes)
DATA_lista_4C1A:
	defb 0abh,039h,050h,04ch,041h,059h,000h,053h,045h,04ch,045h,043h,054h,0feh,007h,03ah	; 4c1a  .9PLAY.SELECT..:
	defb 031h,050h,04ch,041h,059h,045h,052h,000h,000h,05ch,05dh,000h,04ah,04fh,059h,053h	; 4c2a  1PLAYER..\].JOYS
	defb 054h,049h,043h,04bh,0feh,047h,03ah,032h,050h,04ch,041h,059h,045h,052h,053h,000h	; 4c3a  TICK.G:2PLAYERS.
	defb 05ch,05dh,000h,04ah,04fh,059h,053h,054h,049h,043h,04bh,0feh,087h,03ah,031h,050h	; 4c4a  \].JOYSTICK..:1P
	defb 04ch,041h,059h,045h,052h,000h,000h,05ch,05dh,000h,04bh,045h,059h,042h,04fh,041h	; 4c5a  LAYER..\].KEYBOA
	defb 052h,044h,0feh,0c7h,03ah,032h,050h,04ch,041h,059h,045h,052h,053h,000h,05ch,05dh	; 4c6a  RD..:2PLAYERS.\]
	defb 000h,04bh,045h,059h,042h,04fh,041h,052h,044h,0ffh	; 4c7a  .KEYBOARD.

; ----------------------------------------------------------------------
; DATOS rotulo_game_over: Lista de 16 tiles con su VRAM delante, que 0x4333
;   pinta con ROTULO_Y_JUGADOR: GAME OVER
;   0x4c84..0x4c91  (13 bytes)
DATA_rotulo_game_over:
	defb 06bh,039h,047h,041h,04dh,045h,000h,000h,04fh,056h,045h,052h,0feh	; 4c84  k9GAME..OVER.

; ----------------------------------------------------------------------
; DATOS rotulo_player: Lista de 6 tiles, que 0x42B3 pinta cuando E001 vale 0:
;   PLAYER (el numero lo pone 0x4438)
;   0x4c91..0x4c9a  (9 bytes)
DATA_4C91:
	defb 02ch,039h,050h,04ch,041h,059h,045h,052h,0ffh	; 4c91  ,9PLAYER.

; ----------------------------------------------------------------------
; DATOS lista_4C9A: lista de 19 tiles con su VRAM delante, la pinta 0x418F
;   0x4c9a..0x4cb0  (22 bytes)
DATA_lista_4C9A:
	defb 066h,039h,040h,000h,056h,049h,044h,045h,04fh,000h,043h,041h,052h,054h,052h,049h	; 4c9a  f9@.VIDEO.CARTRI
	defb 044h,047h,045h,000h,040h,0ffh	; 4caa

; ----------------------------------------------------------------------
; DATOS lista_4CB0: lista de 16 tiles con su VRAM delante, la pinta 0x42C9
;   0x4cb0..0x4cc3  (19 bytes)
DATA_lista_4CB0:
	defb 088h,039h,042h,04fh,04eh,055h,053h,000h,053h,043h,04fh,052h,045h,000h,032h,030h	; 4cb0  .9BONUS.SCORE.20
	defb 030h,030h,0ffh	; 4cc0

; ======================================================================
; CODIGO 0x4cc3..0x4d4c  (137 bytes)
; ======================================================================


CARGA_LOGO_KONAMI:		; Descomprime los 26 tiles del KONAMI grande (0x60-0x79) en 0x2300, colores blancos, la fuente, y prepara la subida (17 pasos, cursor E050 a 0)
	ld hl,04d4ch		;4cc3
	ld de,06300h		;4cc6   ; Escritura en la VRAM 0x2300 (el bit 6 de D es lo que la marca de escritura): patrones de los tiles 0x60-0x79
	call RLE_A_VRAM_DE		;4cc9
	ld de,00300h		;4ccc   ; Blanco para 26 tiles
	ld bc,000d0h		;4ccf
	ld a,0f0h		;4cd2
	call RELLENA_VRAM		;4cd4
	call CARGA_Y_REPARTE_LA_FUENTE		;4cd7
	ld a,011h		;4cda   ; 17 filas por subir
	ld (0e00ah),a		;4cdc
	ld hl,00000h		;4cdf
	ld (0e050h),hl		;4ce2
	ret			;4ce5
SUBE_LOGO_KONAMI:		; Una fila mas arriba: pinta las tres filas del KONAMI (3, 11 y 12 tiles desde la columna 10) y borra la de debajo. Z al llegar a la fila 4
	ld hl,(0e050h)		;4ce6   ; En el titulo E050 no son las vidas: es el cursor de 16 bits de lo que lleva subido el logotipo
	ld de,00020h		;4ce9   ; Una fila entera de la tabla de nombres son 32 bytes
	add hl,de			;4cec
	ld (0e050h),hl		;4ced
	ex de,hl			;4cf0
	or a			;4cf1
	ld hl,03aaah		;4cf2   ; Desde la fila 21 hacia arriba
	sbc hl,de		;4cf5   ; 0x3AAA menos lo subido; la primera vez sale 0x3A8A, fila 20 y columna 10
	ex de,hl			;4cf7
	ld a,060h		;4cf8   ; Los 26 tiles del logotipo van seguidos desde el 0x60
	ld b,003h		;4cfa   ; Tres tiles arriba, once en medio y doce abajo: asi esta partido el KONAMI grande
	call PINTA_TILES_SEGUIDOS		;4cfc
	ld b,00bh		;4cff
	call PINTA_TILES_SEGUIDOS		;4d01
	ld b,00ch		;4d04
	call PINTA_TILES_SEGUIDOS		;4d06
	ld bc,0000ch		;4d09   ; Doce ceros en la fila de debajo: borran el rastro que deja al subir
	xor a			;4d0c
	call RELLENA_VRAM		;4d0d
	ld hl,0e00ah		;4d10
	dec (hl)			;4d13   ; E00A cuenta las 17 filas; al llegar a cero es el z que espera 0x4183
	ret			;4d14
PINTA_TILES_SEGUIDOS:		; B tiles consecutivos desde A en la VRAM DE y baja una fila
	push de			;4d15
L_4D16:
	call VPOKE		;4d16   ; Un tile por posicion, y el codigo del tile sube con la columna
	inc de			;4d19
	inc a			;4d1a
	djnz L_4D16		;4d1b
	pop de			;4d1d   ; Se recupera el principio de la fila...
	ld hl,00020h		;4d1e   ; ...y se le suman 32: DE se va a la fila de debajo para la llamada siguiente
	add hl,de			;4d21
	ex de,hl			;4d22
	ret			;4d23
RLE_A_VRAM:		; Descomprime en la VRAM cuya direccion va delante de los datos
	ld e,(hl)			;4d24
	inc hl			;4d25
	ld d,(hl)			;4d26
	inc hl			;4d27
RLE_A_VRAM_DE:		; Descomprime HL en la VRAM DE: 0 fin; n<0x80 repite n veces el byte siguiente; n>=0x80 copia n&0x7F bytes tal cual
	di			;4d28
	call PREPARA_ESCRITURA		;4d29
L_4D2C:
	ld a,(hl)			;4d2c
	inc hl			;4d2d
	or a			;4d2e   ; Cero: fin
	ret z			;4d2f
	bit 7,a		;4d30   ; Bit 7: bytes tal cual
	jr nz,RLE_TAL_CUAL		;4d32
	ld b,a			;4d34
	ld a,(hl)			;4d35
	inc hl			;4d36
RLE_RELLENO:		; Repite B veces el byte que sigue a la cuenta
	exx			;4d37
	out (c),a		;4d38   ; Siempre el mismo byte
	exx			;4d3a
	nop			;4d3b
	nop			;4d3c
	djnz RLE_RELLENO		;4d3d
	jr L_4D2C		;4d3f
RLE_TAL_CUAL:		; Copia los bytes uno a uno cuando la cuenta lleva el bit 7
	res 7,a		;4d41   ; Sin el bit 7: los bytes van tal cual
	ld c,a			;4d43
	ld b,000h		;4d44
	call COPIA_A_VRAM_BUCLE		;4d46
	di			;4d49
	jr L_4D2C		;4d4a

; ----------------------------------------------------------------------
; DATOS rle_4D4C: flujo RLE (0x4CC9 lo descomprime en 208 bytes de VRAM)
;   0x4d4c..0x4ddf  (147 bytes)
DATA_rle_4D4C:
	defb 00eh,000h,082h,007h,00fh,006h,000h,082h,0f8h,0f0h,004h,03eh,004h,03fh,090h,01fh	; 4d4c  ...........>.?..
	defb 03fh,07fh,0ffh,0feh,0fch,0f8h,0f0h,0e0h,0c0h,080h,000h,000h,000h,03eh,03eh,005h	; 4d5c  ?............>>.
	defb 000h,083h,01fh,07fh,0fbh,005h,000h,083h,00fh,0cfh,0efh,005h,000h,083h,078h,0fch	; 4d6c  ..............x.
	defb 0bch,005h,000h,083h,03fh,07fh,0f3h,005h,000h,083h,087h,0c7h,0c7h,005h,000h,083h	; 4d7c  ....?...........
	defb 0bch,0feh,0dfh,005h,000h,08dh,078h,0fch,0bch,060h,0f0h,0f0h,060h,000h,0f0h,0f0h	; 4d8c  ......x..`..`...
	defb 0f0h,03fh,03fh,006h,03eh,090h,0f8h,0fch,0feh,07fh,03fh,01fh,00fh,007h,03eh,03eh	; 4d9c  .??.>.....?...>>
	defb 03eh,07eh,0fch,0fch,0f8h,0e0h,005h,0f1h,083h,0fbh,07fh,01fh,006h,0efh,082h,0cfh	; 4dac  >~..............
	defb 00fh,008h,01eh,088h,0e1h,003h,03fh,0f1h,0e1h,0f3h,07fh,01eh,008h,0e7h,008h,08fh	; 4dbc  ......?.........
	defb 008h,01eh,082h,0f1h,0f2h,004h,0f5h,08ah,0f2h,0f1h,0e0h,010h,0c8h,068h,0c8h,028h	; 4dcc  .............h.(
	defb 010h,0e0h,000h	; 4ddc

; ----------------------------------------------------------------------
; DATOS copia_4DDF: 56 bytes que 0x6D4A copia a la VRAM 0x2580
;   0x4ddf..0x4e17  (56 bytes)
DATA_copia_4DDF:
	defb 000h,000h,001h,002h,002h,004h,004h,008h,080h,080h,000h,000h,000h,000h,000h,000h	; 4ddf  ................
	defb 000h,000h,000h,000h,000h,001h,001h,001h,040h,040h,080h,080h,080h,000h,000h,000h	; 4def  ........@@......
	defb 010h,020h,020h,020h,020h,020h,040h,040h,001h,002h,002h,004h,004h,008h,010h,010h	; 4dff  .     @@........
	defb 008h,008h,008h,008h,008h,008h,008h,008h	; 4e0f  ........

; ----------------------------------------------------------------------
; DATOS copia_4E17: 240 bytes que 0x6D33 copia a la VRAM 0x2B00
;   0x4e17..0x4ef7  (224 bytes)
DATA_copia_4E17:
	defb 000h,000h,000h,000h,001h,002h,004h,008h,020h,040h,040h,080h,000h,000h,000h,000h	; 4e17  ........ @@.....
	defb 000h,000h,000h,000h,000h,000h,001h,002h,008h,010h,020h,040h,080h,080h,000h,000h	; 4e27  .......... @....
	defb 004h,008h,010h,020h,040h,080h,000h,000h,000h,000h,000h,000h,000h,003h,004h,038h	; 4e37  ... @..........8
	defb 00ch,010h,020h,040h,080h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,001h	; 4e47  .. @............
	defb 008h,010h,010h,020h,040h,040h,080h,000h,001h,002h,004h,004h,008h,010h,020h,020h	; 4e57  ... @@........  
	defb 000h,000h,001h,002h,002h,004h,008h,010h,040h,080h,000h,000h,000h,000h,000h,000h	; 4e67  ........@.......
	defb 020h,020h,040h,080h,000h,000h,000h,000h,010h,020h,040h,080h,000h,000h,000h,000h	; 4e77    @...... @.....
	defb 002h,002h,004h,004h,008h,008h,008h,010h,010h,020h,020h,040h,040h,080h,080h,000h	; 4e87  .........  @@...
	defb 000h,000h,000h,000h,000h,001h,001h,002h,020h,040h,040h,080h,080h,000h,000h,000h	; 4e97  ........ @@.....
	defb 002h,004h,008h,008h,010h,020h,020h,040h,080h,000h,000h,000h,000h,000h,000h,000h	; 4ea7  .....  @........
	defb 000h,000h,000h,000h,000h,000h,001h,001h,040h,040h,080h,080h,080h,080h,000h,000h	; 4eb7  ........@@......
	defb 001h,001h,002h,002h,002h,002h,004h,004h,004h,004h,008h,008h,008h,008h,010h,010h	; 4ec7  ................
	defb 010h,020h,020h,020h,040h,040h,040h,040h,000h,000h,000h,000h,001h,001h,001h,002h	; 4ed7  .   @@@@........
	defb 080h,080h,080h,080h,000h,000h,000h,000h,002h,002h,004h,004h,004h,008h,000h,000h	; 4ee7  ................

; ----------------------------------------------------------------------
; DATOS copia_4EF7: 240 bytes que 0x6D61 copia a la VRAM 0x2D10
;   0x4ef7..0x4fe7  (240 bytes)
DATA_copia_4EF7:
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,00fh	; 4ef7  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,024h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0f0h	; 4f07  .......$........
	defb 000h,000h,000h,000h,000h,000h,000h,0ffh,0ffh,0ffh,000h,000h,0afh,03fh,07fh,0ffh	; 4f17  .............?..
	defb 0ffh,0ffh,000h,000h,081h,0e7h,0ffh,0ffh,0ffh,0ffh,000h,000h,0f5h,0fch,0feh,0ffh	; 4f27  ................
	defb 0ffh,0ffh,000h,00fh,0bfh,07fh,05fh,034h,0ffh,0ffh,000h,024h,099h,0ffh,0ffh,0bdh	; 4f37  ......_4...$....
	defb 0ffh,0ffh,000h,0f0h,0fdh,0feh,0fah,02ch,018h,018h,018h,018h,018h,018h,018h,018h	; 4f47  .......,........
	defb 081h,0e7h,0ffh,0ffh,0bdh,03ch,018h,05ah,0afh,03fh,07fh,0ffh,0b4h,0a0h,064h,0a0h	; 4f57  .....<.Z.?....d.
	defb 0f5h,0fch,0feh,0ffh,02dh,005h,026h,005h,000h,000h,001h,000h,020h,000h,002h,000h	; 4f67  ....-.&..... ...
	defb 000h,000h,080h,000h,004h,000h,080h,000h,0bfh,07fh,05fh,034h,094h,020h,000h,040h	; 4f77  .........._4. .@
	defb 099h,0ffh,0ffh,0bdh,018h,018h,099h,018h,0fdh,0feh,0fah,02ch,029h,004h,000h,002h	; 4f87  ...........,)...
	defb 008h,080h,000h,000h,000h,000h,000h,000h,010h,001h,000h,000h,000h,000h,000h,000h	; 4f97  ................
	defb 0b4h,0a0h,064h,0a0h,000h,000h,001h,000h,0bdh,03ch,018h,05ah,018h,018h,018h,018h	; 4fa7  ..d......<.Z....
	defb 02dh,005h,026h,005h,000h,000h,080h,000h,020h,000h,001h,000h,000h,000h,000h,000h	; 4fb7  -.&..... .......
	defb 004h,000h,080h,000h,000h,000h,000h,000h,094h,020h,000h,040h,008h,080h,000h,000h	; 4fc7  ......... .@....
	defb 018h,018h,099h,018h,018h,018h,018h,018h,029h,004h,000h,002h,010h,001h,000h,000h	; 4fd7  ........).......

; ----------------------------------------------------------------------
; DATOS copia_4FE7: 136 bytes que 0x6D6D copia a la VRAM 0x2E00
;   0x4fe7..0x506f  (136 bytes)
DATA_copia_4FE7:
	defb 0ffh,07fh,07fh,03fh,00fh,001h,000h,000h,003h,01fh,03fh,03fh,07fh,07fh,07fh,0ffh	; 4fe7  ...?......??....
	defb 000h,007h,01eh,01ch,01ch,00eh,00dh,007h,000h,0e0h,078h,038h,038h,070h,0bbh,0aah	; 4ff7  ..........x88p..
	defb 000h,000h,000h,000h,000h,003h,077h,0ffh,068h,052h,0d0h,0b3h,0e8h,0f4h,0cbh,06fh	; 5007  ......w.hR.....o
	defb 0c1h,001h,007h,00eh,00dh,00dh,003h,01dh,0dfh,0b8h,060h,0c0h,080h,082h,000h,000h	; 5017  ..........`.....
	defb 03dh,03fh,01fh,00dh,001h,006h,006h,001h,002h,002h,081h,0c0h,0e0h,0f0h,0fbh,0ffh	; 5027  =?..............
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,000h,000h,000h,000h,000h,038h,07ch,0eeh,07ch,038h	; 5037  ...........8|.|8
	defb 000h,000h,000h,038h,07ch,0eeh,07ch,038h,000h,000h,000h,038h,07ch,0eeh,07ch,038h	; 5047  ...8|.|8...8|.|8
	defb 000h,000h,000h,038h,07ch,0eeh,07ch,038h,000h,000h,000h,038h,07ch,0eeh,07ch,038h	; 5057  ...8|.|8...8|.|8
	defb 000h,000h,000h,038h,07ch,0eeh,07ch,038h	; 5067  ...8|.|8

; ----------------------------------------------------------------------
; DATOS copia_506F: 88 bytes que 0x6D9A copia a la VRAM 0x0D10
;   0x506f..0x50c7  (88 bytes)
DATA_copia_506F:
	defb 055h,055h,055h,0aah,0aah,066h,055h,055h,055h,055h,055h,0aah,0aah,066h,055h,05fh	; 506f  UUU..fUUUUU..fU_
	defb 055h,055h,055h,0aah,0aah,066h,055h,05fh,055h,055h,055h,0aah,0aah,066h,055h,05fh	; 507f  UUU..fU_UUU..fU_
	defb 055h,055h,055h,055h,055h,055h,055h,0aah,0aah,066h,055h,055h,0f5h,0f5h,0f5h,0f5h	; 508f  UUUUUUU..fUU....
	defb 0aah,066h,055h,055h,0f5h,0f5h,0f5h,0f5h,0aah,066h,055h,055h,0f5h,0f5h,0f5h,0f5h	; 509f  .fUU.....fUU....
	defb 0aah,066h,055h,055h,0f5h,0f5h,0f5h,0f5h,0aah,066h,055h,055h,0f5h,0f5h,0f5h,0f5h	; 50af  .fUU.....fUU....
	defb 0aah,066h,055h,055h,0f5h,0f5h,0f5h,0f5h	; 50bf  .fUU....

; ----------------------------------------------------------------------
; DATOS copia_50C7: 80 bytes que 0x6DBD copia a la VRAM 0x0E88
;   0x50c7..0x5117  (80 bytes)
DATA_copia_50C7:
	defb 053h,053h,053h,053h,053h,053h,053h,053h,0b3h,0b3h,0b3h,0b3h,0b3h,0b3h,0b3h,0b3h	; 50c7  SSSSSSSS........
	defb 0cbh,0cbh,0cbh,0cbh,0cbh,0cbh,0cbh,0cbh,0cbh,0cbh,0cbh,0cbh,0cbh,0cbh,0cbh,0cbh	; 50d7  ................
	defb 0cbh,0cbh,0cbh,0cbh,0cbh,0cbh,0cbh,0cbh,0cbh,0cbh,0cbh,0cbh,0cbh,0cbh,0cbh,0cbh	; 50e7  ................
	defb 0cbh,0cbh,0cbh,0cbh,0cbh,0cbh,0cbh,0cbh,0cbh,0cbh,0cbh,0cbh,0cbh,0cbh,0cbh,0cbh	; 50f7  ................
	defb 0cbh,0cbh,0cbh,0cbh,0cbh,0cbh,0cbh,0cbh,0cbh,0cbh,0cbh,0cbh,0cbh,0cbh,0cbh,0cbh	; 5107  ................

; ----------------------------------------------------------------------
; DATOS copia_5117: 136 bytes que 0x6DB1 copia a la VRAM 0x0E00
;   0x5117..0x514f  (56 bytes)
DATA_copia_5117:
	defb 053h,053h,053h,053h,053h,053h,053h,053h,083h,083h,083h,083h,083h,083h,083h,083h	; 5117  SSSSSSSS........
	defb 093h,093h,093h,093h,093h,093h,093h,093h,063h,063h,063h,063h,063h,063h,063h,063h	; 5127  ........cccccccc
	defb 073h,073h,073h,073h,073h,073h,073h,073h,0d3h,0d3h,0d3h,0d3h,0d3h,0d3h,0d3h,0d3h	; 5137  ssssssss........
	defb 0f3h,0f3h,0f3h,0f3h,0f3h,0f3h,0f3h,0f3h	; 5147  ........

; ----------------------------------------------------------------------
; DATOS rle_de_los_tiles_espejados: Flujo RLE con su VRAM delante (0x1DC0, con
;   el bit de escritura puesto): 286 bytes que rinden 576 de VRAM. Lo lanza
;   0x55EF con un `jp RLE_A_VRAM`
;   0x514f..0x526d  (286 bytes)
DATA_rle_de_los_tiles_espejados:
	defb 0c0h,05dh,085h,001h,003h,007h,007h,00dh,004h,00fh,084h,007h,00fh,00dh,008h,009h	; 514f  .]..............
	defb 000h,089h,0c0h,000h,080h,080h,0c0h,0ffh,01ch,00ch,004h,022h,000h,089h,020h,030h	; 515f  ...........".. 0
	defb 038h,0ffh,003h,001h,001h,000h,003h,009h,000h,084h,010h,0b0h,0f0h,0e0h,004h,0f0h	; 516f  8...............
	defb 0a5h,0b0h,0e0h,0e0h,0c0h,000h,000h,000h,01eh,03fh,078h,0f7h,0efh,0afh,0dfh,0e7h	; 517f  .........?x.....
	defb 0f9h,07eh,07fh,03fh,01fh,007h,000h,000h,078h,0fch,01eh,0eeh,0f6h,0fdh,083h,07fh	; 518f  .~.?....x.......
	defb 0ffh,0feh,07eh,0bch,0f8h,0e0h,005h,000h,085h,001h,003h,007h,007h,003h,00ah,000h	; 519f  ..~.............
	defb 086h,080h,0c0h,0e0h,0f0h,0f0h,0e0h,009h,000h,09dh,008h,008h,029h,02bh,027h,01bh	; 51af  ............)+'.
	defb 007h,01fh,021h,007h,009h,00ah,00ah,000h,000h,000h,010h,010h,094h,0d4h,0e4h,0d8h	; 51bf  ..!.............
	defb 0e0h,0f8h,084h,0e0h,090h,050h,050h,041h,000h,09bh,00eh,01ch,037h,0e7h,0bfh,01eh	; 51cf  .....PPA....7...
	defb 001h,00bh,01eh,037h,02dh,02dh,00dh,00ch,008h,000h,000h,000h,080h,0c0h,0f1h,0ffh	; 51df  ...7--..........
	defb 0ffh,0efh,0a7h,041h,041h,009h,000h,09bh,00eh,01ch,036h,0e7h,0bfh,01fh,003h,001h	; 51ef  ...AA.....6.....
	defb 000h,003h,002h,000h,01fh,07ch,0f6h,0f8h,074h,078h,0f0h,0f1h,0fbh,0ffh,0ffh,0c3h	; 51ff  .....|..tx......
	defb 041h,0c0h,040h,004h,000h,087h,00fh,008h,008h,00eh,001h,001h,00eh,009h,000h,081h	; 520f  A.@.............
	defb 030h,005h,048h,081h,030h,009h,000h,082h,011h,032h,004h,012h,081h,039h,009h,000h	; 521f  0.H.0....2...9..
	defb 081h,08ch,005h,052h,081h,08ch,009h,000h,087h,031h,04ah,00ah,00ah,012h,022h,079h	; 522f  ...R.....1J..."y
	defb 009h,000h,081h,08ch,005h,052h,081h,08ch,025h,000h,060h,000h,0a0h,000h,000h,001h	; 523f  .....R..%.`.....
	defb 00dh,01eh,03ah,03ch,03fh,03fh,03fh,01fh,01fh,00fh,006h,000h,000h,000h,0c0h,000h	; 524f  ..:<???.........
	defb 060h,0f0h,0b8h,078h,0f8h,0f8h,0f8h,0f0h,0f0h,0e0h,0c0h,000h,000h,000h	; 525f  `..x..........

; ----------------------------------------------------------------------
; DATOS tabla_de_la_liana: Nueve punteros a los nueve dibujos de la liana, que
;   0x5B4B indexa por dos con la fase (0..8, y del 9 al 15 los mismos hacia
;   atras)
;   0x526d..0x527f  (18 bytes)
DATA_tabla_de_la_liana:
	defw 0527fh	; 526d  -> DATA_dibujos_de_la_liana
	defw 052a7h	; 526f
	defw 052cfh	; 5271
	defw 052f7h	; 5273
	defw 0531fh	; 5275
	defw 0534fh	; 5277
	defw 05377h	; 5279
	defw 0539fh	; 527b
	defw 053c7h	; 527d

; ----------------------------------------------------------------------
; DATOS dibujos_de_la_liana: Los nueve dibujos: tiles con 0xFE/0xFD/0xFC para
;   bajar de fila y 0xFF de fin, y detras Y, X1 y X2 del cabo. Cada uno cierra
;   exactamente donde empieza el siguiente
;   0x527f..0x53ef  (368 bytes)
DATA_dibujos_de_la_liana:
	defb 0feh,0b5h,005h,0feh,062h,063h,005h,0feh,064h,065h,005h,005h,0feh,064h,066h,005h	; 527f  ....bc..de...df.
	defb 005h,005h,0feh,067h,068h,005h,005h,005h,005h,0fch,005h,005h,005h,005h,005h,0fch	; 528f  ...gh...........
	defb 005h,005h,005h,005h,0ffh,04eh,01ch,07ch,0feh,0b0h,0b1h,0feh,069h,06ah,005h,0feh	; 529f  .....N.|....ij..
	defb 005h,06bh,005h,005h,0feh,005h,06ch,06dh,005h,005h,0feh,005h,062h,06eh,005h,005h	; 52af  .k....lm....bn..
	defb 005h,0fch,06fh,005h,005h,005h,005h,0fch,005h,005h,005h,005h,0ffh,052h,022h,082h	; 52bf  ..o..........R".
	defb 0feh,0b2h,0b3h,0feh,005h,070h,005h,0feh,005h,069h,071h,005h,0feh,005h,005h,060h	; 52cf  .....p...iq....`
	defb 005h,005h,0feh,005h,005h,072h,073h,005h,005h,0fch,005h,074h,005h,005h,005h,0fch	; 52df  .....rs....t....
	defb 075h,005h,005h,005h,0ffh,057h,02ah,08ah,0feh,005h,0b4h,0feh,005h,076h,077h,0feh	; 52ef  u....W*......vw.
	defb 005h,005h,078h,005h,0feh,005h,005h,005h,079h,005h,0feh,005h,005h,005h,005h,07ah	; 52ff  ..x.....y......z
	defb 005h,0fch,005h,005h,07bh,07ch,005h,0fch,005h,07dh,005h,005h,0ffh,05ch,036h,096h	; 530f  ....{|...}...\6.
	defb 0feh,005h,0b6h,0feh,005h,005h,061h,005h,0feh,005h,005h,005h,061h,005h,0feh,005h	; 531f  ......a.....a...
	defb 005h,005h,005h,061h,005h,0feh,005h,005h,005h,005h,005h,061h,005h,0fch,005h,005h	; 532f  ...a.......a....
	defb 005h,005h,061h,005h,005h,0fch,005h,005h,005h,061h,005h,005h,0ffh,05eh,045h,0a5h	; 533f  ..a......a...^E.
	defb 0fdh,0bbh,005h,0fdh,095h,094h,005h,0fdh,005h,096h,005h,005h,0fdh,005h,097h,005h	; 534f  ................
	defb 005h,005h,0fdh,005h,098h,005h,005h,005h,005h,0fdh,005h,09ah,099h,005h,005h,0fdh	; 535f  ................
	defb 005h,005h,09bh,005h,0ffh,05ch,054h,0b4h,0fdh,0bah,0b9h,0fdh,005h,08eh,005h,0fdh	; 536f  .....\T.........
	defb 005h,08fh,087h,005h,0fdh,005h,005h,07eh,005h,005h,0fdh,005h,005h,091h,090h,005h	; 537f  .......~........
	defb 005h,0fdh,005h,005h,005h,092h,005h,0fdh,005h,005h,005h,093h,0ffh,057h,060h,0c0h	; 538f  .............W`.
	defb 0fdh,0b8h,0b7h,0fdh,005h,088h,087h,0fdh,005h,005h,089h,005h,0fdh,005h,005h,08bh	; 539f  ................
	defb 08ah,005h,0fdh,005h,005h,005h,08ch,080h,005h,0fdh,005h,005h,005h,005h,08dh,0fdh	; 53af  ................
	defb 005h,005h,005h,005h,0ffh,052h,068h,0c8h,0fdh,005h,0bch,0fdh,005h,081h,080h,0fdh	; 53bf  .....Rh.........
	defb 005h,005h,083h,082h,0fdh,005h,005h,005h,084h,082h,0fdh,005h,005h,005h,005h,086h	; 53cf  ................
	defb 085h,0fdh,005h,005h,005h,005h,005h,0fdh,005h,005h,005h,005h,0ffh,04eh,06eh,0ceh	; 53df  .............Nn.

; ----------------------------------------------------------------------
; DATOS tabla_de_la_plataforma: Dieciocho punteros a los dieciocho registros
;   de 0x5413, que 0x5B14 indexa por dos con la altura (0..17, y de la 18 a la
;   31 los mismos hacia atras)
;   0x53ef..0x5413  (36 bytes)
DATA_tabla_de_la_plataforma:
	defw 05413h	; 53ef  -> DATA_registros_de_la_plataforma
	defw 05418h	; 53f1
	defw 0541dh	; 53f3
	defw 05422h	; 53f5
	defw 05427h	; 53f7
	defw 0542ch	; 53f9
	defw 05431h	; 53fb
	defw 05436h	; 53fd
	defw 0543bh	; 53ff
	defw 05440h	; 5401
	defw 05445h	; 5403
	defw 0544ah	; 5405
	defw 0544fh	; 5407
	defw 05454h	; 5409
	defw 05459h	; 540b
	defw 0545eh	; 540d
	defw 05463h	; 540f
	defw 05468h	; 5411

; ----------------------------------------------------------------------
; DATOS registros_de_la_plataforma: Dieciocho registros de cinco bytes: la
;   VRAM, el puntero al dibujo y la altura, que va bajando de 0x52 a 0x32 de
;   cuatro en cuatro y de dos en dos
;   0x5413..0x546d  (90 bytes)
DATA_registros_de_la_plataforma:
	defw 039a0h,054a6h	; 5413
	defb 052h	; 5417
	defb 0a0h	; 5418
	defb 039h	; 5419
	defb 076h	; 541a
	defb 054h	; 541b
	defb 052h	; 541c
	defb 0a0h	; 541d
	defb 039h	; 541e
	defb 07fh	; 541f
	defb 054h	; 5420
	defb 04eh	; 5421
	defb 0a0h	; 5422
	defb 039h	; 5423
	defb 088h	; 5424
	defb 054h	; 5425
	defb 04eh	; 5426
	defb 0a0h	; 5427
	defb 039h	; 5428
	defb 06dh	; 5429
	defb 054h	; 542a
	defb 04ah	; 542b
	defb 080h	; 542c
	defb 039h	; 542d
	defb 076h	; 542e
	defb 054h	; 542f
	defb 04ah	; 5430
	defb 080h	; 5431
	defb 039h	; 5432
	defb 07fh	; 5433
	defb 054h	; 5434
	defb 046h	; 5435
	defb 080h	; 5436
	defb 039h	; 5437
	defb 088h	; 5438
	defb 054h	; 5439
	defb 046h	; 543a
	defb 080h	; 543b
	defb 039h	; 543c
	defb 06dh	; 543d
	defb 054h	; 543e
	defb 042h	; 543f
	defb 060h	; 5440
	defb 039h	; 5441
	defb 076h	; 5442
	defb 054h	; 5443
	defb 042h	; 5444
	defb 060h	; 5445
	defb 039h	; 5446
	defb 07fh	; 5447
	defb 054h	; 5448
	defb 03eh	; 5449
	defb 060h	; 544a
	defb 039h	; 544b
	defb 088h	; 544c
	defb 054h	; 544d
	defb 03eh	; 544e
	defb 060h	; 544f
	defb 039h	; 5450
	defb 06dh	; 5451
	defb 054h	; 5452
	defb 03ah	; 5453
	defb 040h	; 5454
	defb 039h	; 5455
	defb 076h	; 5456
	defb 054h	; 5457
	defb 03ah	; 5458
	defb 040h	; 5459
	defb 039h	; 545a
	defb 07fh	; 545b
	defb 054h	; 545c
	defb 036h	; 545d
	defb 040h	; 545e
	defb 039h	; 545f
	defb 091h	; 5460
	defb 054h	; 5461
	defb 036h	; 5462
	defb 040h	; 5463
	defb 039h	; 5464
	defb 09dh	; 5465
	defb 054h	; 5466
	defb 032h	; 5467
	defb 040h	; 5468
	defb 039h	; 5469
	defb 0afh	; 546a
	defb 054h	; 546b
	defb 032h	; 546c

; ----------------------------------------------------------------------
; DATOS dibujos_de_la_plataforma: Los ocho dibujos que apuntan esos registros,
;   de nueve bytes cada uno salvo el de 0x5491, que son doce
;   0x546d..0x54b8  (75 bytes)
DATA_dibujos_de_la_plataforma:
	defb 0a3h,0a4h,0a5h,0b3h,0b4h,0b5h,005h,0adh,005h,005h,005h,005h,0a2h,0a2h,0a2h,0afh	; 546d  ................
	defb 0aeh,0b0h,0a6h,0a6h,0a6h,0aah,0abh,0ach,0bdh,0beh,0bfh,0a6h,0a6h,0a6h,0a7h,0a8h	; 547d  ................
	defb 0a9h,0b8h,0b9h,0bah,0a6h,0a6h,0a6h,0a7h,0a8h,0a9h,0b8h,0b9h,0bah,0bbh,0adh,0bch	; 548d  ................
	defb 0a3h,0a4h,0a5h,0b3h,0b4h,0b5h,0b6h,0adh,0b7h,005h,005h,005h,0a3h,0a4h,0a5h,0b3h	; 549d  ................
	defb 0b4h,0b5h,0a2h,0a2h,0a2h,0afh,0aeh,0b0h,0b2h,0adh,0b1h	; 54ad  ...........

; ======================================================================
; CODIGO 0x54b8..0x55f5  (317 bytes)
; ======================================================================


MONTA_PANTALLA:		; Borra el estado de la pantalla (5A64) y la construye (5AE3)
	call BORRA_PANTALLA		;54b8
	jp CONSTRUYE_PANTALLA		;54bb
UN_FOTOGRAMA_DE_PARTIDA:		; Sube los sprites, mueve los obstaculos y el jugador
	call SUBE_LOS_ATRIBUTOS		;54be
	ld a,(0e13bh)		;54c1   ; E13B, los pasos que lleva andados el jugador
	cp 018h		;54c4   ; A los 24 pasos arrancan los moviles que miran E159
	jr nz,L_54CE		;54c6
	ld hl,0e158h		;54c8   ; E159 solo lo miran las bolas que ruedan (0x5B85) y su cobro (0x6425); los demas moviles leen E158 y salen desde el primer fotograma
	ld a,(hl)			;54cb
	inc hl			;54cc
	ld (hl),a			;54cd
L_54CE:
	ld a,(0e138h)		;54ce
	cp 007h		;54d1   ; Del 7 en adelante el jugador esta muriendo: los obstaculos se paran
	jr nc,L_54F9		;54d3
	call TIEMPO		;54d5   ; El tiempo y los contadores de fase, antes que los obstaculos
	call CONTADORES		;54d8
	call LIANAS		;54db
	call SURTIDORES		;54de
	call BOLAS_QUE_RUEDAN		;54e1
	call PECES		;54e4
	call HOGUERA		;54e7
	call BOLA_QUE_BOTA		;54ea
	call ARANAS		;54ed
	call ABEJA		;54f0
	call TRONCO		;54f3
	call EL_QUE_LATE		;54f6   ; El jugador se pinta siempre, este muriendo o no
L_54F9:
	jp CARAS_DE_LAS_VIDAS		;54f9
PREPARA_DEMO:		; Fuente, graficos del juego, partida nueva, marcador y la primera pantalla
	call CARGA_Y_REPARTE_LA_FUENTE		;54fc
	call ALL_STAGE_CLEAR_ESPERA		;54ff
	call CARGA_GRAFICOS_JUEGO		;5502
	call MARCADOR		;5505
	jp MONTA_PANTALLA		;5508

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; LOS MANDOS DE LA DEMO. En la pantalla 0 corre a la derecha y salta en
; X=0x38 y X=0x80; en la 1 decide por el estado del jugador: andando,
; salta al azar (el registro R resiembra el contador de fotogramas) y da
; la vuelta al pasar de X=0xB0; en la liana suelta cuando toca; sobre el
; tronco salta al llegar al borde. Luego corre el fotograma normal.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
FOTOGRAMA_DE_DEMO:		; Escribe en E009 lo que "pulsa" la demo y corre 585E
	ld a,(0e054h)		;550b   ; E054, la pantalla: la demo se comporta distinto en la 0 y en la 1
	or a			;550e
	jr nz,L_5529		;550f
	ld hl,0e009h		;5511   ; E009 es lo que el juego lee como pulsado ahora; aqui lo escribe la demo, no el mando
	ld a,008h		;5514   ; Derecha
	ld (hl),a			;5516
	ld a,(0e135h)		;5517   ; En la pantalla 0 solo salta en dos sitios, X=0x38 y X=0x80: el resto es correr
	cp 038h		;551a
	jr z,L_5522		;551c
	cp 080h		;551e
	jr nz,L_5527		;5520
L_5522:
	ld (hl),038h		;5522   ; Derecha y salto (0x38 = derecha, espacio y SELECT), sin lo del fotograma anterior
	dec hl			;5524
	ld (hl),000h		;5525
L_5527:
	jr L_5573		;5527
L_5529:
	cp 007h		;5529
	jr nz,L_5573		;552b
	ld hl,0e135h		;552d   ; HL a la X del jugador, que es lo que miran las tres ramas de abajo
	ld a,(0e138h)		;5530   ; E138, el estado del jugador
	or a			;5533
	jr z,L_5542		;5534   ; Cero: andando (0x5542)
	dec a			;5536
	jr z,L_5573		;5537   ; Uno, en el aire: nada que pulsar, el arco va solo
	dec a			;5539
	jr z,L_5576		;553a   ; Con A ya rebajado en dos, este cero es el estado 2: colgado de la liana
	cp 003h		;553c   ; Y este 3 es el estado 5, montado en el tronco
	jr z,L_557F		;553e
	jr L_5573		;5540   ; Cualquier otro estado (trampolin, surtidor, poste, muriendo): quieto
L_5542:
	ld a,(hl)			;5542
	cp 0b0h		;5543   ; Andando: si X esta entre 0x2E y 0xAF, cada cuatro fotogramas...
	jr nc,L_556E		;5545
	sub 004h		;5547
	cp 02ah		;5549
	jr c,L_556E		;554b
	ld a,(0e003h)		;554d
	and 003h		;5550
	jr z,L_555E		;5552
	ld a,(0e139h)		;5554
	xor 00ch		;5557   ; ...da la vuelta (0x0C cambia izquierda por derecha)
L_5559:
	ld (0e009h),a		;5559
	jr L_5573		;555c
L_555E:
	ld a,r		;555e   ; ...o resiembra el contador con el registro R y salta
	and 07fh		;5560
	ld (0e003h),a		;5562
	ld hl,0e008h		;5565
	ld (hl),000h		;5568
	ld a,030h		;556a
	jr L_5559		;556c
L_556E:
	ld a,(0e139h)		;556e
	jr L_5559		;5571
L_5573:
	jp UN_FOTOGRAMA_DE_PARTIDA		;5573
L_5576:
	ld a,(0e003h)		;5576   ; En la liana: suelta cuando el contador da la vuelta
	and 07fh		;5579
	jr z,L_558C		;557b
	jr L_556E		;557d
L_557F:
	ld a,(0e0d9h)		;557f   ; Sobre el tronco: sigue mientras el tronco vaya delante; salta al pasar de X=0xA4
	cp (hl)			;5582
	jr nc,L_556E		;5583
	cp 0a4h		;5585
	jr nc,L_558C		;5587
	xor a			;5589
	jr L_5559		;558a
L_558C:
	ld hl,0e009h		;558c
	jr L_5522		;558f
CARGA_GRAFICOS_JUEGO:		; Patrones y colores del juego (70A5), los espejos de las lianas y de los objetos, y los 64 sprites (23 dibujados, 23 espejados y 18 mas)
	call CARGA_FUENTE		;5591
	call CARGA_PATRONES_Y_COLORES		;5594
CARGA_LOS_TILES_DE_LA_PANTALLA:		; Sube los tiles que toquen segun E05B y E05C, los espeja, y descomprime los dos decorados
	ld a,(0e05bh)		;5597   ; El nibble alto de E05B elige uno de los seis flujos
	and 0f0h		;559a
	ld hl,055f5h		;559c   ; La tabla de seis punteros, indexada por dos (son palabras)
	rra			;559f
	rra			;55a0
	rra			;55a1
	call HL_MAS_A		;55a2
	ld e,(hl)			;55a5
	inc hl			;55a6
	ld d,(hl)			;55a7
	ex de,hl			;55a8
	ld de,05800h		;55a9   ; A la VRAM 0x1800: la tabla de patrones de sprite
	call RLE_A_VRAM_DE		;55ac
	ld hl,01800h		;55af   ; Los objetos: 30 tiles 0x60-0x7D del tercio de en medio
	ld de,01af0h		;55b2
	ld c,003h		;55b5
	call ESPEJA_TILES_EN_VRAM		;55b7
	ld a,(0e000h)		;55ba
	cp 009h		;55bd   ; En el estado 9 (vida nueva) se repintan las vidas
	call z,PINTA_LAS_VIDAS		;55bf
	ld a,(0e05ch)		;55c2   ; Y el bit 4 de E05C elige entre los dos decorados: el de 0x7342 o el de 0x7475
	ld hl,07342h		;55c5
	ld de,07367h		;55c8
	bit 4,a		;55cb
	jr z,L_55D5		;55cd
	ld hl,07475h		;55cf
	ld de,074b7h		;55d2
L_55D5:
	push de			;55d5   ; El segundo flujo de la pareja se guarda para despues del primero
	ld de,01860h		;55d6
	call RLE_A_VRAM_DE		;55d9
	pop de			;55dc
	ex de,hl			;55dd
	ld de,018a0h		;55de
	call RLE_A_VRAM_DE		;55e1
	ld hl,01860h		;55e4   ; Siete tiles 0xB0-0xB6 del primer tercio...
	ld de,01b50h		;55e7
	ld c,014h		;55ea
	call ESPEJA_TILES_EN_VRAM		;55ec
	ld hl,0514fh		;55ef   ; ...y su espejo (0x479E) para los 0xB7-0xBC
	jp RLE_A_VRAM		;55f2

; ----------------------------------------------------------------------
; DATOS tabla_de_seis_flujos: Seis punteros que 0x559C indexa con el nibble
;   alto de E05B (y 0x7702 recorre entero): 0x717D, 0x71C9, 0x7213, 0x725E,
;   0x72AF y 0x72F1, los seis flujos RLE que van seguidos y cierran clavados
;   uno detras de otro
;   0x55f5..0x5601  (12 bytes)
DATA_tabla_de_seis_flujos:
	defw 0717dh	; 55f5  -> DATA_rle_decorado_1
	defw 071c9h	; 55f7  -> DATA_rle_decorado_2
	defw 07213h	; 55f9  -> DATA_rle_decorado_3
	defw 0725eh	; 55fb  -> DATA_rle_decorado_4
	defw 072afh	; 55fd  -> DATA_rle_decorado_5
	defw 072f1h	; 55ff  -> DATA_rle_decorado_6

; ======================================================================
; CODIGO 0x5601..0x5651  (80 bytes)
; ======================================================================


BORRA_PANTALLA:		; Pone a cero E130-E330 salvo las cuatro fases de lianas y surtidores, y arranca los tiempos de los peces y la abeja
	ld a,(0e131h)		;5601   ; E131 y E133, la fase de las dos lianas
	ld b,a			;5604
	ld a,(0e133h)		;5605
	ld c,a			;5608
	ld a,(0e14dh)		;5609   ; E14D y E14F, la de dos de los surtidores
	ld d,a			;560c
	ld a,(0e14fh)		;560d
	ld e,a			;5610
	push bc			;5611
	push de			;5612
	ld hl,0e130h		;5613   ; De E130 a E330 a cero de un ldir
	ld de,0e131h		;5616
	ld (hl),000h		;5619
	ld bc,00200h		;561b
	ldir		;561e
	pop de			;5620
	pop bc			;5621
	ld a,b			;5622   ; Y las cuatro fases vuelven a su sitio
	ld (0e131h),a		;5623
	ld a,c			;5626
	ld (0e133h),a		;5627
	ld a,d			;562a
	ld (0e14dh),a		;562b
	ld a,e			;562e
	ld (0e14fh),a		;562f
	ld a,080h		;5632
	ld (0e176h),a		;5634
	ld a,08ch		;5637
	ld (0e177h),a		;5639
	ld a,098h		;563c
	ld (0e178h),a		;563e
	ld a,001h		;5641
	ld (0e17eh),a		;5643
	ld a,005h		;5646
	ld (0e17ch),a		;5648
	ld a,06ch		;564b   ; Altura segura del salto: el suelo
	ld (0e13ah),a		;564d
	ret			;5650

; ----------------------------------------------------------------------
; DATOS sprites_del_tronco: Los 8 bytes que 0x5E80 copia a 0xE0D4: dos sprites
;   de cuatro (Y, X, patron, color)
;   0x5651..0x5659  (8 bytes)
DATA_sprites_del_tronco:
	defb 087h,098h,058h,003h	; 5651
	defb 087h,0a8h,0b4h,003h	; 5655

; ======================================================================
; CODIGO 0x5659..0x5764  (267 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; CONSTRUYE LA PANTALLA. Los flags de la pantalla salen de la tabla
; 0x5764 (5B8F); luego se colocan los sprites de los obstaculos, se
; eligen las lianas espejadas o no, se pinta el decorado (5C72 o 5E71)
; y encima cada obstaculo fijo segun su bit de E156.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
CONSTRUYE_PANTALLA:		; Sprites fuera (0xC3), flags, sprites de obstaculos, lianas, decorado, obstaculos y jugador
	ld a,0c3h		;5659   ; Todos los atributos a 0xC3: ningun sprite a la vista
	ld hl,0e0b0h		;565b
	ld de,0e0b1h		;565e
	ld (hl),a			;5661
	ld bc,0006bh		;5662
	ldir		;5665
	ld (0e12ch),a		;5667
	call FLAGS_DE_PANTALLA		;566a
	ld a,(0e058h)		;566d   ; Entrando por la izquierda, las bolas E1AC/E1AD empiezan sin X (0xFF)
	cp 008h		;5670
	jr nz,L_567C		;5672
	ld hl,0e1ach		;5674
	ld a,0ffh		;5677
	ld (hl),a			;5679
	inc hl			;567a
	ld (hl),a			;567b
L_567C:
	ld a,080h		;567c
	ld (0e17ah),a		;567e
	ld a,(0e158h)		;5681   ; Arco de las bolas que ruedan: medio con el bit 1 de E158, alto con el bit 0, plano si no
	ld b,a			;5684   ; B guarda E158 entero: el bit 1 se mira ahora y el 0 despues
	ld hl,06627h		;5685   ; Bit 1 puesto: el arco de 0x6627, que sube dieciseis puntos
	and 002h		;5688
	jr nz,L_5697		;568a
	ld a,b			;568c
	and 001h		;568d
	ld hl,05d95h		;568f   ; Solo el bit 0: el de 0x5D67, que sube cuarenta y ocho
	jr nz,L_5697		;5692
	ld hl,05d67h		;5694   ; Ninguno de los dos: el de 0x5D79, que solo sube tres: la bola casi no despega
L_5697:
	ld (0e1b1h),hl		;5697   ; E160, por donde va la primera bola dentro de su arco
	ld a,00eh		;569a   ; La segunda bola arranca 14 bytes mas alla del arco
	ld (0e1b3h),a		;569c
	ld (0e1b4h),hl		;569f   ; E162: en las tres tablas el byte 14 es el penultimo delta, asi que la segunda bola entra por la punta del arco y no bota a la vez que la primera
	ld hl,05d79h		;56a2   ; El arco de salto para la bola que bota y los tres peces
	ld (0e1c0h),hl		;56a5
	ld (0e1b7h),hl		;56a8   ; E169, E16B y E16D: los tres peces arrancan todos al principio del mismo arco
	ld (0e1bah),hl		;56ab
	ld (0e1bdh),hl		;56ae
	jp COLOCA_JUGADOR		;56b1   ; Con los sprites ya puestos, el jugador entra por su lado
FLAGS_DE_PANTALLA:		; E156 y E158 = la pareja de la tabla 0x5764 para SCENE modulo 32, retocada por la fase y por el SCENE
	ld a,(0e054h)		;56b4
	and 01fh		;56b7   ; Modulo 32: de la pantalla 32 en adelante se repiten las mismas
	ld hl,05764h		;56b9   ; La tabla de los obstaculos fijos
	call HL_MAS_A		;56bc
	ld b,(hl)			;56bf   ; B, los fijos de esta pantalla
	ld a,020h		;56c0   ; Los moviles estan 32 bytes mas alla, con el mismo indice
	call HL_MAS_A		;56c2
	ld c,(hl)			;56c5   ; C, los moviles
	ld a,(0e059h)		;56c6   ; E059, el mismo numero de pantalla pero en BCD, que es el que se lee en el marcador
	and 003h		;56c9   ; SCENE acabado en 0, 4 u 8 (BCD): sin obstaculos fijos, y de los moviles solo la abeja
	jr nz,L_56D2		;56cb
	ld b,a			;56cd   ; A vale 0: ni un obstaculo fijo
	ld a,c			;56ce
	and 080h		;56cf   ; Y de los moviles solo queda en pie el bit 7, la abeja
	ld c,a			;56d1
L_56D2:
	ld a,(0e051h)		;56d2   ; La fase, tambien en BCD
	cp 001h		;56d5   ; Fase 1: sin aranas ni abeja
	jr nz,L_56DE		;56d7
	ld a,c			;56d9
	and 077h		;56da   ; Fuera los bits 3 y 7 de los moviles
	jr L_56E9		;56dc
L_56DE:
	cp 004h		;56de   ; Fases 4 y siguientes...
	jr nc,L_56EC		;56e0   ; De la fase 4 en adelante no se quita nada: se anade
	cp 002h		;56e2   ; Fase 2: como esta
	jr z,L_56F6		;56e4
	ld a,c			;56e6   ; Fase 3: sin abeja
	and 07fh		;56e7   ; Fuera el bit 7
L_56E9:
	ld c,a			;56e9
	jr L_56F6		;56ea
L_56EC:
	bit 0,a		;56ec   ; ...pares y con la pantalla vacia: al menos la abeja
	jr nz,L_56F6		;56ee   ; Fase impar: lo que diga la tabla
	ld a,c			;56f0
	or b			;56f1   ; Ni fijos ni moviles
	jr nz,L_56F6		;56f2
	ld c,080h		;56f4   ; Una pantalla vacia en fase par no se queda en nada: al menos la abeja
L_56F6:
	ld hl,0e156h		;56f6   ; E156, los fijos
	ld (hl),b			;56f9
	inc hl			;56fa   ; E157 queda en medio y aqui se salta: lo escribe 0x57AB con el cielo y no lo lee nadie en todo el cartucho
	inc hl			;56fb
	ld (hl),c			;56fc   ; E158, los moviles
	ld a,(0e051h)		;56fd   ; Fase 2: la abeja baja al primer nivel; en las demas al cuarto
	cp 002h		;5700
	ld a,003h		;5702   ; 3 es el cuarto de los cuatro niveles de 0x5E61; solo vale para la primera salida, porque al esconderse se sortea otro (0x5E0F)
	jr nz,L_5707		;5704
	xor a			;5706
L_5707:
	ld (0e179h),a		;5707
	ld a,c			;570a   ; Con bolas: 50 puntos por pasar cada una
	and 007h		;570b   ; Bits 0-2: si esta pantalla lleva bolas rodando
	jr z,L_5717		;570d
	ld hl,0e19ch		;570f   ; E19C y E19D, lo que valen las dos
	ld (hl),005h		;5712   ; 0x05 son 50 puntos: COBRA_PUNTOS parte el byte en dos cifras BCD y les pega un cero (0x5FB3)
	inc hl			;5714
	ld (hl),005h		;5715
L_5717:
	ld a,(0e059h)		;5717   ; E059, el SCENE en BCD
	or a			;571a
	jr z,L_5736		;571b
	and 00fh		;571d
	jr z,L_5736		;571f
	ld a,(0e054h)		;5721
	bit 1,a		;5724
	jr z,L_573B		;5726
	ld a,(0e156h)		;5728   ; Los bits 1-4 del SCENE eligen que obstaculos lleva la pantalla
	and 01eh		;572b
	jr nz,L_573B		;572d
	ld a,(0e158h)		;572f   ; Bit 3 de los moviles: aranas
	and 008h		;5732
	jr nz,L_573B		;5734
L_5736:
	call DECORADO_CON_CIELO		;5736   ; Con la pantalla despejada se ve el fondo del cielo
	jr L_573E		;5739
L_573B:
	call PINTA_EL_TRONCO		;573b
L_573E:
	call PINTA_TIERRA		;573e   ; El decorado normal: suelo y los cerros de arriba (5E71)
	call ROTULO_CHILD_PARK		;5741   ; La tierra, el rotulo del CHILD PARK si toca, el estanque, los postes, los trampolines, los charcos, la hoguera y la piedra
	call PINTA_ESTANQUE		;5744   ; En las pantallas acabadas en 0 esta llamada pone E156 y E158 a cero: por eso va delante de los seis pintores, que asi se vuelven todos por donde han venido
	call PINTA_CHARCOS		;5747
	call PINTA_POSTES		;574a   ; Los charcos antes que los trampolines: en la unica pantalla que lleva las dos cosas, los trampolines les pisan las X
	call PINTA_TRAMPOLINES		;574d
	call PREPARA_HOGUERA		;5750
	call PINTA_PIEDRA		;5753   ; La hoguera y la piedra se reparten el sprite 31; ninguna de las 32 pantallas lleva las dos (los bits 5 y 6 nunca coinciden en 0x5764)
	call PINTA_SI_TOCA		;5756   ; Y si alguna llevara las dos, la piedra pisaria a la hoguera: va la ultima
	ld b,004h		;5759   ; 200 puntos por cada obstaculo de la lista E18C
	ld hl,0e18ch		;575b   ; E18C-E18F, lo que se cobra por colgarse de una liana
L_575E:
	ld (hl),020h		;575e   ; 0x20 son 200 puntos, y se ponen los cuatro aunque la pantalla no tenga lianas
	inc hl			;5760
	djnz L_575E		;5761
	ret			;5763

; ----------------------------------------------------------------------
; DATOS obstaculos_por_pantalla: Un byte por cada una de las 32 pantallas
;   (E156), indice SCENE modulo 32: bit 0 cinco charcos, 1 lianas, 2
;   trampolines, 3 surtidores, 4 postes, 5 piedra, 6 hoguera, 7 estanque
;   0x5764..0x5784  (32 bytes)
DATA_obstaculos_por_pantalla:
	defb 003h,000h,010h,020h,088h,020h,001h,082h,041h,004h,0c0h,040h,088h,001h,088h,020h	; 5764  ... . ..A..@... 
	defb 000h,080h,050h,004h,050h,040h,010h,020h,010h,082h,000h,005h,041h,088h,001h,050h	; 5774  ..P.P@. ....A..P

; ----------------------------------------------------------------------
; DATOS moviles_por_pantalla: Un byte por cada una de las 32 pantallas (E158),
;   con el mismo indice: bits 0-2 bolas que ruedan, 3 aranas, 4 peces, 5
;   tronco, 6 bola que bota, 7 abeja
;   0x5784..0x57a4  (32 bytes)
DATA_moviles_por_pantalla:
	defb 080h,00ch,008h,008h,008h,00ch,080h,0a0h,010h,008h,060h,080h,000h,010h,018h,002h	; 5784  ..........`.....
	defb 008h,0a0h,048h,008h,040h,0c0h,008h,009h,008h,000h,001h,010h,058h,010h,018h,040h	; 5794  ..H.@.......X..@

; ======================================================================
; CODIGO 0x57a4..0x57be  (26 bytes)
; ======================================================================


DECORADO_CON_CIELO:		; Cuatro cielos segun los bits 2-3 del SCENE (E157), por el despachador
	ld a,(0e054h)		;57a4
	and 00ch		;57a7   ; Bits 2-3 del numero de pantalla
	rrca			;57a9   ; A 0..3: el indice de la tabla de cielos
	rrca			;57aa
	ld (0e157h),a		;57ab
	ld hl,068e6h		;57ae
	ld de,03840h		;57b1
	ld bc,001c0h		;57b4
CIELO_ROJO_VERDE:		; Filas 3-8: franjas rojas y cerros verdes
	call COPIA_A_VRAM		;57b7   ; Y otros 0x25: rojo con cerros verdes
	ret			;57ba
PINTA_TIERRA:		; La tierra de las filas 16-19
	call MOTOR_DE_ROTULOS		;57bb   ; La tierra se pinta siempre, lleve la pantalla lo que lleve

; ----------------------------------------------------------------------
; DATOS parametros_de_57BB: Los seis bytes que van detras del call de 0x57BB:
;   lista 0x6728, tiles 0x6BA1 y VRAM 0x3A00 (fila 16)
;   0x57be..0x57c4  (6 bytes)
DATA_parametros_de_57BB:
	defw 06728h,06ba1h,03a00h	; 57be  -> DATA_lista_motor_6728 DATA_tiles_del_suelo 0x3a00

; ======================================================================
; CODIGO 0x57c4..0x57ce  (10 bytes)
; ======================================================================


	ret			;57c4
PINTA_ESTANQUE:		; Bit 7 de E156: el estanque de las filas 16-18, columnas 9-22
	ld a,(0e156h)		;57c5
	and 080h		;57c8   ; Bit 7
	ret z			;57ca   ; Sin estanque la fila 16 se queda con la tierra que acaba de pintar 0x57BB
	call MOTOR_DE_ROTULOS		;57cb   ; Y el estanque encima, en las mismas filas

; ----------------------------------------------------------------------
; DATOS parametros_de_57CB: Los seis del call de 0x57CB: lista 0x672C, tiles
;   0x6BA4 y VRAM 0x3A09 (fila 16, columna 9)
;   0x57ce..0x57d4  (6 bytes)
DATA_parametros_de_57CB:
	defw 0672ch,06ba4h,03a09h	; 57ce  -> DATA_lista_motor_672C DATA_tiles_del_estanque 0x3a09

; ======================================================================
; CODIGO 0x57d4..0x5929  (341 bytes)
; ======================================================================


	ret			;57d4
PINTA_TRAMPOLINES:		; Bit 2: cuatro trampolines de 2x2 en la fila 16 (columnas 9, 13, 17, 21), sus X en E1A5 (100 puntos cada uno) y la fruta (sprite 19) arriba en una X al azar
	ld a,(0e156h)		;57d5
	and 004h		;57d8   ; Bit 2
	ret z			;57da
	ld de,03a09h		;57db   ; Fila 16, columna 9: el primero
L_57DE:
	ld hl,06bc1h		;57de   ; El trampolin (tiles 0xD1-0xD4) cada cuatro columnas
	ld bc,00202h		;57e1   ; Dos filas por dos columnas
	push de			;57e4   ; PINTA_BLOQUE deja DE al final de la ultima fila, asi que la de partida se guarda
	call PINTA_BLOQUE		;57e5
	pop de			;57e8
	ld a,004h		;57e9   ; Cuatro columnas hasta el siguiente
	call DE_MAS_A		;57eb
	ld a,e			;57ee
	cp 019h		;57ef   ; Columna 25: ya estan los cuatro
	jr nz,L_57DE		;57f1
	ld hl,05a24h		;57f3   ; X de los trampolines: 0x48, 0x68, 0x88, 0xA8 (misma tabla desde el otro lado)
	ld a,(0e058h)		;57f6   ; Por donde ha entrado el jugador
	cp 008h		;57f9
	jr z,L_5800		;57fb
	ld hl,05a27h		;57fd   ; La otra mitad de la tabla; para los trampolines las dos dan el mismo 0x48
L_5800:
	ld de,0e1a5h		;5800   ; E1A5-E1A8, las X con que se cobran
	ld b,004h		;5803
	call RELLENA_CADA_32		;5805   ; 0x48, 0x68, 0x88 y 0xA8: justo las cuatro columnas que se acaban de pintar
	ld b,004h		;5808
	ld hl,0e195h		;580a   ; E195-E198, los puntos aun sin cobrar
L_580D:
	ld (hl),010h		;580d   ; 100 puntos cada uno
	inc hl			;580f
	djnz L_580D		;5810
	ld a,020h		;5812   ; 200 por la fruta
	ld (0e19eh),a		;5814
	ld hl,0e0fch		;5817   ; La fruta: el sprite 15 (E0FC), con Y=0x22
	ld (hl),022h		;581a
	inc hl			;581c
	ld a,r		;581d   ; El registro de refresco hace de azar
	and 003h		;581f   ; Uno de cuatro
	rla			;5821   ; Por 32...
	rla			;5822
	rla			;5823
	rla			;5824
	rla			;5825
	add a,048h		;5826   ; ...y desde 0x48: la fruta cae en la vertical de uno de los cuatro trampolines
	ld (hl),a			;5828
	inc hl			;5829
	ld (hl),0fch		;582a   ; Patron 0xFC
	inc hl			;582c
	ld (hl),00fh		;582d
	ret			;582f
PINTA_CHARCOS:		; Bit 0: cinco charcos de dos tiles en la fila 17 (columnas 7, 11, 15, 19, 23), sus X en E1A5 (100 puntos cada uno)
	ld a,(0e156h)		;5830
	and 001h		;5833   ; Bit 0
	ret z			;5835
	ld de,03a27h		;5836   ; Fila 17, columna 7: una fila por debajo de los trampolines
	ld b,005h		;5839   ; Cinco
L_583B:
	push bc			;583b
	ld hl,06bc5h		;583c   ; Los dos tiles del charco (0xCF 0xD0)
	ld bc,00002h		;583f   ; Dos tiles seguidos, sin PINTA_BLOQUE: el charco es una sola fila
	call COPIA_A_VRAM		;5842
	ld a,004h		;5845   ; Cuatro columnas hasta el siguiente
	call DE_MAS_A		;5847
	pop bc			;584a
	djnz L_583B		;584b
	ld hl,05a25h		;584d   ; La tercera X de la tabla: 0x40 entrando por la izquierda
	ld a,(0e058h)		;5850
	cp 008h		;5853
	jr z,L_585A		;5855
	ld hl,05a28h		;5857   ; 0x30 entrando por la derecha, porque yendo hacia la izquierda se cobra al bajar de la X y no al pasarla
L_585A:
	ld de,0e1a5h		;585a   ; Los mismos cinco huecos que los trampolines: la pantalla 27 es la unica que lleva las dos cosas (0x5764 vale 0x05) y estas X pisan las que dejo 0x5800
	ld b,005h		;585d
	call RELLENA_CADA_32		;585f
	ld b,005h		;5862
	ld hl,0e195h		;5864   ; Y los mismos cinco contadores de puntos
L_5867:
	ld (hl),010h		;5867
	inc hl			;5869
	djnz L_5867		;586a
	ret			;586c
PINTA_POSTES:		; Bit 4: los cinco postes del estanque, sus X en E1A0 (100 puntos), dos bajos de 3x2 en la fila 15 y tres altos de 4x2 en la 14
	ld a,(0e156h)		;586d
	and 010h		;5870   ; Bit 4
	ret z			;5872
	ld hl,05a23h		;5873   ; X de los postes: 0x30, 0x50, 0x70, 0x90, 0xB0
	ld a,(0e058h)		;5876   ; Por donde ha entrado
	cp 008h		;5879
	jr z,L_5880		;587b
	ld hl,05a26h		;587d   ; Entrando por la derecha las X van 0x18 por delante de los postes: al caer encima de uno se esta como mucho a 15 puntos de su X (0x607B), y el cp de COBRA_AL_PASAR la exige estrictamente menor
L_5880:
	ld de,0e1a0h		;5880   ; E1A0-E1A4
	ld b,005h		;5883
	call RELLENA_CADA_32		;5885   ; Cinco X separadas 32, las mismas que la tabla de 0x609B
	ld b,005h		;5888
	ld hl,0e190h		;588a   ; E190-E194
L_588D:
	ld (hl),010h		;588d   ; 0x10 son 100 puntos por poste
	inc hl			;588f
	djnz L_588D		;5890
	ld hl,06bc7h		;5892   ; Poste verde de la izquierda, en la fila 15
	ld de,039e7h		;5895   ; Fila 15, columna 7
	call PINTA_BLOQUE_3x2		;5898
	ld hl,06bcdh		;589b   ; Los tres altos: azul, verde y rojo, en la fila 14
	ld de,039cbh		;589e   ; Fila 14, columna 11
	call PINTA_BLOQUE_4x2		;58a1
	ld hl,06bd5h		;58a4   ; El verde, columna 15
	ld de,039cfh		;58a7
	call PINTA_BLOQUE_4x2		;58aa
	ld hl,06bddh		;58ad   ; El rojo, columna 19
	ld de,039d3h		;58b0
	call PINTA_BLOQUE_4x2		;58b3
	ld hl,06bc7h		;58b6   ; Poste verde de la derecha
	ld de,039f7h		;58b9   ; Fila 15, columna 23: el mismo dibujo que el de la izquierda
PINTA_BLOQUE_3x2:		; Bloque de 3 filas por 2 columnas
	ld bc,00302h		;58bc   ; El quinto poste cae aqui por su propio pie: ni CALL ni RET
	jp PINTA_BLOQUE		;58bf
PINTA_BLOQUE_4x2:		; Bloque de 4 filas por 2 columnas
	ld bc,00402h		;58c2
	jp PINTA_BLOQUE		;58c5
PREPARA_HOGUERA:		; Bit 6: la hoguera al fondo de la pantalla (X=0xDC o 0x14, segun por donde se entre) y su caja invisible, el sprite 31 en Y=0x7C
	ld a,(0e156h)		;58c8
	and 040h		;58cb   ; Bit 6
	ret z			;58cd
	ld hl,0e1aah		;58ce   ; E1AA, la X con la que se cobra la hoguera
	ld a,(0e058h)		;58d1
	cp 008h		;58d4   ; 8 = ha entrado por la izquierda
	ld (hl),0dch		;58d6   ; Entrando por la izquierda esta a la derecha, X=0xDC
	ld a,0d0h		;58d8   ; Y la caja de choque doce puntos a la izquierda de esa X
	jr z,L_58E0		;58da
	ld (hl),014h		;58dc   ; Entrando por la derecha, la hoguera al otro lado
	ld a,020h		;58de
L_58E0:
	ld hl,0e12ch		;58e0   ; Sprite 31: Y=0x7C, X=0xD0 o 0x20, color 0x10 (invisible): la caja de choque
	ld (hl),07ch		;58e3   ; Y=0x7C son los pies del jugador, que anda con Y=0x6C
	inc hl			;58e5
	ld (hl),a			;58e6
	inc hl			;58e7
	inc hl			;58e8   ; El patron ni se toca: con color 0 el sprite no se ve, solo choca
	ld a,010h		;58e9   ; 100 puntos por saltarla
	ld (hl),a			;58eb   ; El color del sprite 31
	ld (0e19ah),a		;58ec   ; El mismo 0x10 sirve dos veces: color del sprite y cien puntos en E19A
	ret			;58ef
PINTA_PIEDRA:		; Bit 5: la piedra con matojo (tiles 0x19-0x1B) en la fila 17, columna 18 o 10, y su caja invisible (sprite 31, Y=0x80)
	ld a,(0e156h)		;58f0
	and 020h		;58f3   ; Bit 5
	ret z			;58f5
	ld hl,0e1abh		;58f6   ; E1AB, la X con la que se cobra la piedra
	ld a,(0e058h)		;58f9
	cp 008h		;58fc
	ld (hl),09eh		;58fe
	ld de,03a12h		;5900   ; Fila 17, columna 18
	ld a,094h		;5903   ; Y la caja invisible en X=0x94, cuatro a la derecha del primer tile
	jr z,L_590E		;5905
	ld de,03a0ah		;5907   ; Entrando por la derecha, fila 17 columna 10
	ld (hl),048h		;590a
	ld a,054h		;590c   ; Y la caja en X=0x54
L_590E:
	ld hl,05929h		;590e   ; Los tres tiles y el 0xFF que los cierra
	ld bc,00203h		;5911
	push af			;5914   ; PINTA_LISTA_TILES se lleva A por delante
	call PINTA_BLOQUE		;5915
	pop af			;5918
	ld hl,0e12ch		;5919   ; El sprite 31, el mismo de la hoguera
	ld (hl),080h		;591c   ; Y=0x80, cuatro mas abajo que la caja de la hoguera: la piedra es mas baja
	inc hl			;591e
	ld (hl),a			;591f
	inc hl			;5920
	inc hl			;5921
	ld a,010h		;5922   ; Otra vez el 0x10 doble: color invisible y cien puntos
	ld (hl),a			;5924   ; El color del 31, otra vez invisible
	ld (0e19bh),a		;5925   ; E19B, el ultimo de los siete que repasa 0x65AB
	ret			;5928

; ----------------------------------------------------------------------
; DATOS bloque_de_la_piedra: Los 6 tiles del bloque de 2x3 que 0x590E pinta
;   (ld bc,0x0203)
;   0x5929..0x592f  (6 bytes)
DATA_bloque_de_la_piedra:
	defb 019h,01ah,00eh	; 5929
	defb 01bh,01ch,01dh	; 592c

; ======================================================================
; CODIGO 0x592f..0x5941  (18 bytes)
; ======================================================================


ROTULO_CHILD_PARK:		; En el SCENE 0 y en los acabados en 0: sin obstaculos ninguno (E156 = E158 = 0) y el rotulo CHILD PARK en ladrillo rojo
	ld a,(0e059h)		;592f
	or a			;5932   ; La pantalla 0, la de salida
	jr z,L_5938		;5933
	and 00fh		;5935   ; SCENE 0, 10, 20...: la entrada y las metas
	ret nz			;5937
L_5938:
	ld (0e156h),a		;5938   ; A vale 0: se borran los obstaculos que acaba de elegir 0x56B4
	ld (0e158h),a		;593b   ; Y los moviles: en la entrada y en las metas no hay nada que esquivar
	call MOTOR_DE_ROTULOS		;593e   ; El cartel, fila 9 columna 9

; ----------------------------------------------------------------------
; DATOS parametros_de_593E: Los seis del call de 0x593E: lista 0x673C, tiles
;   0x6BE5 y VRAM 0x39A9 (fila 13, columna 9)
;   0x5941..0x5947  (6 bytes)
DATA_parametros_de_593E:
	defw 0673ch,06be5h,039a9h	; 5941  -> DATA_lista_motor_673C DATA_rotulo_babyland 0x39a9

; ======================================================================
; CODIGO 0x5947..0x597b  (52 bytes)
; ======================================================================


	ret			;5947
PINTA_EL_TRONCO:		; El bloque de 8x4 de 0x6746, desde la fila 3
	ld hl,06746h		;5948   ; Y su tronco, 8 por 4 desde la fila 8 columna 1
	ld de,03860h		;594b
PINTA_BLOQUE_8x4:		; Bloque de 8 filas por 4 columnas
	ld bc,001a0h		;594e
	call COPIA_A_VRAM		;5951
	ret			;5954
PINTA_SI_TOCA:		; Con el bit 3 de E156, cuatro bloques mas en la fila 13
	ld a,(0e156h)		;5955
	and 008h		;5958
	ret z			;595a
	ld de,039a8h		;595b
	ld b,004h		;595e
L_5960:
	push de			;5960
	push bc			;5961
	ld hl,0597bh		;5962
PINTA_BLOQUE_3x6:		; Bloque de 3 filas por 6 columnas
	ld bc,00303h		;5965
CERRO_DERECHA:		; Filas 2-4, columnas 16-31: el cerro con pendiente
	call PINTA_BLOQUE		;5968   ; Su gemelo de la derecha, con lista y tiles propios
	pop bc			;596b
	pop de			;596c
	ld a,004h		;596d
	call DE_MAS_A		;596f
	ld a,b			;5972
	cp 003h		;5973
	jr nz,L_5978		;5975
	inc de			;5977
L_5978:
	djnz L_5960		;5978
	ret			;597a

; ----------------------------------------------------------------------
; DATOS bloque_3x3: Los 9 tiles del bloque de 3x3 que 0x5962 pinta cuatro
;   veces seguidas (ld bc,0x0303)
;   0x597b..0x5984  (9 bytes)
DATA_bloque_3x3:
	defb 005h,0adh,005h	; 597b
	defb 005h,0adh,005h	; 597e
	defb 005h,0adh,005h	; 5981

; ======================================================================
; CODIGO 0x5984..0x59b8  (52 bytes)
; ======================================================================


COLOCA_JUGADOR:		; Sprites 0-3 fuera, colores de los cuatro sprites del jugador, Y=0x6C, X y mirada segun por donde entra (E058), y sus sprites
	ld hl,059b8h		;5984   ; Y=0x90, patron 0 y color 0: los sprites 0-3 no pintan nada
	call CUATRO_SPRITES_IGUALES		;5987   ; Los sprites 0-3, los cuatro iguales
	call COLOCA_LOS_SPRITES_DEL_DECORADO		;598a
	ld hl,0e134h		;598d   ; Y del suelo
	ld (hl),06ch		;5990   ; Y=0x6C, de pie en el suelo
	inc hl			;5992
	ld a,(0e058h)		;5993   ; X de entrada: 8 por la izquierda, 0xE8 por la derecha
	ld (hl),a			;5996   ; E135, la X
	cp 008h		;5997
	ld a,008h		;5999   ; Mira hacia donde va: 8 derecha, 4 izquierda
	jr z,L_599E		;599b
	rrca			;599d   ; El 8 pasa a 4 con un solo rrca: mirando a la izquierda
L_599E:
	inc hl			;599e
	ld (hl),000h		;599f   ; E136, la pose: de pie
	ld (0e139h),a		;59a1   ; E139, hacia donde mira
	jp PINTA_AL_JUGADOR_ENTERO		;59a4   ; Y a pintarlo ya, sin esperar al fotograma siguiente
CUATRO_SPRITES_IGUALES:		; Copia los 4 bytes de HL a los sprites 0-3
	ld de,0e0b0h		;59a7
	ld bc,00404h		;59aa   ; B = 4 sprites, C = 4 bytes cada uno
L_59AD:
	push hl			;59ad
	push bc			;59ae
	ld b,000h		;59af   ; B a cero para que BC sean 4 en el ldir; el djnz recupera el suyo del push
	ldir		;59b1
	pop bc			;59b3
	pop hl			;59b4
	djnz L_59AD		;59b5
	ret			;59b7

; ----------------------------------------------------------------------
; DATOS sprite_fuera: Y=0x90 y ceros: los sprites 0-3 apartados
;   0x59b8..0x59bc  (4 bytes)
DATA_sprite_fuera:
	defb 090h,000h,000h,000h	; 59b8

; ======================================================================
; CODIGO 0x59bc..0x5a23  (103 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; EL MOTOR DE ROTULOS. Tras cada CALL van SEIS BYTES de parametros:
; puntero a la lista, puntero a los tiles y direccion de VRAM. El
; POP HL los recoge y el PUSH HL devuelve el control detras de ellos.
; La lista es una cuenta por entrada: n copia n tiles de la lista de
; tiles; n|0x80 rellena n posiciones con UN tile; 0x80 solo, cambio de
; direccion (palabra detras); 0 fin. La VRAM avanza siempre n.
; Diecinueve llamadas: los creditos, todos los decorados y, en 0x6D24,
; las tablas de COLORES de los tiles.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
MOTOR_DE_ROTULOS:		; Pinta la lista de tiles que describen los 6 bytes que siguen al CALL
	pop hl			;59bc   ; HL = los seis bytes de parametros
	ld de,0e150h		;59bd   ; E150 la lista, E152 los tiles, E154 la VRAM
	ld bc,00006h		;59c0   ; Los seis: dos punteros y una direccion de VRAM
	ldir		;59c3
	push hl			;59c5   ; Se vuelve detras de los parametros
ROTULO_ENTRADA:		; Siguiente entrada de la lista
	ld hl,(0e150h)		;59c6   ; Por donde va la lista
	ld a,(hl)			;59c9   ; El byte de la entrada
	cp 080h		;59ca   ; 0x80: direccion nueva
	jr nz,L_59DB		;59cc
	inc hl			;59ce   ; Detras del 0x80 viene la VRAM nueva
	ld e,(hl)			;59cf
	inc hl			;59d0
	ld d,(hl)			;59d1
	inc hl			;59d2
	ld (0e150h),hl		;59d3
	ld (0e154h),de		;59d6
	ld a,(hl)			;59da   ; Y se sigue con la entrada que venga despues
L_59DB:
	or a			;59db
	ret z			;59dc   ; 0: fin
	ld b,a			;59dd   ; B se queda el byte con su bit 7
	and 07fh		;59de   ; C, la cuenta sin el
	ld c,a			;59e0
	xor a			;59e1   ; El xor va delante del bit para no pisar el flag que decide relleno o copia
	bit 7,b		;59e2   ; Bit 7: relleno con un solo tile
	ld b,a			;59e4
	ld hl,(0e152h)		;59e5   ; HL los tiles...
	ld de,(0e154h)		;59e8   ; ...y DE la VRAM
	jr z,L_59F6		;59ec   ; El flag que se mira es el del bit 7, no el del xor de dos instrucciones antes
	ld a,(hl)			;59ee
	call RELLENA_VRAM		;59ef   ; Relleno de C posiciones con el tile (HL)
	ld a,001h		;59f2   ; El relleno gasta un solo tile de la lista
	jr ROTULO_AVANZA		;59f4
L_59F6:
	push bc			;59f6
	call COPIA_A_VRAM		;59f7   ; Copia de C tiles
	pop bc			;59fa
	ld a,c			;59fb   ; La copia gasta C
ROTULO_AVANZA:		; Avanza los tiles (1 o C) y la VRAM (C)
	ld hl,(0e152h)		;59fc
	call HL_MAS_A		;59ff   ; El puntero de tiles avanza 1 o C
	ld (0e152h),hl		;5a02
	ld hl,(0e150h)		;5a05
	ld a,(hl)			;5a08
	and 07fh		;5a09   ; La VRAM avanza siempre C, lleve el byte el bit 7 o no
	inc hl			;5a0b   ; Y la lista, una entrada
	ld (0e150h),hl		;5a0c
	ld hl,(0e154h)		;5a0f
	call HL_MAS_A		;5a12
	ld (0e154h),hl		;5a15
	jp ROTULO_ENTRADA		;5a18   ; Y a por la entrada siguiente hasta dar con el 0
RELLENA_CADA_32:		; Escribe B veces (HL) en DE sumando 32 cada vez: las X de una fila de obstaculos
	ld a,(hl)			;5a1b
L_5A1C:
	ld (de),a			;5a1c
	add a,020h		;5a1d   ; 32 puntos de X entre obstaculo y obstaculo: cuatro columnas de tiles
	inc de			;5a1f
	djnz L_5A1C		;5a20
	ret			;5a22

; ----------------------------------------------------------------------
; DATOS x_de_obstaculos: Seis X de arranque, a las que 0x5A1B va sumando 32,
;   para cobrar al pasar: entrando por la izquierda, postes 0x30, trampolines
;   0x48, charcos 0x40; entrando por la derecha, 0x48, 0x48 y 0x30
;   0x5a23..0x5a29  (6 bytes)
DATA_x_de_obstaculos:
	defb 030h,048h,040h,048h,048h,030h	; 5a23

; ======================================================================
; CODIGO 0x5a29..0x5af7  (206 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; LOS CONTADORES. Cada fotograma: E130; y a su ritmo E131 (cada 8),
; E133 (cada 10), E14D (cada 9), E14F (cada 11): las fases de las dos
; lianas y de los cuatro surtidores, que asi no van a la par. Con E131
; sube E17B (la abeja) y con E133 los aranas E17C-E17E; E176-E178
; (los peces) siempre; y bajan los cuatro tiempos de los rotulos de puntos.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
CONTADORES:		; Los contadores de fases y las esperas de los moviles
	ld de,0e17bh		;5a29   ; DE se queda en la espera de la abeja; HL va recorriendo los contadores
	ld hl,0e130h		;5a2c
	inc (hl)			;5a2f   ; E130 sube un fotograma
	ld a,(hl)			;5a30
	and 007h		;5a31   ; Cada 8 fotogramas: E131 y la espera de la abeja
	inc hl			;5a33   ; HL a E131
	jr nz,L_5A3A		;5a34
	inc (hl)			;5a36   ; E131, la fase de una liana y de un surtidor
	ex de,hl			;5a37   ; Y al mismo ritmo E17B, lo que le queda a la abeja para salir
	inc (hl)			;5a38
	ex de,hl			;5a39
L_5A3A:
	inc hl			;5a3a   ; E132, el divisor por 10
	inc (hl)			;5a3b
	ld a,(hl)			;5a3c
	cp 00ah		;5a3d   ; Cada 10: E133 y las tres fases de los aranas
	jr nz,L_5A4C		;5a3f
	xor a			;5a41
	ld (hl),a			;5a42   ; A cero, que es un divisor y no un contador libre como E130
	inc hl			;5a43
	inc (hl)			;5a44   ; E133, la fase de la otra liana y del otro surtidor
	ex de,hl			;5a45   ; DE seguia en E17B: E17C, E17D y E17E son las tres aranas
	inc hl			;5a46
	inc (hl)			;5a47
	inc hl			;5a48
	inc (hl)			;5a49
	inc hl			;5a4a
	inc (hl)			;5a4b
L_5A4C:
	ld hl,0e14ch		;5a4c   ; E14C, el divisor por 9
	inc (hl)			;5a4f
	ld a,(hl)			;5a50
	cp 009h		;5a51   ; Cada 9: E14D
	jr nz,L_5A5B		;5a53
	xor a			;5a55
	ld (hl),a			;5a56
	inc hl			;5a57
	inc (hl)			;5a58   ; E14D
	jr L_5A5C		;5a59
L_5A5B:
	inc hl			;5a5b   ; Sin dar la vuelta HL tiene que llegar igual a E14E
L_5A5C:
	inc hl			;5a5c   ; E14E, el divisor por 11
	inc (hl)			;5a5d
	ld a,(hl)			;5a5e
	cp 00bh		;5a5f   ; Cada 11: E14F
	jr nz,L_5A67		;5a61
	xor a			;5a63
	ld (hl),a			;5a64
	inc hl			;5a65
	inc (hl)			;5a66   ; E14F
L_5A67:
	ld hl,0e176h		;5a67   ; Las tres esperas de los peces
	inc (hl)			;5a6a   ; E176, E177 y E178 suben cada fotograma: los peces no llevan divisor
	inc hl			;5a6b
	inc (hl)			;5a6c
	inc hl			;5a6d
	inc (hl)			;5a6e
	ld b,004h		;5a6f   ; Los cuatro rotulos de puntos, hacia cero
	ld hl,0e181h		;5a71   ; E181-E184, lo que le queda en pantalla a cada rotulo de puntos
L_5A74:
	ld a,(hl)			;5a74
	or a			;5a75   ; Se para en cero: sin esto daria la vuelta a 0xFF
	jr z,L_5A79		;5a76
	dec (hl)			;5a78
L_5A79:
	inc hl			;5a79
	djnz L_5A74		;5a7a
	ret			;5a7c
LIANAS:		; Bit 1 de E156: pinta las dos lianas en su fase (E131 y E133) y guarda donde esta el cabo de cada una (E140-E143)
	ld a,(0e156h)		;5a7d
	and 002h		;5a80   ; Bit 1
	ret z			;5a82
	ld de,038cah		;5a83   ; Liana 1 en la fila 6, columna 10
	ld a,(0e131h)		;5a86   ; Su fase es la del divisor de 8
	call PINTA_LIANA		;5a89   ; Devuelve en B, C y D los tres bytes que van detras del 0xFF del dibujo
	ld hl,0e140h		;5a8c   ; E140 la Y del cabo y E141 una de sus dos X
	ld (hl),b			;5a8f
	inc hl			;5a90
	ld (hl),c			;5a91
	ld de,038d6h		;5a92   ; Liana 2 en la columna 22, doce columnas mas alla
	ld a,(0e133h)		;5a95   ; La otra va con el de 10: asi las dos lianas nunca se balancean a la vez
	call PINTA_LIANA		;5a98
	ld hl,0e142h		;5a9b   ; E142 la Y, y E143 la OTRA X que devuelve el dibujo (D, no C)
	ld (hl),b			;5a9e
	inc hl			;5a9f
	ld (hl),d			;5aa0
	ret			;5aa1
SURTIDORES:		; Bit 3: pinta las cuatro tablas de los surtidores en su fase (fila 10, columnas 8, 12, 17, 21) y guarda la altura de cada una en E148-E14B; y el borde de agua de la fila 16
	ld a,(0e156h)		;5aa2
	and 008h		;5aa5   ; Bit 3
	ret z			;5aa7
	ld b,008h		;5aa8
	ld a,(0e131h)		;5aaa   ; Su fase es la misma que la de una de las lianas
	call PINTA_SURTIDOR		;5aad
	ld (0e148h),a		;5ab0   ; E148, la altura de la tabla de la izquierda: por ahi se anda por encima
	ld b,011h		;5ab3
	ld a,(0e14dh)		;5ab5
	call PINTA_SURTIDOR		;5ab8
	ld (0e14ah),a		;5abb
	ld b,00ch		;5abe
	ld a,(0e133h)		;5ac0
	call PINTA_SURTIDOR		;5ac3
	ld (0e149h),a		;5ac6
	ld b,015h		;5ac9
	ld a,(0e14fh)		;5acb
	call PINTA_SURTIDOR		;5ace
	ld (0e14bh),a		;5ad1   ; E148-E14B quedan de izquierda a derecha, no en el orden en que se pintan
	ld hl,05af7h		;5ad4   ; El agua de la fila 16, columnas 8-24
	call PINTA_LISTA		;5ad7
	ld a,0c1h		;5ada
	ld de,03a29h		;5adc   ; Fila 17, columna 9
	call VPOKE		;5adf
	ld de,03a36h		;5ae2   ; Y columna 22: los dos de fuera llevan el mismo tile 0xCB
	call VPOKE		;5ae5
	ld a,0c2h		;5ae8
	ld de,03a2dh		;5aea
	call VPOKE		;5aed
	ld de,03a32h		;5af0
	call VPOKE		;5af3
	ret			;5af6

; ----------------------------------------------------------------------
; DATOS lista_5AF7: lista de 14 tiles con su VRAM delante, la pinta 0x5AD7
;   0x5af7..0x5b08  (17 bytes)
DATA_lista_5AF7:
	defb 009h,03ah,0c3h,0cch,0cch,0cdh,0c4h,0cdh,0cdh,0cdh,0cdh,0c4h,0cdh,0cch,0cch,0c3h	; 5af7  .:..............
	defb 0ffh	; 5b07

; ======================================================================
; CODIGO 0x5b08..0x5c71  (361 bytes)
; ======================================================================


PINTA_SURTIDOR:		; Bloque de 6x3 de la fase A (0..31: sube hasta la 17 y baja) en la VRAM DE; devuelve en A la altura de la tabla
	and 01fh		;5b08   ; La fase, 0..31
	cp 012h		;5b0a   ; De la 18 a la 31 se repite hacia atras: la tabla sube y baja
	jr c,L_5B13		;5b0c
	neg		;5b0e   ; 33 menos A: de la 18 a la 31 se recorren los dibujos 15 a 2, y la tabla parece bajar
	inc a			;5b10
	and 01fh		;5b11
L_5B13:
	push af			;5b13
	ld hl,053efh		;5b14   ; Tabla de 18 bloques
	rlca			;5b17   ; Por dos: la tabla es de palabras
	call HL_MAS_A		;5b18
	ld e,(hl)			;5b1b
	inc hl			;5b1c
	ld d,(hl)			;5b1d
	ex de,hl			;5b1e   ; El bloque a HL y la VRAM otra vez a DE
	ld e,(hl)			;5b1f
	inc hl			;5b20
	ld d,(hl)			;5b21
	ld a,b			;5b22
	call DE_MAS_A		;5b23
	push de			;5b26
	inc hl			;5b27
	ld e,(hl)			;5b28
	inc hl			;5b29
	ld d,(hl)			;5b2a
	inc hl			;5b2b
	ld b,(hl)			;5b2c
	ex de,hl			;5b2d
	pop de			;5b2e
	pop af			;5b2f
	push bc			;5b30
	ld bc,00303h		;5b31
	cp 00fh		;5b34
	jr nz,L_5B3B		;5b36
	ld bc,00403h		;5b38   ; Seis filas por tres columnas, 18 bytes
L_5B3B:
	call PINTA_BLOQUE		;5b3b   ; Y HL queda justo detras de los 18
	pop bc			;5b3e
	ld a,b			;5b3f
	ret			;5b40
PINTA_LIANA:		; La liana en la fase A (0..15: 9 dibujos, del 9 en adelante hacia atras) desde DE; devuelve B=Y y C, D = las dos X del cabo
	and 00fh		;5b41   ; La fase, 0..15
	cp 009h		;5b43   ; Del 9 al 15 se repite hacia atras: la liana va y vuelve
	jr c,L_5B4B		;5b45
	neg		;5b47   ; 16 menos A: del 9 al 15 se repiten los dibujos 7 a 1
	and 00fh		;5b49
L_5B4B:
	ld hl,0526dh		;5b4b   ; Tabla de 9 dibujos
	rlca			;5b4e   ; Por dos: palabras otra vez
	call HL_MAS_A		;5b4f
	push de			;5b52
	ld e,(hl)			;5b53
	inc hl			;5b54
	ld d,(hl)			;5b55
	ex de,hl			;5b56
	pop de			;5b57
PINTA_DIBUJO:		; Un dibujo de tiles: 0xFF fin, 0xFE/0xFD/0xFC bajan una fila (una columna a la izquierda, la misma, una a la derecha), lo demas tiles
	push de			;5b58   ; La DE del principio de la fila, que hara falta al bajar
PINTA_DIBUJO_BUCLE:		; Siguiente byte
	ld a,(hl)			;5b59
	inc hl			;5b5a
	ld b,a			;5b5b   ; Los cuatro codigos se prueban sumando uno cada vez
	inc b			;5b5c
	jr z,PINTA_DIBUJO_FIN		;5b5d   ; 0xFF: fin, y detras vienen Y, X1 y X2 del cabo
	inc b			;5b5f
	jr nz,L_5B6A		;5b60
	ld a,01fh		;5b62   ; 0xFE: fila siguiente, una columna a la izquierda
L_5B64:
	pop de			;5b64   ; Vuelve al principio de la fila...
	call DE_MAS_A		;5b65   ; ...y baja 32, mas o menos una columna
	jr PINTA_DIBUJO		;5b68   ; Otra vez por el push: la fila nueva pasa a ser el origen
L_5B6A:
	inc b			;5b6a
	jr nz,L_5B71		;5b6b
	ld a,020h		;5b6d   ; 0xFD: fila siguiente, misma columna
	jr L_5B64		;5b6f
L_5B71:
	inc b			;5b71
	jr nz,L_5B78		;5b72
	ld a,021h		;5b74   ; 0xFC: fila siguiente, una a la derecha
	jr L_5B64		;5b76
L_5B78:
	call VPOKE		;5b78   ; Lo que no sea codigo es un tile
	inc de			;5b7b   ; Y a la columna de al lado
	jr PINTA_DIBUJO_BUCLE		;5b7c
PINTA_DIBUJO_FIN:		; B, C, D = los tres bytes de detras del 0xFF
	pop de			;5b7e
	ld b,(hl)			;5b7f   ; Y, X1 y X2: donde ha quedado el cabo de la liana
	inc hl			;5b80
	ld c,(hl)			;5b81
	inc hl			;5b82
	ld d,(hl)			;5b83
	ret			;5b84

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; LAS BOLAS QUE RUEDAN. Una (sprite 14) y, de la fase 3 en adelante,
; otra (sprite 15) cada 32 o 64 fotogramas. Ruedan siempre hacia la
; izquierda a un punto por fotograma, dando botes con el arco que eligio
; 5B5C (alto 0x5D67, casi plano 0x5D79 o medio 0x6627). Al acabar el arco
; vuelven a Y=0x7E (el suelo) con el sonido 8. 50 puntos por pasarlas.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
BOLAS_QUE_RUEDAN:		; Bits 0-2 de E159: mueve la bola (y la segunda si toca)
	ld a,(0e159h)		;5b85
	and 007h		;5b88   ; Bits 0-2 de E159, la copia de los moviles que solo miran las bolas
	ret z			;5b8a
	ld ix,0e1b0h		;5b8b
	ld iy,0e1ach		;5b8f
	ld hl,0e0e8h		;5b93   ; E0E8 es el sprite 14
	ld de,0e164h		;5b96
	call UN_PASO_DEL_ARCO		;5b99
	ld a,(0e051h)		;5b9c   ; La segunda bola solo de la fase 3 en adelante
	cp 003h		;5b9f
	ret c			;5ba1
	ld hl,0e187h		;5ba2   ; E187, los fotogramas que lleva la pantalla
	inc (hl)			;5ba5
	ld b,070h		;5ba6
	bit 2,a		;5ba8   ; A sigue siendo la fase
	jr nz,L_5BAE		;5baa
	ld b,050h		;5bac
L_5BAE:
	ld a,(hl)			;5bae   ; E188 a 1 el fotograma justo; a partir de ahi la segunda bola ya no vuelve a esperar
	inc hl			;5baf
	cp b			;5bb0
	jr nz,L_5BB5		;5bb1
	ld (hl),001h		;5bb3
L_5BB5:
	ld a,(hl)			;5bb5   ; Sin ese 1 no hay segunda bola
	rra			;5bb6
	ret nc			;5bb7
	inc iy		;5bb8
	ld ix,0e1b3h		;5bba
	ld hl,0e0ech		;5bbe   ; E0EC es el sprite 15
	ld de,0e165h		;5bc1
UN_PASO_DEL_ARCO:		; Un paso del arco de este bicho; al acabarse, el que sigue
	ld a,(de)			;5bc4
	or a			;5bc5   ; Sin arco no hay nada que mover
	jr z,L_5BEC		;5bc6
	ld c,001h		;5bc8
	call CAMBIA_LA_X		;5bca
	inc hl			;5bcd
	ld a,(hl)			;5bce
	ld (iy+000h),a		;5bcf
	inc a			;5bd2
	jr nz,L_5BDA		;5bd3
	ld a,005h		;5bd5   ; Cinco, en el byte que IY tiene diez mas abajo
	ld (iy-010h),a		;5bd7
L_5BDA:
	ld a,b			;5bda
	or a			;5bdb
	ret nz			;5bdc
L_5BDD:
	dec hl			;5bdd
BOLA_ARRANCA:		; Y=0x7E, patron 0xC4 (la bola grande), rojo, sonido 8
	ld (hl),07eh		;5bde   ; Y=0x7E, rodando por el suelo
	inc hl			;5be0   ; La X no se toca: la bola sigue por donde iba
	inc hl			;5be1
	ld (hl),0c4h		;5be2   ; Patron 0xC4
	inc hl			;5be4
	ld (hl),002h		;5be5
	ld a,007h		;5be7
	jp SONIDO		;5be9
L_5BEC:
	ld a,001h		;5bec
	ld (de),a			;5bee
	inc hl			;5bef   ; Ahora (HL) es la X
	ld (hl),0f0h		;5bf0
	jr L_5BDD		;5bf2

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; LOS PECES. Bit 4 de E158 y charcos o estanque: tres peces (sprites
; 11-13) que saltan uno tras otro cuando su espera (E176-E178) llega a
; 0x1F, con el arco de salto 0x5D8B (el mismo del jugador), y al caer
; vuelven a salir por una X al azar de las de los charcos (0x5C71),
; Y=0x8C, con el sonido 7. Tres dibujos: subiendo, bajando y arriba
; del todo. El arco sube 96 puntos en 26 pasos y baja los mismos en
; 25: 51 fotogramas de salto que devuelven la Y a donde estaba.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
PECES:		; Los tres peces que saltan de los charcos o del estanque
	ld a,(0e158h)		;5bf4   ; Bit 4 de E158: esta pantalla lleva peces
	and 010h		;5bf7
	ret z			;5bf9
	ld a,(0e156h)		;5bfa   ; Y bits 0 o 7 de E156: hacen falta charcos o estanque de donde salir
	and 081h		;5bfd
	ret z			;5bff
	ld ix,0e1b6h		;5c00
	ld bc,00300h		;5c04
L_5C07:
	push bc			;5c07
	ld hl,0e0dch		;5c08
	ld a,c			;5c0b
	add a,a			;5c0c
	add a,a			;5c0d
	call HL_MAS_A		;5c0e
	ld de,0e176h		;5c11
	ld a,c			;5c14
	call DE_MAS_A		;5c15
	ld iy,0e16fh		;5c18
	ld b,000h		;5c1c
	add iy,bc		;5c1e
	ld a,(de)			;5c20
	cp 0c0h		;5c21
	jr z,L_5C3A		;5c23
	cp 01fh		;5c25   ; Espera cumplida
	jr c,SIGUIENTE_DE_LA_TANDA		;5c27
	ld a,(iy+000h)		;5c29
	or a			;5c2c
	jr z,SIGUIENTE_DE_LA_TANDA		;5c2d
	push de			;5c2f
	ld c,000h		;5c30   ; C=0: el arco solo mueve la Y, el pez sube y baja a plomo
	call CAMBIA_LA_X		;5c32
	pop de			;5c35
	ld a,b			;5c36
	or a			;5c37   ; Con B a cero se arranca el bicho; si no, ya estaba en marcha
	jr nz,L_5C59		;5c38
L_5C3A:
	push hl			;5c3a
	xor a			;5c3b
	ld (de),a			;5c3c
	ld (hl),08ch		;5c3d   ; Y=0x8C: asomando por el agua
	inc hl			;5c3f
	ld de,05c71h		;5c40   ; La tabla de ocho X de 0x5C71
	ld a,r		;5c43   ; El registro de refresco hace de azar: una de las ocho X
	and 007h		;5c45   ; Los tres bits bajos de R: una de las ocho
	call DE_MAS_A		;5c47
	ld a,(de)			;5c4a
	ld (hl),a			;5c4b
	inc hl			;5c4c   ; Dos adelante: el patron se lo pone el que llamo, al volver
	inc hl			;5c4d
	ld (hl),00eh		;5c4e
	ld a,006h		;5c50
	call SONIDO		;5c52
	ld (iy+000h),a		;5c55
	pop hl			;5c58
L_5C59:
	ld c,0b8h		;5c59
	bit 7,(ix+000h)		;5c5b
	jr z,L_5C63		;5c5f
	ld c,0c0h		;5c61
L_5C63:
	inc hl			;5c63
	inc hl			;5c64
	ld (hl),c			;5c65
SIGUIENTE_DE_LA_TANDA:		; Pasa al siguiente de los bichos: tres bytes por ficha
	pop bc			;5c66
	inc c			;5c67
	inc ix		;5c68   ; Tres inc: cada ficha son tres bytes
	inc ix		;5c6a
	inc ix		;5c6c
	djnz L_5C07		;5c6e
	ret			;5c70

; ----------------------------------------------------------------------
; DATOS x_de_los_peces: Ocho X por donde puede asomar un pez: 0x38, 0x58,
;   0x58, 0x78, 0x78, 0x98, 0x98 y 0xB8. La elige 0x5C40 con los tres bits
;   bajos del registro R
;   0x5c71..0x5c79  (8 bytes)
DATA_x_de_los_peces:
	defb 038h,058h,058h,078h,078h,098h,098h,0b8h	; 5c71  8XXxx...

; ======================================================================
; CODIGO 0x5c79..0x5d06  (141 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; LA BOLA QUE BOTA (sprite 22). Bit 6 de E158, un fotograma de cada
; dos: cruza la pantalla botando (arco 0x5D8B) desde el lado contrario al
; del jugador, avanzando 1 a 3 puntos por fotograma al azar (E172).
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
BOLA_QUE_BOTA:		; La bola pequena que viene botando por el aire
	ld a,(0e158h)		;5c79   ; Bit 6 de E158: esta pantalla lleva bola que bota
	and 040h		;5c7c
	ret z			;5c7e
	ld a,(0e003h)		;5c7f   ; E175 el sentido y E173 el puntero, los dos del arco 0x5D8B
	rra			;5c82
	ret nc			;5c83
	ld hl,0e108h		;5c84   ; E108 es el sprite 22
	ld a,(0e172h)		;5c87   ; E172, el azar de la vuelta anterior: a cero se sortea uno nuevo
	or a			;5c8a
	jr z,L_5C98		;5c8b
	ld c,a			;5c8d
	ld ix,0e1bfh		;5c8e
	call CAMBIA_LA_X		;5c92
	ld a,b			;5c95
	or a			;5c96
	ret nz			;5c97
L_5C98:
	ld a,r		;5c98
	set 7,a		;5c9a
	ld (0e172h),a		;5c9c
	ld (hl),08ch		;5c9f
	ld a,(0e058h)		;5ca1   ; Entrando el jugador por la izquierda (E058=8) la bola cruza de derecha a izquierda: reaparece en X=0xD0
	cp 008h		;5ca4
	ld a,0d0h		;5ca6
	jr z,L_5CAC		;5ca8
	ld a,020h		;5caa   ; Y al reves, en X=0x20
L_5CAC:
	inc hl			;5cac
	ld (hl),a			;5cad
	inc hl			;5cae
	ld (hl),0c8h		;5caf
	inc hl			;5cb1
	ld (hl),009h		;5cb2
	ld a,004h		;5cb4   ; Sonido 4: la bola vuelve a entrar
	jp SONIDO		;5cb6

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; LAS ARANAS (redondas con ocho patas, sprite 51). Bit 3 de E158: tres
; (sprites 16-18) en X=0x58, 0x78 y 0x98. Su fase (E17C-E17E) sube cada
; 10 fotogramas: en la 8 aparecen arriba (Y=0x28) y se balancean diez
; puntos a cada lado; de la 15 en adelante caen dos puntos por fotograma
; hasta el suelo (0x8C) y vuelven a la fase 0. Blancas, patron 0xCC.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
ARANAS:		; Las tres aranas que se descuelgan de arriba
	ld a,(0e158h)		;5cb9   ; Bit 3 de E158: esta pantalla lleva aranas
	and 008h		;5cbc
	ret z			;5cbe
	ld hl,0e0f0h		;5cbf   ; E0F0 es el sprite 16, el primero de los tres
	ld de,0e17ch		;5cc2
	ld bc,00300h		;5cc5
EL_BICHO_QUE_BAJA:		; Aparece en la fase 8, y de la 15 en adelante baja dos puntos por fotograma hasta el fondo
	push hl			;5cc8
	ld a,(de)			;5cc9
	cp 008h		;5cca   ; Fase 8: aparece
	jr z,L_5CE7		;5ccc
	cp 00fh		;5cce
	jr c,L_5CFD		;5cd0
	inc (hl)			;5cd2   ; Dos puntos por fotograma
	inc (hl)			;5cd3
	ld a,(hl)			;5cd4
	cp 08ch		;5cd5   ; Pasado 0x8C ha llegado abajo: vuelve arriba (Y=0x90) y la fase se reinicia
	jr c,SIGUE_BAJANDO		;5cd7
	xor a			;5cd9
	ld (de),a			;5cda
	ld (hl),090h		;5cdb
SIGUE_BAJANDO:		; Lo que hace mientras cae
	pop hl			;5cdd   ; La X, que tambien se mueve
	inc c			;5cde
	inc hl			;5cdf
	inc hl			;5ce0
	inc hl			;5ce1
	inc hl			;5ce2
	inc de			;5ce3
	djnz EL_BICHO_QUE_BAJA		;5ce4
	ret			;5ce6
L_5CE7:
	push de			;5ce7
	ld (hl),028h		;5ce8
	ld de,05d06h		;5cea
	ld a,c			;5ced
	call DE_MAS_A		;5cee   ; Una de las tres X de la tabla de 0x5D06, la que diga C
	ld a,(de)			;5cf1
	inc hl			;5cf2
	ld (hl),a			;5cf3   ; La X que trae A; mientras la fase valga 8 se vuelve a clavar aqui, diez fotogramas seguidos
	inc hl			;5cf4
	ld (hl),0cch		;5cf5   ; Patron 0xCC, color 15 (blanco)
	inc hl			;5cf7
	ld (hl),001h		;5cf8
	pop de			;5cfa
	jr SIGUE_BAJANDO		;5cfb
L_5CFD:
	inc hl			;5cfd
	dec (hl)			;5cfe
	rra			;5cff
	jr nc,SIGUE_BAJANDO		;5d00
	inc (hl)			;5d02   ; Baja dos puntos por fotograma
	inc (hl)			;5d03
	jr SIGUE_BAJANDO		;5d04

; ----------------------------------------------------------------------
; DATOS x_de_tres: Tres X (0x58, 0x78, 0x98) que 0x5CEA indexa con C
;   0x5d06..0x5d09  (3 bytes)
DATA_x_de_tres:
	defb 058h,078h,098h	; 5d06

; ======================================================================
; CODIGO 0x5d09..0x5d66  (93 bytes)
; ======================================================================


CAMBIA_LA_X:		; Suma o resta a la X segun los bits del azar de C
	ld b,(ix+000h)		;5d09   ; El azar decide de cuanto es el paso
	ld e,(ix+001h)		;5d0c
	ld d,(ix+002h)		;5d0f
	ld a,(de)			;5d12
	bit 7,b		;5d13
	jr nz,MUEVE_EN_HORIZONTAL		;5d15
	neg		;5d17
MUEVE_EN_HORIZONTAL:		; Corre la X y decide si sigue o se da la vuelta, mirando por donde entro el jugador
	add a,(hl)			;5d19   ; La X, mas lo que toque
	ld (hl),a			;5d1a
	inc hl			;5d1b
	bit 0,c		;5d1c
	jr z,DA_LA_VUELTA		;5d1e
	ld a,(0e058h)		;5d20   ; E058: 8 si entro por la izquierda, 0xE8 si por la derecha
	cp 008h		;5d23
	jr z,L_5D38		;5d25
	bit 7,c		;5d27
	jr z,L_5D38		;5d29
	bit 1,c		;5d2b
	jr z,L_5D35		;5d2d
	bit 2,c		;5d2f
	jr z,L_5D34		;5d31
	inc (hl)			;5d33
L_5D34:
	inc (hl)			;5d34
L_5D35:
	inc (hl)			;5d35
	jr DA_LA_VUELTA		;5d36
L_5D38:
	bit 1,c		;5d38
	jr z,L_5D42		;5d3a
	bit 2,c		;5d3c
	jr z,L_5D41		;5d3e
	dec (hl)			;5d40
L_5D41:
	dec (hl)			;5d41
L_5D42:
	dec (hl)			;5d42
DA_LA_VUELTA:		; Cambia el sentido y corre la X un punto hacia el nuevo lado
	ex de,hl			;5d43
	bit 7,b		;5d44   ; El bit 7 del sentido dice si va a la izquierda
	jr nz,L_5D4C		;5d46
	inc b			;5d48
	inc hl			;5d49
	jr L_5D4E		;5d4a
L_5D4C:
	dec b			;5d4c
	dec hl			;5d4d
L_5D4E:
	ld a,(hl)			;5d4e
	inc a			;5d4f
	jr nz,L_5D55		;5d50
	dec hl			;5d52
	set 7,b		;5d53
L_5D55:
	inc a			;5d55
	jr nz,GUARDA_LA_FICHA		;5d56
	inc hl			;5d58   ; HL a la X del sprite
	ld b,a			;5d59
GUARDA_LA_FICHA:		; Deja en la ficha el sentido y el puntero por el que iba el arco
	ld (ix+000h),b		;5d5a   ; +0 el sentido, +1 y +2 el puntero
	ld (ix+001h),l		;5d5d
	ld (ix+002h),h		;5d60
	ex de,hl			;5d63
	dec hl			;5d64
	ret			;5d65

; ----------------------------------------------------------------------
; DATOS arco_alto: El arco de salto alto (0xFE ... 0xFF): 6 5 5 5 4 4 3 3 3 3
;   2 2 2 1 0 0. Lo usa la bola que rueda cuando el bit 0 de E158 esta a 1
;   0x5d66..0x5d78  (18 bytes)
DATA_arco_alto:
	defb 0feh,000h,000h,000h,001h,000h,000h,000h,001h,000h,000h,000h,001h,000h,000h,000h	; 5d66  ................
	defb 000h,0ffh	; 5d76

; ----------------------------------------------------------------------
; DATOS arco_plano: El arco casi plano: 0 0 0 1 0 0 0 1 0 0 0 1 0 0 0 0. La
;   bola que rueda por defecto
;   0x5d78..0x5d8a  (18 bytes)
DATA_arco_plano:
	defb 0feh,000h,008h,008h,008h,008h,008h,008h,007h,007h,005h,005h,004h,004h,003h,003h	; 5d78  ................
	defb 002h,001h	; 5d88

; ----------------------------------------------------------------------
; DATOS arco_de_salto: El arco del jugador (0x6196), de la bola que bota y de
;   los tres peces (0x56A2): 8 8 8 8 8 8 7 7 5 5 4 4 3 3 2 1 1 1 1 1 1 1 1 0
;   0, que suman 96 puntos de subida
;   0x5d8a..0x5da6  (28 bytes)
DATA_arco_de_salto:
	defb 001h,001h,001h,001h,001h,001h,001h,000h,000h,0ffh,0feh,008h,007h,006h,005h,004h	; 5d8a  ................
	defb 003h,003h,003h,002h,002h,002h,001h,001h,001h,000h,000h,0ffh	; 5d9a  ............

; ======================================================================
; CODIGO 0x5da6..0x5dcb  (37 bytes)
; ======================================================================


HOGUERA:		; Bit 6 de E156: la hoguera de 2x2 en la fila 16, columna 26 o 4, con las llamas cambiando cada 11 fotogramas (bit 0 de E14F)
	ld a,(0e156h)		;5da6   ; Bit 6 de E156: esta pantalla lleva hoguera
	and 040h		;5da9
	ret z			;5dab
	ld a,(0e14fh)		;5dac   ; E14F sube cada 11 fotogramas (0x5A66)
	bit 0,a		;5daf
	ld hl,05dcbh		;5db1   ; Con el bit 0 puesto, los cuatro tiles de las llamas altas
	jr nz,L_5DB9		;5db4
	ld hl,05dcfh		;5db6   ; Y sin el, los de las bajas: la hoguera cambia de dibujo cada 11 fotogramas
L_5DB9:
	ld de,03a1ah		;5db9   ; 0x3A1A es la tabla de nombres (0x3800) mas 538: fila 16, columna 26
	ld a,(0e058h)		;5dbc
	cp 008h		;5dbf
	jr z,L_5DC6		;5dc1
	ld de,03a04h		;5dc3   ; Entrando por la derecha, 0x3A04: fila 16, columna 4; la hoguera se pinta siempre al fondo del camino
L_5DC6:
	ld bc,00202h		;5dc6   ; Dos filas por dos columnas
	jr $+10		;5dc9   ; jr $+10 es 0x5DD3: se cae en PINTA_BLOQUE saltando por encima de los ocho bytes de tiles

; ----------------------------------------------------------------------
; DATOS hoguera_a: Los cuatro tiles de la hoguera, llamas altas: 0xE6 0xE7 /
;   0xE8 0xE9
;   0x5dcb..0x5dcf  (4 bytes)
DATA_hoguera_a:
	defb 0d0h,0d1h	; 5dcb
	defb 0d2h,0d3h	; 5dcd

; ----------------------------------------------------------------------
; DATOS hoguera_b: Llamas bajas: 0xEA 0xEB / 0xE8 0xE9
;   0x5dcf..0x5dd3  (4 bytes)
DATA_hoguera_b:
	defb 0d4h,0d5h	; 5dcf
	defb 0d6h,0d7h	; 5dd1

; ======================================================================
; CODIGO 0x5dd3..0x5e61  (142 bytes)
; ======================================================================


PINTA_BLOQUE:		; Bloque de B filas por C columnas de tiles desde HL en la VRAM DE
	push bc			;5dd3   ; Las dos cuentas y el principio de la fila, a la pila
	push de			;5dd4   ; DE, para volver luego al principio de esta fila
PINTA_BLOQUE_FILA:		; Una fila
	ld a,(hl)			;5dd5   ; Un tile
	call VPOKE		;5dd6   ; VPOKE devuelve DE como estaba (el res 6,d esta en 0x47D1): se puede seguir contando con el
	inc hl			;5dd9
	inc de			;5dda
	dec c			;5ddb   ; C columnas
	jr nz,PINTA_BLOQUE_FILA		;5ddc
	pop de			;5dde   ; Otra vez el principio de la fila
	ld a,020h		;5ddf   ; Mas 32: la fila de abajo
	call DE_MAS_A		;5de1
	pop bc			;5de4   ; La pila devuelve tambien C, la anchura, para la fila siguiente
	djnz PINTA_BLOQUE		;5de5
	ret			;5de7

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; LA ABEJA (sprites 20 y 21, amarillo y negro). Bit 7 de E158: cuando su
; espera E17B llega a 8 sale arriba a la derecha (Y=0x28, X=0xD8) con el
; sonido 5, baja dos puntos por fotograma hasta la altura E179 (una de
; cuatro, al azar salvo en la fase 2) y vuela hacia la izquierda a dos
; puntos por fotograma; al salir por X<8 se esconde (sonido 6) y a
; esperar. 100 puntos por pasarla.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
ABEJA:		; La abeja
	ld a,(0e158h)		;5de8   ; Bit 7 de E158: esta pantalla lleva abeja
	and 080h		;5deb
	ret z			;5ded
	ld hl,0e100h		;5dee   ; E100 es el sprite 20
	ld a,(0e17bh)		;5df1
	cp 008h		;5df4   ; Espera cumplida: aparece
	jr z,ABEJA_APARECE		;5df6
	call ABEJA_MUEVE		;5df8   ; Sin acarreo aun esta dentro: a pintarla
	jr nc,ABEJA_SPRITES		;5dfb
	xor a			;5dfd
	ld (0e17bh),a		;5dfe   ; La espera vuelve a cero; E17B sube cada 8 fotogramas (0x5A36), asi que hasta la salida siguiente pasan 64
	ld a,0c8h		;5e01
	ld (0e100h),a		;5e03
	ld a,(0e051h)		;5e06   ; La fase, en BCD
	cp 002h		;5e09   ; En la fase 2 siempre baja al primer nivel
	ld a,000h		;5e0b
	jr z,L_5E11		;5e0d
	ld a,r		;5e0f   ; El registro de refresco: una de las cuatro alturas al azar
L_5E11:
	and 003h		;5e11
	ld (0e179h),a		;5e13   ; E179, la altura de la pasada siguiente
ABEJA_SPRITES:		; El sprite 21 copia Y y X del 20; patrones 0xD8 amarillo y 0xDC negro
	ld hl,0e101h		;5e16   ; E100 es el sprite 16, y HL entra en su X
	ld a,(hl)			;5e19   ; La X se guarda en E1AE, que es por donde se mira si el jugador la ha tocado
	ld (0e1aeh),a		;5e1a   ; E1AE se queda con la X: por ahi se mira si el jugador la ha dejado atras
	inc hl			;5e1d
	ld (hl),0dch		;5e1e
	and 020h		;5e20
	jr z,L_5E34		;5e22
	ld (hl),0d8h		;5e24   ; Con el bit 5 del contador, el otro patron: asi aletea
	push hl			;5e26
	dec hl			;5e27
	dec hl			;5e28
	ld a,(hl)			;5e29
	cp 0c3h		;5e2a
	jr z,L_5E33		;5e2c
	ld a,045h		;5e2e
	call SONIDO		;5e30
L_5E33:
	pop hl			;5e33
L_5E34:
	inc hl			;5e34
	ld (hl),00fh		;5e35
	ret			;5e37
ABEJA_APARECE:		; Y=0x28, X=0xD8, 100 puntos por pasarla, sonido 5
	ld a,010h		;5e38   ; E19E = 0x10 en BCD: cien puntos por dejarla atras
	ld (0e19eh),a		;5e3a
	ld (hl),028h		;5e3d   ; Y=0x28, X=0xD8: entra por arriba a la derecha
	inc hl			;5e3f
	ld (hl),0d8h		;5e40
	jr ABEJA_SPRITES		;5e42
ABEJA_MUEVE:		; Escondida: nada. Por encima de su altura: baja 2. Si no, X-2; acarreo al pasar de X=8
	ld a,0c8h		;5e44   ; Y=0xC8 es la abeja escondida
	cp (hl)			;5e46   ; Escondida no se mueve: de ahi solo la saca ABEJA_APARECE
	jr z,L_5E5F		;5e47
	ld a,(0e179h)		;5e49   ; E179 elige una de las cuatro alturas de 0x5E61
	ld de,05e61h		;5e4c
	call DE_MAS_A		;5e4f
	ld a,(de)			;5e52
	cp (hl)			;5e53   ; Aun por encima de su altura: baja dos
	jr nc,L_5E5D		;5e54
	inc hl			;5e56   ; Ya a su altura: dos puntos a la izquierda
	dec (hl)			;5e57
	dec (hl)			;5e58
	ld a,(hl)			;5e59
	cp 008h		;5e5a   ; Acarreo al llegar a X=8: se sale por el borde
	ret			;5e5c
L_5E5D:
	inc (hl)			;5e5d   ; Dos puntos mas abajo; como sale de 0x28 y las cuatro alturas son pares, se pasa dos y acaba volando en 0x3A, 0x4A, 0x5A o 0x74 (el cobro de 0x642D mira ese 0x74)
	inc (hl)			;5e5e
L_5E5F:
	or a			;5e5f   ; Sin acarreo: aun no se ha salido
	ret			;5e60

; ----------------------------------------------------------------------
; DATOS alturas_de_la_abeja: Las cuatro alturas a las que baja: 0x38, 0x48,
;   0x58, 0x72
;   0x5e61..0x5e65  (4 bytes)
DATA_alturas_de_la_abeja:
	defb 038h,048h,058h,072h	; 5e61

; ======================================================================
; CODIGO 0x5e65..0x5eda  (117 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; EL TRONCO (sprites 9 y 10). Bit 5 de E158 y sin surtidores, un
; fotograma de cada dos: va y viene por el estanque entre X=0x48 y
; X=0x98 un punto cada dos fotogramas; si el jugador va montado (estado
; 5) lo lleva.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
TRONCO:		; El tronco que flota en el estanque
	ld a,(0e158h)		;5e65   ; Bit 5 de E158: esta pantalla lleva tronco
	and 020h		;5e68
	ret z			;5e6a
	ld a,(0e156h)		;5e6b   ; Y bit 3 de E156: con surtidores no hay tronco
	and 008h		;5e6e
	ret nz			;5e70
	ld hl,0e003h		;5e71
	bit 0,(hl)		;5e74   ; Un fotograma de cada dos: medio punto por fotograma
	ret z			;5e76
	ld hl,0e17ah		;5e77
	bit 7,(hl)		;5e7a
	jr z,L_5E8B		;5e7c
	ld (hl),000h		;5e7e
	ld hl,05651h		;5e80
	ld de,0e0d4h		;5e83
	ld bc,00008h		;5e86
	ldir		;5e89
L_5E8B:
	ld a,(0e138h)		;5e8b   ; E138, el estado del jugador
	cp 00fh		;5e8e   ; Con el jugador cayendo al agua, quieto
	ret z			;5e90
	cp 005h		;5e91   ; Estado 5: el jugador va montado y se mueve con el
	ld a,(0e17ah)		;5e93   ; E17A, hacia donde va el tronco
	ld b,a			;5e96
	jr nz,L_5EA3		;5e97
	ld hl,0e135h		;5e99   ; Montado encima, la X del jugador se mueve con el
	or a			;5e9c
	jr nz,L_5EA2		;5e9d
	dec (hl)			;5e9f
	jr L_5EA3		;5ea0
L_5EA2:
	inc (hl)			;5ea2   ; Sentido 1: el jugador a la derecha
L_5EA3:
	ld hl,0e0d5h		;5ea3   ; E0D5 es la X del sprite 9, la mitad izquierda del tronco
	ld a,b			;5ea6
	or a			;5ea7
	jr nz,L_5EAD		;5ea8
	dec (hl)			;5eaa   ; Sentido 0: el tronco tira a la izquierda
	jr L_5EAE		;5eab
L_5EAD:
	inc (hl)			;5ead   ; Y el tronco tambien a la derecha
L_5EAE:
	ld a,(hl)			;5eae   ; El sprite 10 va 16 a la derecha: ese es el borde
	add a,010h		;5eaf
	ld (0e0d9h),a		;5eb1
	cp 058h		;5eb4   ; Con el borde derecho (X+16) en 0x58, da la vuelta hacia la derecha
	jr nz,L_5EBE		;5eb6
	ld a,001h		;5eb8
TRONCO_SENTIDO:		; E17A = 1 derecha, 0 izquierda
	ld (0e17ah),a		;5eba   ; E17A, el sentido nuevo
	ret			;5ebd
L_5EBE:
	cp 0a8h		;5ebe   ; Con el borde derecho en 0xA8, hacia la izquierda
	ret nz			;5ec0
	xor a			;5ec1
	jr TRONCO_SENTIDO		;5ec2
EL_QUE_LATE:		; Con el bit 2 de E156 puesto, cambia de tamano cada ocho fotogramas leyendo la tabla de 0x5EDA
	ld a,(0e156h)		;5ec4
	and 004h		;5ec7   ; Bit 2 de E156: esta pantalla lo lleva
	ret z			;5ec9
	ld a,(0e003h)		;5eca
	and 007h		;5ecd   ; Uno de cada ocho fotogramas
	ld hl,05edah		;5ecf
	call HL_MAS_A		;5ed2
	ld a,(hl)			;5ed5
	ld (0e0ffh),a		;5ed6   ; E0FF, el patron que se pinta
	ret			;5ed9

; ----------------------------------------------------------------------
; DATOS ocho_por_fotograma: Ocho valores que 0x5ECF indexa con los tres bits
;   bajos del contador de fotogramas (E003) y deja en E0FF: 1, 6, 6, 10, 10,
;   6, 6, 6
;   0x5eda..0x5ee2  (8 bytes)
DATA_ocho_por_fotograma:
	defb 001h,006h,006h,00ah,00ah,006h,006h,006h	; 5eda  ........

; ======================================================================
; CODIGO 0x5ee2..0x6016  (308 bytes)
; ======================================================================


CHOCA_CON_SPRITE:		; El jugador contra el sprite (HL): NC si sus 16x16 se solapan (Y+8 y X)
	ld de,0e134h		;5ee2   ; E134 y E135, la Y y la X del jugador
	ld a,(de)			;5ee5
	add a,008h		;5ee6   ; Y del jugador mas 8, menos la del sprite: solapan si cae entre 0 y 15
	sub (hl)			;5ee8
	cp 010h		;5ee9   ; Mas de 15: el sprite queda demasiado abajo
	jr nc,NO_CHOCA		;5eeb
	inc de			;5eed   ; DE a la X del jugador y HL a la del sprite
	inc hl			;5eee
	ld a,(de)			;5eef   ; Lo mismo con las X, estas sin desplazar
	sub (hl)			;5ef0
	cp 010h		;5ef1   ; Ventana de 16 tambien en la X; entre dos sprites se usa una de 17
	jr nc,NO_CHOCA		;5ef3
	or a			;5ef5   ; Sin acarreo: se tocan
	ret			;5ef6
NO_CHOCA:		; Acarreo: no
	scf			;5ef7   ; Acarreo: no se tocan
	ret			;5ef8
CHOCAN_SPRITES:		; Con acarreo, los sprites de HL y DE se solapan: ventana de 16 en las dos coordenadas
	ld a,(de)			;5ef9
	add a,008h		;5efa   ; Yb mas 8 menos Yc: solapan si cae entre 0 y 15
	sub (hl)			;5efc
	inc de			;5efd
	inc hl			;5efe
	cp 010h		;5eff
	jr nc,SIGUIENTE_SPRITE		;5f01
	ld a,(de)			;5f03   ; Con las X la ventana es de 0 a 16, un punto mas ancha
	add a,008h		;5f04
	sub (hl)			;5f06
	cp 011h		;5f07
	jr nc,SIGUIENTE_SPRITE		;5f09
	ret			;5f0b
SIGUIENTE_SPRITE:		; Tres bytes mas en la lista y uno menos en la cuenta
	inc hl			;5f0c
	inc hl			;5f0d
	inc hl			;5f0e
	dec de			;5f0f   ; Y una posicion menos que mirar
	djnz CHOCAN_SPRITES		;5f10
	ret			;5f12

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; EL TIEMPO. E055 son 0x3A tramos que bajan uno cada 256 fotogramas;
; la barra va de la columna 30 hacia la 16 en la fila 1, un tile por
; cada cuatro tramos (0x2F lleno, 0x11-0x13 a medias, 0x14 vacio). Por
; debajo de 0x10 las caras de las vidas se ponen preocupadas (0xF8) y
; cada 64 fotogramas pita (sonido 0x0D). En 2 se para: no mata.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
TIEMPO:		; Gasta el tiempo que queda (E055), avisa con un pitido y lo pinta en la barra
	ld hl,0e055h		;5f13
	ld a,(hl)			;5f16
	ld c,a			;5f17
	cp 010h		;5f18   ; Por debajo de 0x10 queda poco: es cuando avisa
	jr nc,L_5F2C		;5f1a
	ld a,c			;5f1c
	cp 002h		;5f1d   ; Con dos no pita: es el ultimo tramo
	ret z			;5f1f
	ld a,(0e003h)		;5f20
	and 03fh		;5f23   ; Uno de cada 64 fotogramas
	jr nz,L_5F2C		;5f25
	ld a,00ch		;5f27
	call SONIDO		;5f29
L_5F2C:
	ld a,(0e003h)		;5f2c
	and 0ffh		;5f2f   ; Solo cuando el contador de fotogramas da la vuelta
	ret nz			;5f31
TIEMPO_UN_TRAMO_MENOS:		; Un tramo menos, salvo que ya este en 2
	ld hl,0e055h		;5f32
	ld a,(hl)			;5f35
	cp 002h		;5f36
	ret z			;5f38
PINTA_BARRA_TIEMPO:		; El tile del cursor segun E055 modulo 4, luego vacios a su derecha y llenos a su izquierda
	ld de,(0e056h)		;5f39
	ld a,(hl)			;5f3d
	and 003h		;5f3e   ; Modulo 4, mas 0x14: los tiles 0x14 a 0x17 son los cuatro cuartos de barra
	add a,014h		;5f40
	cp 016h		;5f42
	jr nz,L_5F47		;5f44
	dec de			;5f46
L_5F47:
	call VPOKE		;5f47
	dec (hl)			;5f4a
	ex de,hl			;5f4b
	ld (0e056h),hl		;5f4c
	ex de,hl			;5f4f
	push de			;5f50
	ld a,03dh		;5f51   ; Hasta la columna 29, vacios (0x14)
	sub e			;5f53
	jr z,L_5F5F		;5f54
	ld b,a			;5f56
L_5F57:
	inc de			;5f57
	ld a,017h		;5f58
	call VPOKE		;5f5a
	djnz L_5F57		;5f5d
L_5F5F:
	pop de			;5f5f
	ld a,e			;5f60   ; Desde la columna 16, llenos (0x2F)
	sub 030h		;5f61
	ret z			;5f63
	ld b,a			;5f64
L_5F65:
	dec de			;5f65
	ld a,018h		;5f66
	call VPOKE		;5f68
	djnz L_5F65		;5f6b
	ret			;5f6d
PINTA_TIEMPO:		; La barra entera (y de paso un tramo menos); agotada (2), catorce vacios
	ld hl,0e055h		;5f6e   ; E055, los tramos de tiempo que quedan
	ld a,(hl)			;5f71
	cp 002h		;5f72   ; Con mas de 2 se repinta la barra desde el cursor, y de paso se gasta un tramo
	jr nz,PINTA_BARRA_TIEMPO		;5f74
	ld de,03830h		;5f76   ; Agotado: catorce tiles vacios seguidos desde la fila 1, columna 16
	ld b,00eh		;5f79   ; Catorce, que es la barra entera
L_5F7B:
	ld a,017h		;5f7b
	call VPOKE		;5f7d
	inc de			;5f80
	djnz L_5F7B		;5f81
	ret			;5f83
COBRA_AL_PASAR:		; Para B obstaculos con su X en (HL): si el jugador ya los ha dejado atras, cobra los puntos E18C+C (una sola vez)
	ld a,(0e058h)		;5f84
	cp 008h		;5f87
	jr nz,COBRA_AL_PASAR_IZQ		;5f89
L_5F8B:
	ld a,(0e135h)		;5f8b   ; La X del jugador contra la del obstaculo de turno
	cp (hl)			;5f8e
	call nc,COBRA_PUNTOS		;5f8f   ; Entrando por la izquierda (E058 = 8) se anda hacia la derecha: pasados son los que tienen X menor
	inc c			;5f92   ; C es el indice en la tabla de puntos E18C, HL la X del obstaculo siguiente
	inc hl			;5f93
	djnz L_5F8B		;5f94
	ret			;5f96
COBRA_AL_PASAR_IZQ:		; Lo mismo yendo hacia la izquierda
	ld a,(0e135h)		;5f97   ; Entrando por la derecha se anda hacia la izquierda: los pasados son los que quedan a la derecha
	cp (hl)			;5f9a
	call c,COBRA_PUNTOS		;5f9b
	inc c			;5f9e
	inc hl			;5f9f
	djnz COBRA_AL_PASAR_IZQ		;5fa0
	ret			;5fa2
COBRA_PUNTOS:		; Cobra los puntos E18C+C si aun no estan cobrados: los suma, y saca el rotulo 50/100/200 sobre el jugador 30 fotogramas
	push hl			;5fa3
	push bc			;5fa4
	ld a,c			;5fa5
	ld hl,0e18ch		;5fa6
	call HL_MAS_A		;5fa9
	ld a,(hl)			;5fac
	or a			;5fad   ; Ya cobrados
	jr z,COBRA_PUNTOS_FIN		;5fae
	ld e,000h		;5fb0
	ld (hl),e			;5fb2
	rra			;5fb3   ; Los dos nibbles a DE en BCD: 0x20 son 200
	rr e		;5fb4
	rra			;5fb6
	rr e		;5fb7
	rra			;5fb9
	rr e		;5fba
	rra			;5fbc
	rr e		;5fbd
	ld d,a			;5fbf
	push de			;5fc0
	call SUMA_PUNTOS_CON_SONIDO		;5fc1
	pop de			;5fc4
	ld b,004h		;5fc5
	ld c,000h		;5fc7
	ld hl,0e181h		;5fc9   ; El primer rotulo libre de los cuatro (sprites 23-26)
L_5FCC:
	ld a,(hl)			;5fcc   ; E181-E184: los fotogramas que le quedan a cada rotulo; a cero esta libre
	or a			;5fcd
	jr z,L_5FD4		;5fce
	inc c			;5fd0
	inc hl			;5fd1
	djnz L_5FCC		;5fd2
L_5FD4:
	push hl			;5fd4   ; C es el numero de rotulo libre; por cuatro, los bytes del sprite
	ld a,c			;5fd5
	add a,a			;5fd6
	add a,a			;5fd7
	ld hl,0e10ch		;5fd8   ; E10C es el sprite 23, el primero de los cuatro rotulos
	call HL_MAS_A		;5fdb
	ld bc,0e134h		;5fde   ; E134 y E135: el rotulo sale 16 por encima del jugador
	ld a,(bc)			;5fe1
	sub 010h		;5fe2
	ld (hl),a			;5fe4
	inc hl			;5fe5
	inc bc			;5fe6
	ld a,(bc)			;5fe7
	ld (hl),a			;5fe8
	inc hl			;5fe9
	ld a,d			;5fea   ; Patron 0xE0 (50), 0xE4 (100) o 0xE8 (200), blanco
	add a,a			;5feb
	add a,a			;5fec
	add a,0e0h		;5fed
	ld (hl),a			;5fef
	inc hl			;5ff0
	ld (hl),00fh		;5ff1   ; Color 15, blanco
	ld a,01eh		;5ff3   ; 30 fotogramas a la vista
	pop hl			;5ff5
	ld (hl),a			;5ff6
COBRA_PUNTOS_FIN:		; Nada que cobrar
	pop bc			;5ff7
	pop hl			;5ff8
	ret			;5ff9
CARAS_DE_LAS_VIDAS:		; Pone el patron A en las cuatro caras: 0xF4 normal, 0xF8 preocupada, 0xEC contenta, 0xF0 llorando
	ld b,004h		;5ffa
	ld de,0e10ch		;5ffc
	ld hl,0e181h		;5fff
L_6002:
	ld a,(hl)			;6002
	or a			;6003
	jr nz,L_6009		;6004
	ld a,0c8h		;6006   ; Rotulo caducado: Y=0xC8, escondido
	ld (de),a			;6008
L_6009:
	inc hl			;6009   ; Al contador siguiente (E181-E184) y al sprite siguiente, cuatro bytes mas alla
	inc de			;600a
	inc de			;600b
	inc de			;600c
	inc de			;600d
	djnz L_6002		;600e
	ld a,(0e138h)		;6010   ; E138, el estado del jugador: el indice de la tabla de 0x6016
	call DESPACHA		;6013   ; DESPACHA no vuelve: el ret del estado es el de JUGADOR

; ----------------------------------------------------------------------
; DATOS tabla_de_estados_del_jugador: Los 17 destinos del despacho de 0x6013,
;   indice E138: 0x620D, 0x6038, 0x664A, 0x614C, 0x61B3, 0x61E5, 0x61FA,
;   0x62F6 y 0x6322; seis 0x0000 sin uso; 0x6392 y 0x6365. La tabla cierra
;   clavada contra su destino mas bajo, 0x6038
;   0x6016..0x6038  (34 bytes)
DATA_tabla_de_estados_del_jugador:
	defw 0620dh	; 6016  -> ESTADO_0_ANDA
	defw 06038h	; 6018  -> ESTADO_1_EN_EL_AIRE
	defw 0664ah	; 601a  -> ESTADO_2_LIANA
	defw 0614ch	; 601c  -> ESTADO_3_TRAMPOLIN
	defw 061b3h	; 601e  -> L_61B3
	defw 061e5h	; 6020  -> ESTADO_5_TRONCO
	defw 061fah	; 6022  -> ESTADO_6_POSTE
	defw 062f6h	; 6024  -> ESTADO_7_META
	defw 06322h	; 6026  -> ESTADO_8_FASE_SUPERADA
	defw 00000h	; 6028
	defw 00000h	; 602a
	defw 00000h	; 602c
	defw 00000h	; 602e
	defw 00000h	; 6030
	defw 00000h	; 6032
	defw 06392h	; 6034  -> ESTADO_15_SE_HUNDE
	defw 06365h	; 6036  -> ESTADO_16_LE_HAN_DADO

; ======================================================================
; CODIGO 0x6038..0x609b  (99 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; ESTADO 1: EN EL AIRE. Un paso por el arco de salto (6C3C, que de paso
; mira si agarra una liana). Bajando: si hay trampolines y cae en uno,
; bota (estado 3, sonido 9); si no, mira si cae en un surtidor (650E:
; estado 4, o al agua) o aterriza (676A).
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
ESTADO_1_EN_EL_AIRE:		; Un paso del salto y, bajando, donde cae
	call PASO_DE_SALTO		;6038
	ld a,(0e202h)		;603b
	or a			;603e   ; Subiendo todavia: solo la X y los bordes
	jp z,AIRE_MOVIMIENTO_COMUN		;603f
	ld a,(0e156h)		;6042
	bit 2,a		;6045
	jr z,AIRE_SIN_TRAMPOLIN		;6047
	call CAE_EN_TRAMPOLIN		;6049   ; En un trampolin
	jp nc,L_60CF		;604c
	ld a,008h		;604f
	call SONIDO		;6051
	ld a,003h		;6054
	ld (0e138h),a		;6056
	ld hl,06639h		;6059
	call ARCO_SUBIENDO		;605c
	ld (0e137h),a		;605f
	ret			;6062
AIRE_SIN_TRAMPOLIN:		; Con postes: si cae sobre uno, se queda de pie en el (estado 6)
	bit 4,a		;6063
	jr z,$+64		;6065
	ld b,005h		;6067   ; Cinco postes: Y y X en 0x609B
	ld hl,0609bh		;6069
L_606C:
	ld a,(0e134h)		;606c   ; La Y del jugador menos la de la cabeza del poste (parejas Y,X en 0x609B)
	ld c,(hl)			;606f   ; HL avanza a la X en cuanto lee la Y
	inc hl			;6070
	sub c			;6071
	cp 005h		;6072   ; A menos de 5 puntos por encima y a menos de 16 de su X
	jr nc,L_607F		;6074
	ld a,(0e135h)		;6076   ; Y la X del jugador menos la del poste, sin signo: solo cae encima por la derecha
	ld c,(hl)			;6079
	sub c			;607a
	cp 010h		;607b
	jr c,L_6084		;607d
L_607F:
	inc hl			;607f
	djnz L_606C		;6080
	jr $+77		;6082
L_6084:
	dec hl			;6084   ; De pie sobre el poste (Y+4), estado 6, y cobra los 100 puntos del poste
	ld a,(hl)			;6085
	add a,004h		;6086
	ld (0e134h),a		;6088   ; Se queda de pie 4 puntos por debajo de la cabeza del poste
	ld a,006h		;608b
	ld (0e138h),a		;608d
	ld hl,0e1a0h		;6090   ; E1A0-E1A4, las X de los cinco postes; con C=4 sus puntos salen de E190-E194
	ld b,005h		;6093
	ld c,004h		;6095
	call COBRA_AL_PASAR		;6097
	ret			;609a

; ----------------------------------------------------------------------
; DATOS postes_y_x: Cinco parejas Y,X de la cabeza de cada poste: (0x58,0x30)
;   (0x50,0x50) (0x50,0x70) (0x50,0x90) (0x58,0xB0)
;   0x609b..0x60a5  (10 bytes)
DATA_postes_y_x:
	defb 058h,030h	; 609b
	defb 050h,050h	; 609d
	defb 050h,070h	; 609f
	defb 050h,090h	; 60a1
	defb 058h,0b0h	; 60a3

; ======================================================================
; CODIGO 0x60a5..0x61e1  (316 bytes)
; ======================================================================


CAE_SOBRE_ALGO:		; Mira si al caer aterriza en uno de los cuatro sitios de 0x61E1, y si no, se mata
	call MIRA_LOS_CUATRO_UMBRALES		;60a5   ; Los cuatro umbrales
	jr nc,L_60CF		;60a8
	ld hl,0e134h		;60aa
	ld a,(de)			;60ad
	add a,004h		;60ae   ; Cuatro puntos de margen para darlo por bueno
	sub (hl)			;60b0
	cp 009h		;60b1
	jr nc,L_60CF		;60b3
	ld a,004h		;60b5   ; Estado 4 del jugador: encima de la cosa
	ld (0e138h),a		;60b7
	ld a,(0e134h)		;60ba
	ld hl,0e13ah		;60bd
	sub 010h		;60c0   ; Y si ha caido de mas de 16 puntos de altura, muere igual
	cp (hl)			;60c2
	jp nc,LE_HAN_DADO		;60c3
	ld a,e			;60c6   ; Sobre una tabla: cobra los 200 puntos de ese surtidor
	sub 048h		;60c7
	ld c,a			;60c9
	call COBRA_PUNTOS		;60ca
	jr AIRE_MOVIMIENTO_COMUN		;60cd
L_60CF:
	call ATERRIZA		;60cf
AIRE_MOVIMIENTO_COMUN:		; Al movimiento comun (6A24)
	jp MOVIMIENTO_COMUN		;60d2

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; ATERRIZAR. Al llegar a Y=0x6C: sobre el estanque de postes (X 0x28-
; 0xC8) o el foso de los trampolines (X 0x38-0xB8) es caer al agua; si el
; tronco esta activo (Y=0x87) y se cae a menos de 32 de el, se monta
; (estado 5); si no, de pie (estado 0).
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
ATERRIZA:		; De pie, en el tronco, o al agua
	ld hl,0e134h		;60d5
	ld a,(hl)			;60d8
	cp 06ch		;60d9   ; Aun en el aire
	jr c,ATERRIZA_FIN		;60db
	inc hl			;60dd
	ld a,(0e156h)		;60de
	bit 4,a		;60e1
	jr z,L_60EA		;60e3
	call SOBRE_ESTANQUE_POSTES		;60e5   ; El estanque de postes: al agua
	jr c,L_6112		;60e8
L_60EA:
	bit 2,a		;60ea
	jr z,L_60F3		;60ec
	call SOBRE_FOSO		;60ee   ; El foso de los trampolines: al agua
	jr c,L_6112		;60f1
L_60F3:
	ld a,(0e0d4h)		;60f3
	cp 087h		;60f6   ; Tronco activo (Y=0x87)...
	jr nz,L_6108		;60f8
	ld a,(0e0d5h)		;60fa
	sub 008h		;60fd
	ld b,a			;60ff
	ld a,(hl)			;6100
	sub b			;6101
	cp 020h		;6102   ; ...y a menos de 32 puntos: montado (estado 5)
	ld a,005h		;6104
	jr c,L_6109		;6106
L_6108:
	xor a			;6108
L_6109:
	ld (0e138h),a		;6109
	ld a,06ch		;610c
	ld (0e134h),a		;610e
ATERRIZA_FIN:		; Sigue en el aire
	ret			;6111
L_6112:
	pop hl			;6112
AL_AGUA:		; Muere ahogado
	jp LE_HAN_DADO		;6113
SOBRE_ESTANQUE_POSTES:		; Acarreo si X esta entre 0x28 y 0xC7
	ld a,(hl)			;6116
	sub 02ah		;6117
	cp 09eh		;6119
	ret			;611b
SOBRE_FOSO:		; Acarreo si X esta entre 0x38 y 0xB7
	ld a,(hl)			;611c
	sub 03ah		;611d
	cp 07eh		;611f
	ret			;6121
CAE_EN_TRAMPOLIN:		; Acarreo si Y esta entre 0x64 y 0x68 y X a menos de 16 de un trampolin (0x40, 0x60, 0x80, 0xA0): lo centra (X+8) y cobra sus 100 puntos
	ld a,(0e134h)		;6122   ; La Y del jugador: solo entre 0x64 y 0x68 esta a la altura de la lona
	sub 064h		;6125
	cp 005h		;6127
	ret nc			;6129
	ld hl,0e135h		;612a
	ld bc,00440h		;612d   ; B=4 trampolines y C=0x40, la X del primero
L_6130:
	ld a,(hl)			;6130   ; La X del jugador menos la del trampolin de turno
	sub c			;6131
	cp 010h		;6132   ; A menos de 16 por su derecha: ha caido en el
	ld a,c			;6134
	jr c,L_613D		;6135
	add a,020h		;6137   ; El trampolin siguiente, 0x20 mas a la derecha
	ld c,a			;6139
	djnz L_6130		;613a
	ret			;613c   ; Ninguno: se vuelve sin acarreo
L_613D:
	add a,008h		;613d   ; A trae la X del trampolin: el jugador se centra 8 puntos a su derecha
	ld (hl),a			;613f
	ld hl,0e1a5h		;6140   ; E1A5-E1A8, las X de los cuatro; con C=9 sus puntos salen de E195-E198
	ld b,004h		;6143
	ld c,009h		;6145
	call COBRA_AL_PASAR		;6147
	scf			;614a   ; Acarreo: ha caido en un trampolin
	ret			;614b

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; ESTADO 3: BOTANDO EN EL TRAMPOLIN. Un paso del arco (con la liana de
; paso), y con izquierda/derecha se mueve; con el boton pulsado en el
; aire (E204) el siguiente bote sale con el arco alto (0x5D8B), y sin el
; con el corto (0x6639). Bajando por debajo de Y=0x40 se mira si cae en
; un trampolin (Y=0x64, sonido 9) o fuera (aterriza como en el aire).
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
ESTADO_3_TRAMPOLIN:		; Botando en los trampolines
	call PASO_DE_SALTO		;614c
	ld a,(0e009h)		;614f
	and 00ch		;6152   ; Izquierda o derecha pulsadas
	jr nz,L_6157		;6154
	xor a			;6156
L_6157:
	ld (0e203h),a		;6157
	or a			;615a
	jr z,L_6160		;615b
	ld (0e139h),a		;615d   ; Y hacia alli mira
L_6160:
	ld a,(0e202h)		;6160
	or a			;6163
	jr z,TRAMPOLIN_SIGUE		;6164
	ld a,(0e134h)		;6166
	cp 040h		;6169   ; Aun por encima de Y=0x40
	jr c,TRAMPOLIN_SIGUE		;616b
	call SALTA_SI_BOTON		;616d   ; Boton: el proximo bote sera alto
	jr nc,L_6177		;6170
	ld a,001h		;6172
	ld (0e204h),a		;6174
L_6177:
	call CAE_EN_TRAMPOLIN		;6177
	ld a,06ch		;617a   ; Altura segura: el suelo
	ld (0e13ah),a		;617c
	jr nc,TRAMPOLIN_FUERA		;617f
	ld a,064h		;6181   ; En el trampolin: Y=0x64
	ld (0e134h),a		;6183
	ld hl,0e204h		;6186
	ld a,(hl)			;6189
	or a			;618a
	jr z,BOTE_SIN_BOTON		;618b
	ld (hl),000h		;618d   ; Bote alto pedido: arco 0x5D8B y sonido 9
	ld a,(0e203h)		;618f
	ld (0e137h),a		;6192
	or a			;6195
	ld hl,05d79h		;6196
	jr z,L_619E		;6199
BOTE_CORTO:		; Arco corto 0x6639
	ld hl,06639h		;619b
L_619E:
	call ARCO_SUBIENDO		;619e
	ld a,008h		;61a1
	call SONIDO		;61a3
TRAMPOLIN_SIGUE:		; Al movimiento comun (6A24)
	jp MOVIMIENTO_COMUN		;61a6
BOTE_SIN_BOTON:		; Bote corto sin cambiar de direccion
	ld (0e137h),a		;61a9
	jr BOTE_CORTO		;61ac
TRAMPOLIN_FUERA:		; No cayo en trampolin: aterriza (o al foso)
	call ATERRIZA		;61ae
	jr TRAMPOLIN_SIGUE		;61b1
L_61B3:
	call MIRA_LOS_CUATRO_UMBRALES		;61b3
	jr c,SIGUE_LA_TABLA		;61b6
CAE_DE_LO_ALTO:		; Estado 1 con el arco corto, cayendo desde aqui
	ld hl,06639h		;61b8
	call ARCO_CAYENDO		;61bb
	ld a,001h		;61be
	ld (0e138h),a		;61c0
	ret			;61c3
SIGUE_LA_TABLA:		; Y = la altura de la tabla
	ld a,(de)			;61c4
	ld (0e134h),a		;61c5
A_ANDAR_O_SALTAR:		; A andar/saltar (696B)
	jp ANDA_O_SALTA		;61c8
MIRA_LOS_CUATRO_UMBRALES:		; Prepara la lista de 0x61E1 y busca en ella
	ld b,004h		;61cb
	ld hl,061e1h		;61cd
	ld de,0e148h		;61d0
BUSCA_EL_UMBRAL:		; Mira los cuatro umbrales contra la X del jugador (E135) y sale con el primero a menos de 0x19
	ld a,(0e135h)		;61d3
	ld c,(hl)			;61d6
	sub c			;61d7
	cp 019h		;61d8   ; Veinticinco puntos de ancho tiene cada uno
	ret c			;61da
	inc hl			;61db
	inc de			;61dc
	djnz BUSCA_EL_UMBRAL		;61dd
	or a			;61df
	ret			;61e0

; ----------------------------------------------------------------------
; DATOS cuatro_umbrales: Los cuatro bytes que 0x61CD recorre contra E135:
;   0x38, 0x58, 0x80 y 0xA0
;   0x61e1..0x61e5  (4 bytes)
DATA_cuatro_umbrales:
	defb 038h,058h,080h,0a0h	; 61e1

; ======================================================================
; CODIGO 0x61e5..0x6259  (116 bytes)
; ======================================================================


ESTADO_5_TRONCO:		; Montado en el tronco: cobra sus 200 puntos, va con el, y si se aleja mas de 32 de el cae al agua (68C4)
	ld c,000h		;61e5   ; El indice 0 de la tabla de puntos: los 200 que 0x5759 pone en E18C, y que comparten la liana 1, el primer surtidor y el tronco
	call COBRA_PUNTOS		;61e7
	ld a,(0e0d5h)		;61ea   ; E0D5 es la X del sprite 9, la mitad izquierda del tronco; menos 8, su borde util
	sub 008h		;61ed
	ld b,a			;61ef
	ld a,(0e135h)		;61f0
	sub b			;61f3
	cp 020h		;61f4   ; Mas de 32 puntos de separacion: se ha salido del tronco al agua
	jr nc,L_6232		;61f6
	jr $-48		;61f8
ESTADO_6_POSTE:		; De pie en un poste: mientras este a menos de 16 de su X puede andar o saltar; si no, cae (685C)
	ld b,005h		;61fa
	ld hl,0609ch		;61fc
L_61FF:
	ld a,(0e135h)		;61ff   ; HL arranca en 0x609C, la X del primer poste; las Y se van salteando
	sub (hl)			;6202
	cp 010h		;6203   ; A menos de 16 de su X: sigue encima
	jr c,$-61		;6205
	inc hl			;6207   ; Dos bytes por poste, Y y X
	inc hl			;6208
	djnz L_61FF		;6209
	jr $-83		;620b

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; ESTADO 0: ANDANDO. Con estanque (bit 7), pisar entre X=0x36 y 0xB7 es
; hundirse (68C4); con charcos, pisar uno (X a menos de 16 de 0x30+32n) es
; caer en el (68AE); sobre el estanque de postes o el foso de los
; trampolines a ras de suelo se avanza un punto mas y suena el 0x0B (se
; chapotea). Luego la meta (692C), la caida mortal (6960) y andar/saltar.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
ESTADO_0_ANDA:		; Andando por el suelo
	ld a,(0e156h)		;620d
	bit 7,a		;6210
	jr z,$+75		;6212
	ld a,(0e135h)		;6214   ; X menos 0x34, por debajo de 0x88: entre 0x34 y 0xBB
	sub 034h		;6217
	cp 088h		;6219
	jp nc,META		;621b
	jr L_6232		;621e
L_6220:
	ld a,(0e139h)		;6220   ; E139, hacia donde mira: 4 es a la izquierda
	cp 004h		;6223
	ld hl,0e135h		;6225
	jr nz,L_622F		;6228
	dec (hl)			;622a   ; Mirando a la izquierda, dos puntos mas a la izquierda; mirando a la derecha, dos a la derecha
	dec (hl)			;622b
	dec (hl)			;622c
	jr L_6232		;622d
L_622F:
	inc (hl)			;622f
	inc (hl)			;6230
	inc (hl)			;6231
L_6232:
	ld hl,06259h		;6232
	call CUATRO_SPRITES_IGUALES		;6235
SE_HUNDE:		; Arco de hundimiento 0x6627, estado 15, sonido 0x99, caras llorando y todos los obstaculos fuera
	ld hl,06627h		;6238
	call ARCO_CAYENDO		;623b
	ld (0e137h),a		;623e
	ld a,00fh		;6241   ; Estado 15: hundirse
	ld (0e138h),a		;6243
	ld a,021h		;6246
	call SONIDO		;6248
ESCONDE_OBSTACULOS:		; Sprites 11-25 a 0xC3
	ld hl,0e0d4h		;624b   ; E0DC es el sprite 11, el primero de los obstaculos
	ld de,0e0d5h		;624e
	ld (hl),0c3h		;6251   ; 0xC3 en todos los bytes; lo que importa es la Y, que deja el sprite por debajo de las 192 filas
	ld bc,00044h		;6253   ; 61 bytes: los sprites 11 a 25 enteros y la Y del 26
	ldir		;6256
	ret			;6258

; ----------------------------------------------------------------------
; DATOS sprite_en_el_charco: Y=0x8C y ceros para los sprites 0-3
;   0x6259..0x625d  (4 bytes)
DATA_sprite_en_el_charco:
	defb 08ch,000h,000h,000h	; 6259

; ======================================================================
; CODIGO 0x625d..0x64b1  (596 bytes)
; ======================================================================


ANDA_SIN_ESTANQUE:		; Los cinco charcos (X 0x30, 0x50, 0x70, 0x90, 0xB0)
	bit 0,a		;625d
	jr z,ANDA_ESTANQUE_POSTES		;625f
	ld bc,00530h		;6261
L_6264:
	ld a,(0e135h)		;6264   ; La X del jugador menos la del charco de turno (B=5 charcos desde C=0x30)
	sub c			;6267
	cp 010h		;6268
	jr c,$-74		;626a
	ld a,c			;626c
	add a,020h		;626d   ; El charco siguiente, 0x20 mas alla
	ld c,a			;626f
	djnz L_6264		;6270
	jr META		;6272   ; Ninguno pisado: a mirar si se ha llegado a la meta
ANDA_ESTANQUE_POSTES:		; Bit 4: sobre el estanque de postes chapotea (X+1 y sonido 0x0B)
	ld hl,0e135h		;6274
	bit 4,a		;6277
	jr z,ANDA_FOSO		;6279
	call SOBRE_ESTANQUE_POSTES		;627b
	jr nc,META		;627e
CHAPOTEA:		; Un punto mas hacia donde mira y sonido 0x0B
	ld a,(0e139h)		;6280
	bit 3,a		;6283
	jr nz,L_628A		;6285
	inc (hl)			;6287
	jr L_628B		;6288
L_628A:
	dec (hl)			;628a
L_628B:
	ld a,00ah		;628b
	call SONIDO		;628d
	jr META		;6290
ANDA_FOSO:		; Bit 2: sobre el foso de los trampolines, igual
	bit 2,a		;6292
	jr z,META		;6294
	call SOBRE_FOSO		;6296
	jr c,CHAPOTEA		;6299

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; LA META. En los SCENE acabados en 0 (salvo el 0) que coincidan con la
; meta de la fase (E05A: 10, 20, 30...), al pasar de X=0xC8 (o bajar de
; 0x28 si se avanza hacia la izquierda) suena la fanfarria (0x9C) y el
; jugador entra en el estado 7 con seis medias vueltas.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
META:		; Mira si se ha llegado a la meta de la fase
	ld hl,0e059h		;629b
	ld a,(hl)			;629e
	and 00fh		;629f   ; SCENE acabado en 0
	jr nz,CAIDA_MORTAL		;62a1
	ld a,(0e054h)		;62a3
	or a			;62a6   ; Pero no el 0
	jr z,CAIDA_MORTAL		;62a7
	ld a,(hl)			;62a9
	inc hl			;62aa
	cp (hl)			;62ab   ; Y el que dice E05A: la meta de esta fase
	jr nz,CAIDA_MORTAL		;62ac
	ld hl,0e135h		;62ae
	ld a,(0e053h)		;62b1   ; Bit 0 de E053: hacia donde se avanza
	rra			;62b4
	ld a,0c8h		;62b5   ; Avanzando a la derecha, pasar de X=0xC8
	jr nc,L_62C0		;62b7
	ld a,028h		;62b9   ; Avanzando a la izquierda, bajar de X=0x28
	cp (hl)			;62bb
	jr nc,META_ALCANZADA		;62bc
	jr CAIDA_MORTAL		;62be
L_62C0:
	cp (hl)			;62c0
	jr nc,CAIDA_MORTAL		;62c1
META_ALCANZADA:		; Seis medias vueltas (E001) y la fanfarria
	ld a,006h		;62c3
	ld (0e001h),a		;62c5
	ld a,095h		;62c8
	call SONIDO		;62ca
	jr MEDIA_VUELTA		;62cd
CAIDA_MORTAL:		; Si Y-17 llega a la altura desde la que salto (E13A): se ha caido al agua
	ld a,(0e134h)		;62cf
	ld hl,0e13ah		;62d2
	sub 011h		;62d5
	cp (hl)			;62d7
	jr nc,LE_HAN_DADO		;62d8
ANDA_O_SALTA:		; Andar (6D72) y, con el boton, saltar (arco corto 0x6639, sonido 3)
	call ANDA		;62da
	call SALTA_SI_BOTON		;62dd
	jp nc,MOVIMIENTO_COMUN		;62e0
	ld hl,06639h		;62e3   ; Salto normal: arco corto
	call ARCO_SUBIENDO		;62e6
	ld a,001h		;62e9
	ld (0e138h),a		;62eb
	ld a,003h		;62ee   ; Sonido de saltar
	call SONIDO		;62f0
	jp MOVIMIENTO_COMUN		;62f3
ESTADO_7_META:		; Llegado a la meta: cada media vuelta cambia de lado; a la sexta, estado 8
	call PASO_DE_SALTO		;62f6
	call ATERRIZA		;62f9
	cp 06ch		;62fc   ; Aun en el aire
	jr nz,A_PINTAR_JUGADOR		;62fe
	ld hl,0e001h		;6300
	dec (hl)			;6303
	ld a,(hl)			;6304
	dec a			;6305
	ld a,008h		;6306   ; Ultima: estado 8
	jr z,L_631C		;6308
	ld hl,0e139h		;630a
	ld a,(hl)			;630d
	xor 00ch		;630e   ; Media vuelta
	ld (hl),a			;6310
MEDIA_VUELTA:		; Arco corto y estado 7
	ld hl,06639h		;6311
	call ARCO_SUBIENDO		;6314
	ld (0e137h),a		;6317
	ld a,007h		;631a
L_631C:
	ld (0e138h),a		;631c
A_PINTAR_JUGADOR:		; Pinta los sprites del jugador
	jp PINTA_AL_JUGADOR_ENTERO		;631f
ESTADO_8_FASE_SUPERADA:		; E00D = 1: la fase esta superada (lo recoge el estado 11 del juego)
	ld a,001h		;6322
	ld (0e00dh),a		;6324
	ret			;6327
LE_HAN_DADO:		; Esconde los obstaculos, apaga cuatro trozos de dibujo, y pasa al estado 16 con su sonido
	call ESCONDE_OBSTACULOS		;6328
	ld de,0182ah		;632b   ; Cuatro bits sueltos de la tabla de patrones: la cara cambia de gesto
	call VPEEK		;632e
	res 4,a		;6331
	call VPOKE		;6333
	ld de,0183ah		;6336
	call VPEEK		;6339
	res 4,a		;633c
	call VPOKE		;633e
	ld de,01b0ah		;6341
	call VPEEK		;6344
	res 3,a		;6347
	call VPOKE		;6349
	ld de,01b1ah		;634c
	call VPEEK		;634f
	res 3,a		;6352
	call VPOKE		;6354
	ld a,010h		;6357   ; Estado 16 del jugador
	ld (0e138h),a		;6359   ; Estado 16 del jugador
	xor a			;635c   ; El contador de fotogramas a cero: los 128 del estado 16 cuentan desde aqui
	ld (0e003h),a		;635d
	ld a,01eh		;6360
	jp SONIDO		;6362
ESTADO_16_LE_HAN_DADO:		; Cae dos puntos por fotograma hasta el suelo (Y=0x6C); cada 16 alterna las dos poses de muerte; a los 128 fotogramas, muerto (E00C)
	ld hl,0e134h		;6365
	ld a,(hl)			;6368
	cp 06ch		;6369   ; 0x6C es la Y del suelo
	jr nc,L_636F		;636b
	inc (hl)			;636d
	inc (hl)			;636e
L_636F:
	ld a,(0e003h)		;636f
	and 00fh		;6372   ; Cada 16 fotogramas
	jr nz,L_637E		;6374
	inc hl			;6376
	inc hl			;6377
	ld a,(hl)			;6378   ; E136, la pose
	xor 001h		;6379   ; Cambia el bit 0 de la pose: alterna las dos poses de muerte
	and 011h		;637b
	ld (hl),a			;637d
L_637E:
	call PINTA_AL_JUGADOR		;637e
	ld a,(0e134h)		;6381
	cp 06ch		;6384
	ret c			;6386
	ld a,(0e003h)		;6387
	and 07fh		;638a   ; Ciento veintiocho fotogramas tirado antes de dar la vida por perdida
	ret nz			;638c
	inc a			;638d
	ld (0e00ch),a		;638e
	ret			;6391
ESTADO_15_SE_HUNDE:		; Cada 8 fotogramas un paso del arco de hundimiento, con la pose 6; al llegar a Y=0x7C, muerto (E00C)
	ld a,(0e003h)		;6392   ; Un paso cada ocho fotogramas: el hundimiento va ocho veces mas lento que un salto
	and 007h		;6395
	ret nz			;6397
	call PASO_DE_SALTO		;6398
	ld a,003h		;639b
	ld (0e136h),a		;639d
	ld a,(0e134h)		;63a0
	cp 078h		;63a3
	jp c,PINTA_AL_JUGADOR_ENTERO		;63a5
	ld (0e00ch),a		;63a8   ; E00C distinto de cero es muerto, y aqui se le mete la propia Y; lo recoge el estado 12
	ret			;63ab
MOVIMIENTO_COMUN:		; Pinta al jugador y mira los bordes: X<3 sale por la izquierda (E00E=1, entrara por la derecha), X>=0xF0 por la derecha (E00E=2, entrara por la izquierda); si no, los choques
	call PINTA_AL_JUGADOR_ENTERO		;63ac
	ld a,(0e135h)		;63af
	ld bc,001e8h		;63b2   ; Por la izquierda: E00E=1 y la proxima entrada en X=0xE8
	cp 003h		;63b5
	jr c,SALE_DE_PANTALLA		;63b7
	cp 0f0h		;63b9
	jr c,CHOCA_LA_CABEZA		;63bb
	ld bc,00208h		;63bd   ; Por la derecha: E00E=2 y la proxima entrada en X=8
SALE_DE_PANTALLA:		; E00E y E058 con lo que diga BC
	ld a,b			;63c0
	ld (0e00eh),a		;63c1
	ld a,c			;63c4
	ld (0e058h),a		;63c5
	ret			;63c8
CHOCA_LA_CABEZA:		; La cabeza contra el sprite 8 y contra la fruta
	ld hl,0e0dch		;63c9
	ld de,0e0c0h		;63cc
	ld b,008h		;63cf
	call CHOCAN_SPRITES		;63d1   ; La cabeza contra el sprite 8
	jp c,LE_HAN_DADO		;63d4
	ld b,001h		;63d7
	call CHOCAN_SPRITES		;63d9
	jr nc,CHOCAN_LOS_PIES		;63dc
	push hl			;63de
	push de			;63df
	ld c,012h		;63e0   ; 200 puntos, la fruta desaparece, sonido 0x0A
	call COBRA_PUNTOS		;63e2
	ld a,0c8h		;63e5   ; La fruta se aparca fuera de la pantalla
	ld (0e0fch),a		;63e7
	ld a,009h		;63ea
	call SONIDO		;63ec
	pop de			;63ef
	pop hl			;63f0
	inc hl			;63f1
	inc hl			;63f2
	inc hl			;63f3
	dec de			;63f4
CHOCAN_LOS_PIES:		; Las piernas contra los sprites 3 y 8, y los dos de al lado
	ld b,003h		;63f5
	call CHOCAN_SPRITES		;63f7
	jp c,LE_HAN_DADO		;63fa
	ld hl,0e0dch		;63fd   ; Las piernas empiezan en E0DC
	ld de,0e0cch		;6400
	ld b,008h		;6403   ; Contra el sprite 8, el de la fruta
	call CHOCAN_SPRITES		;6405
	jp c,LE_HAN_DADO		;6408
	inc hl			;640b   ; Cuatro bytes: el sprite de al lado
	inc hl			;640c
	inc hl			;640d
	inc hl			;640e
	ld b,003h		;640f
	call CHOCAN_SPRITES		;6411
	jp c,LE_HAN_DADO		;6414
	ld hl,0e12ch		;6417   ; Y el sprite 27 (E12C), que es el que llevan las pantallas con bicho
	ld de,0e0cch		;641a
	ld b,001h		;641d
	call CHOCAN_SPRITES		;641f
	jp c,LE_HAN_DADO		;6422
COBRA_BOLAS_Y_ABEJA:		; Con los moviles activos: por pasar las dos bolas (E1AC, E1AD) y, si la abeja esta baja, tambien a ella (E1AE)
	ld a,(0e159h)		;6425
	or a			;6428
	ret z			;6429
	ld a,(0e100h)		;642a
	cp 074h		;642d   ; Y=0x74 es donde se queda con la altura mas baja (0x72): solo entonces cuenta
	ld hl,0e1ach		;642f   ; E1AC y E1AD son las X de las dos bolas, E1AE la de la abeja
	ld b,003h		;6432
	jr z,L_6438		;6434
	ld b,002h		;6436
L_6438:
	ld c,010h		;6438   ; Del 16 en adelante en la tabla de cobrados
	jp COBRA_AL_PASAR		;643a
PINTA_AL_JUGADOR_ENTERO:		; La figura, la cara y la sombra, desde la Y y la X de E134
	ld hl,0e134h		;643d   ; E134 y E135, la Y y la X del jugador, a B y C
	ld b,(hl)			;6440
	inc hl			;6441
	ld c,(hl)			;6442
	inc hl			;6443
	ld a,(hl)			;6444   ; E136, la pose, con el lado ya sumado
	ld hl,0e0c0h		;6445   ; E0C0 es el sprite 4: cabeza y torso. Las piernas son el 6 y el 7, 16 filas mas abajo
	bit 0,a		;6448   ; Poses impares un punto mas abajo
	jr z,PINTA_LA_POSE		;644a
	inc b			;644c
PINTA_LA_POSE:		; Los dos sprites de la mitad de arriba con los patrones de la pose, y el de mas abajo si la pose es la 5
	push bc			;644d   ; BC se empuja dos veces porque hacen falta las dos copias
	push bc			;644e
	push af			;644f
	ld de,064b1h		;6450   ; Cuatro patrones por pose
	add a,a			;6453
	add a,a			;6454
	call DE_MAS_A		;6455
	ld a,002h		;6458   ; Dos pixeles a la derecha...
	call X_SEGUN_EL_LADO		;645a
	call UN_SPRITE		;645d
	inc hl			;6460
	inc hl			;6461
	inc hl			;6462
	inc hl			;6463
	ld a,0fdh		;6464   ; ...y tres a la izquierda: las dos mitades de la figura
	call X_SEGUN_EL_LADO		;6466
	call UN_SPRITE		;6469
	pop af			;646c
	pop bc			;646d
	cp 005h		;646e   ; La pose 5 lleva un sprite mas
	jr nz,PINTA_LA_MITAD_DE_ABAJO		;6470
	ld a,003h		;6472
	call X_SEGUN_EL_LADO		;6474
PINTA_LA_MITAD_DE_ABAJO:		; Dieciseis pixeles mas abajo, los otros dos sprites
	ld a,010h		;6477   ; Dieciseis pixeles: la altura de un sprite
	add a,b			;6479
	ld b,a			;647a
	call DOS_SPRITES		;647b
	pop bc			;647e
	ld hl,0e0c4h		;647f
	ld a,0fbh		;6482
	call X_SEGUN_EL_LADO		;6484
	call UN_SPRITE		;6487
	dec hl			;648a
	dec hl			;648b
	ld a,(0e139h)		;648c   ; E139, hacia donde mira: 4 es a la izquierda
	cp 004h		;648f
	ld (hl),008h		;6491   ; Y con eso, el patron de la mitad de abajo
	jr nz,L_6497		;6493
	ld (hl),064h		;6495
L_6497:
	ret			;6497
DOS_SPRITES:		; Dos sprites seguidos con la misma Y,X y los dos patrones siguientes de DE
	call UN_SPRITE		;6498
UN_SPRITE:		; Y=B, X=C, patron (DE), y salta el color
	ld (hl),b			;649b   ; Los cuatro bytes del sprite: Y, X, patron y color
	inc hl			;649c
	ld (hl),c			;649d
	inc hl			;649e
	ld a,(0e139h)		;649f
	cp 004h		;64a2
	ld a,(de)			;64a4   ; El patron sale de la tabla que trae DE
	jr nz,L_64AC		;64a5
	ld a,05ch		;64a7
	ex de,hl			;64a9
	add a,(hl)			;64aa
	ex de,hl			;64ab
L_64AC:
	ld (hl),a			;64ac
	inc de			;64ad
	inc hl			;64ae   ; El segundo inc hl salta el color, que no se toca
	inc hl			;64af
	ret			;64b0

; ----------------------------------------------------------------------
; DATOS poses: Siete poses de cuatro patrones que 0x6450 indexa multiplicando
;   por cuatro
;   0x64b1..0x64cd  (28 bytes)
DATA_poses:
	defb 004h,000h,00ch,010h	; 64b1
	defb 004h,000h,014h,018h	; 64b5
	defb 004h,000h,024h,028h	; 64b9
	defb 004h,000h,01ch,020h	; 64bd
	defb 004h,000h,02ch,030h	; 64c1
	defb 004h,000h,034h,038h	; 64c5
	defb 004h,000h,01ch,020h	; 64c9

; ======================================================================
; CODIGO 0x64cd..0x6558  (139 bytes)
; ======================================================================


PINTA_AL_JUGADOR:		; Los cuatro sprites de la figura, los de mas abajo y la cara
	ld de,06558h		;64cd
	call PINTA_CUATRO_SPRITES		;64d0
	ld a,010h		;64d3   ; Otra vez dieciseis mas abajo
	add a,b			;64d5
	ld b,a			;64d6
	ld a,001h		;64d7
	call X_SEGUN_EL_LADO		;64d9
	ld a,(0e136h)		;64dc   ; E136, la pose
	rra			;64df
	ld a,0ffh		;64e0
	jr nc,PINTA_LA_CARA		;64e2
	ld a,001h		;64e4
PINTA_LA_CARA:		; El sprite de la cara encima de la figura, con su color, y el de la sombra debajo
	call X_SEGUN_EL_LADO		;64e6
	ld hl,0e0bch		;64e9   ; E0C0 es el sprite 4, la cabeza
	call UN_SPRITE		;64ec
	dec hl			;64ef
	ld (hl),00bh		;64f0   ; Color 11: amarillo claro
	ld hl,0e0b8h		;64f2
	ld bc,(0e0c8h)		;64f5   ; La sombra copia la posicion del sprite de 0xE0C8
	ld (hl),c			;64f9
	inc hl			;64fa
	ld (hl),b			;64fb
	inc hl			;64fc
	ld a,(0e139h)		;64fd
	bit 3,a		;6500
	ld a,050h		;6502   ; Segun hacia donde mira, un patron u otro
	jr nz,L_6508		;6504
	ld a,0ach		;6506
L_6508:
	ld (hl),a			;6508
	inc hl			;6509
	ld a,(0e0c3h)		;650a
	ld (hl),a			;650d
	ret			;650e
PINTA_CUATRO_SPRITES:		; Los cuatro sprites del jugador alrededor de (E134, E135), con la X reflejada si mira a la izquierda
	ld hl,0e134h		;650f   ; E134 es la Y y E135 la X; ocho pixeles mas abajo es donde empieza la figura
	ld a,(hl)			;6512
	add a,008h		;6513
	ld b,a			;6515
	inc hl			;6516
	ld c,(hl)			;6517
	push bc			;6518
	push bc			;6519
	ld hl,0e0c0h		;651a
	ld a,001h		;651d
	call X_SEGUN_EL_LADO		;651f   ; Desplazamiento +1 en X
	call UN_SPRITE		;6522
	inc hl			;6525
	inc hl			;6526
	inc hl			;6527
	inc hl			;6528
	ld a,0fdh		;6529   ; Y el de al lado, -3
	call X_SEGUN_EL_LADO		;652b
	call UN_SPRITE		;652e
	pop bc			;6531
	ld a,010h		;6532   ; Diecisiete pixeles mas abajo, la mitad de abajo de la figura
	add a,b			;6534
	ld b,a			;6535
	call DOS_SPRITES		;6536
	pop bc			;6539
	push bc			;653a
	ld hl,0e0c4h		;653b   ; El cuarto, a -7
	ld a,0f9h		;653e
	call X_SEGUN_EL_LADO		;6540
	call UN_SPRITE		;6543
	pop bc			;6546
	ret			;6547
X_SEGUN_EL_LADO:		; Suma A a la X (C), y con el jugador mirando a la izquierda (E139=4) se la resta
	push hl			;6548
	ld h,a			;6549
	ld a,(0e139h)		;654a   ; E139 dice hacia donde mira
	cp 004h		;654d
	ld a,h			;654f
	jr nz,L_6554		;6550
	neg		;6552   ; Mirando al otro lado, el desplazamiento cambia de signo: la figura se refleja
L_6554:
	add a,c			;6554
	ld c,a			;6555
	pop hl			;6556
	ret			;6557

; ----------------------------------------------------------------------
; DATOS seis_de_0x64CD: Los seis bytes que 0x64CD pasa a 0x650F: 04 00 44 48
;   08 4C
;   0x6558..0x655e  (6 bytes)
DATA_seis_de_0x64CD:
	defb 004h,000h,044h	; 6558
	defb 048h,008h,04ch	; 655b

; ======================================================================
; CODIGO 0x655e..0x6626  (200 bytes)
; ======================================================================


ARCO_SUBIENDO:		; Arranca el arco HL hacia arriba (E202=0): un salto
	xor a			;655e
	jr ARCO_ARRANCA		;655f
ARCO_CAYENDO:		; Arranca el arco HL hacia abajo (E202=1): una caida
	ld a,001h		;6561
ARCO_ARRANCA:		; E200 = HL, E202 = A, E205 = 0
	ld (0e200h),hl		;6563
	ld (0e202h),a		;6566
	xor a			;6569
	ld (0e205h),a		;656a
	ret			;656d
AGARRA_CUALQUIER_LIANA:		; Prueba con la 2 y con la 1
	ld hl,0e142h		;656e   ; E142 y E143, la Y y la X del cabo de la liana 2
	call CHOCA_CON_SPRITE		;6571   ; El jugador contra ese cabo, con la caja de 16x16 de 0x5EE2
	jr nc,COLGADO		;6574
	ld hl,0e140h		;6576   ; Y si no la agarra, se prueba con la liana 1
	call CHOCA_CON_SPRITE		;6579
	jr nc,COLGADO		;657c
	jr PASO_DE_ARCO_JUGADOR		;657e   ; Ninguna de las dos: el salto sigue su arco

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; UN PASO DEL SALTO. Si puede agarrar (E144=0) y toca el cabo de una
; liana (E140 o E142), se cuelga (estado 2) y cobra sus puntos. Si no:
; cobra lo que haya saltado (E1A5-E1AB), avanza el arco (E200/E202) en Y,
; mueve la X segun la direccion guardada (E137: 2 puntos, o 1 saliendo
; de la liana), y al agotar el arco lo da la vuelta o lo termina.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
PASO_DE_SALTO:		; Liana si se puede; si no, un paso del arco
	ld a,(0e144h)		;6580
	or a			;6583   ; E144 distinto de 0: no puede agarrar
	jr nz,PASO_DE_ARCO_JUGADOR		;6584
	ld hl,0e140h		;6586
	ld a,(0e13ch)		;6589
	bit 1,a		;658c   ; E13C=2: viene de la liana 2 y solo puede agarrar la 1; a 0, cualquiera de las dos
	jr nz,AGARRA_LIANA		;658e
	ld hl,0e142h		;6590
	bit 0,a		;6593
	jr z,AGARRA_CUALQUIER_LIANA		;6595
AGARRA_LIANA:		; Toca el cabo: cuelga
	call CHOCA_CON_SPRITE		;6597
	jr c,PASO_DE_ARCO_JUGADOR		;659a
COLGADO:		; E13C = que liana, cobra sus puntos, estado 2
	ld a,l			;659c   ; Los dos bits bajos del puntero dicen cual de las dos lianas es
	and 003h		;659d
	ld (0e13ch),a		;659f
	ld c,a			;65a2
	call COBRA_PUNTOS		;65a3   ; Sus puntos, por el indice de la tabla de cobrados
	ld a,002h		;65a6
	ld (0e138h),a		;65a8   ; Estado 2: colgado
PASO_DE_ARCO_JUGADOR:		; Cobra lo saltado y avanza el arco
	ld hl,0e1a5h		;65ab   ; Trampolines, charcos, piedra y hoguera (E1A5-E1AB)
	ld b,007h		;65ae   ; Siete obstaculos, del 9 al 15 de la tabla de cobrados
	ld c,009h		;65b0
	call COBRA_AL_PASAR		;65b2
	ld a,(0e202h)		;65b5   ; Bit 0 de E202: hacia donde va el arco del salto
	ld b,a			;65b8
	ld hl,0e205h		;65b9
	bit 0,b		;65bc
	jr nz,L_65C3		;65be
	inc (hl)			;65c0   ; E205 es el paso dentro del arco
	jr L_65C4		;65c1
L_65C3:
	dec (hl)			;65c3
L_65C4:
	ld a,(hl)			;65c4
	cp 008h		;65c5   ; Pose 6 los primeros 8 fotogramas, luego la 4
	ld a,006h		;65c7
	jr c,L_65CD		;65c9
	ld a,004h		;65cb
L_65CD:
	ld (0e136h),a		;65cd
	ld hl,0e134h		;65d0
	ld de,(0e200h)		;65d3
	bit 0,b		;65d7
	ld a,(de)			;65d9   ; Y mas o menos el delta
	jr nz,L_65DE		;65da
	neg		;65dc
L_65DE:
	add a,(hl)			;65de   ; La Y del jugador
	ld (hl),a			;65df
	inc hl			;65e0
	ld a,(0e137h)		;65e1   ; E137: izquierda o derecha, guardadas al saltar
	or a			;65e4
	jr z,ARCO_JUGADOR_AVANZA		;65e5
	ld c,a			;65e7
	ld a,(0e144h)		;65e8   ; Saliendo de la liana (E144=0xFF), dos puntos por fotograma
	inc a			;65eb
	jr nz,L_65FA		;65ec
	bit 3,c		;65ee   ; Bit 3: hacia la derecha
	jr z,L_65F6		;65f0
	inc (hl)			;65f2
	inc (hl)			;65f3
	jr ARCO_JUGADOR_AVANZA		;65f4
L_65F6:
	dec (hl)			;65f6
	dec (hl)			;65f7
	jr ARCO_JUGADOR_AVANZA		;65f8
L_65FA:
	bit 3,c		;65fa   ; Si no, uno
	jr z,L_6601		;65fc
	inc (hl)			;65fe
	jr ARCO_JUGADOR_AVANZA		;65ff
L_6601:
	dec (hl)			;6601
ARCO_JUGADOR_AVANZA:		; Puntero adelante (subiendo) o atras (bajando); 0xFF da la vuelta y E144+1 (desde el suelo ya no se agarra liana bajando; desde otra liana, 0xFF pasa a 0 y si); 0xFE termina
	ex de,hl			;6602
	bit 0,b		;6603
	jr nz,L_660A		;6605
	inc hl			;6607
	jr L_660B		;6608
L_660A:
	dec hl			;660a
L_660B:
	ld a,(hl)			;660b   ; 0xFF cierra la tabla por el lado de subir
	ld b,a			;660c
	inc a			;660d
	jr nz,L_6620		;660e
	dec hl			;6610   ; Dos atras: se vuelve al ultimo valor bueno
	dec hl			;6611
	push hl			;6612
	ld hl,0e144h		;6613
	inc (hl)			;6616   ; E144 sube: sale del 0xFF y ya se puede agarrar otra liana
	pop hl			;6617
	inc a			;6618
	ld (0e202h),a		;6619   ; E202 = 1: el arco se recorre al reves, cayendo
L_661C:
	ld (0e200h),hl		;661c
	ret			;661f
L_6620:
	inc a			;6620   ; 0xFE es el tope de abajo: se vuelve al primer valor y el paso se repite sin fin
	jr nz,L_661C		;6621
	inc hl			;6623
	jr L_661C		;6624

; ----------------------------------------------------------------------
; DATOS arco_de_hundirse: El arco medio: 2 1 2 1 2 1 1 1 1 1 1 1 0 1 0 0. Lo
;   usan hundirse y la bola que rueda con el bit 1 de E158
;   0x6626..0x6636  (16 bytes)
DATA_arco_de_hundirse:
	defb 0feh,002h,001h,002h,001h,002h,001h,001h,001h,001h,001h,001h,001h,000h,001h,000h	; 6626  ................

; ----------------------------------------------------------------------
; DATOS arco_corto: El arco corto: 4 4 3 3 3 3 2 2 2 2 1 1 1 1 0 0. El salto
;   normal, el bote sin boton, y caer de tabla o poste
;   0x6636..0x664a  (20 bytes)
DATA_arco_corto:
	defb 000h,0ffh,0feh,004h,004h,003h,003h,003h,003h,002h,002h,002h,002h,001h,001h,001h	; 6636  ................
	defb 001h,000h,000h,0ffh	; 6646

; ======================================================================
; CODIGO 0x664a..0x6718  (206 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; ESTADO 2: COLGADO DE LA LIANA. Sigue al cabo (E140 o E142), pose 5;
; con abajo se suelta (estado 1, arco corto cayendo, E144=1); con el
; boton salta (arco cortito desde 0x6631, sonido 3, E144=0xFF), y
; mirando a la izquierda la pose 12.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
ESTADO_2_LIANA:		; Colgado del cabo de la liana
	ld hl,0e140h		;664a
	ld a,(0e13ch)		;664d
	bit 1,a		;6650   ; Bit 1 de E13C: la liana 2
	jr z,L_6657		;6652
	ld hl,0e142h		;6654
L_6657:
	ld b,(hl)			;6657   ; El cabo de la liana: Y en B, X en C
	inc hl			;6658
	ld c,(hl)			;6659
	ld hl,0e134h		;665a   ; El jugador se pega al cabo
	ld (hl),b			;665d
	inc hl			;665e
	ld a,(0e139h)		;665f
	cp 004h		;6662
	ld a,c			;6664
	jr nz,L_666A		;6665
	add a,00eh		;6667   ; Mirando a la izquierda, 14 mas a la derecha
	ld c,a			;6669
L_666A:
	ld (hl),a			;666a
	inc hl			;666b
	ld (hl),005h		;666c   ; Pose 5: colgado
	ld a,(0e009h)		;666e   ; E009, lo que se pulsa en este fotograma
	ld b,a			;6671
	bit 1,a		;6672   ; Abajo: se suelta
	jr z,L_6687		;6674
	ld hl,06636h		;6676   ; Al soltarse, el arco corto de 0x6636
	call ARCO_CAYENDO		;6679
	ld a,001h		;667c
	ld (0e138h),a		;667e   ; Estado 1 (en el aire) y E144=1: soltado desde liana
	ld (0e144h),a		;6681
L_6684:
	jp MOVIMIENTO_COMUN		;6684
L_6687:
	and 00ch		;6687   ; Izquierda o derecha guardadas para el salto
	ld (0e137h),a		;6689
	call SALTA_SI_BOTON		;668c
	jr nc,L_6684		;668f
	ld hl,06631h		;6691   ; El arco cortito de 0x6631, el impulso del salto
	call ARCO_SUBIENDO		;6694
	ld a,001h		;6697
	ld (0e138h),a		;6699
	ld a,003h		;669c
	call SONIDO		;669e
	ld a,0ffh		;66a1   ; E144 = 0xFF: acaba de saltar de una liana
	ld (0e144h),a		;66a3
	ld a,(0e139h)		;66a6
	cp 004h		;66a9
	jr nz,L_66B4		;66ab
	ld hl,0e136h		;66ad   ; Mirando a la izquierda, seis poses mas alla: las espejadas
	ld a,(hl)			;66b0
	add a,007h		;66b1
	ld (hl),a			;66b3
L_66B4:
	jr L_6684		;66b4
ANDA:		; Izquierda o derecha: un paso (X mas o menos 1), sonido 2, mirada, y la pose por los pasos (E13B); parado, pose 6
	xor a			;66b6
	ld (0e144h),a		;66b7   ; E144 a cero: desde el suelo no se agarra liana
	ld (0e13ch),a		;66ba
	ld a,(0e009h)		;66bd   ; Bits 2 y 3 de lo pulsado: izquierda y derecha
	and 00ch		;66c0
	ld (0e137h),a		;66c2
	ld hl,0e135h		;66c5
	ld de,0e13bh		;66c8   ; E13B cuenta los pasos; de el sale la pose
	jr nz,L_66D1		;66cb
	ld a,006h		;66cd   ; Parado: pose 6
	jr L_66EB		;66cf
L_66D1:
	ex de,hl			;66d1   ; Un paso mas
	inc (hl)			;66d2
	ex de,hl			;66d3
	ld (0e139h),a		;66d4
	bit 3,a		;66d7
	jr z,L_66DE		;66d9
	inc (hl)			;66db
	jr L_66DF		;66dc
L_66DE:
	dec (hl)			;66de
L_66DF:
	push hl			;66df
	ld a,002h		;66e0   ; Sonido de pisada
	call SONIDO		;66e2
	pop hl			;66e5
	ld a,(de)			;66e6   ; Pose 0-3 por los bits 2-3 de los pasos
	and 00ch		;66e7
	rrca			;66e9
	rrca			;66ea
L_66EB:
	inc hl			;66eb
	ld (hl),a			;66ec
	ret			;66ed
SALTA_SI_BOTON:		; Acarreo si se acaba de pulsar espacio o SELECT (bits 4-5, ahora si y antes no); guarda la altura segura E13A: la del jugador sobre un surtidor de en medio, o 16 mas abajo
	ld hl,0e008h		;66ee
	ld a,(hl)			;66f1
	cpl			;66f2   ; Los botones de antes al reves: los que estaban sueltos
	and 030h		;66f3
	inc hl			;66f5
	and (hl)			;66f6   ; Y ahora pulsados: cuenta el flanco, no que este apretado
	ret z			;66f7
	ld a,(0e134h)		;66f8   ; E134, la Y desde la que arranca el salto
	ld b,a			;66fb
	ld a,(0e138h)		;66fc
	cp 004h		;66ff   ; Sobre un surtidor y entre X=0x48 y 0x9F: la altura es la de la tabla
	jr nz,L_670E		;6701
	ld a,(0e135h)		;6703
	cp 0a0h		;6706
	jr nc,L_670E		;6708
	cp 048h		;670a
	jr nc,L_6712		;670c
L_670E:
	ld a,010h		;670e   ; Si no, 16 por debajo (el suelo)
	add a,b			;6710
	ld b,a			;6711
L_6712:
	ld a,b			;6712
	ld (0e13ah),a		;6713
	scf			;6716   ; Acarreo: hay salto
	ret			;6717

; ----------------------------------------------------------------------
; DATOS resto_listas_de_athletic: Tres listas del motor de rotulos que cierran
;   limpias con su 0x00 y a las que NO apunta nadie: son, byte a byte, las de
;   Athletic Land (0x6DD4 alli, +1724)
;   0x6718..0x6728  (16 bytes)
DATA_resto_listas_de_athletic:
	defb 0a0h,0a0h,0a0h,0a0h,020h,0c0h,000h,0d0h	; 6718  .... ...
	defb 0d0h,0a0h,000h,060h,0a0h,0a0h,0a0h,000h	; 6720  ...`....

; ----------------------------------------------------------------------
; DATOS lista_motor_6728: lista del motor de rotulos de 0x57BB (tiles 0x6BA1,
;   VRAM 0x3A00)
;   0x6728..0x672c  (4 bytes)
DATA_lista_motor_6728:
	defb 0e0h,0a0h,0a0h,000h	; 6728

; ----------------------------------------------------------------------
; DATOS lista_motor_672C: lista del motor de rotulos de 0x57CB (tiles 0x6BA4,
;   VRAM 0x3A09)
;   0x672c..0x673c  (16 bytes)
DATA_lista_motor_672C:
	defb 003h,088h,003h,080h,027h,03ah,007h,084h,007h,080h,049h,03ah,003h,088h,003h,000h	; 672c  ....':....I:....

; ----------------------------------------------------------------------
; DATOS lista_motor_673C: lista del motor de rotulos de 0x593E (tiles 0x6BE5,
;   VRAM 0x39A9)
;   0x673c..0x6746  (10 bytes)
DATA_lista_motor_673C:
	defb 08fh,080h,0c9h,039h,00fh,080h,0e9h,039h,08fh,000h	; 673c  ...9...9..

; ----------------------------------------------------------------------
; DATOS copia_6746: 416 bytes que 0x5951 copia a la VRAM 0x3860
;   0x6746..0x68e6  (416 bytes)
DATA_copia_6746:
	defb 005h,01fh,023h,005h,023h,021h,005h,020h,024h,005h,01fh,024h,005h,023h,020h,025h	; 6746  ..#.#!. $..$.# %
	defb 025h,023h,01fh,024h,005h,023h,021h,005h,024h,01fh,005h,020h,024h,005h,024h,01fh	; 6756  %#.$.#!.$.. $.$.
	defb 020h,027h,029h,023h,029h,027h,025h,027h,02ah,023h,027h,02ah,024h,029h,027h,02bh	; 6766   ')#)'%'*#'*$)'+
	defb 02bh,029h,027h,02ah,020h,029h,027h,025h,02ah,027h,023h,027h,02ah,021h,02ah,027h	; 6776  +)'* )'%*'#'*!*'
	defb 027h,02dh,02dh,029h,02dh,02dh,02bh,02dh,02dh,029h,02dh,02dh,02ah,02dh,02dh,02dh	; 6786  '--)--+--)--*---
	defb 02dh,02dh,02dh,02dh,027h,02dh,02dh,02bh,02dh,02dh,029h,02dh,02dh,027h,02dh,02dh	; 6796  ----'--+--)--'--
	defb 02eh,02eh,02eh,02eh,02eh,02eh,02eh,02eh,02eh,02eh,02eh,02eh,02eh,01eh,005h,005h	; 67a6  ................
	defb 005h,005h,02fh,02eh,02eh,02eh,02eh,02eh,02eh,02eh,02eh,02eh,02eh,02eh,02eh,02eh	; 67b6  ../.............
	defb 02eh,02eh,02eh,02eh,02eh,02eh,01eh,005h,005h,005h,005h,005h,005h,005h,005h,005h	; 67c6  ................
	defb 005h,005h,005h,005h,005h,005h,005h,005h,005h,005h,02fh,02eh,02eh,02eh,02eh,02eh	; 67d6  ........../.....
	defb 0e5h,0e6h,0edh,02eh,02eh,01eh,005h,005h,005h,005h,005h,005h,005h,005h,005h,005h	; 67e6  ................
	defb 005h,005h,005h,005h,005h,005h,005h,005h,005h,005h,005h,02fh,02eh,02eh,0e5h,0e6h	; 67f6  .........../....
	defb 0e7h,0e6h,0e7h,02eh,01eh,005h,005h,005h,005h,005h,005h,005h,005h,005h,005h,005h	; 6806  ................
	defb 005h,005h,005h,005h,005h,005h,005h,005h,005h,005h,005h,005h,02fh,02eh,0e7h,0e6h	; 6816  ............/...
	defb 0e7h,0e6h,0e7h,02eh,0e4h,005h,005h,005h,005h,005h,005h,005h,005h,005h,005h,005h	; 6826  ................
	defb 005h,005h,005h,005h,005h,005h,005h,005h,005h,005h,005h,005h,0ech,02eh,0e7h,0e6h	; 6836  ................
	defb 026h,022h,026h,02eh,0e4h,005h,005h,005h,005h,005h,005h,005h,005h,005h,005h,005h	; 6846  &"&.............
	defb 005h,005h,005h,005h,005h,005h,005h,005h,005h,005h,005h,005h,0ech,02eh,026h,022h	; 6856  ..............&"
	defb 02ch,028h,02ch,02eh,0e4h,005h,005h,005h,005h,005h,005h,005h,005h,005h,005h,005h	; 6866  ,(,.............
	defb 005h,005h,005h,005h,005h,005h,005h,005h,005h,005h,005h,005h,0ech,02eh,02ch,028h	; 6876  ..............,(
	defb 02eh,02eh,02eh,02eh,02dh,0e4h,005h,005h,005h,005h,005h,005h,005h,005h,005h,005h	; 6886  ....-...........
	defb 005h,005h,005h,005h,005h,005h,005h,005h,005h,005h,005h,0ech,02dh,02eh,02eh,02eh	; 6896  ............-...
	defb 02eh,02eh,02eh,02eh,02eh,0e4h,01fh,005h,005h,023h,005h,025h,020h,023h,021h,005h	; 68a6  .........#.% #!.
	defb 025h,005h,025h,01fh,024h,020h,025h,005h,005h,023h,021h,0ech,02eh,02eh,02eh,02eh	; 68b6  %.%.$ %..#!.....
	defb 02eh,02eh,02eh,02eh,02eh,0e4h,027h,010h,010h,029h,010h,02bh,027h,029h,027h,010h	; 68c6  ......'..).+')'.
	defb 02bh,010h,02bh,027h,02ah,027h,02bh,010h,010h,029h,027h,0ech,02eh,02eh,02eh,02eh	; 68d6  +.+'*'+..)'.....

; ----------------------------------------------------------------------
; DATOS copia_68E6: 448 bytes que 0x57B7 copia a la VRAM 0x3840
;   0x68e6..0x6aa6  (448 bytes)
DATA_copia_68E6:
	defb 007h,007h,007h,007h,007h,007h,007h,007h,007h,066h,066h,007h,007h,007h,007h,007h	; 68e6  .........ff.....
	defb 007h,066h,007h,007h,007h,007h,007h,007h,007h,007h,007h,007h,066h,007h,007h,007h	; 68f6  .f..........f...
	defb 007h,066h,007h,007h,066h,066h,007h,007h,060h,074h,007h,007h,066h,066h,007h,007h	; 6906  .f..ff..`t..ff..
	defb 007h,007h,007h,007h,066h,007h,060h,074h,066h,066h,007h,060h,074h,007h,007h,007h	; 6916  ....f.`tff.`t...
	defb 061h,067h,068h,075h,062h,063h,077h,076h,002h,002h,062h,063h,007h,007h,007h,007h	; 6926  aghubcwv..bc....
	defb 077h,076h,061h,068h,076h,069h,002h,002h,069h,069h,069h,002h,002h,061h,067h,068h	; 6936  wvahvi..iii..agh
	defb 06ah,06ah,06ah,002h,06bh,06bh,06bh,06bh,06bh,06bh,06bh,06bh,06bh,002h,002h,002h	; 6946  jjj.kkkkkkkkk...
	defb 002h,06ah,06ah,06ch,06dh,06eh,06eh,06fh,06fh,070h,003h,003h,06fh,06fh,06fh,06eh	; 6956  .jjlmnnoop..ooon
	defb 003h,003h,003h,003h,06fh,06fh,06fh,06fh,06fh,06fh,06fh,06fh,06fh,071h,071h,071h	; 6966  ....oooooooooqqq
	defb 070h,003h,003h,003h,003h,003h,072h,003h,003h,072h,003h,003h,072h,003h,003h,003h	; 6976  p.....r..r..r...
	defb 003h,003h,064h,065h,073h,073h,073h,073h,073h,073h,073h,073h,073h,005h,005h,005h	; 6986  ..desssssssss...
	defb 079h,078h,003h,003h,072h,003h,003h,003h,003h,003h,072h,003h,003h,003h,072h,003h	; 6996  yx..r.....r...r.
	defb 003h,003h,0c0h,0cah,0cah,0cah,0cah,0cah,0cah,0cah,0cah,0cah,0cah,0cah,0cah,0cah	; 69a6  ................
	defb 0cah,0d1h,003h,003h,003h,003h,003h,003h,003h,003h,003h,003h,003h,003h,003h,003h	; 69b6  ................
	defb 003h,0cbh,003h,003h,0cch,003h,0cdh,0c1h,0c2h,0c3h,0d4h,0d3h,0c2h,0c3h,0d4h,0d3h	; 69c6  ................
	defb 0c2h,0c3h,0d4h,0d3h,0c2h,0c3h,0d4h,0d3h,0d2h,0cch,0cfh,003h,0cdh,003h,003h,003h	; 69d6  ................
	defb 0ceh,003h,0cfh,0cdh,0d0h,0cch,0c1h,0c4h,0d5h,0c5h,0d6h,0c4h,0d5h,0c5h,0d6h,0c4h	; 69e6  ................
	defb 0d5h,0c5h,0d6h,0c4h,0d5h,0c5h,0d6h,0c4h,0d5h,0d2h,0cdh,0ceh,0cch,0d0h,0cdh,003h	; 69f6  ................
	defb 0d0h,0cdh,0cbh,0ceh,003h,0c1h,0c6h,0c7h,0d8h,0d7h,0c6h,0c7h,0d8h,0d7h,0c6h,0c7h	; 6a06  ................
	defb 0d8h,0d7h,0c6h,0c7h,0d8h,0d7h,0c6h,0c7h,0d8h,0d7h,0d2h,0cdh,0ceh,0cbh,003h,0cch	; 6a16  ................
	defb 0cfh,0cch,0ceh,0cdh,0c1h,00bh,0c8h,0c9h,0dah,0d9h,0c8h,0c9h,0dah,0d9h,0c8h,0c9h	; 6a26  ................
	defb 0dah,0d9h,0c8h,0c9h,0dah,0d9h,0c8h,0c9h,0dah,0d9h,00bh,0d2h,0cch,0cfh,0d0h,0ceh	; 6a36  ................
	defb 02dh,02dh,02dh,02dh,02dh,02dh,02dh,02dh,02dh,02dh,02dh,02dh,02dh,02dh,02dh,02dh	; 6a46  ----------------
	defb 02dh,02dh,02dh,02dh,02dh,02dh,02dh,02dh,02dh,02dh,02dh,02dh,02dh,02dh,02dh,02dh	; 6a56  ----------------
	defb 02eh,02eh,02eh,02eh,02eh,02eh,02eh,02eh,02eh,02eh,02eh,02eh,02eh,02eh,02eh,02eh	; 6a66  ................
	defb 02eh,02eh,02eh,02eh,02eh,02eh,02eh,02eh,02eh,02eh,02eh,02eh,02eh,02eh,02eh,02eh	; 6a76  ................
	defb 02eh,02eh,02eh,02eh,02eh,02eh,02eh,02eh,02eh,02eh,02eh,02eh,02eh,02eh,02eh,02eh	; 6a86  ................
	defb 02eh,02eh,02eh,02eh,02eh,02eh,02eh,02eh,02eh,02eh,02eh,02eh,02eh,02eh,02eh,02eh	; 6a96  ................

; ----------------------------------------------------------------------
; DATOS resto_tiles_de_athletic: 251 bytes identicos byte a byte a los tiles
;   de fondo de Athletic Land (0x6E90 alli, +1002), sin una sola instruccion
;   que los lea
;   0x6aa6..0x6ba1  (251 bytes)
DATA_resto_tiles_de_athletic:
	defb 01ch,01dh,01eh,01fh,068h,069h,06ah,065h,066h,069h,06ah,060h,064h,060h,061h,062h	; 6aa6  ....hijefij`d`ab
	defb 063h,064h,065h,066h,067h,001h,068h,069h,06ah,060h,064h,060h,061h,063h,064h,065h	; 6ab6  cdefg.hij`d`acde
	defb 066h,067h,068h,069h,001h,01ch,01dh,01eh,01fh,07eh,07fh,080h,07bh,07ch,07fh,080h	; 6ac6  fghi.....~..{|..
	defb 076h,07ah,076h,077h,078h,079h,07ah,07bh,07ch,07dh,00ah,07eh,07fh,080h,076h,07ah	; 6ad6  vzvwxyz{|}.~..vz
	defb 076h,077h,079h,07ah,07bh,07ch,07dh,07eh,07fh,00ah,08ch,08dh,08eh,08fh,073h,074h	; 6ae6  vwyz{|}~......st
	defb 075h,070h,071h,074h,075h,06bh,06fh,06bh,06ch,06dh,06eh,06fh,070h,071h,072h,001h	; 6af6  upqtukoklmnopqr.
	defb 073h,074h,075h,06bh,06fh,06bh,06ch,06eh,06fh,070h,071h,072h,073h,074h,001h,08ch	; 6b06  stukoklnopqrst..
	defb 08dh,08eh,08fh,089h,08ah,08bh,086h,087h,08ah,08bh,081h,085h,081h,082h,083h,084h	; 6b16  ................
	defb 085h,086h,087h,088h,00ah,089h,08ah,08bh,081h,085h,081h,082h,084h,085h,086h,087h	; 6b26  ................
	defb 088h,089h,08ah,00ah,001h,001h,00bh,09ch,09ch,09ch,09ch,09ch,09ch,09ch,09ch,09fh	; 6b36  ................
	defb 09ch,0a0h,0a1h,0a2h,0a3h,0a4h,0a5h,0deh,0ddh,0dch,0dbh,0dah,0d9h,09ch,0d8h,09ch	; 6b46  ................
	defb 09ch,09ch,09ch,09ch,09ch,09ch,09ch,09dh,09dh,09dh,09dh,09dh,09dh,0a6h,09dh,0a7h	; 6b56  ................
	defb 09dh,0a6h,0a8h,09dh,0a9h,0aah,09dh,09dh,0e3h,0e2h,09dh,0e1h,0dfh,09dh,0e0h,09dh	; 6b66  ................
	defb 0dfh,09dh,09dh,09dh,09dh,09dh,09dh,09eh,09eh,09eh,0abh,09eh,09eh,09eh,09eh,0abh	; 6b76  ................
	defb 09eh,09eh,09eh,09eh,0abh,09eh,09eh,09eh,09eh,0e4h,09eh,09eh,09eh,09eh,0e4h,09eh	; 6b86  ................
	defb 09eh,09eh,09eh,0e4h,09eh,09eh,09eh,09eh,008h,00ch,00bh	; 6b96  ...........

; ----------------------------------------------------------------------
; DATOS tiles_del_suelo: Los tres tiles que la lista de 0x6728 reparte por las
;   cuatro filas de abajo
;   0x6ba1..0x6ba4  (3 bytes)
DATA_tiles_del_suelo:
	defb 00eh,0c0h,011h	; 6ba1

; ----------------------------------------------------------------------
; DATOS tiles_del_estanque: Los veintinueve tiles que reparte la lista de
;   0x672C sobre las mismas filas
;   0x6ba4..0x6bc1  (29 bytes)
DATA_tiles_del_estanque:
	defb 0cbh,0cch,0cch,0cdh,0cch,0cch,0cbh,0c5h,0ceh,0cfh,004h,004h,004h,004h,004h,004h	; 6ba4  ................
	defb 004h,004h,004h,0cfh,0ceh,0d8h,0c8h,0c9h,0c9h,0cah,0c9h,0c9h,0c8h	; 6bb4  .............

; ----------------------------------------------------------------------
; DATOS bloque_trampolin: Los cuatro tiles del trampolin (0xC6 0xD9 / 0xC7
;   0xDA), que 0x57DE pinta cada cuatro columnas en un bloque de 2x2
;   0x6bc1..0x6bc5  (4 bytes)
DATA_bloque_trampolin:
	defb 0c6h,0d9h	; 6bc1
	defb 0c7h,0dah	; 6bc3

; ----------------------------------------------------------------------
; DATOS copia_6BC5: 2 bytes que 0x5842 copia a la VRAM 0x3A27
;   0x6bc5..0x6bc7  (2 bytes)
DATA_copia_6BC5:
	defb 0c5h,0d8h	; 6bc5

; ----------------------------------------------------------------------
; DATOS poste_bajo: Los seis tiles del poste bajo de 3x2 que 0x5892 pinta en
;   la fila 15
;   0x6bc7..0x6bcd  (6 bytes)
DATA_poste_bajo:
	defb 0e0h,0e8h	; 6bc7
	defb 0e1h,0e9h	; 6bc9
	defb 0e3h,0ebh	; 6bcb

; ----------------------------------------------------------------------
; DATOS postes_altos: Tres postes de 4x2 (ocho tiles cada uno) que 0x589B,
;   0x58A4 y 0x58AD pintan en la fila 14
;   0x6bcd..0x6be5  (24 bytes)
DATA_postes_altos:
	defb 0e0h,0e8h	; 6bcd
	defb 0e1h,0e9h	; 6bcf
	defb 0e2h,0eah	; 6bd1
	defb 0e3h,0ebh	; 6bd3
	defb 0e0h,0e8h	; 6bd5
	defb 0e1h,0e9h	; 6bd7
	defb 0e2h,0eah	; 6bd9
	defb 0e3h,0ebh	; 6bdb
	defb 0e0h,0e8h	; 6bdd
	defb 0e1h,0e9h	; 6bdf
	defb 0e2h,0eah	; 6be1
	defb 0e3h,0ebh	; 6be3

; ----------------------------------------------------------------------
; DATOS rotulo_babyland: Los diecisiete tiles del cartel BABYLAND que reparte
;   la lista de 0x673C: el nombre del sitio, escrito en el propio cartucho
;   0x6be5..0x6bf6  (17 bytes)
DATA_rotulo_babyland:
	defb 012h,004h,042h,041h,042h,059h,04ch,041h,04eh,044h,004h,050h,041h,052h,04bh,004h	; 6be5  ..BABYLAND.PARK.
	defb 013h	; 6bf5

; ----------------------------------------------------------------------
; DATOS resto_cerros_de_athletic: Otros 172 bytes de lo mismo (Athletic Land
;   0x6FF9, +1027): los tiles de los cerros y las mesetas, aqui muertos
;   0x6bf6..0x6ca2  (172 bytes)
DATA_resto_cerros_de_athletic:
	defb 0abh,002h,0a8h,0a8h,002h,0a9h,090h,090h,09ah,002h,0a8h,0a9h,09fh,092h,0a8h,0ach	; 6bf6  ................
	defb 0a9h,091h,090h,000h,094h,095h,096h,097h,098h,099h,09ch,09dh,09eh,0a2h,0a0h,0a1h	; 6c06  ................
	defb 0a3h,0a4h,004h,004h,0a5h,0a6h,020h,004h,021h,000h,022h,004h,023h,000h,024h,004h	; 6c16  ...... .!.".#.$.
	defb 025h,000h,026h,004h,027h,000h,028h,004h,029h,000h,000h,02ah,004h,02bh,000h,02ch	; 6c26  %.&.'.(.)..*.+.,
	defb 004h,02dh,00bh,02eh,02eh,02eh,0abh,0a8h,0a8h,002h,090h,090h,0aah,002h,0aah,0a8h	; 6c36  .-..............
	defb 002h,093h,091h,0aah,0ach,0ach,0a7h,09bh,000h,000h,090h,0abh,002h,0a8h,002h,0a9h	; 6c46  ................
	defb 090h,002h,0a8h,0a9h,092h,0ach,0ach,0a9h,091h,000h,000h,002h,093h,094h,095h,096h	; 6c56  ................
	defb 098h,099h,09ah,0a7h,09bh,09ch,09dh,0a2h,0a0h,0a1h,09fh,090h,000h,0a3h,0a4h,004h	; 6c66  ................
	defb 0a5h,0a6h,000h,020h,021h,000h,022h,023h,000h,024h,025h,000h,026h,027h,000h,028h	; 6c76  ... !."#.$%.&'.(
	defb 029h,000h,000h,02ah,02bh,000h,02ch,02dh,00bh,02eh,02eh,0abh,0a8h,0a8h,002h,090h	; 6c86  )..*+.,-........
	defb 090h,0aah,002h,0aah,0a8h,002h,091h,0aah,0ach,0ach,000h,000h	; 6c96  ............

; ======================================================================
; CODIGO 0x6ca2..0x6dd3  (305 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; LOS PATRONES Y COLORES DEL JUEGO. Los patrones van a la VRAM 0x2000
; por trozos (y once tiles se repiten cuatro veces en 0x60-0x8B para
; tener el mismo dibujo con cuatro colores). Los COLORES los escribe el
; propio motor de rotulos en la tabla de colores (0x0000): las listas
; que descomprimen los RLE de 0x6DD3 en adelante son colores, no tiles. Los de 0x60-0x75 se copian tal cual a
; 0x0300 y, cambiando el negro por verde claro, a 0x03B0 (0x76-0x8B).
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
CARGA_PATRONES_Y_COLORES:		; Patrones a 0x2000 y colores a 0x0000, estos ultimos por el motor de rotulos
	ld hl,06eddh		;6ca2   ; Los 256 bytes de 0x6EDD: 32 tiles, del 0x10 al 0x2F del primer tercio
	ld de,02080h		;6ca5
	ld bc,00100h		;6ca8
	call COPIA_A_VRAM		;6cab
	ld hl,06fddh		;6cae   ; 160 bytes: los veinte tiles 0x60-0x73
	ld de,02300h		;6cb1
	ld bc,000a0h		;6cb4
	call COPIA_A_VRAM		;6cb7
	ld hl,06fddh		;6cba   ; Y los seis siguientes (0x74-0x79) son esos mismos con los bits al reves: el dibujo espejado
	ld de,023a0h		;6cbd
	ld b,030h		;6cc0
	call COPIA_ESPEJADA		;6cc2
	ld hl,0707dh		;6cc5   ; 192 bytes: los veinticuatro tiles 0xC0-0xD7
	ld de,02600h		;6cc8
	ld bc,000c0h		;6ccb
	call COPIA_A_VRAM		;6cce
	ld hl,070a5h		;6cd1   ; El ld bc deja B a cero, y el bucle de 0x6DC1 cuenta con B: son 256 bytes espejados, no 24, o sea los tiles 0xD8-0xF7
	ld de,026c0h		;6cd4
	ld bc,00018h		;6cd7
	call COPIA_ESPEJADA		;6cda
	ld hl,0713dh		;6cdd   ; 64 bytes tal cual encima de ellos: los ocho tiles 0xE0-0xE7
	ld de,02700h		;6ce0
	ld bc,00040h		;6ce3
	call COPIA_A_VRAM		;6ce6
	ld hl,0713dh		;6ce9   ; Y otros seis espejados detras, 0xE8-0xED: del bloque espejado de antes solo se quedan a la vista los extremos
	ld de,02740h		;6cec
	ld b,030h		;6cef
	call COPIA_ESPEJADA		;6cf1
	ld hl,06dd3h		;6cf4   ; Y a partir de aqui, los COLORES: cada flujo trae su direccion de la tabla de colores (0x0000)
	call RLE_A_VRAM		;6cf7
	ld hl,06e6bh		;6cfa
	call RLE_A_VRAM		;6cfd
	ld hl,06e6dh		;6d00
	ld de,003a0h		;6d03
	call RLE_A_VRAM_DE		;6d06   ; Este y los dos siguientes van sin cabecera, con la direccion puesta a mano
	ld hl,06e88h		;6d09
	call RLE_A_VRAM		;6d0c
	ld hl,06e9ah		;6d0f
	ld de,006c0h		;6d12
	call RLE_A_VRAM_DE		;6d15
	ld hl,06ec0h		;6d18
	call RLE_A_VRAM		;6d1b
	ld hl,06ec2h		;6d1e
	ld de,00740h		;6d21
	call RLE_A_VRAM_DE		;6d24   ; Colores desde el tile 1
	call TRIPLICA_TODO		;6d27   ; Colores desde el tile 0x20
	ld hl,04e07h		;6d2a   ; Los colores de los tiles 0x60-0x75, tal cual
	ld de,02b00h		;6d2d
	ld bc,000f0h		;6d30
	call COPIA_A_VRAM		;6d33
	ld hl,04e07h		;6d36   ; ...y otra vez espejados para 0x76-0x8B
	ld de,02bf0h		;6d39
	ld b,0f0h		;6d3c
	call COPIA_ESPEJADA		;6d3e
	ld hl,04ddfh		;6d41
	ld de,02580h		;6d44
	ld bc,00038h		;6d47
	call COPIA_A_VRAM		;6d4a
	ld hl,04ddfh		;6d4d
	ld de,025b8h		;6d50
	ld b,030h		;6d53
	call COPIA_ESPEJADA		;6d55
	ld hl,04ef7h		;6d58
	ld de,02d10h		;6d5b
	ld bc,000f0h		;6d5e
	call COPIA_A_VRAM		;6d61
	ld hl,04fe7h		;6d64
	ld de,02e00h		;6d67
	ld bc,00088h		;6d6a
	call COPIA_A_VRAM		;6d6d
	ld hl,04fe7h		;6d70
	ld de,02e88h		;6d73
	ld b,050h		;6d76
	call COPIA_ESPEJADA		;6d78
	ld de,00b00h		;6d7b
	ld a,0f5h		;6d7e
	ld bc,001e0h		;6d80
	call RELLENA_VRAM		;6d83
	ld a,0f5h		;6d86
	ld de,00580h		;6d88
	ld bc,00068h		;6d8b
	call RELLENA_VRAM		;6d8e
	ld hl,0506fh		;6d91
	ld de,00d10h		;6d94
	ld bc,00058h		;6d97
	call COPIA_A_VRAM		;6d9a
	ld de,00d68h		;6d9d
	ld bc,00098h		;6da0
	ld a,0f5h		;6da3
	call RELLENA_VRAM		;6da5
	ld hl,050c7h		;6da8
	ld de,00e00h		;6dab
	ld bc,00088h		;6dae
	call COPIA_A_VRAM		;6db1
	ld hl,050c7h		;6db4
	ld de,00e88h		;6db7
	ld bc,00050h		;6dba
	call COPIA_A_VRAM		;6dbd
	ret			;6dc0
COPIA_ESPEJADA:		; B bytes de HL a la VRAM DE, cada uno con sus ocho bits al reves
	push bc			;6dc1   ; B se guarda porque el bucle de dentro lo gasta
	ld b,008h		;6dc2
	ld c,(hl)			;6dc4   ; El byte sale por un lado de C y entra por el otro en A: eso lo da la vuelta
OCHO_BITS_AL_REVES:		; Los ocho bits, uno a uno
	rl c		;6dc5   ; Sale por un lado y entra por el otro
	rra			;6dc7
	djnz OCHO_BITS_AL_REVES		;6dc8
	call VPOKE		;6dca
	inc hl			;6dcd
	inc de			;6dce
	pop bc			;6dcf
	djnz COPIA_ESPEJADA		;6dd0
	ret			;6dd2

; ----------------------------------------------------------------------
; DATOS rle_6DD3: flujo RLE (0x6CF7 lo descomprime en 256 bytes de VRAM)
;   0x6dd3..0x6e6b  (152 bytes)
DATA_rle_6DD3:
	defb 080h,000h,008h,025h,008h,03ch,088h,0eeh,0eeh,0ffh,061h,061h,064h,064h,064h,004h	; 6dd3  ...%.<....aaddd.
	defb 04eh,086h,06fh,06fh,06fh,061h,050h,050h,005h,05bh,083h,050h,050h,050h,005h,05bh	; 6de3  N.oooaPP.[.PPP.[
	defb 083h,050h,050h,050h,005h,05bh,081h,050h,008h,0b0h,008h,050h,012h,0e6h,005h,036h	; 6df3  .PPP.[.P...P...6
	defb 081h,03eh,007h,069h,081h,036h,008h,06eh,08ah,0f6h,0f6h,0f6h,0f1h,065h,065h,065h	; 6e03  .>.i.6.n.....eee
	defb 0f5h,095h,095h,005h,0d9h,083h,095h,0b5h,0b5h,005h,08bh,083h,0b5h,075h,075h,005h	; 6e13  .............uu.
	defb 0d7h,083h,075h,097h,097h,005h,0d9h,081h,097h,008h,0f5h,008h,0a5h,008h,085h,008h	; 6e23  ..u.............
	defb 0f7h,008h,052h,008h,072h,084h,0f5h,0f5h,0f5h,0f2h,004h,052h,084h,0a5h,0a5h,0a5h	; 6e33  ..R.r......R....
	defb 0a2h,004h,052h,004h,085h,004h,052h,084h,0f7h,0f7h,0f7h,0f2h,004h,072h,098h,0e0h	; 6e43  ..R...R......r..
	defb 0e0h,0f0h,011h,0f6h,0f6h,0f6h,011h,0f6h,0f6h,0f6h,0f1h,0f6h,0f6h,0f6h,051h,0f6h	; 6e53  ..............Q.
	defb 0f6h,0f6h,0f1h,065h,065h,065h,0f5h,000h	; 6e63  ...eee..

; ----------------------------------------------------------------------
; DATOS rle_6E6B: flujo RLE (0x6D06 lo descomprime en 160 bytes de VRAM); los
;   dos primeros bytes son la VRAM de destino, que lee 0x4D24
;   0x6e6b..0x6e88  (29 bytes)
DATA_rle_6E6B:
	defb 000h,003h,020h,072h,010h,053h,008h,0f7h,018h,072h,010h,0c2h,018h,032h,008h,0c3h	; 6e6b  .. r.S...r...2..
	defb 008h,032h,008h,023h,005h,038h,083h,0a0h,0a0h,0a0h,008h,045h,000h	; 6e7b  .2.#.8.....E.

; ----------------------------------------------------------------------
; DATOS rle_6E88: flujo RLE (0x6D0C lo descomprime en 192 bytes de VRAM)
;   0x6e88..0x6e9a  (18 bytes)
DATA_rle_6E88:
	defb 000h,006h,008h,0ceh,081h,017h,00fh,047h,007h,0feh,081h,0f1h,005h,0feh,083h,0f1h	; 6e88  .......G........
	defb 0f1h,0f4h	; 6e98

; ----------------------------------------------------------------------
; DATOS rle_6E9A: flujo RLE (0x6D15 lo descomprime en 152 bytes de VRAM)
;   0x6e9a..0x6ec0  (38 bytes)
DATA_rle_6E9A:
	defb 084h,0e1h,0e1h,0e1h,014h,004h,0e4h,006h,0fbh,009h,0f9h,081h,0feh,018h,0e4h,017h	; 6e9a  ................
	defb 0e1h,081h,0e4h,010h,014h,014h,0e8h,004h,0e0h,004h,0e8h,004h,0e0h,014h,0e8h,004h	; 6eaa  ................
	defb 0e0h,004h,0e8h,004h,0e0h,000h	; 6eba

; ----------------------------------------------------------------------
; DATOS rle_6EC0: flujo RLE (0x6D24 lo descomprime en 64 bytes de VRAM); los
;   dos primeros bytes son la VRAM de destino, que lee 0x4D24
;   0x6ec0..0x6edd  (29 bytes)
DATA_rle_6EC0:
	defb 000h,007h,004h,0b5h,006h,0b6h,014h,086h,091h,0e6h,0e6h,0e5h,0e5h,0e5h,0f5h,0e5h	; 6ec0  ................
	defb 0e5h,0e5h,0f5h,076h,076h,076h,071h,076h,076h,076h,011h,075h,000h	; 6ed0  ...vvvqvvv.u.

; ----------------------------------------------------------------------
; DATOS copia_6EDD: 256 bytes que 0x6CAB copia a la VRAM 0x2080
;   0x6edd..0x6fdd  (256 bytes)
DATA_copia_6EDD:
	defb 040h,024h,032h,09ah,05bh,05fh,07eh,0ffh,040h,024h,032h,09ah,05bh,05fh,07eh,0ffh	; 6edd  @$2.[_~.@$2.[_~.
	defb 0ffh,0ffh,0ffh,000h,000h,000h,000h,000h,0ffh,0ffh,0ffh,000h,0efh,0efh,0efh,000h	; 6eed  ................
	defb 000h,000h,0c0h,0c0h,0c0h,0c0h,0c0h,000h,000h,000h,0f0h,0f0h,0f0h,0f0h,0f0h,000h	; 6efd  ................
	defb 000h,000h,0fch,0fch,0fch,0fch,0fch,000h,000h,000h,0ffh,0ffh,0ffh,0ffh,0ffh,000h	; 6f0d  ................
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,0ffh,000h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0f8h,0e0h	; 6f1d  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,03fh,080h,0c0h,0c0h,080h,089h,0a9h,0fbh,0ffh,07fh	; 6f2d  ......?.........
	defb 038h,030h,060h,0e0h,0c8h,068h,0f3h,080h,080h,0c0h,0c0h,0e0h,0f0h,0f0h,0f0h,0e0h	; 6f3d  80`..h..........
	defb 001h,001h,001h,00fh,0f0h,0f0h,0f0h,0f0h,03ch,07eh,018h,03ch,024h,03ch,018h,03ch	; 6f4d  ........<~.<$<.<
	defb 03ch,07eh,018h,03ch,024h,03ch,018h,03ch,03ch,07eh,018h,03ch,024h,03ch,018h,03ch	; 6f5d  <~.<$<.<<~.<$<.<
	defb 03ch,07eh,018h,03ch,024h,03ch,018h,03ch,000h,000h,000h,000h,000h,00ch,03eh,077h	; 6f6d  <~.<$<.<......>w
	defb 000h,000h,000h,000h,000h,00ch,03eh,077h,000h,000h,000h,000h,000h,00ch,03eh,077h	; 6f7d  ......>w......>w
	defb 000h,000h,000h,000h,000h,00ch,03eh,077h,0efh,0e5h,075h,031h,097h,086h,0c4h,0a0h	; 6f8d  ......>w..u1....
	defb 0efh,0e5h,075h,031h,097h,086h,0c4h,0a0h,063h,077h,03eh,01ch,0c1h,0a3h,0c4h,0e1h	; 6f9d  ..u1....cw>.....
	defb 063h,077h,03eh,01ch,0c1h,0a3h,0c4h,0e1h,063h,077h,03eh,01ch,0c1h,0a3h,0c4h,0e1h	; 6fad  cw>.....cw>.....
	defb 063h,077h,03eh,01ch,0c1h,0a3h,0c4h,0e1h,0ffh,0ffh,0ffh,0ffh,010h,010h,010h,0ffh	; 6fbd  cw>.............
	defb 001h,001h,001h,000h,010h,010h,010h,000h,080h,080h,080h,0f0h,00fh,00fh,00fh,00fh	; 6fcd  ................

; ----------------------------------------------------------------------
; DATOS copia_6FDD: 160 bytes que 0x6CB7 copia a la VRAM 0x2300
;   0x6fdd..0x707d  (160 bytes)
DATA_copia_6FDD:
	defb 0ffh,0ffh,0ffh,0ffh,0feh,0f8h,0f0h,0c0h,0ffh,00fh,000h,000h,000h,000h,000h,000h	; 6fdd  ................
	defb 0ffh,0ffh,00fh,003h,000h,000h,000h,000h,0ffh,0ffh,0ffh,0ffh,0ffh,03fh,00fh,000h	; 6fed  .............?..
	defb 000h,000h,000h,001h,007h,01fh,03fh,07fh,000h,01fh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 6ffd  ......?.........
	defb 000h,000h,038h,07eh,0ffh,0ffh,0ffh,03eh,0ffh,0ffh,0ffh,00fh,000h,000h,000h,000h	; 700d  ..8~...>........
	defb 0ffh,0ffh,0ffh,000h,000h,000h,000h,000h,0ffh,000h,000h,000h,000h,000h,000h,000h	; 701d  ................
	defb 070h,0f8h,0f8h,0f8h,0f8h,0f8h,070h,020h,000h,000h,000h,000h,020h,020h,070h,070h	; 702d  p.....p ....  pp
	defb 000h,000h,000h,000h,000h,000h,00fh,0ffh,000h,000h,000h,000h,00fh,0ffh,0ffh,0ffh	; 703d  ................
	defb 000h,000h,000h,0ffh,0ffh,0ffh,0ffh,0ffh,070h,0f8h,0f8h,0f8h,0f8h,0f8h,070h,020h	; 704d  ........p.....p 
	defb 00fh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,000h,000h,000h,000h,000h,000h	; 705d  ................
	defb 0ffh,0fdh,0c5h,081h,000h,0ffh,0a9h,0f9h,020h,070h,070h,0f8h,070h,070h,020h,020h	; 706d  ........ pp.pp  

; ----------------------------------------------------------------------
; DATOS copia_707D: 192 bytes que 0x6CCE copia a la VRAM 0x2600
;   0x707d..0x713d  (192 bytes)
DATA_copia_707D:
	defb 040h,024h,032h,09ah,05bh,05fh,07eh,0ffh,0c3h,0c3h,0c3h,0c3h,0ffh,0ffh,0ffh,0ffh	; 707d  @$2.[_~.........
	defb 0c3h,0c3h,0c3h,0c3h,0ffh,0ffh,0ffh,0ffh,018h,018h,018h,018h,018h,018h,018h,018h	; 708d  ................
	defb 018h,018h,018h,018h,018h,018h,018h,018h,0ffh,0f0h,080h,0c0h,000h,080h,0f0h,0ffh	; 709d  ................
	defb 03fh,070h,0c0h,080h,0c0h,070h,09fh,0c0h,070h,09fh,0c0h,070h,09fh,0c0h,070h,01fh	; 70ad  ?p...p..p..p..p.
	defb 000h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,000h,000h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 70bd  ................
	defb 000h,000h,000h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,000h	; 70cd  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,000h,000h,0ffh,0ffh,0ffh,0ffh,0ffh,000h,000h,000h	; 70dd  ................
	defb 0ffh,0ffh,000h,000h,000h,000h,000h,000h,0ffh,000h,000h,000h,000h,000h,000h,000h	; 70ed  ................
	defb 0ffh,0fbh,0eeh,0a4h,0c0h,0c8h,0c8h,0ceh,0ffh,0fbh,0b7h,097h,00bh,017h,013h,073h	; 70fd  ...............s
	defb 0c0h,0c1h,0e2h,0f8h,0f0h,0c0h,01ah,0f6h,003h,083h,047h,01fh,00fh,003h,058h,06fh	; 710d  ..........G...Xo
	defb 0eeh,0e4h,0e0h,0e0h,0c4h,0c6h,0c2h,0c0h,0efh,0cfh,04fh,007h,027h,063h,043h,003h	; 711d  ..........O.'cC.
	defb 0c1h,0e2h,0f0h,0f8h,0f0h,0c0h,01ah,0f6h,083h,047h,00fh,01fh,00fh,003h,058h,06fh	; 712d  .........G....Xo

; ----------------------------------------------------------------------
; DATOS copia_713D: 64 bytes que 0x6CE6 copia a la VRAM 0x2700
;   0x713d..0x717d  (64 bytes)
DATA_copia_713D:
	defb 000h,000h,000h,07fh,0e0h,0deh,0d8h,0eeh,070h,01fh,000h,012h,012h,01bh,01bh,01bh	; 713d  ........p.......
	defb 01fh,01fh,01fh,01fh,01fh,01fh,01fh,01fh,017h,017h,017h,017h,017h,003h,080h,0e0h	; 714d  ................
	defb 0e0h,0e0h,0e0h,0e0h,0e0h,0e0h,0e0h,0e0h,000h,001h,003h,007h,00fh,01fh,03fh,000h	; 715d  ..............?.
	defb 0e7h,0e7h,0e7h,0e7h,0e7h,0e7h,0e7h,000h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,000h	; 716d  ................

; ----------------------------------------------------------------------
; DATOS rle_decorado_1: El primero de los seis flujos de la tabla de 0x55F5:
;   76 bytes que rinden 96 de VRAM (doce tiles)
;   0x717d..0x71c9  (76 bytes)
DATA_rle_decorado_1:
	defb 006h,000h,08ah,001h,003h,003h,007h,007h,007h,00fh,00fh,007h,001h,006h,000h,096h	; 717d  ................
	defb 0f8h,0fch,0fch,0feh,0ffh,0ffh,0ffh,0feh,0fch,0e0h,000h,000h,080h,0bfh,0ffh,0ffh	; 718d  ................
	defb 0f0h,0e2h,0e0h,0c1h,0d4h,0c3h,003h,080h,08dh,000h,000h,038h,07eh,0dfh,0efh,0f7h	; 719d  ...........8~...
	defb 037h,09bh,01ah,00ch,054h,084h,004h,000h,090h,000h,00eh,01fh,03fh,07fh,07eh,0feh	; 71ad  7...T.......?.~.
	defb 0fdh,0fdh,0fbh,0fbh,0fbh,0fbh,079h,079h,030h,010h,000h,000h	; 71bd  ......yy0...

; ----------------------------------------------------------------------
; DATOS rle_decorado_2: El segundo: 74 bytes, otros 96 de VRAM
;   0x71c9..0x7213  (74 bytes)
DATA_rle_decorado_2:
	defb 006h,000h,08ah,003h,007h,00fh,00fh,01fh,01fh,01fh,00fh,007h,001h,006h,000h,08ch	; 71c9  ................
	defb 0f8h,0fch,0feh,0feh,0ffh,0ffh,0ffh,0feh,0fch,0e0h,000h,01dh,004h,0ffh,09ah,0e0h	; 71d9  ................
	defb 0c2h,080h,081h,014h,003h,000h,080h,0c0h,070h,000h,0c0h,0f0h,0f8h,0fch,0feh,03eh	; 71e9  ........p......>
	defb 09fh,00fh,00fh,057h,086h,004h,00ch,018h,0e0h,003h,000h,084h,003h,007h,00fh,00fh	; 71f9  ...W............
	defb 004h,01fh,084h,00fh,00fh,007h,001h,011h,000h,000h	; 7209  ..........

; ----------------------------------------------------------------------
; DATOS rle_decorado_3: El tercero: 75 bytes, otros 96 de VRAM
;   0x7213..0x725e  (75 bytes)
DATA_rle_decorado_3:
	defb 007h,000h,089h,003h,007h,007h,00fh,00fh,00fh,007h,003h,001h,006h,000h,08dh,0f0h	; 7213  ................
	defb 0fch,0fch,0feh,0ffh,0ffh,0ffh,0feh,0fch,0e0h,000h,000h,03fh,003h,0ffh,089h,0f8h	; 7223  ...........?....
	defb 0e2h,0c0h,0c1h,094h,083h,080h,0c0h,060h,003h,000h,08ah,080h,0f0h,0f8h,0f8h,07ch	; 7233  .......`.......|
	defb 09ch,01eh,00eh,056h,084h,003h,007h,081h,00eh,003h,000h,084h,001h,003h,007h,007h	; 7243  ...V............
	defb 004h,00fh,085h,05fh,0f7h,0f0h,0f0h,07ch,010h,000h,000h	; 7253  ..._...|...

; ----------------------------------------------------------------------
; DATOS rle_decorado_4: El cuarto: 81 bytes, otros 96 de VRAM
;   0x725e..0x72af  (81 bytes)
DATA_rle_decorado_4:
	defb 0bch,000h,000h,004h,0cch,0ech,038h,000h,003h,007h,007h,00fh,00fh,00fh,007h,003h	; 725e  ......8.........
	defb 001h,000h,022h,036h,02ah,000h,000h,0f0h,0fch,0fch,0feh,0ffh,0ffh,0ffh,0feh,0fch	; 726e  .."6*...........
	defb 0e0h,000h,000h,080h,09eh,09fh,03fh,0f8h,0e2h,0c0h,0c1h,094h,083h,080h,0c0h,0e0h	; 727e  ......?.........
	defb 000h,000h,028h,04eh,08fh,0ebh,0f7h,073h,09ah,01ah,00ch,054h,084h,005h,000h,087h	; 728e  ..(N...s...T....
	defb 007h,00fh,019h,038h,03eh,07fh,07fh,004h,0fbh,084h,0f9h,0fdh,0ach,054h,010h,000h	; 729e  ...8>........T..
	defb 000h	; 72ae

; ----------------------------------------------------------------------
; DATOS rle_decorado_5: El quinto: 66 bytes, otros 96 de VRAM
;   0x72af..0x72f1  (66 bytes)
DATA_rle_decorado_5:
	defb 089h,00fh,03fh,07fh,0ffh,000h,000h,003h,007h,00fh,006h,01fh,091h,003h,0c0h,0f0h	; 72af  ..?.............
	defb 0f8h,0ffh,000h,0f0h,0f8h,0fch,0feh,0feh,0feh,0feh,0fch,0fch,0f8h,0c0h,004h,000h	; 72bf  ................
	defb 088h,0ffh,0f8h,0e0h,0c2h,080h,001h,004h,003h,008h,000h,088h,0e0h,070h,038h,098h	; 72cf  .............p8.
	defb 008h,008h,048h,080h,008h,000h,081h,007h,006h,00fh,084h,007h,007h,003h,001h,011h	; 72df  ..H.............
	defb 000h,000h	; 72ef

; ----------------------------------------------------------------------
; DATOS rle_decorado_6: El sexto: 81 bytes, otros 96 de VRAM, y acaba justo
;   donde empieza el flujo de 0x7342
;   0x72f1..0x7342  (81 bytes)
DATA_rle_decorado_6:
	defb 08ah,000h,003h,007h,00ch,000h,080h,0c1h,047h,03fh,03fh,004h,01fh,09eh,00fh,003h	; 72f1  ........G??.....
	defb 000h,0c0h,0e0h,010h,000h,063h,0fah,0fch,0fch,0feh,0feh,0feh,0feh,0fch,0f8h,0c0h	; 7301  .....c..........
	defb 000h,000h,0c0h,09fh,0ffh,0fch,0f0h,0c2h,000h,001h,004h,003h,005h,000h,09ah,0e0h	; 7311  ................
	defb 0f0h,078h,0f8h,0e0h,02ch,09ch,01ch,00eh,04fh,08fh,00fh,01fh,01fh,01eh,000h,003h	; 7321  .x..,...O.......
	defb 007h,00fh,00fh,00bh,001h,00dh,01eh,01eh,01fh,003h,03fh,082h,03eh,03ch,010h,000h	; 7331  ..........?.><..
	defb 000h	; 7341

; ----------------------------------------------------------------------
; DATOS rle_7342: flujo RLE (0x7724 lo descomprime en 64 bytes de VRAM)
;   0x7342..0x7367  (37 bytes)
DATA_rle_7342:
	defb 005h,000h,003h,007h,018h,000h,081h,007h,004h,00fh,085h,008h,018h,018h,01fh,007h	; 7342  ................
	defb 004h,003h,085h,007h,007h,0c0h,0e0h,0e0h,003h,0f0h,003h,0f8h,081h,0e0h,003h,080h	; 7352  ................
	defb 083h,0c0h,0e0h,0f0h,000h	; 7362

; ----------------------------------------------------------------------
; DATOS rle_del_decorado_a: Flujo RLE de 270 bytes que rinde 576 de VRAM.
;   0x55C8 lo mete en DE, lo empuja, y tras el primer descompresor lo recupera
;   con `pop de / ex de,hl` para 0x55E1: por eso ningun `ld hl` apunta aqui
;   0x7367..0x7475  (270 bytes)
DATA_rle_del_decorado_a:
	defb 005h,000h,083h,040h,0c0h,0c0h,00dh,000h,003h,007h,008h,000h,084h,007h,00fh,01fh	; 7367  ...@............
	defb 01fh,005h,03fh,097h,01fh,04fh,0feh,0feh,0f8h,060h,070h,0c0h,0e0h,0f0h,0f8h,0feh	; 7377  ..?..O...`p.....
	defb 0f8h,0f8h,0f8h,0fch,0fch,0f8h,0fdh,03fh,01fh,01eh,00ch,015h,000h,003h,0e0h,008h	; 7387  .......?........
	defb 000h,081h,007h,005h,00fh,003h,01fh,097h,007h,017h,03fh,03fh,03bh,033h,003h,0c0h	; 7397  ..........??;3..
	defb 0e0h,0e0h,0f0h,0f0h,010h,018h,018h,0f8h,0c0h,0e0h,0e0h,080h,0c0h,0e0h,0f0h,005h	; 73a7  ................
	defb 000h,003h,0e0h,00dh,000h,083h,001h,003h,003h,008h,000h,096h,00fh,01fh,03fh,07fh	; 73b7  ..............?.
	defb 07fh,03fh,01fh,01fh,03fh,01fh,04fh,0feh,0feh,0f8h,060h,070h,0e0h,0f0h,0f8h,0fch	; 73c7  .?..?.O...`p....
	defb 0feh,0feh,004h,0fch,089h,0f8h,0fdh,03fh,01fh,01eh,00ch,000h,000h,0c0h,003h,0e0h	; 73d7  .......?........
	defb 00ah,000h,084h,00eh,00eh,006h,006h,00ch,000h,083h,01fh,07fh,03fh,003h,01fh,098h	; 73e7  ............?...
	defb 03fh,01fh,03fh,0ffh,0fch,0f8h,0c0h,080h,000h,000h,080h,0c0h,0f8h,0f8h,0fch,0fch	; 73f7  ?.?.............
	defb 0f0h,0f9h,0ffh,0ffh,03fh,00fh,00eh,006h,012h,000h,083h,038h,038h,018h,00dh,000h	; 7407  ....?......88...
	defb 085h,01fh,03fh,03fh,07fh,07fh,006h,0ffh,082h,03fh,01eh,004h,000h,08dh,080h,0e0h	; 7417  ..??.....?......
	defb 0f0h,0e0h,0c0h,081h,0e3h,0f7h,0ffh,0ffh,01fh,00eh,006h,055h,000h,081h,001h,004h	; 7427  ...........U....
	defb 005h,008h,000h,084h,00fh,01fh,03fh,03fh,004h,07fh,081h,03fh,007h,000h,086h,080h	; 7437  ......??...?....
	defb 0c0h,0c0h,0e2h,0f2h,0f2h,003h,0fah,007h,000h,083h,0fch,0fch,01ch,00dh,000h,083h	; 7447  ................
	defb 0f8h,0f8h,0e0h,018h,000h,082h,001h,001h,00dh,000h,084h,088h,0fch,0fch,0d8h,024h	; 7457  ...............$
	defb 000h,085h,00fh,07fh,0ffh,07fh,00fh,00ah,000h,007h,0ffh,008h,000h,000h	; 7467  ..............

; ----------------------------------------------------------------------
; DATOS rle_7475: flujo RLE (0x55D9 lo descomprime en 64 bytes de VRAM)
;   0x7475..0x74b7  (66 bytes)
DATA_rle_7475:
	defb 0c0h,000h,001h,003h,003h,003h,003h,003h,003h,000h,000h,007h,003h,003h,000h,000h	; 7475  ................
	defb 000h,000h,000h,080h,080h,080h,080h,080h,080h,000h,000h,0c0h,080h,080h,000h,000h	; 7485  ................
	defb 000h,007h,00eh,00ch,01ch,01ch,03ch,03ch,07ch,07fh,01fh,000h,000h,000h,003h,007h	; 7495  ......<<|.......
	defb 007h,0c0h,0e0h,060h,070h,070h,078h,078h,07ch,0fch,0f0h,000h,000h,000h,0c0h,0e0h	; 74a5  ...`ppxx|.......
	defb 0f0h,000h	; 74b5

; ----------------------------------------------------------------------
; DATOS rle_del_decorado_b: El otro, de 568 bytes y otros 576 de VRAM, con el
;   mismo apano en 0x55D2. Es la variante que se pinta con el bit 4 de E05C
;   puesto
;   0x74b7..0x76ef  (568 bytes)
DATA_rle_del_decorado_b:
	defb 0c0h,000h,000h,010h,030h,060h,0c0h,0c0h,000h,000h,000h,00fh,03eh,03eh,018h,000h	; 74b7  ....0`......>>..
	defb 000h,040h,0e0h,070h,078h,03eh,01eh,00eh,000h,000h,000h,0f8h,0fch,038h,010h,000h	; 74c7  .@.px>.......8..
	defb 000h,007h,00fh,00fh,00fh,01fh,03fh,03fh,07fh,07fh,01fh,040h,0c0h,0c0h,0e0h,060h	; 74d7  ......??...@...`
	defb 070h,080h,000h,080h,080h,0c0h,0e0h,0f0h,0fch,0fch,0f8h,000h,001h,007h,00fh,01eh	; 74e7  p...............
	defb 00ch,0c0h,000h,007h,007h,007h,003h,003h,001h,001h,000h,000h,003h,003h,003h,000h	; 74f7  ................
	defb 000h,000h,000h,000h,000h,080h,080h,0c0h,0c0h,0c0h,000h,000h,0c0h,0c0h,080h,000h	; 7507  ................
	defb 000h,000h,007h,008h,008h,018h,01ch,03ch,03eh,07eh,07fh,01fh,004h,03ch,03ch,03bh	; 7517  .......<>~...<<;
	defb 033h,003h,0c0h,0e0h,0e0h,070h,070h,038h,038h,03ch,0fch,0f8h,000h,000h,000h,0c0h	; 7527  3....pp88<......
	defb 0e0h,0f0h,0c0h,008h,01ch,038h,078h,070h,0f0h,0e0h,0e0h,000h,000h,00fh,03eh,03eh	; 7537  .....8xp......>>
	defb 018h,000h,000h,000h,000h,008h,004h,006h,003h,003h,001h,000h,000h,0f8h,0fch,038h	; 7547  ...............8
	defb 000h,000h,000h,007h,003h,007h,007h,00fh,00fh,01fh,01fh,07fh,01fh,040h,0c0h,0c0h	; 7557  .............@..
	defb 0e0h,060h,070h,0e0h,0f0h,0f0h,0f8h,0f8h,0fch,0fch,0feh,0feh,0f8h,000h,001h,007h	; 7567  .`p.............
	defb 01fh,01eh,00ch,0c0h,018h,078h,0f8h,0f0h,0e0h,0e0h,000h,000h,018h,01eh,01ch,000h	; 7577  .....x..........
	defb 000h,000h,000h,000h,00ch,01eh,01eh,01ch,008h,000h,000h,000h,018h,038h,030h,010h	; 7587  .............80.
	defb 000h,000h,000h,000h,007h,007h,007h,00fh,01fh,01fh,07fh,03fh,0e7h,0e1h,0e0h,0e0h	; 7597  ...........?....
	defb 0c0h,080h,000h,000h,080h,0c0h,0e0h,0e0h,0f0h,0f8h,0f8h,0f1h,0e7h,0c7h,00fh,00eh	; 75a7  ................
	defb 01eh,00ch,000h,000h,0c0h,000h,006h,00fh,00fh,007h,001h,000h,000h,001h,003h,003h	; 75b7  ................
	defb 007h,000h,000h,000h,000h,038h,038h,078h,0f0h,0e0h,0c0h,000h,0e0h,0f0h,0f8h,0b8h	; 75c7  .....88x........
	defb 010h,000h,000h,000h,000h,01fh,039h,030h,070h,078h,0feh,0ffh,0ffh,0feh,0fch,07ch	; 75d7  ......90px.....|
	defb 078h,030h,000h,000h,000h,000h,080h,080h,000h,000h,000h,081h,003h,007h,007h,007h	; 75e7  x0..............
	defb 00fh,00eh,006h,000h,000h,0c0h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 75f7  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 7607  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 7617  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 7627  ................
	defb 000h,000h,000h,000h,000h,000h,0c0h,000h,000h,000h,000h,000h,000h,000h,000h,003h	; 7637  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,00ah,00ah,01ah,03ah,0fah,0fah	; 7647  .............:..
	defb 000h,000h,000h,000h,000h,000h,000h,00fh,01fh,01fh,03fh,03fh,07fh,07fh,0ffh,0fch	; 7657  ..........??....
	defb 000h,000h,000h,000h,000h,000h,000h,080h,0c0h,0c0h,0e5h,0e5h,0e5h,0c5h,005h,005h	; 7667  ................
	defb 000h,000h,000h,000h,000h,000h,000h,0c0h,0fch,0fch,01ch,000h,000h,000h,000h,000h	; 7677  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,0f8h,0f8h,0e0h,000h,000h,000h,000h,000h	; 7687  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 7697  ................
	defb 000h,000h,000h,001h,001h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 76a7  ................
	defb 000h,000h,088h,0fch,0fch,0d8h,000h,000h,0a0h,000h,000h,000h,000h,000h,000h,000h	; 76b7  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 76c7  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,087h,000h,000h,00fh,07fh,0ffh,07fh	; 76d7  ................
	defb 00fh,00ah,000h,007h,0ffh,008h,000h,000h	; 76e7  ........

; ======================================================================
; CODIGO 0x76ef..0x77b6  (199 bytes)
; ======================================================================


CARGA_LOS_SPRITES:		; Sube a la VRAM todos los patrones de sprite de la pantalla y deja sus atributos en E0C0
	ld de,032e0h		;76ef   ; Los 16 bytes de 0x7830, a la VRAM 0x32E0
	ld hl,07830h		;76f2
	ld bc,00010h		;76f5
	call COPIA_A_VRAM		;76f8
	ld de,05a00h		;76fb
	ld b,006h		;76fe   ; Seis flujos, uno por vuelta
L_7700:
	push bc			;7700
	push de			;7701
	ld hl,055f5h		;7702   ; La tabla de seis punteros; el indice es 6-B, o sea 0, 1, 2... por dos, que son palabras
	ld a,006h		;7705
	sub b			;7707
	rlca			;7708
	call HL_MAS_A		;7709
	ld e,(hl)			;770c
	inc hl			;770d
	ld d,(hl)			;770e
	ex de,hl			;770f
	pop de			;7710
	push de			;7711
	call RLE_A_VRAM_DE		;7712   ; Cada uno descomprime 96 bytes: doce sprites de 8 bytes
	pop de			;7715
	ld a,080h		;7716   ; Y el destino sube 0x80 en cada vuelta: los seis van seguidos desde la VRAM 0x1A00
	call DE_MAS_A		;7718
	pop bc			;771b
	djnz L_7700		;771c
	ld hl,07342h		;771e   ; Dos flujos mas, ya sin tabla, a 0x1E20 y 0x1E60
	ld de,01e20h		;7721
	call RLE_A_VRAM_DE		;7724
	ld hl,07475h		;7727
	ld de,01e60h		;772a
	call RLE_A_VRAM_DE		;772d
	ld hl,07840h		;7730
	call RLE_A_VRAM		;7733   ; Este trae su propia direccion de VRAM delante
	ld hl,07818h		;7736   ; Y los 20 bytes de atributos de cinco sprites, que se quedan en RAM (E0C0) hasta que el fotograma los suba
	ld de,0e0c0h		;7739
	ld bc,00014h		;773c
	ldir		;773f
PREPARA_EL_MARCADOR:		; Borra el aviso, pinta el rotulo del jugador si son dos, y rellena dos recuadros de la pantalla
	xor a			;7741   ; E214 a cero: el aviso empieza apagado
	ld (0e214h),a		;7742
	ld a,(0e002h)		;7745
	bit 5,a		;7748   ; Bit 5 de E002: dos jugadores
	jr z,L_7761		;774a
	ld hl,077b6h		;774c   ; El rotulo de 0x77B6 solo sale en partida de dos
	call PINTA_LISTA		;774f
	ld a,(0e002h)		;7752
	rlc a		;7755
	and 001h		;7757
	add a,031h		;7759   ; '1' o '2' segun el bit 7 de E002 (a quien le toca), en la fila 13
	ld de,039bch		;775b
	call VPOKE		;775e
L_7761:
	ld de,0394dh		;7761
	ld bc,00806h		;7764
RELLENA_RECUADRO_3:		; Ocho filas de seis con el tile 3, desde 0x394D (fila 10, columna 13)
	push bc			;7767
	ld a,003h		;7768
	ld b,000h		;776a
	call RELLENA_VRAM		;776c   ; Seis posiciones con el mismo tile; B a cero para que BC sea 6
	ld a,020h		;776f   ; Y a la fila de abajo: 32 casillas mas
	call DE_MAS_A		;7771
	pop bc			;7774
	djnz RELLENA_RECUADRO_3		;7775
	ld de,0396eh		;7777
	ld bc,00604h		;777a
RELLENA_RECUADRO_1:		; Seis filas de cuatro con el tile 1, desde 0x396E
	push bc			;777d
	ld a,001h		;777e
	ld b,000h		;7780
	call RELLENA_VRAM		;7782   ; Cuatro posiciones con el tile 1
	ld a,020h		;7785   ; Otra fila
	call DE_MAS_A		;7787
	pop bc			;778a
	djnz RELLENA_RECUADRO_1		;778b
	ld hl,077bfh		;778d
	jp PINTA_LISTA		;7790
PINTA_EL_CURSOR_DEL_NOMBRE:		; Los dos tiles del cursor de la pantalla del nombre y los sprites
	ld bc,05e5fh		;7793
	ld de,0398ah		;7796
	call PINTA_DOS_TILES		;7799
	jp COLOCA_Y_SUBE		;779c
PINTA_LA_PANTALLA_DEL_NOMBRE:		; El rotulo, el nombre escrito hasta ahora y el sprite del cursor
	ld hl,0780dh		;779f
	call PINTA_LISTA		;77a2
	call PINTA_EL_NOMBRE		;77a5
	ld hl,0782ch		;77a8   ; Los cuatro bytes del sprite del cursor
	ld de,0e0d4h		;77ab
	ld bc,00004h		;77ae
	ldir		;77b1
	jp SUBE_LOS_SPRITES		;77b3

; ----------------------------------------------------------------------
; DATOS rotulo_player: La lista del rotulo PLAYER, que 0x774F pinta solo en
;   partida de dos
;   0x77b6..0x77bf  (9 bytes)
DATA_77B6:
	defb 0b5h,039h,050h,04ch,041h,059h,045h,052h,0ffh	; 77b6  .9PLAYER.

; ----------------------------------------------------------------------
; DATOS rotulo_de_las_teclas: Lista de 66 tiles que 0x778D pinta con un `jp
;   PINTA_LISTA`: FORWARD, BACKWARD, CURSOR y SPACE, o sea las instrucciones
;   de la pantalla del nombre
;   0x77bf..0x780d  (78 bytes)
DATA_rotulo_de_las_teclas:
	defb 067h,03ah,05bh,03bh,05bh,000h,05ch,05dh,000h,040h,040h,000h,046h,04fh,052h,057h	; 77bf  g:[;[.\].@@.FORW
	defb 041h,052h,044h,0feh,087h,03ah,05bh,03ch,05bh,000h,05ch,05dh,000h,040h,040h,000h	; 77cf  ARD..:[<[.\].@@.
	defb 042h,041h,043h,04bh,057h,041h,052h,044h,0feh,0a7h,03ah,05bh,03dh,05bh,000h,05ch	; 77df  BACKWARD..:[=[.\
	defb 05dh,000h,040h,040h,000h,043h,055h,052h,053h,04fh,052h,0feh,0c5h,03ah,053h,050h	; 77ef  ].@@.CURSOR..:SP
	defb 041h,043h,045h,000h,05ch,05dh,000h,040h,040h,000h,045h,04eh,044h,0ffh	; 77ff  ACE.\].@@.END.

; ----------------------------------------------------------------------
; DATOS rotulo_name: La lista del rotulo NAME de la pantalla del nombre, que
;   pinta 0x77A2
;   0x780d..0x7818  (11 bytes)
DATA_rotulo_name:
	defb 063h,039h,040h,040h,04eh,041h,04dh,045h,040h,040h,0ffh	; 780d  c9@@NAME@@.

; ----------------------------------------------------------------------
; DATOS veinte_a_e0c0: Los 20 bytes que 0x7736 copia a 0xE0C0
;   0x7818..0x782c  (20 bytes)
DATA_veinte_a_e0c0:
	defb 05fh,07ch,000h,000h	; 7818
	defb 05fh,074h,000h,000h	; 781c
	defb 05fh,079h,000h,000h	; 7820
	defb 06fh,079h,000h,000h	; 7824
	defb 06fh,079h,000h,000h	; 7828

; ----------------------------------------------------------------------
; DATOS cuatro_a_e0d4: Los cuatro bytes que 0x77A8 copia a 0xE0D4: un sprite
;   (Y, X, patron, color)
;   0x782c..0x7830  (4 bytes)
DATA_cuatro_a_e0d4:
	defb 066h,018h,0d4h,006h	; 782c

; ----------------------------------------------------------------------
; DATOS copia_7830: 16 bytes que 0x76F8 copia a la VRAM 0x32E0
;   0x7830..0x7840  (16 bytes)
DATA_copia_7830:
	defb 000h,000h,040h,049h,05ah,073h,052h,059h,000h,000h,000h,092h,052h,0ceh,002h,0dch	; 7830  ..@IZsRY....R...

; ----------------------------------------------------------------------
; DATOS rle_7840: flujo RLE (0x7733 lo descomprime en 32 bytes de VRAM)
;   0x7840..0x7851  (17 bytes)
DATA_rle_7840:
	defb 0a0h,01eh,082h,0ffh,0ffh,008h,0c0h,082h,0ffh,0ffh,004h,000h,00ch,0c0h,004h,000h	; 7840  ................
	defb 000h	; 7850

; ======================================================================
; CODIGO 0x7851..0x785d  (12 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; LAS DOS PANTALLAS DE PREPARACION. Las dos van igual: se pinta el
; cursor (0x792C o 0x7947), 0x79BA convierte lo que se acaba de
; pulsar en un numero en E215, y ese numero despacha por una tabla de
; cuatro: 0 no hace nada, 1 mueve el cursor, 2 tampoco, 3 cambia lo
; que hay debajo. El acarreo a la vuelta dice si se ha terminado.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
PANTALLA_DE_COLOCAR:		; Un fotograma de la primera pantalla: cursor, tecla y lo que toque
	call PINTA_EL_CURSOR		;7851   ; El cursor, que parpadea con el bit 3 del contador de fotogramas
	call QUE_SE_HA_PULSADO		;7854   ; Lo pulsado se convierte en un numero de accion
	ld a,(0e215h)		;7857   ; E215, la accion, y la tabla justo detras
	call DESPACHA		;785a

; ----------------------------------------------------------------------
; DATOS tabla_de_acciones_colocar: Las cuatro acciones de la pantalla de
;   colocar, indice E215: 0x792A terminar (disparo), 0x791E cambiar de campo
;   (SELECT), 0x7928 nada, 0x7865 subir o bajar el valor (flecha)
;   0x785d..0x7865  (8 bytes)
DATA_tabla_de_acciones_colocar:
	defw 0792ah	; 785d  -> TERMINA
	defw 0791eh	; 785f  -> CAMBIA_DE_CAMPO
	defw 07928h	; 7861  -> SIN_HACER_NADA
	defw 07865h	; 7863  -> CAMBIA_LA_COLOCACION

; ======================================================================
; CODIGO 0x7865..0x78bf  (90 bytes)
; ======================================================================


CAMBIA_LA_COLOCACION:		; Sube o baja el valor de debajo del cursor, dando la vuelta por los dos extremos
	ld hl,0e05bh		;7865   ; E05B es el primero de los dos, y su tope, 0x60 en el nibble alto y 3 en el bajo
	ld de,00360h		;7868
	ld a,(0e214h)		;786b   ; E214 dice cual de los dos se esta tocando
	and a			;786e
	jr z,L_7875		;786f
	ld de,00720h		;7871   ; El segundo, E05C, con otros topes: 0x20 arriba y 7 abajo
	inc hl			;7874
L_7875:
	ld a,(0e009h)		;7875   ; Arriba suma uno y abajo resta: el inc y los dos dec de la vuelta
	inc (hl)			;7878
	srl a		;7879
	jr c,L_787F		;787b
	dec (hl)			;787d
	dec (hl)			;787e
L_787F:
	ld a,(hl)			;787f
	and 00fh		;7880
	cp d			;7882   ; Al pasarse por arriba, vuelta al 1 y una fila mas
	jr nz,L_788D		;7883
	ld d,001h		;7885
	ld a,(hl)			;7887
	add a,010h		;7888
	ld (hl),a			;788a
	jr L_7891		;788b
L_788D:
	cp 00fh		;788d   ; Y al pasarse por abajo, al 0x0F
	jr nz,L_7897		;788f
L_7891:
	dec d			;7891
	ld a,(hl)			;7892
	and 0f0h		;7893
	or d			;7895
	ld (hl),a			;7896
L_7897:
	ld a,(hl)			;7897
	and 0f0h		;7898
	cp e			;789a   ; El nibble alto, igual: en el tope vuelve al 0x10...
	jr nz,L_78A1		;789b
	ld e,010h		;789d
	jr SUBE_EL_NIBBLE_ALTO		;789f
L_78A1:
	cp 0f0h		;78a1   ; ...y por abajo, al 0xF0
	jr nz,COLOCA_Y_SUBE		;78a3
SUBE_EL_NIBBLE_ALTO:		; Deja el nibble alto una fila mas arriba
	ld a,e			;78a5
	sub 010h		;78a6   ; Una fila son 0x10 en el nibble alto
	ld e,a			;78a8
	ld a,(hl)			;78a9
	and 00fh		;78aa
	or e			;78ac
	ld (hl),a			;78ad
COLOCA_Y_SUBE:		; Recoloca los sprites y los manda a la VRAM
	call COLOCA_LOS_SPRITES_DEL_DECORADO		;78ae
SUBE_LOS_SPRITES:		; Los 24 bytes de atributos de E0C0 a la tabla de sprites (VRAM 0x3B00)
	ld hl,0e0c0h		;78b1
	ld de,03b00h		;78b4
	ld bc,00018h		;78b7
	call COPIA_A_VRAM		;78ba
	and a			;78bd   ; Sin acarreo: aqui no se ha terminado nada
	ret			;78be

; ----------------------------------------------------------------------
; DATOS columnas_del_primero: Las tres columnas donde puede ir el primero de
;   los sprites del decorado (6, 12 y 13), que 0x78D6 elige con el nibble bajo
;   de E05B
;   0x78bf..0x78c2  (3 bytes)
DATA_columnas_del_primero:
	defb 006h,00ch,00dh	; 78bf

; ----------------------------------------------------------------------
; DATOS columnas_del_segundo: Las siete del segundo (13, 6, 4, 7, 8, 12 y 15),
;   que 0x78EB elige con el nibble bajo de E05C
;   0x78c2..0x78c9  (7 bytes)
DATA_columnas_del_segundo:
	defb 00dh,006h,004h,007h,008h,00ch,00fh	; 78c2

; ======================================================================
; CODIGO 0x78c9..0x7960  (151 bytes)
; ======================================================================


COLOCA_LOS_SPRITES_DEL_DECORADO:		; Reparte cinco sprites por la pantalla leyendo las dos posiciones de E05B y E05C
	ld hl,0e05bh		;78c9   ; E05B: el nibble alto es la fila y el bajo el indice de la columna
	ld a,(hl)			;78cc
	and 0f0h		;78cd
	add a,040h		;78cf   ; La fila, en pixeles: 0x40 mas el nibble alto
	ld b,a			;78d1
	ld a,(hl)			;78d2
	and 00fh		;78d3
	push hl			;78d5
	ld hl,078bfh		;78d6   ; Y la columna sale de la tabla de tres
	call HL_MAS_A		;78d9
	ld a,(hl)			;78dc
	pop hl			;78dd
	ld c,a			;78de
	inc hl			;78df
	ld a,(hl)			;78e0
	and 0f0h		;78e1   ; E05C: la otra pareja, con el nibble alto a la mitad y 0xC4 de base
	srl a		;78e3
	add a,0c4h		;78e5
	ld d,a			;78e7
	ld a,(hl)			;78e8
	and 00fh		;78e9
	ld hl,078c2h		;78eb   ; Y su columna, de la tabla de siete
	call HL_MAS_A		;78ee
	ld a,(hl)			;78f1
	ld e,a			;78f2
	ld hl,0e0cah		;78f3   ; El sprite de E0CA con el patron 0x0B...
	ld (hl),b			;78f6
	inc hl			;78f7
	ld (hl),00bh		;78f8
	ld hl,0e0c2h		;78fa   ; ...y los dos de E0C2 y E0C6, cuatro pixeles mas abajo cada uno
	ld a,004h		;78fd
	add a,b			;78ff
	ld b,a			;7900
	ld (hl),b			;7901
	inc hl			;7902
	ld (hl),c			;7903
	ld hl,0e0c6h		;7904
	ld a,004h		;7907
	add a,b			;7909
	ld (hl),a			;790a
	inc hl			;790b
	ld (hl),c			;790c
	ld hl,0e0ceh		;790d   ; El de E0CE con el patron 0x0A y su pareja en E0D2
	ld (hl),d			;7910
	inc hl			;7911
	ld (hl),00ah		;7912
	ld hl,0e0d2h		;7914
	ld a,004h		;7917
	add a,d			;7919
	ld (hl),a			;791a
	inc hl			;791b
	ld (hl),e			;791c
	ret			;791d
CAMBIA_DE_CAMPO:		; Mueve el cursor al otro de los dos valores (E214) y lo repinta
	call BORRA_EL_CURSOR		;791e
	ld hl,0e214h		;7921
	ld a,(hl)			;7924
	xor 001h		;7925   ; E214 alterna entre 0 y 1
	ld (hl),a			;7927
SIN_HACER_NADA:		; La accion 2: ni cambia nada ni termina (sin acarreo)
	and a			;7928
	ret			;7929
TERMINA:		; La accion 0, el disparo: acarreo puesto, que es como se dice "ya esta"
	scf			;792a
	ret			;792b
PINTA_EL_CURSOR:		; El cursor de la primera pantalla, en la fila 12; parpadea con el bit 3 del contador
	ld bc,05e5fh		;792c   ; Los dos tiles del cursor
	ld hl,0e003h		;792f
	bit 3,(hl)		;7932   ; Un bit del contador de fotogramas: ocho cuadros con cursor y ocho sin
	jr nz,L_7939		;7934
BORRA_EL_CURSOR:		; Lo mismo con los tiles a cero
	ld bc,00000h		;7936
L_7939:
	ld de,0398ah		;7939   ; Fila 12, columna 10
	ld a,(0e214h)		;793c   ; Con E214 a 1 el cursor se va a la otra mitad (el bit 6 de E, o sea 64 casillas mas)
	and a			;793f
	jr z,L_7944		;7940
	set 6,e		;7942
L_7944:
	jp PINTA_DOS_TILES		;7944
PANTALLA_DEL_NOMBRE:		; Un fotograma de la segunda pantalla: la que deja escribir el nombre
	call SUBE_LOS_SPRITES		;7947   ; Los sprites, primero
	ld a,(0e003h)		;794a
	bit 3,a		;794d   ; El sprite del cursor se ve u ocupa el patron 6 segun el bit 3: asi parpadea
	ld a,006h		;794f
	jr nz,L_7954		;7951
	xor a			;7953
L_7954:
	ld (0e0d7h),a		;7954
	call QUE_SE_HA_PULSADO		;7957   ; Y la misma lectura de teclas, con su tabla detras
	ld a,(0e215h)		;795a
	call DESPACHA		;795d

; ----------------------------------------------------------------------
; DATOS tabla_de_acciones_nombre: Las mismas cuatro para la pantalla del
;   nombre: 0x792A terminar, 0x79A4 mover el cursor, 0x7928 nada, 0x7968
;   cambiar la letra
;   0x7960..0x7968  (8 bytes)
DATA_tabla_de_acciones_nombre:
	defw 0792ah	; 7960  -> TERMINA
	defw 079a4h	; 7962  -> MUEVE_EL_CURSOR_DEL_NOMBRE
	defw 07928h	; 7964  -> SIN_HACER_NADA
	defw 07968h	; 7966  -> CAMBIA_LA_LETRA

; ======================================================================
; CODIGO 0x7968..0x7bff  (663 bytes)
; ======================================================================


CAMBIA_LA_LETRA:		; Sube o baja la letra que hay bajo el cursor, con la vuelta entre la Z y el blanco
	ld a,(0e0d5h)		;7968   ; La X del cursor entre ocho da la columna...
	srl a		;796b
	srl a		;796d
	srl a		;796f
	sub 002h		;7971   ; ...y quitandole dos, la letra dentro del nombre (E05D en adelante)
	push af			;7973
	ld hl,0e05dh		;7974
	call HL_MAS_A		;7977
	ld a,(0e009h)		;797a
	inc (hl)			;797d   ; Arriba la siguiente letra, abajo la anterior
	srl a		;797e
	jr c,L_7984		;7980
	dec (hl)			;7982
	dec (hl)			;7983
L_7984:
	ld a,(hl)			;7984
	ld b,a			;7985
	cp 03eh		;7986   ; Pasado el 0x3E vuelve al blanco (0x5B)...
	jr nz,L_798C		;7988
	ld b,05bh		;798a
L_798C:
	cp 05ch		;798c   ; ...y pasado el 0x5C, al 0x3F: se recorre el alfabeto en redondo
	jr nz,L_7992		;798e
	ld b,03fh		;7990
L_7992:
	ld (hl),b			;7992
	pop af			;7993
	add a,0a2h		;7994   ; La casilla de la fila 13 donde va esa letra
	ld e,a			;7996
	ld d,039h		;7997
	ld a,b			;7999
	cp 05bh		;799a   ; El blanco no tiene dibujo: se pinta el tile 0
	jr nz,L_799F		;799c
	xor a			;799e
L_799F:
	call VPOKE		;799f
	xor a			;79a2
	ret			;79a3
MUEVE_EL_CURSOR_DEL_NOMBRE:		; El cursor salta de ocho en ocho pixeles y da la vuelta entre las diez letras
	ld hl,0e0d5h		;79a4
	ld a,008h		;79a7   ; Ocho pixeles: una casilla
	add a,(hl)			;79a9
	ld b,a			;79aa
	cp 008h		;79ab   ; Pasado el final vuelve a la X 0x58...
	jr nz,L_79B1		;79ad
	ld b,058h		;79af
L_79B1:
	cp 060h		;79b1   ; ...y pasado el principio, a la 0x10
	jr nz,L_79B7		;79b3
	ld b,010h		;79b5
L_79B7:
	ld (hl),b			;79b7
	and a			;79b8
	ret			;79b9
QUE_SE_HA_PULSADO:		; Convierte lo que se acaba de pulsar en el numero de accion de E215 (0 disparo, 1 SELECT, 2 nada, 3 flecha)
	ld de,0e215h		;79ba
	xor a			;79bd
	ld (de),a			;79be   ; E215 empieza a cero
	ld hl,0e008h		;79bf
	ld a,(hl)			;79c2   ; E008 contra E009: solo lo que se acaba de pulsar
	inc hl			;79c3
	xor (hl)			;79c4
	and (hl)			;79c5
	ld b,a			;79c6   ; La tinta, cambiada o no, se aparca en B
	ex de,hl			;79c7
	bit 4,a		;79c8   ; El disparo deja la accion en 0
	ret nz			;79ca
	inc (hl)			;79cb
	bit 3,a		;79cc   ; SELECT, en 1
	ret nz			;79ce
	inc (hl)			;79cf
	ld a,003h		;79d0
	ex de,hl			;79d2
	and (hl)			;79d3   ; Las dos flechas a la vez no valen
	ex de,hl			;79d4
	cp 003h		;79d5
	ret z			;79d7
	and a			;79d8
	ret z			;79d9
	inc (hl)			;79da   ; Una sola flecha: accion 3
	ld a,b			;79db
	and 003h		;79dc
	jr z,REBOBINA_EL_PARPADEO		;79de
	ld a,(0e003h)		;79e0   ; Y con flecha se rebobina el contador de fotogramas para que el cursor no se apague justo ahora
	and 0f8h		;79e3
	ld (0e003h),a		;79e5
	ret			;79e8
REBOBINA_EL_PARPADEO:		; Deja el contador de fotogramas justo antes de cambiar de fase, para que el cursor no se apague al pulsar
	dec (hl)			;79e9
	ld a,(0e003h)		;79ea   ; Uno de cada ocho fotogramas
	and 007h		;79ed
	ret nz			;79ef
	inc (hl)			;79f0
	ret			;79f1
PINTA_EL_NOMBRE:		; Escribe las diez letras del nombre (E05D) en la fila 13, columna 2
	ld de,039a2h		;79f2   ; Fila 13, columna 2
PINTA_EL_NOMBRE_EN:		; Las diez letras del nombre en la VRAM que traiga DE
	ld hl,0e05dh		;79f5
	ld b,00ah		;79f8   ; Diez letras
L_79FA:
	ld a,(hl)			;79fa
	cp 05bh		;79fb   ; El 0x5B es el blanco: se pinta el tile 0, que no tiene dibujo
	jr nz,L_7A00		;79fd
	xor a			;79ff
L_7A00:
	call VPOKE		;7a00
	inc de			;7a03
	inc hl			;7a04
	djnz L_79FA		;7a05
	ret			;7a07
SONIDO:		; Pide el sonido A: efecto (canal C), musica de dos canales (0x8E) o de tres (0x90+)
	di			;7a08   ; El reproductor corre dentro de la interrupcion: no puede pillar los canales a medio repartir
	push hl			;7a09
	push de			;7a0a
	push bc			;7a0b
	push af			;7a0c
	ld d,000h		;7a0d   ; D=0: solo entra si el canal no lleva ya algo igual o mas alto
	call SONIDO_SIN_GUARDAR		;7a0f
	pop af			;7a12
	pop bc			;7a13
	pop de			;7a14
	pop hl			;7a15
	ei			;7a16
	ret			;7a17
SONIDO_SIN_GUARDAR:		; La entrada al reparto de canales, con el numero ya en C
	ld c,a			;7a18
SONIDO_ARRANCA:		; D=0 respeta la prioridad; D=1 (desde el bucle) no. Reparte los canales y arranca la pista
	ld b,002h		;7a19   ; Dos canales por defecto: A y B
	ld hl,0e012h		;7a1b
	and 03fh		;7a1e
	cp 00dh		;7a20   ; Por debajo de 0x0D son efectos: un canal
	jr c,SONIDO_UN_CANAL		;7a22
	cp 00fh		;7a24   ; De 0x0F en adelante, tres canales
	jr c,SONIDO_PRIORIDAD		;7a26
	inc b			;7a28
	jr SONIDO_PRIORIDAD		;7a29
SONIDO_UN_CANAL:		; El canal C (E024) para los efectos
	dec b			;7a2b
	ld hl,0e028h		;7a2c
SONIDO_PRIORIDAD:		; Si el canal ya lleva algo de numero igual o mayor, no se le pisa
	dec d			;7a2f   ; Con D=1 se salta la comprobacion
	jr z,L_7A3C		;7a30
	ld a,(hl)			;7a32
	and 03fh		;7a33
	ld e,a			;7a35
	ld a,c			;7a36   ; Los seis bits bajos son el numero, que es la prioridad
	and 03fh		;7a37
	cp e			;7a39
	ret c			;7a3a
	ret z			;7a3b
L_7A3C:
	and 03fh		;7a3c
	add a,a			;7a3e
	ld de,07c09h		;7a3f
	call DE_MAS_A		;7a42
SONIDO_CANAL:		; Arranca un canal: 1 fotograma, duracion 1, el numero, y el puntero de la tabla; y al siguiente canal (10 bytes mas alla)
	dec hl			;7a45   ; HL llega apuntando a +2 del canal: atras hasta +0
	dec hl			;7a46
L_7A47:
	ld (hl),001h		;7a47   ; +0, lo que queda de nota: 1 fotograma, para que el primer paso ya lea el evento
	inc hl			;7a49
	ld (hl),001h		;7a4a   ; +1, la duracion de las notas
	inc hl			;7a4c
	ld (hl),c			;7a4d
	inc hl			;7a4e
	ld a,(de)			;7a4f   ; +3/+4, el puntero de la pista que da la tabla de 0x7C0B
	ld (hl),a			;7a50
	inc hl			;7a51
	inc de			;7a52
	ld a,(de)			;7a53
	ld (hl),a			;7a54
	ld a,007h		;7a55
	add a,l			;7a57
	ld l,a			;7a58
	inc de			;7a59
	djnz L_7A47		;7a5a
SONIDO_FIN:		; Nada que hacer
	ret			;7a5c
SONIDO_SIGUIENTE_VUELTA:		; Cuenta una vuelta mas del sonido en curso y, mientras no llegue a la ultima, lo vuelve a arrancar
	inc hl			;7a5d
	ld a,(ix+009h)		;7a5e   ; +9 es la vuelta por la que va
	inc a			;7a61
	cp (hl)			;7a62   ; En la ultima, a callar (0x7B4A)
	jp z,L_7B4A		;7a63
	jp m,L_7A6A		;7a66
	dec a			;7a69   ; El contador se guarda sin pasarse
L_7A6A:
	ex af,af'			;7a6a
SONIDO_REPITE:		; 0xFE en la pista: vuelve a arrancar el mismo sonido sin mirar prioridades (bucle)
	ld a,(ix+002h)		;7a6b   ; +2 guarda el numero del sonido que estaba sonando
	push bc			;7a6e
	ld d,001h		;7a6f   ; D=1: sin mirar prioridad, o el bucle se cortaria a si mismo
	call SONIDO_SIN_GUARDAR		;7a71
	pop bc			;7a74
	ex af,af'			;7a75
	ld (ix+009h),a		;7a76
	ret			;7a79
ENCIENDE_EL_CANAL:		; Pone o quita el bit del canal C en el mezclador del PSG (registro 7), sin tocar los demas
	ld a,(0e037h)		;7a7a   ; E037 es la copia del registro 7: el mezclador
	ld e,a			;7a7d
	ld a,c			;7a7e
	cp 001h		;7a7f   ; El canal 1 no baja: los bits de tono van en 0, 1 y 2
	jr z,L_7A84		;7a81
	dec a			;7a83
L_7A84:
	rlca			;7a84   ; Tres bits arriba: el bit del canal que toca
	rlca			;7a85
	rlca			;7a86
	dec d			;7a87   ; D=0 apaga (and del complemento) y D=1 enciende (or)
	jr z,L_7A8E		;7a88
	cpl			;7a8a
	and e			;7a8b
	jr L_7A8F		;7a8c
L_7A8E:
	or e			;7a8e
L_7A8F:
	set 0,a		;7a8f   ; El bit 0 siempre puesto salvo si el 3 lo pide: asi el ruido y el tono no se pisan
	bit 3,a		;7a91
	jr z,ESCRIBE_EL_MEZCLADOR		;7a93
	res 0,a		;7a95
ESCRIBE_EL_MEZCLADOR:		; Guarda A en E037 y lo manda al registro 7 del PSG
	ld (0e037h),a		;7a97
	ld e,a			;7a9a
	ld a,007h		;7a9b   ; Registro 7 del PSG
	jp 00093h		;7a9d   ; BIOS WRTPSG - Writes data to PSG-register
EL_REPRODUCTOR:		; Un paso de los tres canales, en cada interrupcion
	ld a,(0e037h)		;7aa0
	call ESCRIBE_EL_MEZCLADOR		;7aa3
	ld c,001h		;7aa6
	ld ix,0e010h		;7aa8
	exx			;7aac

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; EL REPRODUCTOR, en cada interrupcion (aunque el juego vaya atrasado).
; Para cada canal ocupado descuenta la nota y, si acabo, lee el
; siguiente evento de su pista. Dos formatos segun el bit 7 del numero:
; EFECTO: [0x2n duracion n] vp pp -> volumen v, periodo 0xppp
; MUSICA: [0xFD oo] ln -> l duracion (tabla 0x7C4F), n nota 0-11 en
; la octava de 0x7C01 bajada oo&7 octavas, 12 silencio;
; oo>>3 es el volumen de arranque
; 0xFE vuelve al principio (bucle), 0xFF apaga el canal.
; La musica lleva envolvente: la nota arranca al volumen v y baja tres
; pasos en tres fotogramas, se mantiene, y baja dos mas al acabar.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
SUENA:		; Un fotograma de los tres canales (IX = E010, +10 por canal; C = registro de periodo)
	ld b,003h		;7aad
	ld de,0000bh		;7aaf   ; Once bytes por canal: E010, E01B y E026
L_7AB2:
	exx			;7ab2
	ld a,(ix+002h)		;7ab3   ; +2 a cero es canal libre: ni se le mira la pista
	or a			;7ab6
	call nz,UN_PASO_DEL_CANAL		;7ab7
	inc c			;7aba   ; Los dos registros del canal siguiente: 1, 3, 5
	inc c			;7abb
	exx			;7abc
	add ix,de		;7abd   ; IX al bloque del canal siguiente
	djnz L_7AB2		;7abf
	ret			;7ac1
UN_PASO_DEL_CANAL:		; Lo que le toca al canal de IX en este fotograma
	bit 6,a		;7ac2
	ld d,001h		;7ac4
	call z,ENCIENDE_EL_CANAL		;7ac6
	ld a,(ix+002h)		;7ac9
	or a			;7acc
SUENA_PASO:		; Musica (bit 7) por 78D7; efecto: descuenta y, a cero, siguiente evento
	jp m,MUSICA_PASO		;7acd
	dec (ix+000h)		;7ad0
	ret nz			;7ad3
SIGUIENTE_EVENTO:		; Lee la pista: 0xFE bucle, 0xFF apaga, musica por 7902, efecto aqui
	ld l,(ix+003h)		;7ad4
	ld h,(ix+004h)		;7ad7
	ld a,(hl)			;7ada
	cp 0feh		;7adb   ; 0xFE: bucle
	jp z,SONIDO_SIGUIENTE_VUELTA		;7add
	jr nc,L_7B4A		;7ae0
	bit 7,(ix+002h)		;7ae2   ; Musica: otro formato
	jp nz,MUSICA_EVENTO_LARGO		;7ae6
	and 0f0h		;7ae9
	cp 020h		;7aeb   ; 0x2n: nueva duracion de las notas del efecto
	jr nz,EFECTO_UN_PASO		;7aed
	jr nz,EFECTO_EVENTO		;7aef
	ld a,(hl)			;7af1
	and 00fh		;7af2
	ld (ix+001h),a		;7af4
	inc hl			;7af7
EFECTO_UN_PASO:		; Un evento de la pista de un efecto: 0x1n pone el ruido, y detras el volumen y el periodo
	ld a,(hl)			;7af8
	and 0f0h		;7af9
	cp 010h		;7afb   ; 0x1n: el registro 6, el periodo del ruido
	jr nz,EFECTO_MIRA_EL_RUIDO		;7afd
	ld a,(hl)			;7aff
	and 01fh		;7b00
	ld e,a			;7b02
	ld a,006h		;7b03
	call 00093h		;7b05   ; BIOS WRTPSG - Writes data to PSG-register
	ld d,000h		;7b08   ; D=0: el canal se apaga en el mezclador mientras suena el ruido
	call ENCIENDE_EL_CANAL		;7b0a
	inc hl			;7b0d
	ld a,(hl)			;7b0e
EFECTO_MIRA_EL_RUIDO:		; Con el bit 6 puesto y en el canal 1, el byte es el periodo del ruido
	bit 6,(ix+002h)		;7b0f   ; Bit 6 del numero: el efecto lleva ruido
	jr z,EFECTO_EVENTO		;7b13
	ld a,c			;7b15
	cp 001h		;7b16   ; Y solo en el canal 1
	ld a,(hl)			;7b18
	jr nz,EFECTO_EVENTO		;7b19
	inc hl			;7b1b
	ld (ix+003h),l		;7b1c
	ld (ix+004h),h		;7b1f
	jr NOTA_ARRANCA		;7b22
EFECTO_EVENTO:		; Nibble alto volumen, nibble bajo y byte siguiente el periodo
	ld a,(hl)			;7b24
	and 0f0h		;7b25   ; El nibble alto, el volumen
	ld b,a			;7b27
	xor (hl)			;7b28   ; El xor deja el nibble bajo: los 4 bits altos del periodo
	ld d,a			;7b29
	inc hl			;7b2a
	ld e,(hl)			;7b2b   ; Y el byte de detras, los 8 bajos
	inc hl			;7b2c
	ld (ix+003h),l		;7b2d   ; La pista queda apuntando a lo que venga detras
	ld (ix+004h),h		;7b30
	ex de,hl			;7b33
	call PSG_PERIODO		;7b34
	ld a,b			;7b37
	rrca			;7b38   ; El volumen baja al nibble bajo para PSG_VOLUMEN
	rrca			;7b39
	rrca			;7b3a
	rrca			;7b3b
NOTA_ARRANCA:		; H = volumen; +0 = duracion, +8 = duracion + 3 (la envolvente); y al PSG
	ld h,a			;7b3c
	ld a,(ix+001h)		;7b3d   ; +1 es la duracion fijada; +0 la cuenta atras que se le pone al lado
	ld (ix+000h),a		;7b40
	add a,004h		;7b43
	ld (ix+008h),a		;7b45   ; +8 arranca tres por encima: la envolvente los gasta al principio
	jr PSG_VOLUMEN		;7b48
L_7B4A:
	xor a			;7b4a
	ld (ix+009h),a		;7b4b
	ld d,001h		;7b4e
	call ENCIENDE_EL_CANAL		;7b50
CANAL_APAGA:		; Numero 0 y volumen 0
	xor a			;7b53
	ld (ix+002h),a		;7b54
	ld h,a			;7b57
	jr PSG_VOLUMEN		;7b58
MUSICA_PASO:		; Descuenta la nota y la envolvente; al llegar a cero, el evento siguiente
	dec (ix+000h)		;7b5a   ; +0 es lo que queda de nota
	jp z,SIGUIENTE_EVENTO		;7b5d
	dec (ix+008h)		;7b60   ; +8 es la envolvente, que va tres por delante
	ld a,(ix+008h)		;7b63
	cp (ix+000h)		;7b66
	jr nz,ENVOLVENTE_ARRANQUE		;7b69
	cp 001h		;7b6b
	jr c,VOLUMEN_BAJA		;7b6d
	ret			;7b6f
ENVOLVENTE_ARRANQUE:		; Los tres primeros fotogramas: baja
	dec (ix+008h)		;7b70
VOLUMEN_BAJA:		; Un paso menos, sin pasar de cero
	ld a,(ix+007h)		;7b73
	dec a			;7b76
	ret m			;7b77
	ld (ix+007h),a		;7b78
	ld h,a			;7b7b
PSG_VOLUMEN:		; Registro 8/9/10 (segun C) = H
	ld a,c			;7b7c
	rrca			;7b7d   ; C vale 1, 3 o 5: registros 8, 9 y 10, los tres volumenes
	add a,088h		;7b7e
	ld e,h			;7b80
	jp 00093h		;7b81   ; BIOS WRTPSG - Writes data to PSG-register
MUSICA_EVENTO_LARGO:		; Los eventos que traen mas de un byte: el ruido (bit 6) y el 0xDn, que fija el volumen
	ld a,(ix+002h)		;7b84
	bit 6,a		;7b87   ; Bit 6 del numero de sonido: ademas del tono, ruido
	call nz,EFECTO_UN_PASO		;7b89
	ld a,(hl)			;7b8c
	and 0f0h		;7b8d
	cp 0d0h		;7b8f   ; 0xDn: el nibble bajo se queda en +10 como volumen
	ld a,(hl)			;7b91
	jr nz,MUSICA_LEE_LA_NOTA		;7b92
	and 00fh		;7b94
	ld (ix+00ah),a		;7b96
	inc hl			;7b99
	ld a,(hl)			;7b9a
MUSICA_LEE_LA_NOTA:		; El byte que queda es la nota, con su octava y su duracion
	cp 0f0h		;7b9b   ; Por debajo de 0xF0 no hay cambio de octava
	jr c,L_7BA6		;7b9d
	and 00fh		;7b9f   ; 0xFn: el nibble bajo es la octava, y la nota viene detras
	ld (ix+006h),a		;7ba1
	inc hl			;7ba4
	ld a,(hl)			;7ba5
L_7BA6:
	cp 0e0h		;7ba6
	jr c,MUSICA_NOTA		;7ba8
	and 00fh		;7baa
	ld (ix+005h),a		;7bac
	inc hl			;7baf
	ld a,(hl)			;7bb0   ; Y detras del 0xFD viene ya el byte de la nota
MUSICA_NOTA:		; Nibble bajo la nota, alto el indice de duracion; 12 es silencio (no repone el volumen)
	and 00fh		;7bb1
	ld b,a			;7bb3
	ld a,(ix+00ah)		;7bb4
	jr z,MUSICA_APUNTA_LA_PISTA		;7bb7
L_7BB9:
	add a,(ix+00ah)		;7bb9
	djnz L_7BB9		;7bbc
MUSICA_APUNTA_LA_PISTA:		; Guarda por donde va la pista y saca de la nota el numero y la octava
	ld (ix+001h),a		;7bbe
	ld a,(hl)			;7bc1
	inc hl			;7bc2
	ld (ix+003h),l		;7bc3   ; +3 y +4: por donde va la pista, para la vuelta siguiente
	ld (ix+004h),h		;7bc6
	and 0f0h		;7bc9   ; El nibble alto es la nota
	rrca			;7bcb
	rrca			;7bcc
	rrca			;7bcd
	rrca			;7bce
	ld b,a			;7bcf
	sub 00ch		;7bd0   ; Nota 12: silencio
	ld (ix+007h),a		;7bd2
	jr z,MUSICA_PERIODO		;7bd5
	ld a,(ix+006h)		;7bd7
	ld (ix+007h),a		;7bda
MUSICA_PERIODO:		; Periodo de la nota por 0x7C01, doblado tantas veces como octavas
	call NOTA_ARRANCA		;7bdd
	ld a,b			;7be0
	ld hl,07bffh		;7be1   ; Los doce periodos de la octava mas alta
	call HL_MAS_A		;7be4
	ld l,(hl)			;7be7
	ld h,000h		;7be8
	ld a,(ix+005h)		;7bea   ; Sin octavas que bajar, el periodo va tal cual
	or a			;7bed
	jr z,PSG_PERIODO		;7bee
	ld b,a			;7bf0
MUSICA_OCTAVA:		; Una octava mas abajo por vuelta
	add hl,hl			;7bf1   ; Doblar el periodo es bajar una octava
	djnz MUSICA_OCTAVA		;7bf2
PSG_PERIODO:		; Registros C y C-1 = HL (periodo)
	ld a,c			;7bf4   ; El registro impar lleva el byte alto del periodo
	ld e,h			;7bf5
	call 00093h		;7bf6   ; BIOS WRTPSG - Writes data to PSG-register
	ld a,c			;7bf9
	dec a			;7bfa
	ld e,l			;7bfb
	jp 00093h		;7bfc   ; BIOS WRTPSG - Writes data to PSG-register

; ----------------------------------------------------------------------
; DATOS periodos_de_notas: Los doce periodos del PSG de una octava, que 0x7BE1
;   indexa con la nota: 106, 100, 95, 89, 84, 80, 75, 71, 67, 63, 60 y 56.
;   Empiezan en 0x7BFF, dos bytes antes de donde los pone el cartucho hermano,
;   y aqui NO se solapan con la tabla de punteros
;   0x7bff..0x7c0b  (12 bytes)
DATA_periodos_de_notas:
	defb 06ah,064h,05fh,059h,054h,050h,04bh,047h,043h,03fh,03ch,038h	; 7bff  jd_YTPKGC?<8

; ----------------------------------------------------------------------
; DATOS tabla_de_sonidos: 34 punteros de pista, indice = numero del sonido &
;   0x3F, con los canales seguidos: 1-13 los efectos, 14-15 la musica de la
;   partida (0x8E), 16-18 la muerte (0x90), 19-21 GAME OVER (0x93), 22-24 le
;   han dado (0x96), 25-27 se hunde (0x99), 28-30 la fanfarria del menu y la
;   meta (0x9C), 31-33 mudos. 0x7C7C (un 0xFF) es la pista muda de los canales
;   vacios y del sonido 6
;   0x7c0b..0x7c4f  (68 bytes)
DATA_tabla_de_sonidos:
	defw 07c53h	; 7c0b
	defw 07c5dh	; 7c0d  -> DATA_fanfarria_canal_a
	defw 07c6bh	; 7c0f
	defw 07c79h	; 7c11
	defw 07c96h	; 7c13
	defw 07ca5h	; 7c15
	defw 07cb7h	; 7c17
	defw 07cc9h	; 7c19
	defw 07ce0h	; 7c1b
	defw 07ce9h	; 7c1d
	defw 07cf4h	; 7c1f
	defw 07cffh	; 7c21
	defw 07d06h	; 7c23
	defw 07d63h	; 7c25
	defw 07de1h	; 7c27
	defw 07e0dh	; 7c29
	defw 07e3ah	; 7c2b
	defw 07e7bh	; 7c2d
	defw 07ea2h	; 7c2f
	defw 07eb5h	; 7c31
	defw 07df9h	; 7c33
	defw 07e22h	; 7c35  -> DATA_efecto_pisada
	defw 07e5ch	; 7c37
	defw 07ed7h	; 7c39
	defw 07eebh	; 7c3b  -> DATA_pista_7EEB
	defw 07ef6h	; 7c3d  -> DATA_pista_7EF6
	defw 07f02h	; 7c3f  -> DATA_pista_7F02
	defw 07f23h	; 7c41  -> DATA_pista_7F23
	defw 07f42h	; 7c43  -> DATA_pista_7F42
	defw 07f5fh	; 7c45  -> DATA_pista_7F5F
	defw 07e0ch	; 7c47
	defw 07e0ch	; 7c49
	defw 07f6bh	; 7c4b  -> DATA_pista_7F6B
	defw 07e0ch	; 7c4d

; ----------------------------------------------------------------------
; DATOS duraciones_de_notas: Las 14 duraciones en fotogramas que elige el
;   nibble alto de cada nota: 5, 10, 15, 6, 12, 24, 40, 72, 4, 8, 16, 32, 20,
;   66
;   0x7c4f..0x7c5d  (14 bytes)
DATA_duraciones_de_notas:
	defb 00ch,07eh,00ch,07eh,021h,0b0h,044h,0a0h,044h,0b0h,04fh,0a0h,04fh,0ffh	; 7c4f  .~.~!.D.D.O.O.

; ----------------------------------------------------------------------
; DATOS fanfarria_canal_a: Sonido 0x9C (el menu y la meta), canal A. Su 0xFF
;   final, en 0x7C7C, es la pista muda del sonido 6 (calla el zumbido de la
;   abeja) y de los canales vacios
;   0x7c5d..0x7c7d  (32 bytes)
DATA_fanfarria_canal_a:
	defb 021h,0c0h,090h,0c0h,0a0h,028h,000h,000h,021h,0c0h,070h,0c0h,080h,0ffh,022h,0d0h	; 7c5d  !....(..!.p...".
	defb 07fh,0b0h,070h,0b0h,077h,0a0h,062h,090h,050h,080h,043h,0ffh,021h,0d1h,099h,0c1h	; 7c6d  ..p.w.b.P.C.!...

; ----------------------------------------------------------------------
; DATOS fanfarria_canal_b: Sonido 0x9C, canal B
;   0x7c7d..0x7c8e  (17 bytes)
DATA_fanfarria_canal_b:
	defb 099h,0d1h,099h,000h,000h,022h,0c0h,090h,0b0h,080h,0a0h,070h,090h,060h,080h,050h	; 7c7d  .....".....p.`.P
	defb 070h	; 7c8d

; ----------------------------------------------------------------------
; DATOS fanfarria_canal_c: Sonido 0x9C, canal C
;   0x7c8e..0x7ca0  (18 bytes)
DATA_fanfarria_canal_c:
	defb 04ch,060h,048h,050h,044h,040h,040h,0ffh,021h,010h,0d1h,080h,028h,000h,000h,021h	; 7c8e  L`HPD@@.!...(..!
	defb 010h,0c1h	; 7c9e

; ----------------------------------------------------------------------
; DATOS musica_partida_canal_a: Sonido 0x8E: la musica de la partida, canal A;
;   acaba en 0xFE, en bucle mientras dura la pantalla
;   0x7ca0..0x7cfa  (90 bytes)
DATA_musica_partida_canal_a:
	defb 030h,02ch,000h,000h,0ffh,021h,0b0h,0aah,0b0h,077h,0b0h,088h,0b0h,055h,0b0h,066h	; 7ca0  0,...!...w...U.f
	defb 0b0h,033h,0b0h,044h,0b0h,022h,0ffh,023h,0d1h,09fh,0c1h,087h,0b1h,090h,0a1h,081h	; 7cb0  .3.D.".#........
	defb 091h,085h,081h,079h,071h,080h,061h,074h,0ffh,023h,0d1h,0aah,0c1h,077h,0b1h,0aah	; 7cc0  ...yq.at.#...w..
	defb 0a1h,077h,022h,091h,0aah,081h,077h,071h,0aah,071h,077h,071h,0aah,071h,077h,0ffh	; 7cd0  .w"...wq.qwq.qw.
	defb 022h,0d0h,0a9h,0d0h,08eh,0d0h,06ah,0feh,002h,021h,0d1h,050h,0d1h,060h,0d1h,050h	; 7ce0  ".....j..!.P.`.P
	defb 025h,000h,000h,0ffh,024h,0c1h,01dh,0c0h,0d5h,0c0h	; 7cf0  %...$.....

; ----------------------------------------------------------------------
; DATOS musica_partida_canal_b: La musica de la partida, canal B (0xFE, en
;   bucle)
;   0x7cfa..0x7d75  (123 bytes)
DATA_musica_partida_canal_b:
	defb 0a9h,0c0h,08eh,0feh,002h,023h,090h,060h,090h,040h,0feh,005h,0d6h,0fbh,0e2h,000h	; 7cfa  .....#.`.@......
	defb 050h,091h,0e1h,001h,0e2h,091h,000h,050h,091h,0e1h,001h,0e2h,091h,0c1h,0e1h,020h	; 7d0a  P......P....... 
	defb 020h,021h,021h,0e2h,0a1h,071h,0c3h,000h,040h,071h,0a1h,071h,000h,040h,071h,0a1h	; 7d1a   !!..q..@q.q.@q.
	defb 071h,0c1h,0e1h,000h,000h,001h,001h,0e2h,091h,051h,0c3h,0c1h,0e1h,021h,001h,0e2h	; 7d2a  q........Q...!..
	defb 0a1h,0e1h,001h,0e2h,053h,091h,0c1h,0a0h,090h,071h,0e1h,021h,021h,003h,0e2h,051h	; 7d3a  ....S....q.!!..Q
	defb 0c1h,0e1h,021h,001h,0e2h,0a1h,0e1h,001h,0e2h,053h,091h,0c1h,0b0h,090h,071h,090h	; 7d4a  ..!......S....q.
	defb 0a0h,0e1h,000h,020h,000h,020h,003h,0feh,0ffh,0d6h,0fbh,0e3h,051h,0e2h,001h,0e3h	; 7d5a  ... . ......Q...
	defb 001h,0e2h,001h,0e3h,051h,0e2h,001h,0e3h,001h,0e2h,001h	; 7d6a  ....Q......

; ----------------------------------------------------------------------
; DATOS game_over_canal_a: Sonido 0x93 (GAME OVER), canal A
;   0x7d75..0x7d95  (32 bytes)
DATA_game_over_canal_a:
	defb 0e3h,061h,0e2h,021h,0e3h,021h,0e2h,021h,0e3h,071h,0e2h,021h,0e3h,051h,0e2h,021h	; 7d75  .a.!.!.!.q.!.Q.!
	defb 0e3h,041h,0e2h,001h,0e3h,001h,0e2h,001h,0e3h,041h,0e2h,001h,0e3h,001h,0e2h,001h	; 7d85  .A.......A......

; ----------------------------------------------------------------------
; DATOS game_over_canal_b: Canal B
;   0x7d95..0x7da9  (20 bytes)
DATA_game_over_canal_b:
	defb 0e3h,041h,0e2h,001h,0e3h,001h,0e2h,001h,0e3h,051h,0e2h,001h,0e3h,051h,0e2h,031h	; 7d95  .A.......Q...Q.1
	defb 0e3h,0a1h,0e2h,051h	; 7da5

; ----------------------------------------------------------------------
; DATOS game_over_canal_c: Canal C
;   0x7da9..0x7dcb  (34 bytes)
DATA_game_over_canal_c:
	defb 0e3h,0a1h,0e2h,051h,0e3h,091h,0e2h,051h,0e3h,091h,0e2h,051h,0e3h,071h,0e2h,021h	; 7da9  ...Q...Q...Q.q.!
	defb 0e3h,001h,0a1h,051h,0e2h,001h,0e3h,051h,0e2h,031h,0e3h,0a1h,0e2h,051h,0e3h,0a1h	; 7db9  ...Q...Q.1...Q..
	defb 0e2h,051h	; 7dc9

; ----------------------------------------------------------------------
; DATOS efecto_salto: Sonido 3: saltar y soltarse de la liana
;   0x7dcb..0x7dd9  (14 bytes)
DATA_efecto_salto:
	defb 0e3h,091h,0e2h,051h,0e3h,091h,0e2h,051h,0e3h,071h,0e2h,021h,0e3h,071h	; 7dcb  ...Q...Q.q.!.q

; ----------------------------------------------------------------------
; DATOS efecto_trampolin: Sonido 9: el bote en el trampolin
;   0x7dd9..0x7def  (22 bytes)
DATA_efecto_trampolin:
	defb 0e2h,051h,041h,0e3h,001h,021h,041h,0ffh,0d6h,0fch,0e2h,0b1h,0e1h,001h,012h,020h	; 7dd9  .QA..!A........ 
	defb 040h,041h,020h,001h,0e2h,0b1h	; 7de9

; ----------------------------------------------------------------------
; DATOS efecto_bola_arranca: Sonido 8: una bola echa a rodar
;   0x7def..0x7e10  (33 bytes)
DATA_efecto_bola_arranca:
	defb 091h,091h,0e1h,041h,031h,021h,0e2h,0b0h,0e1h,074h,0d6h,0fch,0e2h,0b1h,0e1h,001h	; 7def  ...A1!...t......
	defb 012h,020h,070h,071h,060h,041h,021h,041h,001h,0e2h,091h,061h,077h,0ffh,0d6h,0fbh	; 7dff  . pq`A!A...aw...
	defb 0e2h	; 7e0f

; ----------------------------------------------------------------------
; DATOS efecto_pez: Sonido 7: un pez salta
;   0x7e10..0x7e22  (18 bytes)
DATA_efecto_pez:
	defb 071h,091h,0a2h,0b0h,0e1h,000h,001h,0e2h,0b0h,091h,071h,061h,061h,061h,061h,0b1h	; 7e10  q.........qaaaa.
	defb 070h,0b4h	; 7e20

; ----------------------------------------------------------------------
; DATOS efecto_pisada: Sonido 2: cada paso
;   0x7e22..0x7e30  (14 bytes)
DATA_efecto_pisada:
	defb 0d6h,0fbh,0e2h,071h,091h,0a2h,0b0h,0e1h,040h,041h,020h,001h,0e2h,0b1h	; 7e22  ...q....@A ...

; ----------------------------------------------------------------------
; DATOS efecto_se_hunde: Sonido 0x99 (formato de efecto por tres canales):
;   ahogarse; solo el canal A suena, B y C van a la pista muda
;   0x7e30..0x7e4a  (26 bytes)
DATA_efecto_se_hunde:
	defb 0e1h,001h,0e2h,091h,061h,021h,0e3h,0b7h,0ffh,0ffh,0d6h,0fbh,0e3h,071h,0e2h,021h	; 7e30  ....a!.......q.!
	defb 0e3h,021h,0e3h,071h,0e3h,071h,0e2h,021h,0e3h,021h	; 7e40  .!.q.q.!.!

; ----------------------------------------------------------------------
; DATOS efecto_le_han_dado: Sonido 0x96 (idem): le ha dado un bicho; canal A
;   0x7e4a..0x7e56  (12 bytes)
DATA_efecto_le_han_dado:
	defb 0e3h,071h,0e3h,091h,0e2h,001h,0e3h,021h,0e2h,001h,0e3h,071h	; 7e4a  .q.....!...q

; ----------------------------------------------------------------------
; DATOS efecto_puntos: Sonido 1: puntos cobrados
;   0x7e56..0x7e60  (10 bytes)
DATA_efecto_puntos:
	defb 0e2h,021h,0e3h,021h,0e2h,021h,0d6h,0fbh,0e3h,071h	; 7e56  .!.!.!...q

; ----------------------------------------------------------------------
; DATOS efecto_abeja: Sonido 5: el zumbido de la abeja, en bucle (0xFE) hasta
;   que el 6 lo calla
;   0x7e60..0x7e66  (6 bytes)
DATA_efecto_abeja:
	defb 0e2h,021h,0e3h,021h,0e2h,021h	; 7e60

; ----------------------------------------------------------------------
; DATOS efecto_bola_bota: Sonido 4: la bola que bota entra
;   0x7e66..0x7e83  (29 bytes)
DATA_efecto_bola_bota:
	defb 0e3h,071h,0e2h,021h,0e3h,021h,0e2h,021h,0e3h,091h,0e2h,001h,0e3h,021h,0e2h,001h	; 7e66  .q.!.!.!.....!..
	defb 0e3h,071h,021h,073h,0ffh,0d6h,0fch,0e1h,022h,040h,0e2h,0b2h,0e1h	; 7e76  .q!s...."@...

; ----------------------------------------------------------------------
; DATOS muerte_canal_a: Sonido 0x90 (la muerte, con vidas), canal A
;   0x7e83..0x7e95  (18 bytes)
DATA_muerte_canal_a:
	defb 040h,022h,0e2h,0b0h,072h,040h,062h,090h,0e1h,002h,040h,023h,0c3h,032h,040h,002h	; 7e83  @"..r@b...@#.2@.
	defb 060h,042h	; 7e93

; ----------------------------------------------------------------------
; DATOS muerte_canal_b: Canal B; el C va a la pista muda
;   0x7e95..0x7e9c  (7 bytes)
DATA_muerte_canal_b:
	defb 000h,0e2h,092h,060h,072h,0b0h,0e1h	; 7e95

; ----------------------------------------------------------------------
; DATOS efecto_chapoteo: Sonido 0x0B: chapotear en el agua
;   0x7e9c..0x7ea7  (11 bytes)
DATA_efecto_chapoteo:
	defb 022h,060h,043h,0c3h,0feh,0ffh,0d6h,0fbh,0e2h,0c3h,023h	; 7e9c  "`C.......#

; ----------------------------------------------------------------------
; DATOS efecto_vida_extra: Sonido 0x0C: vida extra
;   0x7ea7..0x7eb9  (18 bytes)
DATA_efecto_vida_extra:
	defb 0c3h,023h,0c3h,023h,0c3h,023h,0c3h,023h,0c3h,023h,0c3h,023h,0cbh,0ffh,0d6h,0fbh	; 7ea7  .#.#.#.#.#.#....
	defb 0e3h,073h	; 7eb7

; ----------------------------------------------------------------------
; DATOS efecto_prisa: Sonido 0x0D: el pitido de que se acaba el tiempo
;   0x7eb9..0x7ed1  (24 bytes)
DATA_efecto_prisa:
	defb 0b3h,023h,0b3h,093h,0e2h,003h,0e3h,023h,0fch,0e2h,023h,0fbh,0e3h,093h,0e2h,003h	; 7eb9  .#.....#..#.....
	defb 0e3h,023h,0e2h,003h,0fch,0e3h,073h,0b3h	; 7ec9  .#....s.

; ----------------------------------------------------------------------
; DATOS efecto_fruta: Sonido 0x0A: coger la fruta, y el aviso de fase superada
;   0x7ed1..0x7edf  (14 bytes)
DATA_efecto_fruta:
	defb 022h,020h,042h,060h,0c3h,0ffh,0d5h,0fch,0e1h,043h,023h,021h,0e2h,0b1h	; 7ed1  " B`.....C#!..

; ----------------------------------------------------------------------
; DATOS pista_cola_7EDF: La cola de la pista que empieza en 0x7ED7: sigue
;   pasada la frontera del bloque anterior
;   0x7edf..0x7eeb  (12 bytes)
DATA_pista_cola_7EDF:
	defb 0e1h,041h,0e2h,0b1h,0e1h,021h,001h,0e2h,0b1h,091h,073h,0ffh	; 7edf  .A...!....s.

; ----------------------------------------------------------------------
; DATOS pista_7EEB: Pista del reproductor: la entrada 24 de la tabla de
;   0x7C0B, o sea los sonidos con ese numero
;   0x7eeb..0x7ef6  (11 bytes)
DATA_pista_7EEB:
	defb 0d5h,0fch,0e3h,073h,0b3h,083h,0c3h,093h,0c3h,073h,0ffh	; 7eeb  ...s.....s.

; ----------------------------------------------------------------------
; DATOS pista_7EF6: Pista del reproductor: la entrada 25 de la tabla de
;   0x7C0B, o sea los sonidos con ese numero
;   0x7ef6..0x7f02  (12 bytes)
DATA_pista_7EF6:
	defb 0d5h,0fch,0e2h,0c3h,023h,0c3h,023h,0c3h,021h,001h,0c3h,0ffh	; 7ef6  ....#.#.!...

; ----------------------------------------------------------------------
; DATOS pista_7F02: Pista del reproductor: la entrada 26 de la tabla de
;   0x7C0B, o sea los sonidos con ese numero
;   0x7f02..0x7f23  (33 bytes)
DATA_pista_7F02:
	defb 0d5h,0fch,0e2h,0c2h,0b0h,0b2h,0b0h,0e1h,023h,0e2h,0b3h,0e1h,002h,0e2h,0b0h,0e1h	; 7f02  ........#.......
	defb 002h,047h,070h,062h,060h,062h,040h,022h,090h,072h,060h,072h,040h,022h,0c4h,071h	; 7f12  .Gpb`b@".r`r@".q
	defb 0ffh	; 7f22

; ----------------------------------------------------------------------
; DATOS pista_7F23: Pista del reproductor: la entrada 27 de la tabla de
;   0x7C0B, o sea los sonidos con ese numero
;   0x7f23..0x7f42  (31 bytes)
DATA_pista_7F23:
	defb 0d5h,0fch,0e2h,0c2h,070h,072h,070h,053h,053h,072h,070h,072h,0e1h,007h,040h,002h	; 7f23  ....prpSSrpr..@.
	defb 000h,002h,000h,002h,000h,002h,000h,0e2h,0b2h,040h,022h,0b0h,073h,0b1h,0ffh	; 7f33  .........@".s..

; ----------------------------------------------------------------------
; DATOS pista_7F42: Pista del reproductor: la entrada 28 de la tabla de
;   0x7C0B, o sea los sonidos con ese numero
;   0x7f42..0x7f5f  (29 bytes)
DATA_pista_7F42:
	defb 0d5h,0fch,0e3h,073h,0e2h,023h,0e3h,083h,0e2h,023h,0e3h,093h,0e2h,043h,0e3h,093h	; 7f42  ...s.#...#...C..
	defb 0e2h,043h,0e3h,023h,093h,023h,093h,072h,0c3h,0b0h,073h,071h,0ffh	; 7f52  .C.#.#.r..sq.

; ----------------------------------------------------------------------
; DATOS pista_7F5F: Pista del reproductor: la entrada 29 de la tabla de
;   0x7C0B, o sea los sonidos con ese numero
;   0x7f5f..0x7f6b  (12 bytes)
DATA_pista_7F5F:
	defb 022h,0c2h,005h,0c2h,00eh,0c3h,022h,0c2h,0cch,0c2h,0fbh,0ffh	; 7f5f  ".....".....

; ----------------------------------------------------------------------
; DATOS pista_7F6B: Pista del reproductor: la entrada 32 de la tabla de
;   0x7C0B, o sea los sonidos con ese numero
;   0x7f6b..0x7f83  (24 bytes)
DATA_pista_7F6B:
	defb 023h,0c1h,027h,0c1h,09ah,0c1h,0c4h,0c2h,012h,0c2h,006h,0c2h,0f7h,0c3h,050h,0a3h	; 7f6b  #.'...........P.
	defb 0cfh,084h,030h,064h,0b5h,026h,045h,031h	; 7f7b  ..0d.&E1

; ----------------------------------------------------------------------
; DATOS relleno_final: 125 bytes a 0xFF hasta el final del cartucho
;   0x7f83..0x8000  (125 bytes)
DATA_relleno_final:
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7f83  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7f93  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7fa3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7fb3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7fc3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7fd3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7fe3  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7ff3  .............
