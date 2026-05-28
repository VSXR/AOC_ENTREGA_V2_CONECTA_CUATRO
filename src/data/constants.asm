; ============================================================================================
; ARCHIVO: constants.asm
; USO: Constantes inmutables del juego (configuración, textos, gráficos)
;      Valores definidos con EQU (constante) o DB (Data Bytes)
; ============================================================================================

; ============================================================================================
; 1. CONSTANTES DE COLOR (ATRIBUTOS ZX SPECTRUM)
; ============================================================================================
; Formato Atributo (8 bits): INK + (PAPER*8) + (BRIGHT*64) + (FLASH*128)
; Donde:
; B = Bright (1=Brillante), F = Flash (1=Parpadeo)
; P = Paper (Color de fondo, 0-7)
; I = Ink (Color de tinta, 0-7)
;
; Valores base INK/PAPER: 0=Negro, 1=Azul, 2=Rojo, 3=Magenta, 4=Verde, 5=Cian, 6=Amarillo, 7=Blanco
; Valores base BRIGHT/FLASH: 0=Apagado, 1=Encendido

; Valores base (0=Negro, 1=Azul, 2=Rojo, 3=Magenta, 4=Verde, 5=Cian, 6=Amarillo, 7=Blanco)
COLOR_INK_NEGRO:         EQU 0
COLOR_INK_AZUL:          EQU 1
COLOR_INK_ROJO:          EQU 2
COLOR_INK_MAGENTA:       EQU 3
COLOR_INK_VERDE:         EQU 4
COLOR_INK_CIAN:          EQU 5
COLOR_INK_AMARILLO:      EQU 6
COLOR_INK_BLANCO:        EQU 7

; --- Atributos Compuestos Usados en el Juego ---
; Título (StartScreen)
COLOR_AMARILLO_NEGRO:    EQU COLOR_INK_AMARILLO + (0*8) + (1*64)    ; Tinta: Amarillo Brillante, Fondo: Negro

; Título (EndScreen) y Prompt (common.asm)
COLOR_ROJO_BLANCO_FLASH: EQU COLOR_INK_ROJO + (7*8) + (1*64) + 128  ; Tinta: Rojo Brillante, Fondo: Blanco, Parpadeo
COLOR_NEGRO_BLANCO:      EQU COLOR_INK_NEGRO + (7*8)                ; Tinta: Negro, Fondo: Blanco

; Fondo del Tablero (tablero.asm)
COLOR_PAPER_AZUL:        EQU (1*8)                                  ; Tinta: (Cualquiera), Fondo: Azul
COLOR_PAPER_AZUL_BRT:    EQU (1*8) + (1*64)                         ; Tinta: (Cualquiera), Fondo: Azul Brillante

; ============================================================================================
; 2. VARIABLES DE COLOR (para Portada)
; ============================================================================================
; Estas variables se cargan en portada.asm para dibujar el "C4".
; Atributo: Tinta Amarilla (6) + Fondo Negro (0) + Brillante (64) = 70 = $46
COLOR_CUADRADO_AMARILLO:    DB $46

; Atributo: Tinta Roja (2) + Fondo Negro (0) + Brillante (64) = 66 = $42
COLOR_CUADRADO_ROJO:        DB $42

; ============================================================================================
; 3. CONFIGURACIÓN Y REGLAS DEL JUEGO
; ============================================================================================
; Dimensiones del Tablero
BOARD_ROWS:              EQU 6      ; 6 filas
BOARD_COLS:              EQU 7      ; 7 columnas

; Identificadores de Estado de Celda (en BOARD_ARRAY)
EMPTY_CELL:              EQU 0      ; Celda vacía
PLAYER_1:                EQU 1      ; Ficha Roja
PLAYER_2:                EQU 2      ; Ficha Amarilla

; --- Control de Velocidad (para bucle sin HALT) ---
; Cuanto más alto el valor, más lento será el movimiento.
MOVE_DELAY_FRAMES        EQU 1500   ; Pausa (16 bits) para movimiento IZQ/DRCHA
DROP_ANIM_DELAY          EQU 5500   ; Pausa (16 bits) para animación de caída de ficha

; ============================================================================================
; 4. CONTROLES (CÓDIGOS ASCII)
; ============================================================================================
KEY_S:                   EQU 'S'    ; Confirmar Sí
KEY_N:                   EQU 'N'    ; Confirmar No
KEY_Q:                   EQU 'Q'    ; Mover Izquierda
KEY_W:                   EQU 'W'    ; Mover Derecha
KEY_F:                   EQU 'F'    ; Salir del juego (en partida)
KEY_ENTER:               EQU 13     ; Colocar Ficha

; ============================================================================================
; 5. TEXTOS Y MENSAJES (Terminados en 0)
; ============================================================================================
WELCOME_MESSAGE:         DB "Bienvenido al Conecta 4", 0
PLAY_MESSAGE_1:          DB "Quieres jugar? ", 0
GAME_OVER_MESSAGE:       DB "Se acabo el juego!", 0
PLAY_AGAIN_MESSAGE_1:    DB "Volver a jugar? ", 0
CONFIRMATION_MESSAGE_SN: DB "(S / N): ", 0
BYE_MESSAGE:             DB "Hasta pronto!", 0
EMPTY_MESSAGE:           DB 0                 ; Puntero nulo para título opcional en common.asm

; Nota: La 'X' está en el índice 11, se sobrescribe en EndScreen.asm
WINNER_MESSAGE:          DB "El jugador X ha ganado!", 0
EMPATE_MESSAGE:          DB "Habeis quedado en empate!", 0

; ============================================================================================
; 6. RECURSOS GRÁFICOS (MATRICES 8x8)
; ============================================================================================
; 6.1. Bloques Sólidos/Vacíos (para borrar o rellenar)
MATRIZ_SOLIDA_8x8:
    DB %11111111, %11111111, %11111111, %11111111, %11111111, %11111111, %11111111, %11111111
MATRIZ_NEGRA_8x8:
    DB %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
; Usada por ERASE_PREVIEW para borrar la ficha flotante
MATRIZ_CIRCULO_PERMUTACIONES: ; Matriz vacía (alias de MATRIZ_NEGRA_8x8)
    DB %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000

; 6.2. Huecos del Tablero (Círculo VACÍO)
MATRIZ_CIRCULO_ARRIBA_IZQUIERDA:
    DB %11111000, %11100000, %11000000, %10000000, %10000000, %00000000, %00000000, %00000000
MATRIZ_CIRCULO_ARRIBA_DERECHA:
    DB %00011111, %00000111, %00000011, %00000001, %00000001, %00000000, %00000000, %00000000
MATRIZ_CIRCULO_ABAJO_IZQUIERDA:
    DB %00000000, %00000000, %00000000, %10000000, %10000000, %11000000, %11100000, %11111000
MATRIZ_CIRCULO_ABAJO_DERECHA:
    DB %00000000, %00000000, %00000000, %00000001, %00000001, %00000011, %00000111, %00011111

; 6.3. Fichas de Jugador (Círculo RELLENO)
; (Usado por 'fichas.asm' para portada y juego)
MATRIZ_CIRCULO_ARRIBA_IZQUIERDA_FICHA:
    DB %00000111, %00011111, %00111111, %01111111, %01111111, %11111111, %11111111, %11111111
MATRIZ_CIRCULO_ARRIBA_DERECHA_FICHA:
    DB %11100000, %11111000, %11111100, %11111110, %11111110, %11111111, %11111111, %11111111
MATRIZ_CIRCULO_ABAJO_IZQUIERDA_FICHA:
    DB %11111111, %11111111, %11111111, %01111111, %01111111, %00111111, %00011111, %00000111
MATRIZ_CIRCULO_ABAJO_DERECHA_FICHA:
    DB %11111111, %11111111, %11111111, %11111110, %11111110, %11111100, %11111000, %11100000