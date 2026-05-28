; ============================================================================================
; ARCHIVO: input.asm
; USO: Lógica principal del juego.
;      Gestiona la inicialización, el movimiento de la ficha del jugador,
;      la animación de caída y la lógica de turnos, victorias y empates.
; ============================================================================================

; ============================================================================================
; 1. INICIALIZACIÓN DE PARTIDA
; ============================================================================================
; --------------------------------------------------------------------------------------------
; INPUT_Inicializar_Teclado
; Prepara las variables de estado para una nueva partida.
; Se llama desde GAME_SCREEN.
; --------------------------------------------------------------------------------------------
INPUT_Inicializar_Teclado:
    PUSH AF: PUSH BC: PUSH DE: PUSH HL
    
    ; Poner a 0 las variables de estado
    XOR A
    LD (TOTAL_FICHAS_PUESTAS), A    ; Reiniciar contador de fichas (0 de 42)
    LD (CURRENT_COLUMN), A          ; Poner la ficha flotante en la columna 0
    LD (GAME_OVER_REASON), A        ; Borrar la razón del fin de juego (0 = En curso)

    ; Establecemos al Jugador 1 como el primero en jugar (osea, la ficha roja)
    LD A, PLAYER_1
    LD (GUARDAR_JUGADOR_ACTUAL), A
    
    ; Dibujamos la primera ficha del jugador en la pantalla
    CALL DIBUJAR_FICHA_JUGADOR
    
    POP HL: POP DE: POP BC: POP AF
    RET

; ============================================================================================
; 2. GESTIÓN VISUAL DE LA FICHA FLOTANTE (PREVIEW)
; ============================================================================================
; --------------------------------------------------------------------------------------------
; DIBUJAR_FICHA_JUGADOR
; Dibuja la ficha flotante del jugador en la parte superior de la pantalla.
; Lee la columna actual (CURRENT_COLUMN) y el jugador actual (GUARDAR_JUGADOR_ACTUAL).
; --------------------------------------------------------------------------------------------
DIBUJAR_FICHA_JUGADOR:
    PUSH AF: PUSH BC: PUSH DE: PUSH HL

    ; --- Calcular Coordenada X (Columna) ---
    ; OJO: Acordarse de que la lógica debe coincidir con la cuadrícula del tablero para que
    ; la ficha quede centrada en la columna correcta!!
    LD A, (CURRENT_COLUMN)
    SLA A                       ; A = Columna * 2
    SLA A                       ; A = Columna * 4
    ADD A, 4                    ; Offset X del tablero = 4
    LD L, A                     ; L = Coordenada X final

    ; --- Calcular Coordenada Y (Fila) ---
    LD H, 1                     ; Fila Y fija (arriba del tablero)
    
    ; --- Determinar Color ---
    LD A, (GUARDAR_JUGADOR_ACTUAL)
    CP PLAYER_1
    JR Z, .SET_COLOR_P1
    
    ; Si no es P1, es P2 (Amarillo)
    LD A, COLOR_INK_AMARILLO
    JR .DRAW_NOW
.SET_COLOR_P1:
    LD A, COLOR_INK_ROJO        ; P1 es Rojo (Jugador 1)

.DRAW_NOW:
    ; Pintar la ficha de 16x16
    CALL FICHAS_PintarFicha_AjustadaTablero ; (Usamos esta para asegurar consistencia de matriz)
    POP HL: POP DE: POP BC: POP AF
    RET

; --------------------------------------------------------------------------------------------
; ERASE_PREVIEW
; Borra la ficha del jugador en la parte superior de la pantalla.
; Es la operación inversa a DIBUJAR_FICHA_JUGADOR.
; --------------------------------------------------------------------------------------------
ERASE_PREVIEW:
    PUSH AF: PUSH BC: PUSH DE: PUSH HL

    ; --- Calcular Coordenada X (Debe ser IDÉNTICA a DIBUJAR_FICHA_JUGADOR) ---
    LD A, (CURRENT_COLUMN)
    SLA A
    SLA A
    ADD A, 4
    LD L, A
    LD H, 1                     ; Fila Y fija

    ; --- Borrar con Píxeles Vacíos ---
    XOR A                                   ; Atributo 0 (Negro/Negro/Transparente)
    LD IX, MATRIZ_CIRCULO_PERMUTACIONES     ; Carga la matriz 8x8 vacía (todo 0s)
    
    ; Pinta los 4 cuadrantes vacíos, borrando la ficha de 16x16
    CALL FICHAS_PintarMatriz8x8
    INC L
    CALL FICHAS_PintarMatriz8x8
    INC H
    CALL FICHAS_PintarMatriz8x8
    DEC L
    CALL FICHAS_PintarMatriz8x8

    POP HL: POP DE: POP BC: POP AF
    RET

; --------------------------------------------------------------------------------------------
; ERASE_FICHA_16x16
; Rutina genérica para borrar una ficha en CUALQUIER coordenada (H, L).
; NOTA: La animación de caída ya NO usa esta rutina, pero se mantiene como utilidad.
; --------------------------------------------------------------------------------------------
ERASE_FICHA_16x16:
    PUSH AF: PUSH HL: PUSH IX

    XOR A                               ; Atributo 0 (Negro/Transparente)
    LD IX, MATRIZ_CIRCULO_PERMUTACIONES ; Matriz 8x8 vacía

    ; Pintar los 4 cuadrantes con la matriz vacía
    CALL FICHAS_PintarMatriz8x8     ; Arriba-Izquierda
    INC L
    CALL FICHAS_PintarMatriz8x8     ; Arriba-Derecha
    INC H
    CALL FICHAS_PintarMatriz8x8     ; Abajo-Derecha
    DEC L
    CALL FICHAS_PintarMatriz8x8     ; Abajo-Izquierda

    POP IX: POP HL: POP AF
    RET

; ============================================================================================
; 3. LÓGICA PRINCIPAL DE JUEGO (COLOCACIÓN Y TURNOS)
; ============================================================================================
; --------------------------------------------------------------------------------------------
; COLOCAR_FICHA_EN_TABLERO
; Se llama al pulsar ENTER. Gestiona toda la lógica de un turno:
; 1. Encuentra la celda vacía más baja en la columna seleccionada.
; 2. Si la columna está llena, retorna sin hacer nada.
; 3. Guarda la posición (fila, col) y actualiza el tablero lógico (BOARD_ARRAY).
; 4. Lanza la animación de caída.
; 5. Comprueba si hay victoria o empate.
; 6. Si el juego sigue, cambia de jugador.
; --------------------------------------------------------------------------------------------
COLOCAR_FICHA_EN_TABLERO:
    PUSH AF: PUSH BC: PUSH DE: PUSH HL

    ; --- 1. BUSCAR CELDA VACÍA (DE ABAJO HACIA ARRIBA) ---
    LD B, BOARD_ROWS - 1        ; B = 5 (Fila lógica inferior)

.BUSCAR_FILA_LIBRE_LOOP:
    ; Calcular dirección de memoria de (Fila B, Columna C)
    LD A, B                     ; A = Fila (B)
    LD D, A
    SLA A: SLA A: SLA A         ; A = B * 8
    SUB D                       ; A = B * 7 (A = B*8 - B)
    LD D, A                     ; D = Offset de Fila
    LD A, (CURRENT_COLUMN)      ; A = Columna
    ADD A, D                    ; A = (Fila * 7) + Columna
    LD E, A
    LD D, 0
    LD HL, BOARD_ARRAY
    ADD HL, DE                  ; HL = Dirección de la celda en BOARD_ARRAY
    
    ; Comprobar si la celda está vacía
    LD A, (HL)                  ; A = Valor de la celda (0, 1 o 2)
    OR A                        ; Comprobar si A es 0
    JR Z, .CELDA_ENCONTRADA     ; Si es 0, hemos encontrado la celda
    
    ; Si no está vacía, comprobar la celda de arriba
    DEC B
    JP P, .BUSCAR_FILA_LIBRE_LOOP ; Si B >= 0 (Positivo), seguir buscando
    
    ; Si el bucle termina (B<0), la columna estaba llena.
    CALL UTIL_VISUAL_ERROR_FULL_COLUMN
    POP HL: POP DE: POP BC: POP AF
    RET                         ; Retornar sin hacer nada

.CELDA_ENCONTRADA:
    ; --- 2. ACTUALIZAR ESTADO DEL JUEGO ---
    
    ; Guardar la posición de la jugada para la comprobación de victoria
    LD A, B
    LD (LAST_ROW), A            ; Guardamos Fila (0-5)
    LD A, (CURRENT_COLUMN)
    LD (LAST_COL), A            ; Guardamos Columna (0-6)

    ; Escribir el jugador (1 o 2) en el tablero lógico
    LD A, (GUARDAR_JUGADOR_ACTUAL)
    LD (HL), A

    ; Preparar el color de la ficha para la animación (con fondo azul)
    CP PLAYER_1
    JR Z, .COLOR_P1_FINAL
    LD A, COLOR_INK_AMARILLO + COLOR_PAPER_AZUL
    JR .CALC_COORDS_FINAL
.COLOR_P1_FINAL:
    LD A, COLOR_INK_ROJO + COLOR_PAPER_AZUL

.CALC_COORDS_FINAL:
    ; --- 3. INICIA LÓGICA DE ANIMACIÓN DE CAÍDA DE LA FICHA DE LOS JUGADORES (HUECO A HUECO) ---
    ; 3.1. Guardar Color (A) y Calcular Columna Final de pantalla (L)
    PUSH AF                     ; Guardamos el color (ej: ROJO + AZUL)
    
    LD A, (CURRENT_COLUMN)
    SLA A
    SLA A
    ADD A, 4                    ; Offset X del tablero
    LD L, A                     ; L = Coordenada X (se mantendrá constante)
    
    ; 3.2. Calcular Fila Final de pantalla (D = H_final)
    LD A, B                     ; B = Fila lógica (0-5) donde cayó
    LD C, A
    ADD A, A                    ; A = B*2
    ADD A, C                    ; A = B*3
    ADD A, 4                    ; Offset Y del tablero (Fila lógica 0 empieza en Y=4)
    LD D, A                     ; D = Coordenada Y final

    ; 3.3. Bucle de Animación
    LD E, 4                     ; E = Coordenada Y actual, empieza en Y=4 (1a fila lógica)

.ANIMATION_LOOP:
    ; --- A. Dibujar (Ficha del Jugador) ---
    LD H, E                     ; H = Fila Actual
    POP AF                      ; Recupera el Color
    PUSH AF                     ; Guárdalo de nuevo para el próximo bucle
    CALL FICHAS_PintarFicha_AjustadaTablero ; Dibuja la ficha

    ; --- B. Pausa (Controla la velocidad de caída) ---
    LD BC, DROP_ANIM_DELAY      ; Carga el delay (su delay en constants.asm es de 5500ms / FPS)
    CALL UTIL_Pausar

    ; --- C. Comprobar si es la última fila ---
    LD A, E
    CP D                        ; ¿Es Fila Actual (E) == Fila Final (D)?
    JR Z, .SKIP_ERASE_AND_FINISH ; Si SÍ, saltar (dejar la ficha dibujada)

    ; --- D. Borrar (Redibujar el HUECO NEGRO) ---
    ; (Solo se ejecuta si NO es la última fila)
    LD H, E                                     ; H = Fila Actual (L ya está cargado)
    LD A, COLOR_INK_NEGRO + COLOR_PAPER_AZUL    ; Color del hueco
    CALL FICHAS_PintarFicha_AjustadaTablero     ; Redibuja el hueco negro del tablero donde iran fichas que aun no se han colocado

    ; --- E. Incrementar y Repetir ---
    LD A, E
    ADD A, 3                    ; Salta 3 filas de pantalla (1 fila lógica)
    LD E, A                     
    JR .ANIMATION_LOOP          ; Repetir

.SKIP_ERASE_AND_FINISH:
    ; La ficha final ya está dibujada, solo limpiamos el color del stack
    POP AF
    ; --- FIN LÓGICA DE ANIMACIÓN ---

    ; ======================================================
    ; 4. VERIFICAR VICTORIA
    ; ======================================================
    CALL CHECK_WIN                  ; Llama a logic.asm
    JR C, .FIN_POR_VICTORIA         ; Si Carry=1 (victoria), saltar

    ; ======================================================
    ; 5. VERIFICAR EMPATE
    ; ======================================================
    LD HL, TOTAL_FICHAS_PUESTAS
    INC (HL)                        ; Incrementar contador de fichas
    LD A, (HL)
    CP 42                           ; ¿Hemos puesto 42 fichas?
    JR Z, .FIN_POR_EMPATE           ; Si sí, es empate

    ; ======================================================
    ; 6. CAMBIAR DE JUGADOR (SI NO HAY VICTORIA NI EMPATE)
    ; ======================================================
    LD A, (GUARDAR_JUGADOR_ACTUAL)
    XOR 3                           ; OJO: Acordarse de truco para alternar jugadores: 1^3 = 2, 2^3 = 1
    LD (GUARDAR_JUGADOR_ACTUAL), A
    POP HL: POP DE: POP BC: POP AF
    RET                             ; Volver al bucle de teclado

; --- RUTINAS DE FIN DE JUEGO ---
.FIN_POR_VICTORIA:
    LD A, (GUARDAR_JUGADOR_ACTUAL)  ; Carga al jugador ganador (1 o 2)
    LD (GAME_OVER_REASON), A        ; Guardar como la razón del fin
    POP HL: POP DE: POP BC: POP AF
    JP GAME_End                     ; Saltar a la limpieza final

.FIN_POR_EMPATE:
    XOR A                           ; A = 0 (Código para Empate)
    LD (GAME_OVER_REASON), A        ; Guardar como la razón del fin
    POP HL: POP DE: POP BC: POP AF
    JP GAME_End                     ; Saltar a la limpieza final

; ============================================================================================
; 4. FINALIZACIÓN
; ============================================================================================
; --------------------------------------------------------------------------------------------
; GAME_End
; Limpieza visual antes de saltar a la pantalla de resultados (END_SCREEN).
; --------------------------------------------------------------------------------------------
GAME_End:
    CALL ERASE_PREVIEW              ; Borrar la ficha flotante
    JP END_SCREEN                   ; Saltar a la pantalla de "Fin de Juego"