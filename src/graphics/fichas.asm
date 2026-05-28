; =============================================================================================
; ARCHIVO: fichas.asm
; USO: Núcleo gráfico para dibujar las FICHAS DE JUGADOR (círculos rellenos).
;      Contiene la rutina de bajo nivel (8x8) y las de alto nivel (16x16).
; =============================================================================================

; --------------------------------------------------------------------------------------------
; FICHAS_PintarMatriz8x8
; Dibuja una matriz de 8x8 píxeles (un carácter) en la pantalla.
; Es la rutina gráfica de más bajo nivel.
;
; ENTRADA:
;     HL -> Coordenadas (H = Y, L = X)
;     A  -> Color del atributo (byte de color, ej: INK_ROJO + PAPER_AZUL)
;     IX -> Dirección de la matriz de 8 bytes (patrón de píxeles)
;
; PROCESO:
;     1. Calcula la dirección de atributos ($5800) y escribe el color (A).
;     2. Calcula la dirección de píxeles ($4000) y la pone en HL.
;     3. Entra en un bucle (B=8) que copia 8 bytes de (IX) a (HL),
;        incrementando H (fila de píxeles) e IX (fuente) en cada paso.
; --------------------------------------------------------------------------------------------
FICHAS_PintarMatriz8x8:
    PUSH BC: PUSH DE: PUSH IY              ; Preservar registros
    PUSH AF                                ; Preservar AF (el color)

    LD IY, IX                              ; Guardar IX (puntero a matriz) en IY
    LD DE, HL                              ; Guardar coordenadas (H,L) en DE

    ; 1. PINTAR ATRIBUTO DE COLOR
    CALL POSXY_CalcAttrAddr_5800           ; HL = dirección de atributo
    LD (HL), A                             ; Escribir el color en $58xx

    ; 2. CALCULAR POSICIÓN DE PÍXELES
    LD HL, DE                              ; Restaurar coordenadas (H,L)
    CALL POSXY_CalcPixelAddr_4000          ; HL = dirección de píxel en $4xxx

    LD B, 8                                ; Contador de 8 filas

; 3. BUCLE DE DIBUJO (Copia 8 bytes de IX a HL)
FICHAS_PaintMatrix8x8_Loop:
    LD C, (IX)                             ; C = byte del patrón de píxeles
    LD (HL), C                             ; Escribir el byte en la memoria de vídeo
    
    INC IX                                 ; Siguiente byte del patrón
    INC H                                  ; Siguiente fila de píxeles en pantalla
    DEC B
    JR NZ, FICHAS_PaintMatrix8x8_Loop      ; Repetir 8 veces

    ; 4. RESTAURACIÓN
    LD HL, DE                              ; Restaurar coordenadas originales
    LD IX, IY                              ; Restaurar puntero a matriz original

    POP AF                                 ; Restaurar AF (color)
    POP IY: POP DE: POP BC
    RET

; ==========================================================================
; FUNCION: FICHAS_PintarFicha16
; Pinta una ficha circular RELLENA de 16x16 píxeles (4 caracteres 8x8).
; Usa las matrices "_FICHA" (ej. MATRIZ_CIRCULO_ARRIBA_IZQUIERDA_FICHA).
;
; ENTRADA:
;   H = fila (Y)
;   L = columna (X)
;   A = color de la ficha
; ==========================================================================
FICHAS_PintarFicha16:
    PUSH HL: PUSH AF

    ; Cuadrante superior izquierdo
    LD IX, MATRIZ_CIRCULO_ARRIBA_IZQUIERDA_FICHA
    CALL FICHAS_PintarMatriz8x8

    ; Cuadrante superior derecho
    INC L
    LD IX, MATRIZ_CIRCULO_ARRIBA_DERECHA_FICHA
    CALL FICHAS_PintarMatriz8x8

    ; Cuadrante inferior derecho
    INC H
    LD IX, MATRIZ_CIRCULO_ABAJO_DERECHA_FICHA
    CALL FICHAS_PintarMatriz8x8

    ; Cuadrante inferior izquierdo
    DEC L
    LD IX, MATRIZ_CIRCULO_ABAJO_IZQUIERDA_FICHA
    CALL FICHAS_PintarMatriz8x8

    POP AF: POP HL
    RET

; ==========================================================================
; FUNCIÓN: FICHAS_PintarFicha_AjustadaTablero
; Pinta una ficha RELLENA de 16x16. Es funcionalmente idéntica a FICHAS_PintarFicha16
; y es la que se usa en el juego (tablero, preview, animación).
;
; ENTRADAS:
;   H = fila (Y)
;   L = columna (X)
;   A = color de la ficha
; ==========================================================================
FICHAS_PintarFicha_AjustadaTablero:
    PUSH HL: PUSH AF

    ; Cuadrante superior izquierdo
    LD IX, MATRIZ_CIRCULO_ARRIBA_IZQUIERDA_FICHA
    CALL FICHAS_PintarMatriz8x8

    ; Cuadrante superior derecho
    INC L
    LD IX, MATRIZ_CIRCULO_ARRIBA_DERECHA_FICHA
    CALL FICHAS_PintarMatriz8x8

    ; Cuadrante inferior derecho
    INC H
    LD IX, MATRIZ_CIRCULO_ABAJO_DERECHA_FICHA
    CALL FICHAS_PintarMatriz8x8

    ; Cuadrante inferior izquierdo
    DEC L
    LD IX, MATRIZ_CIRCULO_ABAJO_IZQUIERDA_FICHA
    CALL FICHAS_PintarMatriz8x8

    POP AF: POP HL
    RET

; ==========================================================================
; FUNCION: FICHAS_PintarNfichas
; Pinta N fichas (rellenas) una al lado de la otra (pegadas).
;
; ENTRADAS:
;   H = Y inicial (fila)
;   L = X inicial (columna)
;   A = color
;   B = número de fichas a pintar
; ==========================================================================
FICHAS_PintarNfichas:
    PUSH HL: PUSH AF: PUSH BC

FICHAS_PaintNDiscs_Loop:
    CALL FICHAS_PintarFicha16           ; Pinta una ficha
    INC L                               ; Mueve a la siguiente columna (pegado)
    DJNZ FICHAS_PaintNDiscs_Loop        ; Repite B veces

    POP BC: POP AF: POP HL
    RET

; ==========================================================================
; FUNCION: FICHAS_PintarNfichasSeparadas
; Pinta N fichas (rellenas) con espacio entre ellas.
; Usado por la portada (via utils).
;
; ENTRADAS:
;   H, L = Coordenadas
;   A = Color
;   B = Número de fichas
; ==========================================================================
FICHAS_PintarNfichasSeparadas:
    PUSH HL: PUSH AF: PUSH BC

FICHAS_PintarNfichasSeparadas_Loop:
    CALL FICHAS_PintarFicha16
    INC L: INC L: INC L                 ; Avanza 3 posiciones para dejar espacio
    DJNZ FICHAS_PintarNfichasSeparadas_Loop

    POP BC: POP AF: POP HL
    RET

; ==========================================================================
; FUNCIÓN: FICHAS_PintarNfichasSeparadas_Juego
; Pinta N fichas (rellenas) con el espaciado específico del tablero (4 celdas).
;
; ENTRADAS:
;   H, L = Coordenadas
;   A = color
;   B = número de fichas (normalmente 7)
; ==========================================================================
FICHAS_PintarNfichasSeparadas_Juego:
    PUSH HL: PUSH AF: PUSH BC
    
FICHAS_PintarNfichasSeparadas_Juego_Loop:
    CALL FICHAS_PintarFicha_AjustadaTablero
    INC L: INC L: INC L: INC L      ; Avanza 4 celdas (espacio del tablero)
    DEC B
    JR NZ, FICHAS_PintarNfichasSeparadas_Juego_Loop
    POP BC: POP AF: POP HL
    RET