; ============================================================================================
; ARCHIVO: tablero.asm
; USO: Dibuja el tablero gráfico del juego "Conecta 4".
; ============================================================================================

; ============================================================================================
; FUNCIÓN PRINCIPAL: TABLERO_DibujarTableroCompleto
; Dibuja el tablero de juego completo: un gran fondo azul y 42 huecos negros
; (que son en realidad fichas negras) para crear la cuadrícula.
; ============================================================================================
TABLERO_DibujarTableroCompleto:
    PUSH AF: PUSH BC: PUSH DE: PUSH HL: PUSH IX
    CALL CLEARSCR

    ; === PASO 1: Pintar fondo azul completo (19x29) ===
    LD H, 3                             ; Fila inicial (Y)
    LD L, 3                             ; Columna inicial (X)
    LD B, 19                            ; Alto (19 filas de caracteres)
    LD C, 28                            ; Ancho (28 columnas de caracteres)
    LD A, COLOR_PAPER_AZUL              ; Color de atributo (Fondo Azul)
    CALL TABLERO_RellenarRectAtributo   ; Llama a la subrutina que rellena

    ; === PASO 2: Pintar los 42 huecos negros (Grid 6x7) ===
    ; Usamos un bucle anidado para dibujar 6 filas de 7 huecos cada una.
    LD H, 4                      ; H = Fila Y inicial del primer hueco (Fila Lógica 0)
    LD D, 6                      ; D = Contador de filas de huecos (6 filas)

TABLERO_Row_Loop:
    PUSH HL                      ; Guardar H (posición Y de la fila actual)
    LD L, 4                      ; L = Columna X inicial (Columna Lógica 0)
    LD E, 7                      ; E = Contador de columnas de huecos (7 columnas)

TABLERO_Col_Loop:
    PUSH DE                      ; Guardar contadores D (filas) y E (columnas)
    PUSH HL                      ; Guardar H,L (posición actual del hueco)

    ; Pintar un HUECO (una ficha negra sobre fondo azul)
    ; Se usa la misma rutina que para pintar fichas de jugador.
    LD A, COLOR_INK_NEGRO + COLOR_PAPER_AZUL
    CALL FICHAS_PintarFicha_AjustadaTablero
    
    POP HL                       ; Recuperar H,L
    POP DE                       ; Recuperar D,E

    ; Avanzar a la siguiente columna de huecos
    ; La ficha mide 2 celdas + 2 celdas de barra azul = 4 celdas
    LD A, L
    ADD A, 4                     ; Avanza 4 columnas de caracteres
    LD L, A
    
    DEC E                        ; Decrementar contador de columnas (E)
    JR NZ, TABLERO_Col_Loop      ; Repetir 7 veces
    
    POP HL                       ; Recuperar H (posición Y de la fila)
    
    ; Avanzar a la siguiente fila de huecos
    ; La ficha mide 2 celdas + 1 celda de barra azul = 3 celdas
    LD A, H
    ADD A, 3                     ; Avanza 3 filas de caracteres
    LD H, A
    
    DEC D                        ; Decrementar contador de filas (D)
    JR NZ, TABLERO_Row_Loop      ; Repetir 6 veces

    POP IX: POP HL: POP DE: POP BC: POP AF
    RET

; ============================================================================================
; FUNCIÓN: TABLERO_RellenarRectAtributo
; Rellena un área de (B x C) caracteres en (H, L) con píxeles vacíos (0)
; y un atributo de color sólido (A).
;
; ENTRADA: B = Alto, C = Ancho, A = Color, HL = Coordenadas (Y,X)
; ============================================================================================
TABLERO_RellenarRectAtributo:
    PUSH AF: PUSH BC: PUSH DE: PUSH HL
    LD D, B              ; D = Contador de filas

TABLERO_RellenarRect_RowLoop:
    PUSH HL              ; Guardar H,L (inicio de la fila)
    LD E, C              ; E = Contador de columnas

TABLERO_RellenarRect_ColLoop:
    PUSH HL              ; Guardar H,L (celda actual)
    PUSH AF              ; Guardar Color (A)

    ; 1. Borrar píxeles (poner a 0)
    CALL POSXY_CalcPixelAddr_4000 ; HL = Dirección de píxel
    LD B, 8              ; 8 líneas de píxeles por carácter
    XOR A                ; A = 0
.Pixel_Loop:
    LD (HL), A           ; Escribir 0 en memoria de vídeo
    INC H                ; Siguiente línea de píxel
    DJNZ .Pixel_Loop

    ; 2. Pintar atributo
    POP AF               ; Recuperar Color (A)
    POP HL               ; Recuperar H,L (coordenadas)
    PUSH HL              ; Guardar H,L otra vez (POSXY lo modifica)

    CALL POSXY_CalcAttrAddr_5800 ; HL = Dirección de atributo
    LD (HL), A           ; Escribir el color
    
    POP HL               ; Recuperar H,L
    INC L                ; Siguiente columna (X+1)
    DEC E                ; Decrementar contador de columnas
    JR NZ, TABLERO_RellenarRect_ColLoop

    POP HL               ; Recuperar H,L (inicio de fila)
    INC H                ; Siguiente fila (Y+1)
    DEC D                ; Decrementar contador de filas
    JR NZ, TABLERO_RellenarRect_RowLoop

    POP HL: POP DE: POP BC: POP AF
    RET

; ============================================================================================
; RUTINAS AUXILIARES
; (Funciones de dibujo de matrices de fichas, que usabamos antes en el archivo 'core.asm')
; ============================================================================================
; --------------------------------------------------------------------------------------------
; TABLERO_DibujarMatrizFichas_Juego
; Dibuja N filas (D) de N fichas (B) con el espaciado del JUEGO (4 celdas H).
; --------------------------------------------------------------------------------------------
TABLERO_DibujarMatrizFichas_Juego:
    PUSH HL: PUSH AF: PUSH BC
    LD D, C                                     ; D = Contador de filas

TABLERO_DibujarMatrizFichas_Juego_Fila_Loop:
    PUSH HL: PUSH AF: PUSH BC

    CALL FICHAS_PintarNfichasSeparadas_Juego
    POP BC: POP AF: POP HL

    INC H: INC H: INC H                         ; Avanza 3 filas (Y)
    LD L, 4                                     ; Reinicia X a la columna 4
    DEC D
    JR NZ, TABLERO_DibujarMatrizFichas_Juego_Fila_Loop

    POP BC: POP AF: POP HL
    RET

; --------------------------------------------------------------------------------------------
; TABLERO_DibujarMatrizFichas
; Dibuja N filas (D) de N fichas (B) con el espaciado de PORTADA (3 celdas H).
; --------------------------------------------------------------------------------------------
TABLERO_DibujarMatrizFichas:
    PUSH HL: PUSH AF: PUSH BC
    LD D, C                                     ; D = Contador de filas

TABLERO_DibujarMatrizFichas_Fila_Loop:
    PUSH HL: PUSH AF: PUSH BC
    
    CALL FICHAS_PintarNfichasSeparadas
    POP BC: POP AF: POP HL

    INC H: INC H: INC H                         ; Avanza 3 filas (Y)
    LD L, 3                                     ; Reinicia X a la columna 3
    DEC D                                       ; Decrementar contador de filas con el fin de evitar pintar de más (filas sobrantes)
    JR NZ, TABLERO_DibujarMatrizFichas_Fila_Loop

    POP BC: POP AF: POP HL
    RET