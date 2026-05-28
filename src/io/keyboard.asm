; ============================================================================================
; ARCHIVO: keyboard.asm
; USO: Rutinas de hardware y bucle principal de entrada (teclado) del juego.
;
; NOTA TÉCNICA: El ZX Spectrum usa LÓGICA NEGATIVA para el teclado:
;               BIT = 0 -> Tecla PULSADA
;               BIT = 1 -> Tecla NO pulsada
;
; MAPA DE TECLAS (Conecta 3 - 3 jugadores):
;   P1 (izquierdo):     Q=Arriba ($FBFE/D0), A=Abajo ($FDFE/D0), Z=Confirmar ($FEFE/D1)
;   P2 (centro-izq):    E=Arriba ($FBFE/D2), D=Abajo ($FDFE/D2), C=Confirmar ($FEFE/D3)
;   P3 (centro):        T=Arriba ($FBFE/D4), G=Abajo ($FDFE/D4), B=Confirmar ($7FFE/D4)
; ============================================================================================

; ============================================================================================
; 1. UTILIDADES DE HARDWARE
; ============================================================================================
; --------------------------------------------------------------------------------------------
; COLOR_BORDE_PANTALLA
; Pone el borde de la pantalla en blanco (7).
; --------------------------------------------------------------------------------------------
COLOR_BORDE_PANTALLA:
    LD A, 7
    OUT (254), A
    RET

; --------------------------------------------------------------------------------------------
; KEYBOARD_WAIT_RELEASE
; Espera hasta que todas las teclas de una fila sean soltadas (debounce).
;
; Entrada:  BC = puerto de la fila de teclado a monitorizar
; Salida:   -
; Modifica: AF
; --------------------------------------------------------------------------------------------
KEYBOARD_WAIT_RELEASE:
    IN A, (C)
    AND $1F                         ; Solo los 5 bits de teclas
    CP $1F                          ; $1F = todas sueltas (lógica negativa)
    JR NZ, KEYBOARD_WAIT_RELEASE
    RET

; ============================================================================================
; 2. LECTURA BLOQUEANTE (PARA MENÚS)
; ============================================================================================
; --------------------------------------------------------------------------------------------
; KEYBOARD_LEER_SN
; Detiene la ejecución hasta que el usuario pulsa 'S' o 'N'.
;
; Entrada:  -
; Salida:   A = 'S' o 'N'
; Modifica: AF, BC (BC preservado)
; --------------------------------------------------------------------------------------------
KEYBOARD_LEER_SN:
    PUSH BC

.CHECK_S:
    LD BC, $FDFE        ; Fila A,S,D,F,G - Bit 1 = 'S'
    IN A, (C)
    BIT 1, A
    JR Z, .S_PRESSED

.CHECK_N:
    LD BC, $7FFE        ; Fila Space,Sym,M,N,B - Bit 3 = 'N'
    IN A, (C)
    BIT 3, A
    JR NZ, .CHECK_S

.N_PRESSED:
    CALL KEYBOARD_WAIT_RELEASE
    LD A, 'N'
    POP BC
    RET

.S_PRESSED:
    CALL KEYBOARD_WAIT_RELEASE
    LD A, 'S'
    POP BC
    RET

; ============================================================================================
; 3. LECTURA NO BLOQUEANTE (POLLING PARA EL JUEGO)
; ============================================================================================
; --------------------------------------------------------------------------------------------
; KEYBOARD_POLL_PLAYER_MOVE
; Comprueba las teclas de movimiento vertical del jugador activo.
;
; Entrada:  (GUARDAR_JUGADOR_ACTUAL) - jugador activo (1, 2 o 3)
; Salida:   A = KEY_UP  si tecla arriba pulsada
;           A = KEY_DOWN si tecla abajo pulsada
;           A = 0       si ninguna tecla pulsada
; Modifica: AF, BC
; --------------------------------------------------------------------------------------------
KEYBOARD_POLL_PLAYER_MOVE:
    LD A, (GUARDAR_JUGADOR_ACTUAL)
    CP PLAYER_2
    JR Z, .CHECK_P2_KEYS
    CP PLAYER_3
    JR Z, .CHECK_P3_KEYS

.CHECK_P1_KEYS:
    ; P1: Q=Arriba ($FBFE/D0),  A=Abajo ($FDFE/D0)
    LD BC, $FBFE
    IN A, (C)
    BIT 0, A            ; Q = bit D0
    JR Z, .RET_UP

    LD BC, $FDFE
    IN A, (C)
    BIT 0, A            ; A = bit D0
    JR Z, .RET_DOWN
    JR .RET_NONE

.CHECK_P2_KEYS:
    ; P2: E=Arriba ($FBFE/D2),  D=Abajo ($FDFE/D2)
    LD BC, $FBFE
    IN A, (C)
    BIT 2, A            ; E = bit D2
    JR Z, .RET_UP

    LD BC, $FDFE
    IN A, (C)
    BIT 2, A            ; D = bit D2
    JR Z, .RET_DOWN
    JR .RET_NONE

.CHECK_P3_KEYS:
    ; P3: T=Arriba ($FBFE/D4),  G=Abajo ($FDFE/D4)
    LD BC, $FBFE
    IN A, (C)
    BIT 4, A            ; T = bit D4
    JR Z, .RET_UP

    LD BC, $FDFE
    IN A, (C)
    BIT 4, A            ; G = bit D4
    JR Z, .RET_DOWN

.RET_NONE:
    XOR A
    RET
.RET_UP:
    LD A, KEY_UP
    RET
.RET_DOWN:
    LD A, KEY_DOWN
    RET

; --------------------------------------------------------------------------------------------
; KEYBOARD_POLL_CONFIRM
; Comprueba si el jugador activo ha pulsado su tecla CONFIRMAR.
;
; Entrada:  (GUARDAR_JUGADOR_ACTUAL) - jugador activo (1, 2 o 3)
; Salida:   A = KEY_CONFIRM (13) si pulsada, A = 0 si no
; Modifica: AF, BC
; --------------------------------------------------------------------------------------------
KEYBOARD_POLL_CONFIRM:
    LD A, (GUARDAR_JUGADOR_ACTUAL)
    CP PLAYER_2
    JR Z, .CONFIRM_P2
    CP PLAYER_3
    JR Z, .CONFIRM_P3

.CONFIRM_P1:
    ; Z = $FEFE / bit D1
    LD BC, $FEFE
    IN A, (C)
    BIT 1, A
    JR NZ, .NO_CONFIRM
    JR .YES_CONFIRM

.CONFIRM_P2:
    ; C = $FEFE / bit D3
    LD BC, $FEFE
    IN A, (C)
    BIT 3, A
    JR NZ, .NO_CONFIRM
    JR .YES_CONFIRM

.CONFIRM_P3:
    ; B = $7FFE / bit D4
    LD BC, $7FFE
    IN A, (C)
    BIT 4, A
    JR NZ, .NO_CONFIRM

.YES_CONFIRM:
    LD A, KEY_CONFIRM
    RET
.NO_CONFIRM:
    XOR A
    RET

; --------------------------------------------------------------------------------------------
; KEYBOARD_WAIT_RELEASE_CONFIRM
; Espera a que el jugador activo suelte su tecla CONFIRMAR (debounce post-acción).
;
; Entrada:  (GUARDAR_JUGADOR_ACTUAL) - jugador activo (1, 2 o 3)
; Salida:   -
; Modifica: AF, BC
; --------------------------------------------------------------------------------------------
KEYBOARD_WAIT_RELEASE_CONFIRM:
    PUSH AF
    LD A, (GUARDAR_JUGADOR_ACTUAL)
    CP PLAYER_2
    JR Z, .WR_P2
    CP PLAYER_3
    JR Z, .WR_P3

.WR_P1:
    LD BC, $FEFE        ; Puerto de Z (P1 confirm)
    JR .DO_WAIT

.WR_P2:
    LD BC, $FEFE        ; Puerto de C (P2 confirm)
    JR .DO_WAIT

.WR_P3:
    LD BC, $7FFE        ; Puerto de B (P3 confirm)

.DO_WAIT:
    POP AF
    JP KEYBOARD_WAIT_RELEASE    ; Preserva AF ya recuperado

; --------------------------------------------------------------------------------------------
; KEYBOARD_POLL_F
; Comprueba si 'F' (salir del juego) está pulsada.
;
; Entrada:  -
; Salida:   A = 'F' o 0
; Modifica: AF, BC
; --------------------------------------------------------------------------------------------
KEYBOARD_POLL_F:
    LD BC, $FDFE        ; Fila A,S,D,F,G - Bit 3 = 'F'
    IN A, (C)
    BIT 3, A
    JR NZ, .NO_F
    LD A, 'F'
    RET
.NO_F:
    XOR A
    RET

; ============================================================================================
; 4. BUCLE PRINCIPAL DE ENTRADA (GAME INPUT LOOP)
; ============================================================================================
; Bucle ocupado (busy-loop) sin HALT. El temporizador de 16 bits controla la velocidad
; del movimiento vertical del preview para evitar desplazamiento demasiado rápido.
;
; Flujo: inicializar -> poll teclas -> gestionar movimiento/confirmación -> redibujar -> repetir

KEYBOARD_ActivarInput_Keys:
    CALL INPUT_Inicializar_Teclado  ; Prepara estado inicial y dibuja preview de P1

    ; Sincronizar PREVIOUS_ROW con la fila inicial
    LD A, (CURRENT_ROW)
    LD (PREVIOUS_ROW), A

    ; Inicializar temporizador de 16 bits a 0 (permite movimiento inmediato)
    LD HL, MOVE_COOLDOWN_TIMER
    XOR A
    LD (HL), A
    INC HL
    LD (HL), A

.LOOP:
    ; --- 1. GESTIÓN DEL TEMPORIZADOR DE COOLDOWN (16 bits) ---
    LD HL, MOVE_COOLDOWN_TIMER
    LD C, (HL)
    INC HL
    LD B, (HL)

    LD A, B
    OR C
    JR Z, .SKIP_COOLDOWN_DEC

    DEC BC
    LD HL, MOVE_COOLDOWN_TIMER
    LD (HL), C
    INC HL
    LD (HL), B

.SKIP_COOLDOWN_DEC:
    ; --- 2. SONDEO DE TECLAS DE MOVIMIENTO ---
    CALL KEYBOARD_POLL_PLAYER_MOVE

    CP KEY_UP
    JR Z, .HANDLE_UP_CONTINUOUS
    CP KEY_DOWN
    JR Z, .HANDLE_DOWN_CONTINUOUS

    ; --- 3. SONDEO DE CONFIRMAR Y SALIR ---
    CALL KEYBOARD_POLL_CONFIRM
    CP KEY_CONFIRM
    JP Z, .HANDLE_CONFIRM_PRESS

    CALL KEYBOARD_POLL_F
    CP 'F'
    JP Z, .HANDLE_F_PRESS

    JR .LOOP

; --------------------------------------------------------------------------------------------
; MANEJADORES DE MOVIMIENTO VERTICAL (ARRIBA y ABAJO)
; --------------------------------------------------------------------------------------------
.HANDLE_UP_CONTINUOUS:
    ; Recargar temporizador (BC destruido por KEYBOARD_POLL_PLAYER_MOVE)
    LD HL, MOVE_COOLDOWN_TIMER
    LD C, (HL)
    INC HL
    LD B, (HL)

    LD A, B
    OR C
    JR NZ, .CHECK_REDRAW        ; Timer activo -> no mover!!

    ; Timer = 0: mover si no estamos en la fila 0
    LD A, (CURRENT_ROW)
    OR A                        ; ¿Ya en fila 0?
    JR Z, .CHECK_REDRAW
    DEC A
    LD (CURRENT_ROW), A

    LD BC, MOVE_DELAY_FRAMES
    LD HL, MOVE_COOLDOWN_TIMER
    LD (HL), C
    INC HL
    LD (HL), B

    JR .CHECK_REDRAW

.HANDLE_DOWN_CONTINUOUS:
    LD HL, MOVE_COOLDOWN_TIMER
    LD C, (HL)
    INC HL
    LD B, (HL)

    LD A, B
    OR C
    JR NZ, .CHECK_REDRAW

    ; Timer = 0: mover si no estamos en la fila 5 (BOARD_ROWS - 1)
    LD A, (CURRENT_ROW)
    CP BOARD_ROWS - 1           ; ¿Ya en fila 5?
    JR Z, .CHECK_REDRAW
    INC A
    LD (CURRENT_ROW), A

    LD BC, MOVE_DELAY_FRAMES
    LD HL, MOVE_COOLDOWN_TIMER
    LD (HL), C
    INC HL
    LD (HL), B

    JR .CHECK_REDRAW

; --------------------------------------------------------------------------------------------
; RUTINA DE REDIBUJADO - Previene parpadeo comparando fila actual con la anterior
; --------------------------------------------------------------------------------------------
.CHECK_REDRAW:
    LD A, (CURRENT_ROW)         ; A = fila nueva
    LD B, A
    LD A, (PREVIOUS_ROW)        ; A = fila antigua
    CP B
    JR Z, .LOOP                 ; Sin cambio, no redibujar

    ; 1. Borrar preview en la posición ANTIGUA
    LD A, (PREVIOUS_ROW)
    LD (CURRENT_ROW), A         ; Temporalmente apuntamos a la fila antigua
    CALL ERASE_PREVIEW

    ; 2. Dibujar preview en la posición NUEVA
    LD A, B
    LD (CURRENT_ROW), A
    CALL DIBUJAR_FICHA_JUGADOR

    ; 3. Sincronizar PREVIOUS_ROW
    LD (PREVIOUS_ROW), A
    JP .LOOP

; --------------------------------------------------------------------------------------------
; MANEJADORES DE ACCIÓN (CONFIRMAR y F)
; Una sola acción por pulsación gracias a KEYBOARD_WAIT_RELEASE_CONFIRM.
; --------------------------------------------------------------------------------------------
.HANDLE_CONFIRM_PRESS:
    CALL KEYBOARD_WAIT_RELEASE_CONFIRM  ; Esperar a que el jugador suelte su tecla CONFIRM
    CALL ERASE_PREVIEW
    CALL COLOCAR_FICHA_EN_TABLERO       ; Lógica completa del turno (puede JP a GAME_End)

    ; Si el juego continúa, retorna aquí
    CALL DIBUJAR_FICHA_JUGADOR          ; Preview del siguiente jugador
    LD A, (CURRENT_ROW)
    LD (PREVIOUS_ROW), A                ; Sincronizar
    JP .LOOP

.HANDLE_F_PRESS:
    LD BC, $FDFE
    CALL KEYBOARD_WAIT_RELEASE
    JP GAME_End
