; ============================================================================================
; ARCHIVO: GameScreen.asm
; USO: Prepara e inicia una nueva partida.
;      Limpia la pantalla, reinicia el tablero lógico (array de memoria),
;      dibuja el tablero gráfico y cede el control al bucle de juego.
; ============================================================================================

GAME_SCREEN:
    ; 1. Inicialización de la pantalla
    CALL COMMON_INIT_SCREEN    

    ; --- 2. Reinicio del Tablero Lógico (BOARD_ARRAY) ---
    ; Pone a 0 (EMPTY_CELL) las 42 celdas del tablero en la memoria RAM.
    LD HL, BOARD_ARRAY          ; HL = Dirección de inicio del tablero
    LD B, 42                    ; B = Contador (42 bytes/celdas)
    XOR A                       ; A = 0 (valor para celda vacía)
.RESET_MEMORY_LOOP:
    LD (HL), A                  ; Escribir 0 en la celda
    INC HL                      ; Siguiente dirección de memoria
    DJNZ .RESET_MEMORY_LOOP     ; Repetir 42 veces

    ; --- 3. Reinicio de Variables de Estado de la Partida ---
    LD A, PLAYER_1
    LD (GUARDAR_JUGADOR_ACTUAL), A ; El Jugador 1 siempre empieza
    
    XOR A
    LD (CURRENT_ROW), A         ; Ficha flotante empieza en fila 0 (INPUT_Inicializar_Teclado la reseteará también)

    ; --- 4. Dibujado inicial y Ceder Control ---
    ; Dibuja el tablero azul vacío con los 42 huecos negros.
    CALL TABLERO_DibujarTableroCompleto
    
    ; Esta rutina (GAME_SCREEN) no se ejecutará más hasta que se inicie
    ; una nueva partida desde la pantalla final.
    JP KEYBOARD_ActivarInput_Keys