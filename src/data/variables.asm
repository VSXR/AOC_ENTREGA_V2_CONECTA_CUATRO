; ============================================================================================
; ARCHIVO: variables.asm
; USO: Define el espacio en memoria para variables MUTABLES (que cambian)
;      para el estado del juego Conecta 4.
; ============================================================================================

; ============================================================================================
; 1. BUFFERS DE TEXTO
; ============================================================================================
; Buffer de 2 bytes para el eco de S/N en common.asm (1 char + 0 terminador)
MESSAGE_KEY_SN:          DB 0, 0

; ============================================================================================
; 2. ESTADO DEL JUEGO (GAME STATE)
; ============================================================================================
GUARDAR_JUGADOR_ACTUAL:  DB 0           ; Jugador activo (1 = P1, 2 = P2)
CURRENT_COLUMN:          DB 0           ; Columna (0-6) de la ficha flotante
PREVIOUS_COLUMN:         DB 0           ; Columna (0-6) en el frame anterior (para evitar parpadeo)
TOTAL_FICHAS_PUESTAS:    DB 0           ; Contador de fichas (0-42) para detectar empate

; --- Variables para la comprobación de victoria ---
LAST_ROW:                DB 0           ; Fila (0-5) de la última ficha colocada
LAST_COL:                DB 0           ; Columna (0-6) de la última ficha colocada

; --- Temporizador de Cooldown ---
; DW (Define Word) = 16 bits (0-65535)
; Se usa en keyboard.asm para el retraso de movimiento IZQ/DRCHA
MOVE_COOLDOWN_TIMER:     DW 0

; --- Estado de Fin de Juego ---
; (0 = Juego en curso o Empate, 1 = Gana P1, 2 = Gana P2)
GAME_OVER_REASON:        DB 0

; --- Tablero Lógico ---
; Define 42 bytes (6 filas * 7 columnas) de memoria, todos inicializados a 0.
BOARD_ARRAY:
    DEFB 0,0,0,0,0,0,0   ; Fila 0
    DEFB 0,0,0,0,0,0,0   ; Fila 1
    DEFB 0,0,0,0,0,0,0   ; Fila 2
    DEFB 0,0,0,0,0,0,0   ; Fila 3
    DEFB 0,0,0,0,0,0,0   ; Fila 4
    DEFB 0,0,0,0,0,0,0   ; Fila 5

; --- Input / Keyboard variables ---
KEY_MASK_Q      EQU %00000001   ; Bit 0
KEY_MASK_W      EQU %00000010   ; Bit 1
KEY_MASK_R      EQU %00001000   ; Bit 3
KEY_MASK_T      EQU %00010000   ; Bit 4
KEY_MASK_ENTER  EQU %00000001   ; Bit 0 en puerto &8BFE