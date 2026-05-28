; ============================================================================================
; ARCHIVO: EndScreen.asm
; USO: Pantalla de fin de juego (Conecta 3).
;      Se llama desde input.asm (GAME_End).
;      Muestra el resultado (quién ganó o si fue empate) y pregunta si se desea
;      jugar de nuevo.
;
;      El color del texto del ganador se obtiene dinámicamente de PLAYER_COLORS,
;      por lo que cambia automáticamente si se modifican los EQU de color en constants.asm.
; ============================================================================================

END_SCREEN:
    ; 1. Inicialización de la pantalla
    CALL COMMON_INIT_SCREEN

    ; --- 2. MOSTRAR TÍTULO: "Se acabó el juego!" ---
    LD A, COLOR_ROJO_BLANCO_FLASH
    LD B, 1
    LD C, 7
    LD IX, GAME_OVER_MESSAGE
    CALL PRINTAT

    ; --- 3. MOSTRAR RESULTADO (Ganador o Empate) ---
    ; GAME_OVER_REASON: 0 = Empate, 1 = Gana P1, 2 = Gana P2, 3 = Gana P3
    LD A, (GAME_OVER_REASON)
    OR A
    JR Z, .PRINT_EMPATE         ; A = 0 -> Empate

    ; --- CASO GANADOR (A = 1, 2 o 3) ---
    ; 3a. Insertar número de jugador en WINNER_MESSAGE (posición 11 = 'X')
    ADD A, '0'                  ; Convierte 1/2/3 a '1'/'2'/'3' (ASCII)
    LD (WINNER_MESSAGE + 11), A

    ; 3b. Obtener el atributo de color del ganador desde PLAYER_COLORS
    ;     índice = GAME_OVER_REASON - 1  (0=P1, 1=P2, 2=P3)
    ;     El color cambia automáticamente si se modifica COLOR_JUGADOR_x en constants.asm
    LD A, (GAME_OVER_REASON)
    DEC A                       ; 1->0, 2->1, 3->2
    LD C, A
    LD B, 0
    LD HL, PLAYER_COLORS
    ADD HL, BC
    LD A, (HL)                  ; A = atributo completo del jugador ganador

    LD B, 10
    LD C, 4
    LD IX, WINNER_MESSAGE
    JR .DO_PRINT_RESULT

.PRINT_EMPATE:
    LD A, COLOR_INK_CIAN
    OR 64                       ; Cian brillante
    LD B, 10
    LD C, 4
    LD IX, EMPATE_MESSAGE

.DO_PRINT_RESULT:
    CALL PRINTAT

    ; --- 4. PREGUNTAR "¿Volver a jugar?" ---
    LD IX, EMPTY_MESSAGE
    LD IY, PLAY_AGAIN_MESSAGE_1
    JP COMMON_HANDLE_PLAY_RESPONSE
