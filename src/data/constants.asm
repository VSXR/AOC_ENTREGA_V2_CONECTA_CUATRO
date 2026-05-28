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
; Usados en portada.asm para dibujar el logo "C3".
; Derivados de los EQU de jugadores para coherencia con el resto del juego.
COLOR_CUADRADO_AMARILLO:    DB COLOR_JUGADOR_2 + (1*64)   ; = COLOR_JUGADOR_2 + bright
COLOR_CUADRADO_ROJO:        DB COLOR_JUGADOR_1 + (1*64)   ; = COLOR_JUGADOR_1 + bright

; ============================================================================================
; 3. CONFIGURACIÓN Y REGLAS DEL JUEGO
; ============================================================================================
; Dimensiones del Tablero
BOARD_ROWS:              EQU 6      ; 6 filas
BOARD_COLS:              EQU 7      ; 7 columnas

; Identificadores de Estado de Celda (en BOARD_ARRAY)
EMPTY_CELL:              EQU 0      ; Celda vacía
PLAYER_1:                EQU 1      ; Ficha J1
PLAYER_2:                EQU 2      ; Ficha J2
PLAYER_3:                EQU 3      ; Ficha J3

; Condición de victoria - ÚNICO PUNTO DE CONTROL
WIN_LENGTH:              EQU 3      ; Fichas en raya para ganar

; --- Colores por jugador - CAMBIAR AQUÍ AFECTA TODO EL JUEGO (extra rúbrica) ---
; Valores ink: 0=Negro, 1=Azul, 2=Rojo, 3=Magenta, 4=Verde, 5=Cian, 6=Amarillo, 7=Blanco
COLOR_JUGADOR_1:         EQU COLOR_INK_ROJO      ; 2
COLOR_JUGADOR_2:         EQU COLOR_INK_AMARILLO  ; 6
COLOR_JUGADOR_3:         EQU COLOR_INK_CIAN      ; 5

; Tabla de atributos derivada automáticamente: ink + bright (64)
; Indexada 0-based: índice 0 = P1, 1 = P2, 2 = P3
PLAYER_COLORS:
    DB COLOR_JUGADOR_1 + (1*64)     ; P1: tinta J1 + brillante
    DB COLOR_JUGADOR_2 + (1*64)     ; P2: tinta J2 + brillante
    DB COLOR_JUGADOR_3 + (1*64)     ; P3: tinta J3 + brillante

; Tabla de atributos con fondo azul (para animación sobre tablero)
PLAYER_COLORS_BOARD:
    DB COLOR_JUGADOR_1 + COLOR_PAPER_AZUL   ; P1 sobre tablero azul
    DB COLOR_JUGADOR_2 + COLOR_PAPER_AZUL   ; P2 sobre tablero azul
    DB COLOR_JUGADOR_3 + COLOR_PAPER_AZUL   ; P3 sobre tablero azul

; --- Control de Velocidad (para bucle sin HALT) ---
; Cuanto más alto el valor, más lento será el movimiento.
MOVE_DELAY_FRAMES        EQU 1500   ; Pausa (16 bits) para movimiento ARRIBA/ABAJO
DROP_ANIM_DELAY          EQU 5500   ; Pausa (16 bits) para animación de deslizamiento

; ============================================================================================
; 4. CONTROLES (CÓDIGOS ASCII)
; ============================================================================================
; Teclas de menú
KEY_S:                   EQU 'S'    ; Confirmar Sí
KEY_N:                   EQU 'N'    ; Confirmar No
KEY_F:                   EQU 'F'    ; Salir del juego (en partida)

; Códigos internos de movimiento/acción (no corresponden a teclas físicas directas)
KEY_UP:                  EQU 'U'    ; Señal interna: mover preview arriba
KEY_DOWN:                EQU 'D'    ; Señal interna: mover preview abajo
KEY_CONFIRM:             EQU 13     ; Señal interna: confirmar colocación

; --- Mapa de teclas físicas por jugador ---
; P1 - lado izquierdo del teclado
;   ARRIBA:   Q  -> puerto $FBFE, bit D0
;   ABAJO:    A  -> puerto $FDFE, bit D0
;   CONFIRMAR:Z  -> puerto $FEFE, bit D1
;
; P2 - centro-izquierda del teclado
;   ARRIBA:   E  -> puerto $FBFE, bit D2
;   ABAJO:    D  -> puerto $FDFE, bit D2
;   CONFIRMAR:C  -> puerto $FEFE, bit D3
;
; P3 - centro del teclado
;   ARRIBA:   T  -> puerto $FBFE, bit D4
;   ABAJO:    G  -> puerto $FDFE, bit D4
;   CONFIRMAR:B  -> puerto $7FFE, bit D4

; ============================================================================================
; 5. TEXTOS Y MENSAJES (Terminados en 0)
; ============================================================================================
WELCOME_MESSAGE:         DB "Bienvenido al Conecta 3", 0
PLAY_MESSAGE_1:          DB "Quieres jugar? ", 0
GAME_OVER_MESSAGE:       DB "Se acabo el juego!", 0
PLAY_AGAIN_MESSAGE_1:    DB "Volver a jugar? ", 0
CONFIRMATION_MESSAGE_SN: DB "(S / N): ", 0
BYE_MESSAGE:             DB "Hasta pronto!", 0
EMPTY_MESSAGE:           DB 0                 ; Puntero nulo para título opcional en common.asm

; Nota: El dígito en el índice 11 se sobrescribe dinámicamente en EndScreen.asm
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
