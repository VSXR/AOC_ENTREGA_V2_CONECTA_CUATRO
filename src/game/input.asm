; ============================================================================================
; ARCHIVO: input.asm
; USO: Lógica principal del juego (Conecta 3 - Convocatoria Extraordinaria).
;      Gestiona la inicialización, el movimiento vertical de la ficha del jugador,
;      la animación de deslizamiento horizontal y la lógica de turnos, victorias y empates.
;
;      Mecánica: El jugador selecciona una FILA (movimiento vertical).
;                Al confirmar, la ficha desliza de izquierda a derecha hasta chocar.
; ============================================================================================

; ============================================================================================
; 1. INICIALIZACIÓN DE PARTIDA
; ============================================================================================
; --------------------------------------------------------------------------------------------
; INPUT_Inicializar_Teclado
; Prepara las variables de estado para una nueva partida.
; Se llama desde GAME_SCREEN antes del bucle principal de teclado.
;
; Entrada:  -
; Salida:   Variables de estado limpias, preview de P1 dibujada en fila 0
; Modifica: AF, BC, DE, HL (preservados con PUSH/POP)
; --------------------------------------------------------------------------------------------
INPUT_Inicializar_Teclado:
    PUSH AF: PUSH BC: PUSH DE: PUSH HL

    XOR A
    LD (TOTAL_FICHAS_PUESTAS), A    ; Reiniciar contador de fichas
    LD (CURRENT_ROW), A             ; Ficha flotante empieza en fila 0
    LD (GAME_OVER_REASON), A        ; 0 = en curso

    LD A, PLAYER_1
    LD (GUARDAR_JUGADOR_ACTUAL), A

    CALL DIBUJAR_FICHA_JUGADOR      ; Dibujar preview de P1

    POP HL: POP DE: POP BC: POP AF
    RET

; ============================================================================================
; 2. GESTIÓN VISUAL DE LA FICHA FLOTANTE (PREVIEW)
; ============================================================================================
; --------------------------------------------------------------------------------------------
; DIBUJAR_FICHA_JUGADOR
; Dibuja la ficha de preview del jugador activo en el lado IZQUIERDO del tablero,
; a la altura de la fila seleccionada (CURRENT_ROW).
;
; Entrada:  (CURRENT_ROW)            - fila seleccionada (0-5)
;           (GUARDAR_JUGADOR_ACTUAL) - jugador activo (1, 2 o 3)
; Salida:   Ficha de 16×16 dibujada en (Y = ROW*3+4,  X = 2)
; Modifica: AF, BC, DE, HL (preservados)
; --------------------------------------------------------------------------------------------
DIBUJAR_FICHA_JUGADOR:
    PUSH AF: PUSH BC: PUSH DE: PUSH HL

    ; Y = CURRENT_ROW * 3 + 4
    LD A, (CURRENT_ROW)
    LD C, A
    ADD A, A              ; A = ROW * 2
    ADD A, C              ; A = ROW * 3
    ADD A, 4              ; A = ROW * 3 + 4
    LD H, A               ; H = coordenada Y

    LD L, 0               ; L = X fijo (fuera del tablero: board empieza en L=3)

    ; Color: lookup en tabla PLAYER_COLORS (índice = jugador - 1)
    LD A, (GUARDAR_JUGADOR_ACTUAL)
    DEC A                 ; 1->0, 2->1, 3->2
    PUSH HL               ; preservar (Y, X)
    LD C, A
    LD B, 0
    LD HL, PLAYER_COLORS
    ADD HL, BC
    LD A, (HL)            ; A = atributo del jugador actual
    POP HL                ; restaurar (H=Y, L=X)

    CALL FICHAS_PintarFicha_AjustadaTablero

    POP HL: POP DE: POP BC: POP AF
    RET

; --------------------------------------------------------------------------------------------
; ERASE_PREVIEW
; Borra la ficha de preview del lado izquierdo del tablero.
; Las coordenadas son IDÉNTICAS a las de DIBUJAR_FICHA_JUGADOR.
;
; Entrada:  (CURRENT_ROW) - fila que se va a borrar
; Salida:   Ficha de 16×16 borrada (píxeles y atributo a 0)
; Modifica: AF, BC, DE, HL (preservados)
; --------------------------------------------------------------------------------------------
ERASE_PREVIEW:
    PUSH AF: PUSH BC: PUSH DE: PUSH HL

    LD A, (CURRENT_ROW)
    LD C, A
    ADD A, A
    ADD A, C
    ADD A, 4
    LD H, A               ; H = Y = ROW * 3 + 4
    LD L, 0               ; L = X = 0 (fijo, fuera del tablero azul)

    XOR A
    LD IX, MATRIZ_CIRCULO_PERMUTACIONES

    CALL FICHAS_PintarMatriz8x8     ; Arriba-Izquierda
    INC L
    CALL FICHAS_PintarMatriz8x8     ; Arriba-Derecha
    INC H
    CALL FICHAS_PintarMatriz8x8     ; Abajo-Derecha
    DEC L
    CALL FICHAS_PintarMatriz8x8     ; Abajo-Izquierda

    POP HL: POP DE: POP BC: POP AF
    RET

; --------------------------------------------------------------------------------------------
; ERASE_FICHA_16x16
; Rutina genérica para borrar una ficha de 16×16 en cualquier coordenada (H, L).
; Mantenida como utilidad para uso externo.
;
; Entrada:  H = fila char, L = columna char
; Salida:   Ficha de 16×16 borrada
; Modifica: AF, HL, IX (preservados)
; --------------------------------------------------------------------------------------------
ERASE_FICHA_16x16:
    PUSH AF: PUSH HL: PUSH IX

    XOR A
    LD IX, MATRIZ_CIRCULO_PERMUTACIONES

    CALL FICHAS_PintarMatriz8x8
    INC L
    CALL FICHAS_PintarMatriz8x8
    INC H
    CALL FICHAS_PintarMatriz8x8
    DEC L
    CALL FICHAS_PintarMatriz8x8

    POP IX: POP HL: POP AF
    RET

; ============================================================================================
; 3. LÓGICA PRINCIPAL DE JUEGO (COLOCACIÓN Y TURNOS)
; ============================================================================================
; --------------------------------------------------------------------------------------------
; COLOCAR_FICHA_EN_TABLERO
; Se llama al pulsar CONFIRM. Gestiona toda la lógica de un turno:
;   1. Busca la columna vacía más a la DERECHA en CURRENT_ROW (gravedad horizontal).
;   2. Si la fila está llena, muestra aviso visual y retorna sin hacer nada.
;   3. Guarda (LAST_ROW, LAST_COL) y actualiza BOARD_ARRAY.
;   4. Anima el deslizamiento izquierda -> derecha (X += 4 por columna).
;   5. Comprueba victoria (CHECK_WIN) o empate (42 fichas).
;   6. Avanza jugador: 1 -> 2 -> 3 -> 1.
;
; Entrada:  (CURRENT_ROW), (GUARDAR_JUGADOR_ACTUAL)
; Salida:   Estado actualizado. JP a GAME_End si fin de partida, RET si continúa.
; Modifica: AF, BC, DE, HL (preservados)
; Carry:    Solo uso interno (vía CHECK_WIN)
; --------------------------------------------------------------------------------------------
COLOCAR_FICHA_EN_TABLERO:
    PUSH AF: PUSH BC: PUSH DE: PUSH HL

    ; ======================================================
    ; 1. BUSCAR COLUMNA VACÍA (EMPEZANDO POR LA DERECHA)
    ; ======================================================
    ; La fila buscada es CURRENT_ROW (fija). Iteramos columnas 6 -> 0.
    ; Dirección de celda: BOARD_ARRAY + (CURRENT_ROW * 7) + columna

    LD B, BOARD_COLS - 1  ; B = 6 (columna más a la derecha = "fondo" horizontal)

.BUSCAR_COLUMNA_LIBRE_LOOP:
    ; Calcular índice en cada iteración (CURRENT_ROW puede leerse desde memoria)
    LD A, (CURRENT_ROW)
    LD C, A
    SLA A: SLA A: SLA A   ; A = ROW * 8
    SUB C                  ; A = ROW * 7
    ADD A, B               ; A = (ROW * 7) + columna_actual
    LD E, A
    LD D, 0
    LD HL, BOARD_ARRAY
    ADD HL, DE             ; HL -> BOARD_ARRAY[ROW][B]

    LD A, (HL)
    OR A                   ; ¿Vacía?
    JR Z, .CELDA_ENCONTRADA

    DEC B
    JP P, .BUSCAR_COLUMNA_LIBRE_LOOP  ; Si B >= 0, seguir

    ; Fila llena: aviso y retornar
    CALL UTIL_VISUAL_ERROR_FULL_ROW
    POP HL: POP DE: POP BC: POP AF
    RET

.CELDA_ENCONTRADA:
    ; ======================================================
    ; 2. ACTUALIZAR ESTADO
    ; ======================================================
    ; B = columna encontrada (0-6), HL = dirección de la celda
    LD A, (CURRENT_ROW)
    LD (LAST_ROW), A      ; Guardar fila de la jugada
    LD A, B
    LD (LAST_COL), A      ; Guardar columna de la jugada

    LD A, (GUARDAR_JUGADOR_ACTUAL)
    LD (HL), A            ; Escribir jugador en BOARD_ARRAY

    ; ======================================================
    ; 3. ANIMACIÓN DE DESLIZAMIENTO (IZQ -> DER)
    ; ======================================================
    ; 3.1. Obtener color del jugador sobre fondo azul (para pintar sobre tablero)
    ;      Lookup en PLAYER_COLORS_BOARD, índice = jugador - 1
    LD A, (GUARDAR_JUGADOR_ACTUAL)
    DEC A
    LD C, A
    LD B, 0
    LD HL, PLAYER_COLORS_BOARD
    ADD HL, BC
    LD A, (HL)            ; A = color sobre tablero azul

    PUSH AF               ; Guardar color para el bucle

    ; 3.2. Y fija = CURRENT_ROW * 3 + 4
    LD A, (CURRENT_ROW)
    LD C, A
    ADD A, A
    ADD A, C
    ADD A, 4
    LD H, A               ; H = Y (fija durante toda la animación)

    ; 3.3. X_final = LAST_COL * 4 + 4
    LD A, (LAST_COL)
    SLA A
    SLA A                 ; A = COL * 4
    ADD A, 4
    LD D, A               ; D = X_final

    LD E, 4               ; E = X_actual, empieza en la columna 0 del tablero (X=4)

.ANIMATION_LOOP:
    ; A. Dibujar ficha en (H=Y, L=X_actual)
    LD L, E
    POP AF
    PUSH AF
    CALL FICHAS_PintarFicha_AjustadaTablero

    ; B. Pausa
    LD BC, DROP_ANIM_DELAY
    CALL UTIL_Pausar

    ; C. ¿Llegamos al destino?
    LD A, E
    CP D
    JR Z, .SKIP_ERASE_AND_FINISH

    ; D. Borrar (redibujar hueco negro) y avanzar
    LD L, E
    LD A, COLOR_INK_NEGRO + COLOR_PAPER_AZUL
    CALL FICHAS_PintarFicha_AjustadaTablero

    LD A, E
    ADD A, 4              ; Siguiente columna lógica (+4 chars)
    LD E, A
    JR .ANIMATION_LOOP

.SKIP_ERASE_AND_FINISH:
    POP AF                ; Limpiar color del stack

    ; ======================================================
    ; 4. VERIFICAR VICTORIA
    ; ======================================================
    CALL CHECK_WIN
    JR C, .FIN_POR_VICTORIA

    ; ======================================================
    ; 5. VERIFICAR EMPATE
    ; ======================================================
    LD HL, TOTAL_FICHAS_PUESTAS
    INC (HL)
    LD A, (HL)
    CP 42
    JR Z, .FIN_POR_EMPATE

    ; ======================================================
    ; 6. CAMBIAR DE JUGADOR: 1 -> 2 -> 3 -> 1
    ; ======================================================
    LD A, (GUARDAR_JUGADOR_ACTUAL)
    INC A
    CP PLAYER_3 + 1       ; ¿Llegó a 4?
    JR NZ, .NO_WRAP
    LD A, PLAYER_1        ; Volver al jugador 1
.NO_WRAP:
    LD (GUARDAR_JUGADOR_ACTUAL), A

    POP HL: POP DE: POP BC: POP AF
    RET

.FIN_POR_VICTORIA:
    LD A, (GUARDAR_JUGADOR_ACTUAL)
    LD (GAME_OVER_REASON), A
    POP HL: POP DE: POP BC: POP AF
    JP GAME_End

.FIN_POR_EMPATE:
    XOR A
    LD (GAME_OVER_REASON), A
    POP HL: POP DE: POP BC: POP AF
    JP GAME_End

; ============================================================================================
; 4. FINALIZACIÓN
; ============================================================================================
; --------------------------------------------------------------------------------------------
; GAME_End
; Limpieza visual antes de saltar a la pantalla de resultados.
;
; Entrada:  -
; Salida:   JP a END_SCREEN (no retorna)
; --------------------------------------------------------------------------------------------
GAME_End:
    CALL ERASE_PREVIEW
    JP END_SCREEN
